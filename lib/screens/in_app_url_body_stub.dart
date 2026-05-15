import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Vista embebida en plataformas sin iframe (abre visor del sistema).
class InAppUrlBody extends StatefulWidget {
  const InAppUrlBody({super.key, required this.url});

  final String url;

  @override
  State<InAppUrlBody> createState() => _InAppUrlBodyState();
}

class _InAppUrlBodyState extends State<InAppUrlBody> {
  @override
  void initState() {
    super.initState();
    _open();
  }

  Future<void> _open() async {
    final uri = Uri.parse(widget.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.inAppWebView);
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'Si no se abrió el documento, use el botón del navegador para volver.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
