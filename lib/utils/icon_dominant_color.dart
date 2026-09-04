import 'dart:ui' as ui;

import 'package:flutter/services.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// PNG ikonların (beyaz zemin hariç) baskın rengini okur.
class IconDominantColor {
  IconDominantColor._();

  static final Map<String, Color> _cache = {};

  static Future<Color> fromAsset(String path) async {
    final key = path.trim();
    if (key.isEmpty) return AppColors.primary;
    final cached = _cache[key];
    if (cached != null) return cached;
    try {
      final data = await rootBundle.load(key);
      final color = await fromBytes(data.buffer.asUint8List());
      _cache[key] = color;
      return color;
    } catch (_) {
      return AppColors.primary;
    }
  }

  static Future<Color> fromBytes(Uint8List bytes) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: 48,
      targetHeight: 48,
    );
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final width = image.width;
    final height = image.height;
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    if (byteData == null) return AppColors.primary;
    return _fromRgba(byteData.buffer.asUint8List(), width * height);
  }

  static Color _fromRgba(Uint8List rgba, int pixelCount) {
    final counts = <int, int>{};
    final samples = <int, List<int>>{};
    for (var i = 0; i + 3 < rgba.length && i < pixelCount * 4; i += 4) {
      final a = rgba[i + 3];
      if (a < 140) continue;
      final r = rgba[i];
      final g = rgba[i + 1];
      final b = rgba[i + 2];
      if (r > 232 && g > 232 && b > 232) continue;
      final maxC = r > g ? (r > b ? r : b) : (g > b ? g : b);
      final minC = r < g ? (r < b ? r : b) : (g < b ? g : b);
      if (maxC - minC < 18 && maxC < 210) continue;
      final key = ((r >> 3) << 10) | ((g >> 3) << 5) | (b >> 3);
      counts[key] = (counts[key] ?? 0) + 1;
      samples.putIfAbsent(key, () => [r, g, b]);
    }
    if (counts.isEmpty) return AppColors.primary;
    var bestKey = counts.keys.first;
    var bestCount = 0;
    counts.forEach((key, count) {
      if (count > bestCount) {
        bestCount = count;
        bestKey = key;
      }
    });
    final rgb = samples[bestKey]!;
    return Color.fromARGB(255, rgb[0], rgb[1], rgb[2]);
  }
}
