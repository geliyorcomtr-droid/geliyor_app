import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Proje genelinde kullanılan standart geri ok.
/// Akıllı Plan sayfasındaki stil: beyaz kutu + açık mavi çerçeve.
class AppBackButton extends StatelessWidget {
  const AppBackButton({
    super.key,
    this.onPressed,
    this.size = 34,
    this.iconSize = 16,
  });

  final VoidCallback? onPressed;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed ?? () => Navigator.of(context).maybePop(),
      padding: EdgeInsets.zero,
      constraints: BoxConstraints.tightFor(width: size + 8, height: size + 8),
      icon: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          Icons.arrow_back_ios_new_rounded,
          color: AppColors.primary,
          size: iconSize,
        ),
      ),
    );
  }
}
