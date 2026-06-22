import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../config.dart';

class AuditVerificationException implements Exception {
  AuditVerificationException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class AuditVerificationService {
  AuditVerificationService({
    required this.token,
    required this.companyId,
  });

  final String token;
  final int companyId;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $token',
        'X-Company-ID': companyId.toString(),
      };

  Future<Map<String, dynamic>> fetchDetail(int checkItemId) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/check-items/$checkItemId/verify/',
    );
    final response = await http
        .get(uri, headers: _headers)
        .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

    if (response.statusCode == 401) {
      throw AuditVerificationException('Sesión no válida', statusCode: 401);
    }
    if (response.statusCode != 200) {
      throw AuditVerificationException(
        'Error ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// [status] 1 = conforme, 2 = no conforme (requiere [ncFinding]).
  Future<Map<String, dynamic>> submit({
    required int checkItemId,
    required int status,
    required String evidence,
    String ncFinding = '',
    List<({String name, Uint8List bytes, String description})> uploads =
        const [],
  }) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}/api/v1/check-items/$checkItemId/verify/',
    );

    if (uploads.isEmpty) {
      final response = await http
          .post(
            uri,
            headers: {
              ..._headers,
              'Content-Type': 'application/json',
            },
            body: jsonEncode({
              'status': status,
              'evidence': evidence,
              'nc_finding': ncFinding,
            }),
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      return _parseSubmitResponse(response);
    }

    final request = http.MultipartRequest('POST', uri);
    request.headers.addAll(_headers);
    request.fields['status'] = status.toString();
    request.fields['evidence'] = evidence;
    request.fields['nc_finding'] = ncFinding;
    request.fields['document_descriptions'] = jsonEncode(
      uploads.map((u) => u.description).toList(),
    );
    for (final u in uploads) {
      request.files.add(
        http.MultipartFile.fromBytes(
          'attach_files',
          u.bytes,
          filename: u.name,
        ),
      );
    }

    final streamed = await request.send().timeout(
          Duration(seconds: ApiConfig.timeoutSeconds),
        );
    final response = await http.Response.fromStream(streamed);
    return _parseSubmitResponse(response);
  }

  Map<String, dynamic> _parseSubmitResponse(http.Response response) {
    if (response.statusCode == 401) {
      throw AuditVerificationException('Sesión no válida', statusCode: 401);
    }
    if (response.statusCode == 400) {
      var msg = 'Datos inválidos';
      try {
        final decoded = jsonDecode(response.body);
        if (decoded is Map && decoded['detail'] != null) {
          msg = '${decoded['detail']}';
        }
      } catch (_) {}
      throw AuditVerificationException(msg, statusCode: 400);
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw AuditVerificationException(
        'Error ${response.statusCode}',
        statusCode: response.statusCode,
      );
    }
    return jsonDecode(response.body) as Map<String, dynamic>;
  }
}
