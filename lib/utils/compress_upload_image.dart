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

  int get kiloBytes => (bytes.length / 1024).ceil();
}

enum UploadImageStyle {
  /// Banner / ürün / ilan fotoğrafı.
  photo,

  /// Marka, kategori, rozet, fayda ikonu.
  icon,

  /// Karşılama ekranı (393×852 @ 3x).
  screen,
}

class UploadImageQuota {
  UploadImageQuota._();

  static const photoMaxEdge = 1080;
  static const photoMaxBytes = 200 * 1024;
  static const iconMaxEdge = 512;
  static const iconMaxBytes = 80 * 1024;
  static const screenMaxWidth = 1179; // 393 × 3
  static const screenMaxHeight = 2556; // 852 × 3
  static const screenMaxBytes = 400 * 1024;
}

/// Yüklenen her görseli tek standarda indirir; kota aşılırsa yüklemez.
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
    throw Exception('SVG yüklenemez. JPG veya PNG kullan.');
  }

  final decoded = img.decodeImage(bytes);
  if (decoded == null) {
    throw Exception('Bu görsel okunamadı. JPG veya PNG dene.');
  }

  final maxBytes = switch (style) {
    UploadImageStyle.icon => UploadImageQuota.iconMaxBytes,
    UploadImageStyle.screen => UploadImageQuota.screenMaxBytes,
    UploadImageStyle.photo => UploadImageQuota.photoMaxBytes,
  };
  var image = _fitToQuota(decoded, style);

  if (style == UploadImageStyle.icon && decoded.hasAlpha) {
    final png = Uint8List.fromList(img.encodePng(image, level: 6));
    if (png.length <= maxBytes) {
      return PreparedUploadImage(
        bytes: png,
        fileName: _safeName(originalName, '.png'),
        contentType: 'image/png',
      );
    }
  }

  return _encodeJpeg(
    image,
    originalName: originalName,
    maxBytes: maxBytes,
    qualities: style == UploadImageStyle.screen
        ? const [90, 86, 82, 78]
        : const [78, 70, 62, 54, 46],
  );
}

img.Image _fitToQuota(img.Image image, UploadImageStyle style) {
  if (style == UploadImageStyle.screen) {
    final scale = math.min(
      1.0,
      math.min(
        UploadImageQuota.screenMaxWidth / image.width,
        UploadImageQuota.screenMaxHeight / image.height,
      ),
    );
    if (scale >= 1) return image;
    return img.copyResize(
      image,
      width: math.max(1, (image.width * scale).round()),
      height: math.max(1, (image.height * scale).round()),
      interpolation: img.Interpolation.cubic,
    );
  }

  final maxEdge = style == UploadImageStyle.icon
      ? UploadImageQuota.iconMaxEdge
      : UploadImageQuota.photoMaxEdge;
  final longest = math.max(image.width, image.height);
  if (longest <= maxEdge) return image;
  final scale = maxEdge / longest;
  return img.copyResize(
    image,
    width: math.max(1, (image.width * scale).round()),
    height: math.max(1, (image.height * scale).round()),
    interpolation: img.Interpolation.linear,
  );
}

PreparedUploadImage _encodeJpeg(
  img.Image image, {
  required String originalName,
  required int maxBytes,
  List<int> qualities = const [78, 70, 62, 54, 46],
}) {
  var current = image;
  Uint8List? best;
  for (var pass = 0; pass < 5; pass++) {
    for (final quality in qualities) {
      final encoded = Uint8List.fromList(
        img.encodeJpg(current, quality: quality),
      );
      best = encoded;
      if (encoded.length <= maxBytes) {
        return PreparedUploadImage(
          bytes: encoded,
          fileName: _safeName(originalName, '.jpg'),
          contentType: 'image/jpeg',
        );
      }
    }
    current = img.copyResize(
      current,
      width: math.max(1, (current.width * 0.82).round()),
      height: math.max(1, (current.height * 0.82).round()),
      interpolation: img.Interpolation.cubic,
    );
  }

  final limitKb = (maxBytes / 1024).round();
  throw Exception(
    'Görsel $limitKb KB kotasını aşıyor (${((best?.length ?? 0) / 1024).ceil()} KB). '
    'Daha sade bir fotoğraf dene.',
  );
}

String _safeName(String originalName, String extension) {
  final base = originalName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
  final dot = base.lastIndexOf('.');
  final stem = dot > 0 ? base.substring(0, dot) : base;
  return '$stem$extension';
}
