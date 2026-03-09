// lib/config.dart

class ApiConfig {
  /// Dominio de tu API
  /// Debe ser HTTPS con certificado válido
  static const String baseUrl = 'https://www.simfour.com';

  /// Timeout para todas las solicitudes HTTP (en segundos)
  static const int timeoutSeconds = 30;

  /// Headers por defecto para requests JSON
  static Map<String, String> defaultHeaders({String? token}) {
    final headers = <String, String>{};
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }
}