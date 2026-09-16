import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class WelcomePhoneLine extends StatelessWidget {
  const WelcomePhoneLine({super.key, this.fontSize = 18});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Text(
      '0 540 299 00 00',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: AppColors.primary,
        fontSize: fontSize,
        fontWeight: FontWeight.w900,
        letterSpacing: 0.6,
        height: 1.1,
      ),
    );
  }
}
