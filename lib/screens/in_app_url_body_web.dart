// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:ui_web' as ui_web;

import 'package:flutter/material.dart';

/// Iframe a pantalla completa (Chrome / web).
class InAppUrlBody extends StatefulWidget {
  const InAppUrlBody({super.key, required this.url});

  final String url;

  @override
  State<InAppUrlBody> createState() => _InAppUrlBodyState();
}

class _InAppUrlBodyState extends State<InAppUrlBody> {
  late final String _viewType;

  @override
  void initState() {
    super.initState();
    _viewType = 'in-app-url-${widget.url.hashCode}';
    ui_web.platformViewRegistry.registerViewFactory(
      _viewType,
      (int viewId) => html.IFrameElement()
        ..src = widget.url
        ..style.border = 'none'
        ..style.width = '100%'
        ..style.height = '100%',
    );
  }

  @override
  Widget build(BuildContext context) {
    return HtmlElementView(viewType: _viewType);
  }
}
