import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/local_image_cache.dart';
import 'package:geliyor_app/utils/product_image.dart';

/// Marka kartı görseli. Paket içi asset anında, yüklenen URL disk cache ile gelir.
class BrandTileImage extends StatelessWidget {
  const BrandTileImage({
    super.key,
    required this.brand,
    this.fit = BoxFit.cover,
    this.fallbackColor = AppColors.primary,
  });

  final AppBrand brand;
  final BoxFit fit;
  final Color fallbackColor;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocalImageCache.instance,
      builder: (context, _) {
        final fallback = Center(
          child: Text(
            brand.name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: fallbackColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        );
        final path = brand.displayImage;
        if (path.isEmpty) return fallback;
        final local = isNetworkProductImage(path)
            ? LocalImageCache.instance.peek(path)
            : null;
        if (local != null && local.isNotEmpty) {
          return Image.memory(
            local,
            fit: fit,
            gaplessPlayback: true,
            filterQuality: FilterQuality.medium,
            errorBuilder: (_, _, _) => fallback,
          );
        }
        if (isNetworkProductImage(path)) {
          unawaited(LocalImageCache.instance.prefetch([path]));
        }
        return buildProductImage(
          path,
          fit: fit,
          filterQuality: FilterQuality.medium,
          cacheWidth: brandLogoCachePx,
          errorWidget: fallback,
        );
      },
    );
  }
}
