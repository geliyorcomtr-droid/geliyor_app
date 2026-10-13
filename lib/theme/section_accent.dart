import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Ana sayfa kutusundan gelen bölüm rengi.
class SectionAccent {
  const SectionAccent(this.color);

  final Color color;

  Color get soft => color.withValues(alpha: 0.08);
  Color get fill => color.withValues(alpha: 0.10);
  Color get line => color.withValues(alpha: 0.28);

  static const easyOrder = SectionAccent(AppColors.primary);
  static const knowledge = SectionAccent(AppColors.primary);
  static const hangiMama = SectionAccent(AppColors.primary);
  static const petMarket = SectionAccent(AppColors.primary);
  static const adoption = SectionAccent(AppColors.primary);
}
