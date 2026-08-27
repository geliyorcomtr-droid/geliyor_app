import 'package:flutter/material.dart';
import 'package:geliyor_app/state/favorite_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Ürün görselinin sol üst köşesine oturan favori ikonu.
class ProductFavoriteCorner extends StatelessWidget {
  const ProductFavoriteCorner({
    super.key,
    required this.productId,
    required this.onToggle,
    this.size = 24,
    this.iconSize = 14,
  }) : isFavorite = null;

  /// FavoriteStore dinlemeden, dışarıdan verilen durumla aynı görünüm.
  const ProductFavoriteCorner.controlled({
    super.key,
    required bool this.isFavorite,
    required this.onToggle,
    this.size = 24,
    this.iconSize = 14,
  }) : productId = null;

  final String? productId;
  final bool? isFavorite;
  final VoidCallback onToggle;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    if (isFavorite != null) {
      return _badge(isFavorite: isFavorite!);
    }
    final id = productId!;
    return ListenableBuilder(
      listenable: FavoriteStore.instance,
      builder: (context, _) {
        return _badge(
          isFavorite: FavoriteStore.instance.isFavorite(id),
        );
      },
    );
  }

  Widget _badge({required bool isFavorite}) {
    return GestureDetector(
      onTap: onToggle,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: 0.95),
          shape: BoxShape.circle,
          border: Border.all(
            color: isFavorite ? AppColors.error : AppColors.primary,
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Icon(
          isFavorite
              ? Icons.favorite_rounded
              : Icons.favorite_border_rounded,
          color: isFavorite ? AppColors.error : AppColors.primary,
          size: iconSize,
        ),
      ),
    );
  }
}
