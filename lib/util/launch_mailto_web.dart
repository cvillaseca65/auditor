// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

/// En navegador, `url_launcher` a menudo no abre clientes de correo; esto sí.
Future<bool> openMailtoOnWeb(Uri uri) async {
  html.window.location.href = uri.toString();
  return true;
}
