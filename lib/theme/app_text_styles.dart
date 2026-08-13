import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Uygulama genelinde tipografi sabitleri.
class AppTextStyles {
  AppTextStyles._();

  /// Avenir Next Rounded Pro Bold2 — `assets/fonts/AvenirNextRoundedPro-Bold2.otf`
  static const String fontFamily = 'AvenirNextRoundedPro';

  /// Sayfa üst başlığı: 20px, #1E90FF, Bold2.
  static const TextStyle pageHeader = TextStyle(
    fontFamily: fontFamily,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    height: 1.15,
    letterSpacing: -0.2,
  );

  static TextStyle pageHeaderWith({Color? color, double? fontSize}) {
    return pageHeader.copyWith(
      color: color,
      fontSize: fontSize,
    );
  }
}
