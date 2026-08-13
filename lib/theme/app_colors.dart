import 'package:flutter/material.dart';

/// geliyor.app ortak renk paleti — tüm sayfalarda bunu kullan.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF1E90FF);
  static const Color primaryLight = Color(0xFF60A5FA);
  static const Color background = Color(0xFFFBFDFF);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color selected = Color(0xFFE8F3FF);
  static const Color border = Color(0xFFD6E8FF);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color text = Color(0xFF1F2937);
  static const Color subText = Color(0xFF6B7280);

  /// Eski isimler (geçiş uyumu)
  static const Color white = surface;
  static const Color mid = border;
  static const Color soft = selected;
  static const Color textDark = text;
  static const Color textGray = subText;
}
