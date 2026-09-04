import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

enum PawPrintStyle {
  /// Karşılama ekranı: büyük, belirgin izler.
  splash,

  /// Standart sayfalar: büyük, renkli izler.
  page,
}

class _PawSpec {
  const _PawSpec({
    required this.x,
    required this.y,
    required this.size,
    required this.rotation,
    required this.color,
    required this.opacity,
  });

  final double x;
  final double y;
  final double size;
  final double rotation;
  final Color color;
  final double opacity;
}

/// Boş alanlara ana sayfadaki ortadaki pati ikonu (`Icons.pets_rounded`) ile desen.
class PawPrintBackground extends StatelessWidget {
  const PawPrintBackground({
    super.key,
    required this.child,
    this.style = PawPrintStyle.page,
  });

  final Widget child;
  final PawPrintStyle style;

  static const _splashPrints = <_PawSpec>[
    _PawSpec(
      x: 0.08,
      y: 0.06,
      size: 108,
      rotation: -0.4,
      color: AppColors.primaryLight,
      opacity: 0.32,
    ),
    _PawSpec(
      x: 0.86,
      y: 0.1,
      size: 96,
      rotation: 0.55,
      color: AppColors.warning,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.16,
      y: 0.24,
      size: 88,
      rotation: 0.2,
      color: AppColors.success,
      opacity: 0.26,
    ),
    _PawSpec(
      x: 0.9,
      y: 0.3,
      size: 112,
      rotation: -0.65,
      color: AppColors.primary,
      opacity: 0.3,
    ),
    _PawSpec(
      x: 0.05,
      y: 0.44,
      size: 92,
      rotation: 0.5,
      color: AppColors.warning,
      opacity: 0.24,
    ),
    _PawSpec(
      x: 0.94,
      y: 0.5,
      size: 104,
      rotation: -0.25,
      color: AppColors.error,
      opacity: 0.22,
    ),
    _PawSpec(
      x: 0.12,
      y: 0.7,
      size: 116,
      rotation: -0.5,
      color: AppColors.primaryLight,
      opacity: 0.3,
    ),
    _PawSpec(
      x: 0.8,
      y: 0.74,
      size: 100,
      rotation: 0.4,
      color: AppColors.error,
      opacity: 0.24,
    ),
    _PawSpec(
      x: 0.22,
      y: 0.88,
      size: 84,
      rotation: 0.15,
      color: AppColors.success,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.72,
      y: 0.92,
      size: 98,
      rotation: -0.3,
      color: AppColors.warning,
      opacity: 0.26,
    ),
    _PawSpec(
      x: 0.48,
      y: 0.14,
      size: 80,
      rotation: 0.75,
      color: AppColors.primary,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.5,
      y: 0.86,
      size: 90,
      rotation: -0.85,
      color: AppColors.success,
      opacity: 0.24,
    ),
  ];

  /// Kutu / bölüm aralarındaki boşluklara yayılmış, büyük ve renkli izler.
  static const _pagePrints = <_PawSpec>[
    _PawSpec(
      x: 0.12,
      y: 0.11,
      size: 58,
      rotation: -0.4,
      color: AppColors.primaryLight,
      opacity: 0.3,
    ),
    _PawSpec(
      x: 0.88,
      y: 0.12,
      size: 54,
      rotation: 0.5,
      color: AppColors.warning,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.22,
      y: 0.26,
      size: 50,
      rotation: 0.2,
      color: AppColors.success,
      opacity: 0.26,
    ),
    _PawSpec(
      x: 0.78,
      y: 0.27,
      size: 62,
      rotation: -0.55,
      color: AppColors.primary,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.08,
      y: 0.34,
      size: 48,
      rotation: 0.35,
      color: AppColors.error,
      opacity: 0.22,
    ),
    _PawSpec(
      x: 0.92,
      y: 0.35,
      size: 56,
      rotation: -0.25,
      color: AppColors.warning,
      opacity: 0.3,
    ),
    _PawSpec(
      x: 0.18,
      y: 0.44,
      size: 64,
      rotation: -0.45,
      color: AppColors.primaryLight,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.5,
      y: 0.45,
      size: 46,
      rotation: 0.7,
      color: AppColors.success,
      opacity: 0.24,
    ),
    _PawSpec(
      x: 0.82,
      y: 0.46,
      size: 58,
      rotation: 0.3,
      color: AppColors.error,
      opacity: 0.22,
    ),
    _PawSpec(
      x: 0.1,
      y: 0.56,
      size: 54,
      rotation: 0.15,
      color: AppColors.success,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.7,
      y: 0.57,
      size: 52,
      rotation: -0.6,
      color: AppColors.primary,
      opacity: 0.26,
    ),
    _PawSpec(
      x: 0.28,
      y: 0.66,
      size: 62,
      rotation: 0.4,
      color: AppColors.warning,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.9,
      y: 0.67,
      size: 48,
      rotation: -0.35,
      color: AppColors.primaryLight,
      opacity: 0.3,
    ),
    _PawSpec(
      x: 0.14,
      y: 0.78,
      size: 58,
      rotation: -0.2,
      color: AppColors.primary,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.55,
      y: 0.8,
      size: 50,
      rotation: 0.55,
      color: AppColors.error,
      opacity: 0.22,
    ),
    _PawSpec(
      x: 0.86,
      y: 0.82,
      size: 64,
      rotation: -0.5,
      color: AppColors.success,
      opacity: 0.26,
    ),
    _PawSpec(
      x: 0.32,
      y: 0.9,
      size: 54,
      rotation: 0.25,
      color: AppColors.warning,
      opacity: 0.28,
    ),
    _PawSpec(
      x: 0.72,
      y: 0.92,
      size: 58,
      rotation: -0.4,
      color: AppColors.primaryLight,
      opacity: 0.3,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final prints = style == PawPrintStyle.splash ? _splashPrints : _pagePrints;

    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        return Stack(
          fit: StackFit.expand,
          children: [
            for (final spec in prints)
              Positioned(
                left: spec.x * w - spec.size / 2,
                top: spec.y * h - spec.size / 2,
                width: spec.size,
                height: spec.size,
                child: IgnorePointer(
                  child: Transform.rotate(
                    angle: spec.rotation,
                    child: Icon(
                      Icons.pets_rounded,
                      size: spec.size,
                      color: spec.color.withValues(alpha: spec.opacity),
                    ),
                  ),
                ),
              ),
            child,
          ],
        );
      },
    );
  }
}
