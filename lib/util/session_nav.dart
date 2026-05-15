import 'package:flutter/material.dart';

import '../screens/login_page.dart';
import '../services/session_service.dart';

/// Cierra sesión y vuelve al login usando el navegador raíz (no el de pestaña).
Future<void> navigateToLogin(BuildContext context) async {
  await SessionService.clearSession();
  if (!context.mounted) return;
  Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => const LoginPage()),
    (route) => false,
  );
}
