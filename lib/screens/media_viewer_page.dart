import 'package:flutter/material.dart';

import '../core/widgets/authenticated_network_image.dart';
import '../core/widgets/mobile_detail/detail_utils.dart';
import '../core/widgets/sim_loading_indicator.dart';
import 'in_app_url_body_stub.dart'
    if (dart.library.html) 'in_app_url_body_web.dart';

/// Visor in-app: imágenes a pantalla completa; PDF y otros en WebView.
class MediaViewerPage extends StatelessWidget {
  const MediaViewerPage({
    super.key,
    required this.url,
    required this.title,
  });

  final String url;
  final String title;

  @override
  Widget build(BuildContext context) {
    final isImage = DetailUtils.isImageUrl(url, name: title);

    return Scaffold(
      backgroundColor: isImage ? Colors.black : null,
      appBar: AppBar(
        title: Text(title, maxLines: 1),
        backgroundColor: isImage ? Colors.black : null,
        foregroundColor: isImage ? Colors.white : null,
      ),
      body: isImage ? _ImageBody(url: url) : InAppUrlBody(url: url),
    );
  }
}

class _ImageBody extends StatelessWidget {
  const _ImageBody({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 4,
      child: Center(
        child: AuthenticatedNetworkImage(
          url: url,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
