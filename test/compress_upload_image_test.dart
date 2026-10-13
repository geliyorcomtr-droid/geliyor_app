import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:image/image.dart' as img;

void main() {
  test('büyük fotoğraf kota altına iner', () {
    final source = img.Image(width: 2400, height: 1800);
    img.fill(source, color: img.ColorRgb8(30, 140, 255));
    final raw = Uint8List.fromList(img.encodeJpg(source, quality: 95));
    final prepared = prepareUploadImage(raw, 'photo.jpg');
    expect(prepared.bytes.length, lessThanOrEqualTo(UploadImageQuota.photoMaxBytes));
    expect(prepared.contentType, 'image/jpeg');
  });

  test('karşılama görseli 3x tuval ve kota altına iner', () {
    final source = img.Image(width: 1600, height: 3200);
    img.fill(source, color: img.ColorRgb8(250, 130, 2));
    final raw = Uint8List.fromList(img.encodePng(source));
    final prepared = prepareUploadImage(
      raw,
      'splash.png',
      style: UploadImageStyle.screen,
    );
    final decoded = img.decodeImage(prepared.bytes)!;
    expect(decoded.width, lessThanOrEqualTo(UploadImageQuota.screenMaxWidth));
    expect(decoded.height, lessThanOrEqualTo(UploadImageQuota.screenMaxHeight));
    expect(decoded.width, greaterThanOrEqualTo(700));
    expect(
      prepared.bytes.length,
      lessThanOrEqualTo(UploadImageQuota.screenMaxBytes),
    );
  });
}
