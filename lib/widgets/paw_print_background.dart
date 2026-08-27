import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

enum PawPrintStyle {
  /// Karşılama ekranı: büyük, belirgin izler.
  splash,

  /// Standart sayfalar: küçük, kenarlara yerleştirilmiş hafif izler.
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
      size: 72,
      rotation: -0.4,
      color: AppColors.primaryLight,
      opacity: 0.18,
    ),
    _PawSpec(
      x: 0.86,
      y: 0.1,
      size: 64,
      rotation: 0.55,
      color: AppColors.warning,
      opacity: 0.12,
    ),
    _PawSpec(
      x: 0.16,
      y: 0.24,
      size: 56,
      rotation: 0.2,
      color: AppColors.border,
      opacity: 0.55,
    ),
    _PawSpec(
      x: 0.9,
      y: 0.3,
      size: 78,
      rotation: -0.65,
      color: AppColors.selected,
      opacity: 1.0,
    ),
    _PawSpec(
      x: 0.05,
      y: 0.44,
      size: 60,
      rotation: 0.5,
      color: AppColors.success,
      opacity: 0.1,
    ),
    _PawSpec(
      x: 0.94,
      y: 0.5,
      size: 70,
      rotation: -0.25,
      color: AppColors.primary,
      opacity: 0.12,
    ),
    _PawSpec(
      x: 0.12,
      y: 0.7,
      size: 80,
      rotation: -0.5,
      color: AppColors.primaryLight,
      opacity: 0.14,
    ),
    _PawSpec(
      x: 0.8,
      y: 0.74,
      size: 68,
      rotation: 0.4,
      color: AppColors.error,
      opacity: 0.08,
    ),
    _PawSpec(
      x: 0.22,
      y: 0.88,
      size: 52,
      rotation: 0.15,
      color: AppColors.border,
      opacity: 0.45,
    ),
    _PawSpec(
      x: 0.72,
      y: 0.92,
      size: 66,
      rotation: -0.3,
      color: AppColors.warning,
      opacity: 0.1,
    ),
    _PawSpec(
      x: 0.48,
      y: 0.14,
      size: 48,
      rotation: 0.75,
      color: AppColors.selected,
      opacity: 0.95,
    ),
    _PawSpec(
      x: 0.5,
      y: 0.86,
      size: 58,
      rotation: -0.85,
      color: AppColors.success,
      opacity: 0.09,
    ),
  ];

  /// Kutu / bölüm aralarındaki boşluklara yayılmış, daha belirgin izler.
  static const _pagePrints = <_PawSpec>[
    // Üst — header / banner arası
    _PawSpec(
      x: 0.12,
      y: 0.11,
      size: 30,
      rotation: -0.4,
      color: AppColors.primaryLight,
      opacity: 0.22,
    ),
    _PawSpec(
      x: 0.88,
      y: 0.12,
      size: 28,
      rotation: 0.5,
      color: AppColors.border,
      opacity: 0.7,
    ),
    // Banner / arama arası
    _PawSpec(
      x: 0.22,
      y: 0.26,
      size: 26,
      rotation: 0.2,
      color: AppColors.selected,
      opacity: 1.0,
    ),
    _PawSpec(
      x: 0.78,
      y: 0.27,
      size: 32,
      rotation: -0.55,
      color: AppColors.primary,
      opacity: 0.16,
    ),
    // Arama / akıllı plan arası
    _PawSpec(
      x: 0.08,
      y: 0.34,
      size: 24,
      rotation: 0.35,
      color: AppColors.primaryLight,
      opacity: 0.2,
    ),
    _PawSpec(
      x: 0.92,
      y: 0.35,
      size: 28,
      rotation: -0.25,
      color: AppColors.warning,
      opacity: 0.14,
    ),
    // Plan / hizmetler arası
    _PawSpec(
      x: 0.18,
      y: 0.44,
      size: 34,
      rotation: -0.45,
      color: AppColors.border,
      opacity: 0.65,
    ),
    _PawSpec(
      x: 0.5,
      y: 0.45,
      size: 22,
      rotation: 0.7,
      color: AppColors.primaryLight,
      opacity: 0.18,
    ),
    _PawSpec(
      x: 0.82,
      y: 0.46,
      size: 30,
      rotation: 0.3,
      color: AppColors.selected,
      opacity: 0.95,
    ),
    // Hizmetler / profil arası
    _PawSpec(
      x: 0.1,
      y: 0.56,
      size: 28,
      rotation: 0.15,
      color: AppColors.success,
      opacity: 0.14,
    ),
    _PawSpec(
      x: 0.7,
      y: 0.57,
      size: 26,
      rotation: -0.6,
      color: AppColors.primary,
      opacity: 0.15,
    ),
    // Profil / market arası
    _PawSpec(
      x: 0.28,
      y: 0.66,
      size: 32,
      rotation: 0.4,
      color: AppColors.primaryLight,
      opacity: 0.2,
    ),
    _PawSpec(
      x: 0.9,
      y: 0.67,
      size: 24,
      rotation: -0.35,
      color: AppColors.border,
      opacity: 0.6,
    ),
    // Market / navbar arası
    _PawSpec(
      x: 0.14,
      y: 0.78,
      size: 30,
      rotation: -0.2,
      color: AppColors.selected,
      opacity: 0.9,
    ),
    _PawSpec(
      x: 0.55,
      y: 0.8,
      size: 26,
      rotation: 0.55,
      color: AppColors.warning,
      opacity: 0.12,
    ),
    _PawSpec(
      x: 0.86,
      y: 0.82,
      size: 34,
      rotation: -0.5,
      color: AppColors.primaryLight,
      opacity: 0.18,
    ),
    // Alt kenar
    _PawSpec(
      x: 0.32,
      y: 0.9,
      size: 28,
      rotation: 0.25,
      color: AppColors.border,
      opacity: 0.55,
    ),
    _PawSpec(
      x: 0.72,
      y: 0.92,
      size: 30,
      rotation: -0.4,
      color: AppColors.primary,
      opacity: 0.14,
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
