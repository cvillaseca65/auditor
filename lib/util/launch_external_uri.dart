import 'package:url_launcher/url_launcher.dart';

import 'launch_mailto_stub.dart'
    if (dart.library.html) 'launch_mailto_web.dart';

/// Abre tel:, mailto:, https:, etc. (mailto fiable en Flutter web).
Future<bool> launchExternalUri(Uri uri) async {
  if (uri.scheme == 'mailto') {
    if (await openMailtoOnWeb(uri)) {
      return true;
    }
  }

  if (await canLaunchUrl(uri)) {
    return launchUrl(uri, mode: LaunchMode.platformDefault);
  }
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
