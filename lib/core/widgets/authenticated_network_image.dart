import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../services/mobile_api_service.dart';
import 'sim_loading_indicator.dart';

/// Imagen de medios SIM con cabecera JWT (adjuntos, fotos en documentos).
class AuthenticatedNetworkImage extends StatefulWidget {
  const AuthenticatedNetworkImage({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.height,
    this.width,
    this.borderRadius,
  });

  final String url;
  final BoxFit fit;
  final double? height;
  final double? width;
  final BorderRadius? borderRadius;

  @override
  State<AuthenticatedNetworkImage> createState() =>
      _AuthenticatedNetworkImageState();
}

class _AuthenticatedNetworkImageState extends State<AuthenticatedNetworkImage> {
  Uint8List? _bytes;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant AuthenticatedNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url) {
      _bytes = null;
      _error = null;
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final headers = await MobileApiService().authHeadersForMedia();
      final response = await http
          .get(Uri.parse(widget.url), headers: headers)
          .timeout(const Duration(seconds: 45));
      if (!mounted) return;
      if (response.statusCode == 200) {
        setState(() => _bytes = response.bodyBytes);
      } else {
        setState(() => _error = response.statusCode);
      }
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    Widget child;

    if (_bytes != null) {
      child = Image.memory(
        _bytes!,
        fit: widget.fit,
        width: widget.width,
        height: widget.height,
      );
    } else if (_error != null) {
      child = SizedBox(
        height: widget.height ?? 120,
        width: widget.width,
        child: Center(
          child: Icon(Icons.broken_image_outlined, color: scheme.error),
        ),
      );
    } else {
      child = SizedBox(
        height: widget.height ?? 120,
        width: widget.width,
        child: const Center(child: SimLoadingIndicator.compact()),
      );
    }

    if (widget.borderRadius != null) {
      child = ClipRRect(borderRadius: widget.borderRadius!, child: child);
    }
    return child;
  }
}
