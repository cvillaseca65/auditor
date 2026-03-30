import 'dart:typed_data';

import 'file_bytes_stub.dart' if (dart.library.io) 'file_bytes_io.dart' as impl;

Future<Uint8List?> readLocalFileBytes(String path) =>
    impl.readLocalFileBytes(path);
