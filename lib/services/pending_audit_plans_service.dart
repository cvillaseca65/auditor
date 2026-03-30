import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';

/// Indica si el usuario debe ver el flujo de auditoría en el menú.
/// Usa el endpoint dedicado y, en paralelo, la lista de compañías de auditoría
/// (misma fuente que el dashboard) para cubrir servidores antiguos o discrepancias.
class PendingAuditPlansService {
  PendingAuditPlansService._();

  static Future<bool> userHasPendingPlans(String token) async {
    final companiesFuture = _auditCompaniesNonEmpty(token);
    final statusFuture = _fromStatusEndpoint(token);

    final fromCompanies = await companiesFuture;
    final fromStatus = await statusFuture;

    if (fromStatus == null) {
      return fromCompanies;
    }
    return fromStatus || fromCompanies;
  }

  /// `null` si no hubo respuesta 200 válida (p. ej. 404 en servidor viejo).
  static Future<bool?> _fromStatusEndpoint(String token) async {
    final uri = Uri.parse(
      '${ApiConfig.baseUrl}${ApiConfig.pendingAuditPlansStatusPath}',
    );
    try {
      final response = await http
          .get(
            uri,
            headers: {
              ...ApiConfig.defaultHeaders(token: token),
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode != 200) {
        return null;
      }

      final decoded = jsonDecode(response.body);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final hasPending = decoded['has_pending'];
      if (hasPending is bool) {
        return hasPending;
      }
      if (hasPending is String) {
        return hasPending.toLowerCase() == 'true';
      }

      final count = decoded['pending_count'];
      if (count is int) {
        return count > 0;
      }
      if (count is String) {
        final n = int.tryParse(count);
        return n != null && n > 0;
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> _auditCompaniesNonEmpty(String token) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.auditCompaniesPath}');
    try {
      final response = await http
          .get(
            uri,
            headers: {
              ...ApiConfig.defaultHeaders(token: token),
              'Accept': 'application/json',
            },
          )
          .timeout(Duration(seconds: ApiConfig.timeoutSeconds));

      if (response.statusCode != 200) {
        return false;
      }

      final decoded = jsonDecode(response.body);
      List<dynamic> data = [];
      if (decoded is List) {
        data = decoded;
      } else if (decoded is Map && decoded['results'] is List) {
        data = decoded['results'] as List;
      }
      return data.isNotEmpty;
    } catch (_) {
      return false;
    }
  }
}
