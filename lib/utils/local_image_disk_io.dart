import 'dart:io';
import 'dart:typed_data';

import 'package:path_provider/path_provider.dart';

Future<Uint8List?> readLocalImage(String key) async {
  try {
    final file = await _fileFor(key);
    if (!await file.exists()) return null;
    return file.readAsBytes();
  } catch (_) {
    return null;
  }
}

Future<void> writeLocalImage(String key, Uint8List bytes) async {
  try {
    final file = await _fileFor(key);
    await file.parent.create(recursive: true);
    await file.writeAsBytes(bytes, flush: true);
  } catch (_) {}
}

Future<File> _fileFor(String key) async {
  final dir = await getApplicationSupportDirectory();
  return File('${dir.path}/img_cache/$key');
}
