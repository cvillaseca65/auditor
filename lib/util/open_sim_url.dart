import 'package:url_launcher/url_launcher.dart';

Future<bool> openSimUrl(String url) async {
  if (url.isEmpty) return false;
  final uri = Uri.parse(url);
  if (!await canLaunchUrl(uri)) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
