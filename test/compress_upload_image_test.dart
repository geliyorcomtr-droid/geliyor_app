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

  test('yetki belgesi 361x510 oranında 3x tuvale oturur', () {
    final source = img.Image(width: 800, height: 1200);
    img.fill(source, color: img.ColorRgb8(255, 255, 255));
    img.fillRect(
      source,
      x1: 40,
      y1: 40,
      x2: 760,
      y2: 1160,
      color: img.ColorRgb8(30, 144, 255),
    );
    final raw = Uint8List.fromList(img.encodeJpg(source, quality: 90));
    final prepared = prepareUploadImage(
      raw,
      'yetki.jpg',
      style: UploadImageStyle.certificate,
    );
    final decoded = img.decodeImage(prepared.bytes)!;
    expect(decoded.width, UploadImageQuota.certificateWidth);
    expect(decoded.height, UploadImageQuota.certificateHeight);
    expect(
      prepared.bytes.length,
      lessThanOrEqualTo(UploadImageQuota.certificateMaxBytes),
    );
  });
}
