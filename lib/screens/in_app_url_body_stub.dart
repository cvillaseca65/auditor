import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../core/widgets/sim_loading_indicator.dart';
import '../services/mobile_api_service.dart';

/// PDF / documentos en WebView con autenticación (Android / iOS).
class InAppUrlBody extends StatefulWidget {
  const InAppUrlBody({super.key, required this.url});

  final String url;

  @override
  State<InAppUrlBody> createState() => _InAppUrlBodyState();
}

class _InAppUrlBodyState extends State<InAppUrlBody> {
  WebViewController? _controller;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    try {
      final headers = await MobileApiService().authHeadersForMedia();
      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (_) {
              if (mounted) setState(() => _loading = false);
            },
            onWebResourceError: (err) {
              if (mounted) {
                setState(() {
                  _error = err.description;
                  _loading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse(widget.url), headers: headers);
      if (!mounted) return;
      setState(() => _controller = controller);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (_controller == null) {
      return const Center(child: SimLoadingIndicator());
    }
    return Stack(
      children: [
        WebViewWidget(controller: _controller!),
        if (_loading)
          const ColoredBox(
            color: Color(0x88FFFFFF),
            child: Center(child: SimLoadingIndicator()),
          ),
      ],
    );
  }
}
