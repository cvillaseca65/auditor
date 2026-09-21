import 'dart:typed_data';

Future<void> offlineEnsureDir(String path) async {}

Future<bool> offlineFileExists(String path) async => false;

Future<void> offlineWriteString(String path, String contents) async {}

Future<String?> offlineReadString(String path) async => null;

Future<void> offlineWriteBytes(String path, Uint8List bytes) async {}

Future<Uint8List?> offlineReadBytes(String path) async => null;

Future<void> offlineDeleteFile(String path) async {}

Future<String?> offlineDocumentsRoot() async => null;
