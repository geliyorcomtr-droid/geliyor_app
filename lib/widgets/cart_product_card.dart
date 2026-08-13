import 'package:flutter/material.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/favorite_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_price.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';

/// Sepet ürün kartı — ekteki mockup düzeni (üstte Somonlu rozeti yok).
class CartProductCard extends StatefulWidget {
  const CartProductCard({
    super.key,
    required this.item,
    this.onTap,
    this.onQuantityChanged,
    this.onRemove,
    this.onAddToCart,
  });

  final CartItem item;
  final VoidCallback? onTap;
  final ValueChanged<int>? onQuantityChanged;
  final VoidCallback? onRemove;
  final VoidCallback? onAddToCart;

  static const double cardHeight = MarketProductCard.listCardHeight;

  @override
  State<CartProductCard> createState() => _CartProductCardState();
}

class _CartProductCardState extends State<CartProductCard> {
  CartItem get item => widget.item;

  String get _brand {
    if (item.brand != null && item.brand!.trim().isNotEmpty) {
      return item.brand!;
    }
    final title = item.title.toLowerCase();
    if (title.contains("hill")) return "Hill's";
    if (title.contains('pro plan') || title.contains('proplan')) return 'Pro Plan';
    if (title.contains('royal')) return 'Royal Canin';
    if (title.contains('n&d')) return 'N&D';
    return 'Pro Plan';
  }

  void _setQuantity(int next) {
    if (next < 1) return;
    widget.onQuantityChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Container(
        height: CartProductCard.cardHeight,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        clipBehavior: Clip.hardEdge,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImage(),
            const SizedBox(width: 8),
            Expanded(child: _buildMiddle()),
            Container(
              width: 1,
              margin: const EdgeInsets.symmetric(vertical: 4),
              color: AppColors.border.withValues(alpha: 0.8),
            ),
            const SizedBox(width: 6),
            SizedBox(width: 62, child: _buildRight()),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return SizedBox(
      width: 72,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Image.asset(
                  item.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.inventory_2_outlined,
                    color: AppColors.subText,
                    size: 28,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 4,
              left: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_outlined,
                      color: AppColors.surface,
                      size: 9,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      'x${item.quantity}',
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMiddle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Text(
          item.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _metaCell(
              label: 'Marka',
              value: _brand,
              align: TextAlign.left,
            ),
            const SizedBox(width: 14),
            _metaCell(
              label: 'SKT',
              value: '12.2027',
              align: TextAlign.left,
            ),
            const SizedBox(width: 14),
            _metaCell(
              label: 'Ağırlık',
              value: item.weight,
              align: TextAlign.left,
            ),
            const Spacer(),
          ],
        ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFE8F9EE),
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: AppColors.success,
                size: 12,
              ),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '3 saatte kapında',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _metaCell({
    required String label,
    required String value,
    TextAlign align = TextAlign.center,
  }) {
    final cross = align == TextAlign.left
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    return Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: cross,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 10,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: align,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            height: 1.2,
          ),
        ),
      ],
    );
  }

  Widget _buildRight() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Align(
          alignment: Alignment.center,
          child: ListenableBuilder(
            listenable: FavoriteStore.instance,
            builder: (context, _) {
              final isFavorite = FavoriteStore.instance.isFavorite(item.id);
              return GestureDetector(
                onTap: () {
                  FavoriteStore.instance.toggle(FavoriteItem.fromCartItem(item));
                },
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFavorite ? AppColors.error : AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    color: isFavorite ? AppColors.error : AppColors.primary,
                    size: 14,
                  ),
                ),
              );
            },
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatProductPrice(item.oldPrice, withDecimals: true),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.right,
                    style: TextStyle(
                      color: AppColors.subText.withValues(alpha: 0.9),
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      height: 1,
                      decoration: TextDecoration.lineThrough,
                      decorationColor: AppColors.subText.withValues(alpha: 0.7),
                    ),
                  ),
                ),
                const SizedBox(width: 2),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '%${item.discountPercent}',
                    style: const TextStyle(
                      color: AppColors.error,
                      fontSize: 7,
                      fontWeight: FontWeight.w900,
                      height: 1,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 1),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                formatProductPrice(item.unitPrice, withDecimals: true),
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -0.4,
                ),
              ),
            ),
          ],
        ),
        SizedBox(
          height: 16,
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setQuantity(item.quantity - 1),
                    child: const Center(
                      child: Icon(
                        Icons.remove_rounded,
                        color: AppColors.primary,
                        size: 11,
                      ),
                    ),
                  ),
                ),
                Text(
                  '${item.quantity}',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => _setQuantity(item.quantity + 1),
                    child: const Center(
                      child: Icon(
                        Icons.add_rounded,
                        color: AppColors.primary,
                        size: 11,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        Align(
          alignment: Alignment.center,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (widget.onRemove != null) {
                widget.onRemove!();
              } else {
                widget.onAddToCart?.call();
              }
            },
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: widget.onRemove != null
                    ? AppColors.error.withValues(alpha: 0.12)
                    : AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                widget.onRemove != null
                    ? Icons.delete_outline_rounded
                    : Icons.add_shopping_cart_rounded,
                color: widget.onRemove != null
                    ? AppColors.error
                    : AppColors.surface,
                size: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
