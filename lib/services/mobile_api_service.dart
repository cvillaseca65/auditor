import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import '../models/mobile_models.dart';
import '../util/plazo_sort.dart';
import 'session_service.dart';

class MobileApiException implements Exception {
  final String message;
  final int? statusCode;

  MobileApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class MobileApiService {
  static int _cmpInsensitive(String a, String b) {
    return a.toLowerCase().trim().compareTo(b.toLowerCase().trim());
  }

  static void _sortPendingRows(List<PendingRow> rows) {
    rows.sort((a, b) {
      final c = comparePlazoAscendingNullable(
        pendingPlazoDays(endIso: a.endIso, alertText: a.alertText),
        pendingPlazoDays(endIso: b.endIso, alertText: b.alertText),
      );
      if (c != 0) return c;
      return _cmpInsensitive(a.title, b.title);
    });
  }

  static void _sortOwedRows(List<OwedRow> rows) {
    rows.sort((a, b) {
      final c = comparePlazoAscendingNullable(
        pendingPlazoDays(endIso: a.endIso, alertText: a.alertText),
        pendingPlazoDays(endIso: b.endIso, alertText: b.alertText),
      );
      if (c != 0) return c;
      return _cmpInsensitive(a.title, b.title);
    });
  }

  Future<Map<String, String>> _headers() async {
    final token = await SessionService.getToken();
    final companyId = await SessionService.getCompanyId();
    final headers = {
      ...ApiConfig.defaultHeaders(token: token),
      'Content-Type': 'application/json',
    };
    if (companyId != null) {
      headers['X-Company-ID'] = companyId.toString();
    }
    return headers;
  }

  Future<http.Response> _get(String path, {Map<String, String>? query}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(
      queryParameters: query,
    );
    final response = await http
        .get(uri, headers: await _headers())
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    if (response.statusCode == 401) {
      throw MobileApiException('Sesión expirada', statusCode: 401);
    }
    if (response.statusCode >= 400) {
      throw MobileApiException(
        _errorDetail(response),
        statusCode: response.statusCode,
      );
    }
    return response;
  }

  String _errorDetail(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      return _formatDrfErrorBody(decoded) ?? 'Error ${response.statusCode}';
    } catch (_) {
      return 'Error ${response.statusCode}';
    }
  }

  /// Texto legible a partir de respuestas de error JSON de DRF (dict, lista o detail).
  String? _formatDrfErrorBody(dynamic data) {
    if (data == null) {
      return null;
    }
    if (data is String) {
      return data.isEmpty ? null : data;
    }
    if (data is List) {
      if (data.isEmpty) {
        return null;
      }
      return data.map((e) => e.toString()).join('\n');
    }
    if (data is Map<String, dynamic>) {
      if (data.containsKey('detail')) {
        final d = data['detail'];
        if (d is List && d.isNotEmpty) {
          return d.map((e) => e.toString()).join('\n');
        }
        final s = d?.toString();
        if (s != null && s.isNotEmpty) {
          return s;
        }
      }
      final parts = <String>[];
      data.forEach((key, value) {
        if (value is List) {
          for (final item in value) {
            parts.add('$key: $item');
          }
        } else if (value != null) {
          parts.add('$key: $value');
        }
      });
      if (parts.isNotEmpty) {
        return parts.join('\n');
      }
    }
    return data.toString();
  }

  /// Obtiene primer nombre desde GET /api/v1/me/ y lo guarda para el saludo.
  /// Si [fallbackUsername] se pasa y no hay nombre en SIM, usa ese texto.
  Future<void> syncWelcomeFirstNameFromServer({String? fallbackUsername}) async {
    final token = await SessionService.getToken();
    if (token == null || token.isEmpty) return;
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.currentUserPath}');
      final response = await http
          .get(
            uri,
            headers: {
              ...ApiConfig.defaultHeaders(token: token),
              'Content-Type': 'application/json',
            },
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
      if (response.statusCode != 200) return;
      final data = jsonDecode(response.body);
      if (data is! Map<String, dynamic>) return;
      var first = (data['first_name'] as String?)?.trim() ?? '';
      if (first.isEmpty) {
        final full = (data['name'] as String?)?.trim() ?? '';
        if (full.isNotEmpty) {
          first = full.split(RegExp(r'\s+')).first;
        }
      }
      if (first.isNotEmpty) {
        await SessionService.setUserDisplayName(first);
        return;
      }
    } catch (_) {
      /* login / inicio puede seguir sin saludo personalizado */
    }
    final fb = fallbackUsername?.trim();
    if (fb != null && fb.isNotEmpty) {
      await SessionService.setUserDisplayName(fb);
    }
  }

  Future<List<CompanyOption>> fetchCompanies() async {
    final token = await SessionService.getToken();
    final response = await http
        .get(
          Uri.parse('${ApiConfig.baseUrl}${ApiConfig.ncCompaniesPath}'),
          headers: ApiConfig.defaultHeaders(token: token),
        )
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    if (response.statusCode != 200) {
      throw MobileApiException(_errorDetail(response), statusCode: response.statusCode);
    }
    final list = jsonDecode(response.body) as List<dynamic>;
    final out = list
        .map((e) => CompanyOption.fromJson(e as Map<String, dynamic>))
        .toList();
    out.sort((a, b) => _cmpInsensitive(a.name, b.name));
    return out;
  }

  Future<({
    PendingSummary summary,
    OrganizationSummary organizationSummary,
    HallazgosSummary hallazgosSummary,
    List<PendingRow> myItems,
    List<OwedRow> owedItems,
  })> fetchHomePending() async {
    final response = await _get(ApiConfig.mobileHomePendingPath);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final summary = PendingSummary.fromJson(
      data['summary'] as Map<String, dynamic>? ?? {},
    );
    final organizationSummary = OrganizationSummary.fromJson(
      data['organization_summary'] as Map<String, dynamic>? ?? {},
    );
    final hallazgosSummary = HallazgosSummary.fromJson(
      data['hallazgos_summary'] as Map<String, dynamic>? ?? {},
    );
    final myItems = (data['my_items'] as List<dynamic>? ?? [])
        .map((e) => PendingRow.fromJson(e as Map<String, dynamic>))
        .toList();
    final owedItems = (data['owed_items'] as List<dynamic>? ?? [])
        .map((e) => OwedRow.fromJson(e as Map<String, dynamic>))
        .toList();
    _sortPendingRows(myItems);
    _sortOwedRows(owedItems);
    return (
      summary: summary,
      organizationSummary: organizationSummary,
      hallazgosSummary: hallazgosSummary,
      myItems: myItems,
      owedItems: owedItems,
    );
  }

  Future<List<NcListItem>> fetchNcList({
    required String tab,
    String? query,
  }) async {
    final queryParams = <String, String>{'tab': tab};
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    final response = await _get(ApiConfig.mobileNcListPath, query: queryParams);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (data['results'] as List<dynamic>? ?? [])
        .map((e) => NcListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    if (tab.toLowerCase() == 'closed') {
      rows.sort((a, b) {
        final da = DateTime.tryParse(a.date);
        final db = DateTime.tryParse(b.date);
        if (da != null && db != null) {
          final c = db.compareTo(da);
          if (c != 0) return c;
        }
        return b.id.compareTo(a.id);
      });
    } else {
      rows.sort((a, b) {
        final c = comparePlazoAscendingNullable(
          pendingPlazoDays(endIso: null, alertText: a.alertText),
          pendingPlazoDays(endIso: null, alertText: b.alertText),
        );
        if (c != 0) return c;
        return _cmpInsensitive(a.finding, b.finding);
      });
    }
    return rows;
  }

  Future<Map<String, dynamic>> fetchNcDetail(int id) async {
    final response = await _get(ApiConfig.mobileNcDetailPath(id));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitNcWorkflow(
    int id,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.mobileNcWorkflowPath(id)}');
    final response = await http
        .post(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    if (response.statusCode == 401) {
      throw MobileApiException('Sesión expirada', statusCode: 401);
    }
    if (response.statusCode >= 400) {
      try {
        final decoded = jsonDecode(response.body);
        final message = _formatDrfErrorBody(decoded);
        if (message != null && message.isNotEmpty) {
          throw MobileApiException(message, statusCode: response.statusCode);
        }
      } catch (e) {
        if (e is MobileApiException) rethrow;
      }
      throw MobileApiException(_errorDetail(response), statusCode: response.statusCode);
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchPendingAction(
    String actionType,
    int objectId,
  ) async {
    final response = await _get(
      ApiConfig.mobilePendingActionPath(actionType, objectId),
    );
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> submitPendingAction(
    String actionType,
    int objectId,
    Map<String, dynamic> body,
  ) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.mobilePendingActionPath(actionType, objectId)}',
    );
    final response = await http
        .post(uri, headers: await _headers(), body: jsonEncode(body))
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));
    if (response.statusCode == 401) {
      throw MobileApiException('Sesión expirada', statusCode: 401);
    }
    if (response.statusCode >= 400) {
      try {
        final decoded = jsonDecode(response.body);
        final message = _formatDrfErrorBody(decoded);
        if (message != null && message.isNotEmpty) {
          throw MobileApiException(message, statusCode: response.statusCode);
        }
      } catch (e) {
        if (e is MobileApiException) rethrow;
      }
      throw MobileApiException(
        _errorDetail(response),
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<DocumentListItem>> fetchDocuments({String? query}) async {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    final response = await _get(
      ApiConfig.mobileDocumentsPath,
      query: queryParams.isEmpty ? null : queryParams,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (data['results'] as List<dynamic>? ?? [])
        .map((e) => DocumentListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    rows.sort((a, b) {
      final pa = DateTime.tryParse(a.publication);
      final pb = DateTime.tryParse(b.publication);
      if (pa != null && pb != null) {
        final c = pb.compareTo(pa);
        if (c != 0) return c;
      }
      return _cmpInsensitive('${a.code} ${a.title}', '${b.code} ${b.title}');
    });
    return rows;
  }

  Future<Map<String, dynamic>> fetchDocumentDetail(int id) async {
    final response = await _get(ApiConfig.mobileDocumentDetailPath(id));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<NormativeListItem>> fetchNormative({String? query}) async {
    final queryParams = <String, String>{};
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    final response = await _get(
      ApiConfig.mobileNormativePath,
      query: queryParams.isEmpty ? null : queryParams,
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (data['results'] as List<dynamic>? ?? [])
        .map((e) => NormativeListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    rows.sort((a, b) => _cmpInsensitive(a.title, b.title));
    return rows;
  }

  Future<Map<String, dynamic>> fetchNormativeDetail(String slug) async {
    final response = await _get(ApiConfig.mobileNormativeDetailPath(slug));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> fetchComplyDetail(int complyId) async {
    final response = await _get(ApiConfig.mobileComplyDetailPath(complyId));
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  Future<List<UserListItem>> fetchUsers({String? query, String active = '1'}) async {
    final queryParams = <String, String>{'active': active};
    if (query != null && query.isNotEmpty) {
      queryParams['q'] = query;
    }
    final response = await _get(ApiConfig.mobileUsersPath, query: queryParams);
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (data['results'] as List<dynamic>? ?? [])
        .map((e) => UserListItem.fromJson(e as Map<String, dynamic>))
        .toList();
    rows.sort((a, b) => _cmpInsensitive(a.name, b.name));
    return rows;
  }

  Future<UserProfile> fetchUserProfile(int id) async {
    final response = await _get(ApiConfig.mobileUserDetailPath(id));
    return UserProfile.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<UserSkillItem>> fetchUserSkills(int id) async {
    final response = await _get(ApiConfig.mobileUserSkillsPath(id));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (data['results'] as List<dynamic>? ?? [])
        .map((e) => UserSkillItem.fromJson(e as Map<String, dynamic>))
        .toList();
    rows.sort((a, b) {
      final c = comparePlazoAscendingNullable(
        pendingPlazoDays(endIso: a.deadline, alertText: a.alertText),
        pendingPlazoDays(endIso: b.deadline, alertText: b.alertText),
      );
      if (c != 0) return c;
      return _cmpInsensitive(a.skillType, b.skillType);
    });
    return rows;
  }

  Future<List<UserPerformanceItem>> fetchUserPerformance(int id) async {
    final response = await _get(ApiConfig.mobileUserPerformancePath(id));
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (data['results'] as List<dynamic>? ?? [])
        .map((e) => UserPerformanceItem.fromJson(e as Map<String, dynamic>))
        .toList();
    rows.sort((a, b) {
      final c = comparePlazoAscendingNullable(
        pendingPlazoDays(endIso: a.end.isNotEmpty ? a.end : null, alertText: a.alertText),
        pendingPlazoDays(endIso: b.end.isNotEmpty ? b.end : null, alertText: b.alertText),
      );
      if (c != 0) return c;
      return b.id.compareTo(a.id);
    });
    return rows;
  }

  Future<List<UserTaskItem>> fetchUserTasks(int id, {required String tab}) async {
    final response = await _get(
      ApiConfig.mobileUserTasksPath(id),
      query: {'tab': tab},
    );
    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final rows = (data['results'] as List<dynamic>? ?? [])
        .map((e) => UserTaskItem.fromJson(e as Map<String, dynamic>))
        .toList();
    final tabKey = tab.trim().toLowerCase();
    void sortByPlazoAsc() {
      rows.sort((a, b) {
        final c = comparePlazoAscendingNullable(
          pendingPlazoDays(
            endIso: a.end.trim().isEmpty ? null : a.end,
            alertText: a.alertText,
          ),
          pendingPlazoDays(
            endIso: b.end.trim().isEmpty ? null : b.end,
            alertText: b.alertText,
          ),
        );
        if (c != 0) return c;
        return _cmpInsensitive(a.subject, b.subject);
      });
    }

    if (tabKey == 'closed') {
      rows.sort((a, b) {
        final ea = DateTime.tryParse(a.end);
        final eb = DateTime.tryParse(b.end);
        if (ea != null && eb != null) {
          final c = eb.compareTo(ea);
          if (c != 0) return c;
        }
        return b.id.compareTo(a.id);
      });
    } else {
      sortByPlazoAsc();
    }
    return rows;
  }
}
