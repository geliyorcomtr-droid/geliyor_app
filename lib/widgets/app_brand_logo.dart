import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Karşılama / giriş logosu. PNG’nin beyaz zemini şeffaf sayılır;
/// pati izleri logo çerçevesinin arkasında kaybolmaz.
class AppBrandLogo extends StatelessWidget {
  const AppBrandLogo({
    super.key,
    this.height,
    this.width,
    this.errorIconSize = 56,
  });

  static const assetPath = 'assets/images/geliyor_splash_logo.png';

  final double? height;
  final double? width;
  final double errorIconSize;

  /// Beyaz pikselleri şeffaf yapar; mavi marka çizimi durur.
  static const _knockOutWhite = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    -1, -1, -1, 3, 0,
  ]);

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: _knockOutWhite,
      child: Image.asset(
        assetPath,
        height: height,
        width: width,
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
        errorBuilder: (context, error, stackTrace) => Icon(
          Icons.pets_rounded,
          color: AppColors.primary,
          size: errorIconSize,
        ),
      ),
    );
  }
}
