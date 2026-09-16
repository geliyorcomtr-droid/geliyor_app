import 'dart:math' as math;
import 'dart:typed_data';

import 'package:image/image.dart' as img;

class PreparedUploadImage {
  const PreparedUploadImage({
    required this.bytes,
    required this.fileName,
    required this.contentType,
  });

  final Uint8List bytes;
  final String fileName;
  final String contentType;
}

enum UploadImageStyle {
  /// Banner / reklam / ürün fotoğrafı.
  photo,

  /// Marka, kategori, rozet ikonu.
  icon,
}

/// 1–2 MB görselleri ekranda net kalacak kadar küçültüp JPEG’e çevirir.
PreparedUploadImage prepareUploadImage(
  Uint8List bytes,
  String originalName, {
  UploadImageStyle style = UploadImageStyle.photo,
}) {
  if (bytes.isEmpty) {
    throw Exception('Dosya okunamadı, başka bir görsel dene.');
  }

  final lower = originalName.toLowerCase();
  if (lower.endsWith('.svg')) {
    return PreparedUploadImage(
      bytes: bytes,
      fileName: _safeName(originalName, '.svg'),
      contentType: 'image/svg+xml',
    );
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('Bu görsel okunamadı. JPG veya PNG dene.');
  }

  final maxEdge = style == UploadImageStyle.icon ? 512 : 1080;
  final maxBytes = style == UploadImageStyle.icon ? 120 * 1024 : 250 * 1024;
  final keepAlpha = style == UploadImageStyle.icon && decoded.hasAlpha;

  var image = decoded;
  final longest = math.max(image.width, image.height);
  if (longest > maxEdge) {
    final scale = maxEdge / longest;
    image = img.copyResize(
      image,
      width: math.max(1, (image.width * scale).round()),
      height: math.max(1, (image.height * scale).round()),
      interpolation: img.Interpolation.linear,
    );
  }

  if (keepAlpha) {
    final png = Uint8List.fromList(img.encodePng(image, level: 6));
    return PreparedUploadImage(
      bytes: png.length < bytes.length ? png : bytes,
      fileName: _safeName(originalName, '.png'),
      contentType: 'image/png',
    );
  }

  Uint8List best = Uint8List.fromList(img.encodeJpg(image, quality: 80));
  for (final quality in const [80, 72, 64]) {
    final encoded = Uint8List.fromList(img.encodeJpg(image, quality: quality));
    best = encoded;
    if (encoded.length <= maxBytes) break;
  }

  return PreparedUploadImage(
    bytes: best,
    fileName: _safeName(originalName, '.jpg'),
    contentType: 'image/jpeg',
  );
}

String _safeName(String originalName, String extension) {
  final base = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final dot = base.lastIndexOf('.');
  final stem = dot > 0 ? base.substring(0, dot) : base;
  return '$stem$extension';
}
