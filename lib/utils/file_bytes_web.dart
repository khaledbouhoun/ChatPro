import 'dart:typed_data';

Future<Uint8List> getFileBytes(String path) =>
    Future.error(UnsupportedError('getFileBytes is not supported on web; provide bytes directly'));
