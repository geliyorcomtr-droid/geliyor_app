import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

bool isNetworkProductImage(String path) {
  final value = path.trim().toLowerCase();
  return value.startsWith('http://') || value.startsWith('https://');
}

bool isUiIconAsset(String path) {
  return path.contains('/app_ikonlar/') ||
      path.contains('/son_ikonlar/') ||
      path.contains('/icons/');
}

/// UI ikonları ekranda en fazla ~64 logical px; 3x ekran için 256 px yeter.
const int uiIconAssetPx = 256;

Widget buildProductImage(
  String path, {
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
  FilterQuality filterQuality = FilterQuality.low,
  Widget? errorWidget,
  Alignment alignment = Alignment.center,
  bool useHtmlElement = true,
  int? cacheWidth,
  int? cacheHeight,
}) {
  final fallback =
      errorWidget ??
      const Icon(
        Icons.inventory_2_outlined,
        color: AppColors.subText,
        size: 28,
      );

  if (path.trim().isEmpty) return fallback;

  if (isNetworkProductImage(path)) {
    return Image.network(
      path,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      filterQuality: filterQuality,
      gaplessPlayback: true,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
      webHtmlElementStrategy: useHtmlElement
          ? WebHtmlElementStrategy.prefer
          : WebHtmlElementStrategy.never,
      errorBuilder: (_, _, _) => fallback,
    );
  }

  if (isUiIconAsset(path)) {
    return _UiIconImage(
      path: path,
      fit: fit,
      width: width,
      height: height,
      alignment: alignment,
      filterQuality: filterQuality,
      fallback: fallback,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  return Image.asset(
    path,
    fit: fit,
    width: width,
    height: height,
    alignment: alignment,
    filterQuality: filterQuality,
    gaplessPlayback: true,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    errorBuilder: (_, _, _) => fallback,
  );
}

class _UiIconImage extends StatelessWidget {
  const _UiIconImage({
    required this.path,
    required this.fit,
    required this.width,
    required this.height,
    required this.alignment,
    required this.filterQuality,
    required this.fallback,
    this.cacheWidth,
    this.cacheHeight,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final Widget fallback;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 3;

    return LayoutBuilder(
      builder: (context, constraints) {
        final logical = _smallestFinite([
          width,
          height,
          constraints.maxWidth,
          constraints.maxHeight,
        ]);
        final decodePx = cacheWidth ??
            cacheHeight ??
            (logical == null
                ? uiIconAssetPx
                : (logical * dpr).round().clamp(48, uiIconAssetPx));

        return Image.asset(
          path,
          fit: fit,
          width: width,
          height: height,
          alignment: alignment,
          filterQuality: filterQuality,
          gaplessPlayback: true,
          cacheWidth: decodePx,
          cacheHeight: decodePx,
          errorBuilder: (_, _, _) => fallback,
        );
      },
    );
  }

  double? _smallestFinite(List<double?> values) {
    double? smallest;
    for (final value in values) {
      if (value == null || !value.isFinite || value <= 0) continue;
      smallest = smallest == null ? value : math.min(smallest, value);
    }
    return smallest;
  }
}
