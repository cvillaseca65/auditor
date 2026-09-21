import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<String?> offlineDocumentsRoot() async {
  final dir = await getApplicationDocumentsDirectory();
  return '${dir.path}/audit_offline';
}

Future<void> offlineEnsureDir(String path) async {
  final d = Directory(path);
  if (!await d.exists()) {
    await d.create(recursive: true);
  }
}

Future<bool> offlineFileExists(String path) async => File(path).exists();

Future<void> offlineWriteString(String path, String contents) async {
  await File(path).writeAsString(contents, flush: true);
}

Future<String?> offlineReadString(String path) async {
  final f = File(path);
  if (!await f.exists()) return null;
  return f.readAsString();
}

Future<void> offlineWriteBytes(String path, Uint8List bytes) async {
  await File(path).writeAsBytes(bytes, flush: true);
}

Future<Uint8List?> offlineReadBytes(String path) async {
  final f = File(path);
  if (!await f.exists()) return null;
  return f.readAsBytes();
}

Future<void> offlineDeleteFile(String path) async {
  final f = File(path);
  if (await f.exists()) {
    await f.delete();
  }
}
