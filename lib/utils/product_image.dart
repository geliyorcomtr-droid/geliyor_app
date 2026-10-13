import 'dart:async';
import 'dart:math' as math;

import 'package:cached_network_image/cached_network_image.dart';
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

/// Marka logoları kartta ~84 logical px; 3x için 256 px yeter.
const int brandLogoCachePx = 256;

/// Ürün fotoğrafı detayda ~240 logical px; 3x için 900 px decode yeter.
const int productPhotoCachePx = 900;

/// Liste / kart thumbnail.
const int productThumbCachePx = 480;

/// Ana sayfa ve sayfa bannerleri (361 logical px, 3x).
const int bannerCachePx = 1080;

/// Karşılama ekranı (393 logical px, 3x).
const int splashCachePx = 1179;

ImageProvider? productImageProvider(
  String path, {
  bool useHtmlElement = true,
  int? cacheWidth,
  int? cacheHeight,
}) {
  final trimmed = path.trim();
  if (trimmed.isEmpty) return null;

  if (isNetworkProductImage(trimmed)) {
    if (kIsWeb) {
      return NetworkImage(
        trimmed,
        webHtmlElementStrategy: useHtmlElement
            ? WebHtmlElementStrategy.prefer
            : WebHtmlElementStrategy.never,
      );
    }
    return ResizeImage.resizeIfNeeded(
      cacheWidth,
      cacheHeight,
      CachedNetworkImageProvider(trimmed),
    );
  }

  return ResizeImage.resizeIfNeeded(
    cacheWidth,
    cacheHeight,
    AssetImage(trimmed),
  );
}

Future<void> precacheProductImage(
  BuildContext context,
  String path, {
  int? cacheWidth,
}) {
  final provider = productImageProvider(
    path,
    useHtmlElement: false,
    cacheWidth: cacheWidth ?? productPhotoCachePx,
  );
  if (provider == null) return Future.value();
  return precacheImage(provider, context).onError((_, _) {});
}

abstract final class ImageWarmup {
  static final Set<String> _queued = <String>{};

  static void precache(
    BuildContext? context,
    Iterable<String> paths, {
    int? cacheWidth,
  }) {
    final ctx = context;
    if (ctx == null || !ctx.mounted) return;
    for (final raw in paths) {
      final path = raw.trim();
      if (path.isEmpty) continue;
      final key = '$path#${cacheWidth ?? 0}';
      if (!_queued.add(key)) continue;
      unawaited(precacheProductImage(ctx, path, cacheWidth: cacheWidth));
    }
  }
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
  int? maxDecodePx,
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
  final html = !icon && useHtmlElement;
  return _FittedDecodeImage(
    key: ValueKey('${path.trim()}|$html'),
    path: path,
    fit: fit,
    width: width,
    height: height,
    alignment: alignment,
    filterQuality: icon ? FilterQuality.low : filterQuality,
    fallback: fallback,
    cacheWidth: cacheWidth,
    cacheHeight: cacheHeight,
    maxDecodePx: maxDecodePx ?? (icon ? uiIconAssetPx : productPhotoCachePx),
    minDecodePx: icon ? 64 : 160,
    useHtmlElement: html,
  );
}

class _FittedDecodeImage extends StatefulWidget {
  const _FittedDecodeImage({
    super.key,
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
  State<_FittedDecodeImage> createState() => _FittedDecodeImageState();
}

class _FittedDecodeImageState extends State<_FittedDecodeImage> {
  late int _decodePx = widget.cacheWidth?.clamp(
        widget.minDecodePx,
        widget.maxDecodePx,
      ) ??
      widget.minDecodePx;

  @override
  void didUpdateWidget(covariant _FittedDecodeImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.cacheWidth != widget.cacheWidth ||
        oldWidget.cacheHeight != widget.cacheHeight) {
      _decodePx = widget.cacheWidth?.clamp(
            widget.minDecodePx,
            widget.maxDecodePx,
          ) ??
          widget.minDecodePx;
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final next = _layoutDecodePx(
          context: context,
          constraints: constraints,
          width: widget.width,
          height: widget.height,
          cacheWidth: widget.cacheWidth,
          cacheHeight: widget.cacheHeight,
          maxPx: widget.maxDecodePx,
          minPx: widget.minDecodePx,
        );
        if (next > _decodePx * 1.5) {
          _decodePx = next;
        }

        final network = isNetworkProductImage(widget.path);
        // Web Storage görselleri CORS ister; HTML <img> istemez.
        // Frozen RawImage decode yolu yalnızca native'de (wifi kopunca pixel tutmak).
        if (network && !kIsWeb) {
          return _FrozenNetworkImage(
            path: widget.path.trim(),
            fit: widget.fit,
            width: widget.width,
            height: widget.height,
            alignment: widget.alignment,
            filterQuality: widget.filterQuality,
            decodePx: _decodePx,
            fallback: widget.fallback,
          );
        }

        final provider = productImageProvider(
          widget.path,
          useHtmlElement: kIsWeb || widget.useHtmlElement,
          cacheWidth: kIsWeb ? null : _decodePx,
          cacheHeight: kIsWeb || widget.cacheHeight == null ? null : _decodePx,
        );
        if (provider == null) return widget.fallback;

        return SizedBox.expand(
          child: Image(
            image: provider,
            fit: widget.fit,
            alignment: widget.alignment,
            filterQuality: widget.filterQuality,
            gaplessPlayback: true,
            errorBuilder: (_, _, _) => widget.fallback,
          ),
        );
      },
    );
  }
}

class _FrozenNetworkImage extends StatefulWidget {
  const _FrozenNetworkImage({
    required this.path,
    required this.fit,
    required this.width,
    required this.height,
    required this.alignment,
    required this.filterQuality,
    required this.decodePx,
    required this.fallback,
  });

  final String path;
  final BoxFit fit;
  final double? width;
  final double? height;
  final Alignment alignment;
  final FilterQuality filterQuality;
  final int decodePx;
  final Widget fallback;

  @override
  State<_FrozenNetworkImage> createState() => _FrozenNetworkImageState();
}

class _FrozenNetworkImageState extends State<_FrozenNetworkImage> {
  ImageStream? _stream;
  ImageStreamListener? _listener;
  ImageInfo? _info;
  var _failed = false;
  var _attached = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_attached) return;
    _attached = true;
    _listen();
  }

  @override
  void didUpdateWidget(covariant _FrozenNetworkImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) {
      _listen();
    }
  }

  void _listen() {
    final provider = productImageProvider(
      widget.path,
      useHtmlElement: false,
      cacheWidth: widget.decodePx,
    );
    if (provider == null) return;
    _listener ??= ImageStreamListener(_onImage, onError: _onError);
    final next = provider.resolve(createLocalImageConfiguration(context));
    if (_stream == next) return;
    _stream?.removeListener(_listener!);
    _stream = next;
    _stream!.addListener(_listener!);
  }

  void _onImage(ImageInfo info, bool synchronousCall) {
    _info?.dispose();
    _info = info.clone();
    _failed = false;
    if (!mounted) return;
    if (synchronousCall) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() {});
      });
    } else {
      setState(() {});
    }
  }

  void _onError(Object error, StackTrace? stackTrace) {
    if (_info != null) return;
    if (mounted) setState(() => _failed = true);
  }

  @override
  void dispose() {
    if (_listener != null) {
      _stream?.removeListener(_listener!);
    }
    _info?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = _info;
    if (info != null) {
      return SizedBox.expand(
        child: RawImage(
          image: info.image,
          scale: info.scale,
          fit: widget.fit,
          alignment: widget.alignment,
          filterQuality: widget.filterQuality,
        ),
      );
    }
    if (_failed) {
      return SizedBox.expand(child: widget.fallback);
    }
    return const SizedBox.expand();
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
