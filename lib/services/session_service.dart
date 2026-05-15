import 'package:shared_preferences/shared_preferences.dart';

class SessionService {
  static const _tokenKey = 'jwt_token';
  static const _companyKey = 'company_id';
  static const _companyNameKey = 'company_name';
  static const _companyLogoKey = 'company_logo_url';
  static const _userDisplayNameKey = 'user_display_name';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_companyKey);
    await prefs.remove(_companyNameKey);
    await prefs.remove(_companyLogoKey);
    await prefs.remove(_userDisplayNameKey);
  }

  /// Nombre para saludo en inicio (se guarda al iniciar sesión).
  static Future<void> setUserDisplayName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    final t = name.trim();
    if (t.isEmpty) {
      await prefs.remove(_userDisplayNameKey);
    } else {
      await prefs.setString(_userDisplayNameKey, t);
    }
  }

  static Future<String?> getUserDisplayName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userDisplayNameKey);
  }

  static Future<int?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_companyKey);
  }

  static Future<String?> getCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyNameKey);
  }

  static Future<String?> getCompanyLogoUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyLogoKey);
  }

  static Future<void> setCompany(int id, String name, {String? logoUrl}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_companyKey, id);
    await prefs.setString(_companyNameKey, name);
    if (logoUrl != null && logoUrl.isNotEmpty) {
      await prefs.setString(_companyLogoKey, logoUrl);
    } else {
      await prefs.remove(_companyLogoKey);
    }
  }
}
