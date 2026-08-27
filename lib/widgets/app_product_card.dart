import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_price.dart';
import 'package:geliyor_app/widgets/product_favorite_corner.dart';

/// Favorilerim ile aynı yatay ürün kartı — tüm ürün listelerinde kullanılır.
class AppProductCard extends StatelessWidget {
  const AppProductCard({
    super.key,
    required this.imagePath,
    required this.title,
    this.category,
    this.rating,
    this.reviewCount,
    this.price,
    this.priceLabel,
    this.oldPrice,
    this.oldPriceLabel,
    this.discount,
    this.inStock = true,
    this.statusLabel,
    this.isFavorite = false,
    this.showFavorite = true,
    this.showRating = true,
    this.showStock = true,
    this.showCartButton = true,
    this.onTap,
    this.onCartTap,
    this.onFavoriteTap,
    this.trailing,
    this.action,
    this.width,
  });

  final String imagePath;
  final String title;
  final String? category;
  final double? rating;
  final int? reviewCount;
  final double? price;
  final String? priceLabel;
  final double? oldPrice;
  final String? oldPriceLabel;
  final int? discount;
  final bool inStock;
  final String? statusLabel;
  final bool isFavorite;
  final bool showFavorite;
  final bool showRating;
  final bool showStock;
  final bool showCartButton;
  final VoidCallback? onTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onFavoriteTap;
  final Widget? trailing;

  /// Sepet / kolay sipariş için: sepet butonu yerine adet kontrolü.
  final Widget? action;
  final double? width;

  String get _priceText =>
      priceLabel ?? (price != null ? formatProductPrice(price!) : '');

  String? get _oldPriceText {
    if (oldPriceLabel != null) return oldPriceLabel;
    if (oldPrice != null) return formatProductPrice(oldPrice!);
    return null;
  }

  int? get _discountBadge {
    if (discount != null) return discount;
    if (price != null && oldPrice != null) {
      return discountPercentFromPrices(price!, oldPrice);
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 78,
                height: 92,
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                padding: const EdgeInsets.all(6),
                child: Image.asset(
                  imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.subText,
                    size: 28,
                  ),
                ),
              ),
              if (showFavorite && trailing == null)
                Positioned(
                  top: -2,
                  left: -2,
                  child: ProductFavoriteCorner.controlled(
                    isFavorite: isFavorite,
                    onToggle: () => onFavoriteTap?.call(),
                    size: 22,
                    iconSize: 12,
                  ),
                ),
              if (_discountBadge != null)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '%$_discountBadge',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 92,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (category != null)
                    Text(
                      category!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 12,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      ?trailing,
                    ],
                  ),
                  if (showRating && rating != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final filled = index < rating!.floor();
                          final half = index == rating!.floor() &&
                              rating! % 1 >= 0.5;
                          return Icon(
                            half
                                ? Icons.star_half_rounded
                                : (filled
                                    ? Icons.star_rounded
                                    : Icons.star_border_rounded),
                            size: 11,
                            color: AppColors.warning,
                          );
                        }),
                        if (reviewCount != null) ...[
                          const SizedBox(width: 3),
                          Text(
                            '($reviewCount)',
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  const Spacer(),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (_priceText.isNotEmpty)
                              Row(
                                children: [
                                  Flexible(
                                    child: Text(
                                      _priceText,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        color: AppColors.success,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  if (_oldPriceText != null) ...[
                                    const SizedBox(width: 4),
                                    Text(
                                      _oldPriceText!,
                                      style: TextStyle(
                                        color: AppColors.subText
                                            .withValues(alpha: 0.8),
                                        fontSize: 9,
                                        fontWeight: FontWeight.w600,
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            if (showStock) ...[
                              const SizedBox(height: 2),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: inStock
                                      ? AppColors.success.withValues(alpha: 0.1)
                                      : AppColors.error.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  statusLabel ??
                                      (inStock ? 'Stokta' : 'Tükendi'),
                                  style: TextStyle(
                                    color: inStock
                                        ? AppColors.success
                                        : AppColors.error,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (action != null)
                        action!
                      else if (showCartButton)
                        GestureDetector(
                          onTap: onCartTap,
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: AppColors.selected,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: const Icon(
                              Icons.shopping_cart_outlined,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );

    if (onTap == null) return card;
    return GestureDetector(onTap: onTap, child: card);
  }
}

/// Favoriler kartındaki sepet butonu yerine kullanılan kompakt adet kontrolü.
class AppProductQuantityBar extends StatelessWidget {
  const AppProductQuantityBar({
    super.key,
    required this.quantity,
    required this.onDecrease,
    required this.onIncrease,
    this.canDecrease = true,
  });

  final int quantity;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool canDecrease;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 28,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(Icons.remove_rounded, onDecrease, enabled: canDecrease),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '$quantity',
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          _qtyButton(Icons.add_rounded, onIncrease),
        ],
      ),
    );
  }

  Widget _qtyButton(
    IconData icon,
    VoidCallback onTap, {
    bool enabled = true,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 22,
        height: 22,
        decoration: BoxDecoration(
          color: AppColors.selected,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          color: enabled ? AppColors.primary : AppColors.subText,
          size: 13,
        ),
      ),
    );
  }
}
