import 'package:flutter/material.dart';
import 'package:geliyor_app/data/trust_badge_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

/// Rakamsız madalya ikonu + turuncu dairenin tam ortasındaki sıra rakamı.
class PreferredRankMedal extends StatelessWidget {
  const PreferredRankMedal({
    super.key,
    required this.rank,
    this.imagePath,
    this.errorWidget,
  });

  final String rank;
  final String? imagePath;
  final Widget? errorWidget;

  static const Size _assetSize = Size(1024, 1024);

  /// Puan (4.9) ile aynı değer yazı stili.
  static const TextStyle valueTextStyle = TextStyle(
    color: AppColors.surface,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1,
    letterSpacing: -0.3,
  );

  /// Turuncu dış dairenin merkezi — 1024px görselde ~y=330.
  static const double _circleCenterX = 0.5;
  static const double _circleCenterY = 0.322;

  /// İç beyaz halka alanı (rakam buraya oturur).
  static const double _innerCircleSizeFactor = 0.34;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final maxW = constraints.maxWidth;
        final maxH = constraints.maxHeight;
        if (!maxW.isFinite || !maxH.isFinite || maxW <= 0 || maxH <= 0) {
          return const SizedBox.shrink();
        }

        final fitted = applyBoxFit(
          BoxFit.contain,
          _assetSize,
          Size(maxW, maxH),
        );
        final dest = Alignment.center.inscribe(
          fitted.destination,
          Offset.zero & Size(maxW, maxH),
        );
        final innerSize = dest.width * _innerCircleSizeFactor;
        final centerX = dest.left + dest.width * _circleCenterX;
        final centerY = dest.top + dest.height * _circleCenterY;
        final fallback =
            errorWidget ??
            Icon(
              Icons.workspace_premium_rounded,
              size: innerSize * 1.4,
              color: AppColors.warning,
            );
        final medalPath = () {
          final custom = imagePath?.trim() ?? '';
          return custom.isNotEmpty
              ? custom
              : TrustBadgeRepository.preferredIconPath;
        }();

        return SizedBox(
          width: maxW,
          height: maxH,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Positioned.fromRect(
                rect: dest,
                child: buildProductImage(
                  medalPath,
                  fit: BoxFit.fill,
                  width: dest.width,
                  height: dest.height,
                  filterQuality: FilterQuality.high,
                  errorWidget: fallback,
                ),
              ),
              Positioned(
                left: centerX - innerSize / 2,
                top: centerY - innerSize / 2,
                width: innerSize,
                height: innerSize,
                child: Center(
                  child: Text(
                    rank,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    style: valueTextStyle,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
