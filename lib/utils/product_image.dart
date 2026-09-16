import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
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

/// Ürün fotoğrafı detayda ~240 logical px; 3x için 900 px decode yeter.
const int productPhotoCachePx = 900;

ImageProvider? productImageProvider(
  String path, {
  bool useHtmlElement = true,
  int? cacheWidth,
  int? cacheHeight,
}) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;

  if (isNetworkProductImage(trimmed)) {
    final html = kIsWeb || useHtmlElement;
    final network = NetworkImage(
      trimmed,
      webHtmlElementStrategy: html
          ? WebHtmlElementStrategy.prefer
          : WebHtmlElementStrategy.never,
    );
    // Web'de ResizeImage canvas + CORS ister; Storage görselleri HTML img ile görünür.
    if (kIsWeb) return network;
    return ResizeImage.resizeIfNeeded(cacheWidth, cacheHeight, network);
  }

  return ResizeImage.resizeIfNeeded(
    cacheWidth,
    cacheHeight,
    AssetImage(trimmed),
  );
}

/// Detay ekranının kullandığı canvas + 900px decode önbelleğini ısıtır.
Future<void> precacheProductImage(BuildContext context, String path) {
  final provider = productImageProvider(
    path,
    useHtmlElement: false,
    cacheWidth: productPhotoCachePx,
  );
  if (provider == null) return Future.value();
  return precacheImage(provider, context).onError((_, _) {});
}

Widget buildProductImage(
  String path, {
  BoxFit fit = BoxFit.contain,
  double? width,
  double? height,
  FilterQuality filterQuality = FilterQuality.medium,
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

  final icon = isUiIconAsset(path);
  return _FittedDecodeImage(
    path: path,
    fit: fit,
    width: width,
    height: height,
    alignment: alignment,
    filterQuality: icon ? FilterQuality.low : filterQuality,
    fallback: fallback,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    maxDecodePx: icon ? uiIconAssetPx : productPhotoCachePx,
    minDecodePx: icon ? 64 : 160,
    useHtmlElement: kIsWeb || useHtmlElement,
  );
}

class _FittedDecodeImage extends StatelessWidget {
  const _FittedDecodeImage({
    required this.path,
    required this.fit,
    required this.width,
    required this.height,
    required this.alignment,
    required this.filterQuality,
    required this.fallback,
    required this.maxDecodePx,
    required this.minDecodePx,
    required this.useHtmlElement,
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
  final int maxDecodePx;
  final int minDecodePx;
  final bool useHtmlElement;
  final int? cacheWidth;
  final int? cacheHeight;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final decodePx = _layoutDecodePx(
          context: context,
          constraints: constraints,
          width: width,
          height: height,
          cacheWidth: cacheWidth,
          cacheHeight: cacheHeight,
          maxPx: maxDecodePx,
          minPx: minDecodePx,
        );
        final provider = productImageProvider(
          path,
          useHtmlElement: useHtmlElement,
          cacheWidth: decodePx,
          cacheHeight: cacheHeight == null ? null : decodePx,
        );
        if (provider == null) return fallback;

        return Image(
          image: provider,
          fit: fit,
          width: width,
          height: height,
          alignment: alignment,
          filterQuality: filterQuality,
          gaplessPlayback: true,
          errorBuilder: (_, _, _) => fallback,
        );
      },
    );
  }
}

int _layoutDecodePx({
  required BuildContext context,
  required BoxConstraints constraints,
  double? width,
  double? height,
  int? cacheWidth,
  int? cacheHeight,
  required int maxPx,
  int minPx = 64,
}) {
  if (cacheWidth != null) return cacheWidth.clamp(minPx, maxPx);
  if (cacheHeight != null) return cacheHeight.clamp(minPx, maxPx);

  final dpr = MediaQuery.maybeDevicePixelRatioOf(context) ?? 3;
  // cacheWidth görselin genişliğidir; kısa kenarı (banner yüksekliği) kullanma.
  final logical = _firstFinite([
    width,
    constraints.maxWidth,
    height,
    constraints.maxHeight,
  ]);
  if (logical == null) return math.min(maxPx, 720);
  return (logical * dpr).round().clamp(minPx, maxPx);
}

double? _firstFinite(List<double?> values) {
  for (final value in values) {
    if (value == null || !value.isFinite || value <= 0) continue;
    return value;
  }
  return null;
}
