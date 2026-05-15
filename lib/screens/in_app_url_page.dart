import 'package:flutter/material.dart';

import 'in_app_url_body_stub.dart'
    if (dart.library.html) 'in_app_url_body_web.dart';

/// Abre PDF/archivo dentro de la app (iframe en web).
class InAppUrlPage extends StatelessWidget {
  const InAppUrlPage({
    super.key,
    required this.url,
    this.title = 'Documento',
    this.embedded = false,
  });

  final String url;
  final String title;
  /// Sin AppBar propio (p. ej. formulario NC embebido).
  final bool embedded;

  @override
  Widget build(BuildContext context) {
    if (embedded) {
      return InAppUrlBody(url: url);
    }
    return Scaffold(
      appBar: AppBar(title: Text(title, maxLines: 1)),
      body: InAppUrlBody(url: url),
    );
  }
}
