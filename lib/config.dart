// lib/config.dart

class ApiConfig {
  /// Base de la API (producción por defecto).
  ///
  /// Contra `sim` local, por ejemplo:
  /// `flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000`
  /// En emulador Android hacia el PC: `http://10.0.2.2:8000`
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://www.simfour.com',
  );

  /// Timeout para todas las solicitudes HTTP (en segundos)
  static const int timeoutSeconds = 30;

  /// Django: endpoint que indica si el usuario tiene planes de auditoría pendientes.
  /// Respuesta esperada: `200` y JSON `{"has_pending": true|false}`.
  /// Si el endpoint aún no existe (`404`, etc.), la app asume `has_pending: false`
  /// y solo mostrará la opción Hallazgo en el menú post-login.
  static const String pendingAuditPlansStatusPath =
      '/api/v1/auditor/pending-plans-status/';

  /// Compañías con planes donde el usuario es auditor (misma lógica que el dashboard).
  static const String auditCompaniesPath = '/api/v1/companies/';

  /// NC / Hallazgos (createNc en Django `nc/create/`).
  static const String ncCompaniesPath = '/api/v1/nc/companies/';
  static const String ncFormOptionsPath = '/api/v1/nc/form-options/';
  static const String ncCompanyUsersSearchPath =
      '/api/v1/nc/company-users/search/';
  static const String ncCreatePath = '/api/v1/nc/create/';
  static String ncAttachmentPath(int ncId) =>
      '/api/v1/nc/$ncId/attachments/';

  /// Headers por defecto para requests JSON
  static Map<String, String> defaultHeaders({String? token}) {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}