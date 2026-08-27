import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Uygulama genelinde tipografi sabitleri.
class AppTextStyles {
  AppTextStyles._();

  /// Avenir Next Rounded Pro Bold2 — `assets/fonts/AvenirNextRoundedPro-Bold2.otf`
  static const String fontFamily = 'AvenirNextRoundedPro';

  /// Sayfa üst başlığı (AppPageHeader): 20px, #1E90FF, Bold2.
  static const TextStyle pageHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.15,
    letterSpacing: -0.2,
  );

  /// Sayfa içi bölüm / içerik başlıkları: 16px (üst başlıktan ayrı).
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.15,
    letterSpacing: -0.2,
  );

  /// Form ve anket soru başlıkları: 16px.
  static const TextStyle questionHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.15,
    letterSpacing: -0.2,
  );

  /// "Tümünü Gör" ve benzeri liste aksiyonları: 16px.
  static const TextStyle seeAllAction = TextStyle(
    fontFamily: fontFamily,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.15,
    letterSpacing: -0.2,
  );

  static TextStyle pageHeaderWith({Color? color, double? fontSize}) {
    return pageHeader.copyWith(color: color, fontSize: fontSize);
  }

  static TextStyle sectionHeaderWith({Color? color, double? fontSize}) {
    return sectionHeader.copyWith(color: color, fontSize: fontSize);
  }
}
