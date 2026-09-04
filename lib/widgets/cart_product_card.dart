import 'package:flutter/material.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/favorite_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/utils/product_price.dart';
import 'package:geliyor_app/utils/product_skt.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';
import 'package:geliyor_app/widgets/product_favorite_corner.dart';

/// Sepet ürün kartı.
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

  String get _sktDisplay {
    final value = ProductSkt.display(item.skt);
    return value.isEmpty ? '—' : value;
  }

  String get _displayTitle {
    var title = item.title.trim();
    final weight = item.weight.trim();
    if (weight.isNotEmpty) {
      final lower = title.toLowerCase();
      final weightLower = weight.toLowerCase();
      if (lower.endsWith(weightLower)) {
        title = title.substring(0, title.length - weight.length).trim();
      }
    }
    title = title
        .replaceFirst(
          RegExp(r'\s+\d+([.,]\d+)?\s*(kg|g)\s*$', caseSensitive: false),
          '',
        )
        .trim();
    return title.isEmpty ? item.title : title;
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
        child: Column(
          children: [
            const Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.delivery_dining_rounded,
                    color: AppColors.success,
                    size: 12,
                  ),
                  SizedBox(width: 4),
                  Text(
                    '3 saatte kapında',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.success,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildImage(),
                  const SizedBox(width: 8),
                  Expanded(child: _buildContent()),
                ],
              ),
            ),
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
                child: buildProductImage(
                  item.imagePath,
                  fit: BoxFit.contain,
                  errorWidget: const Icon(
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
              child: ProductFavoriteCorner(
                productId: item.id,
                onToggle: () {
                  FavoriteStore.instance.toggle(
                    FavoriteItem.fromCartItem(item),
                  );
                },
                size: 22,
                iconSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _displayTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const Spacer(),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _metaCell(label: 'Marka', value: _brand),
            const SizedBox(width: 14),
            _metaCell(label: 'SKT', value: _sktDisplay),
            const SizedBox(width: 14),
            _metaCell(
              label: 'Ağırlık',
              value: item.weight.trim().isEmpty ? '—' : item.weight,
            ),
            const Spacer(),
          ],
        ),
        const Spacer(),
        _buildActionsRow(),
      ],
    );
  }

  Widget _buildActionsRow() {
    return Row(
      children: [
        Expanded(
          child: Align(
            alignment: const Alignment(-0.2, 0),
            child: _buildPriceBlock(),
          ),
        ),
        _buildQuantityControls(),
        Expanded(
          child: Align(
            alignment: const Alignment(0.35, 0),
            child: _buildDeleteButton(),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              formatProductPrice(item.oldPrice, withDecimals: true),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.subText.withValues(alpha: 0.9),
                fontSize: 8,
                fontWeight: FontWeight.w700,
                height: 1,
                decoration: TextDecoration.lineThrough,
                decorationColor: AppColors.subText.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '%${item.discountPercent}',
                style: const TextStyle(
                  color: AppColors.error,
                  fontSize: 8,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          formatProductPrice(item.unitPrice, withDecimals: true),
          maxLines: 1,
          style: const TextStyle(
            color: AppColors.primary,
            fontSize: 13,
            fontWeight: FontWeight.w900,
            height: 1,
            letterSpacing: -0.4,
          ),
        ),
      ],
    );
  }

  Widget _buildQuantityControls() {
    return Container(
      height: 30,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _qtyButton(
            icon: Icons.remove_rounded,
            onTap: () => _setQuantity(item.quantity - 1),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(
              '${item.quantity}',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          _qtyButton(
            icon: Icons.add_rounded,
            onTap: () => _setQuantity(item.quantity + 1),
          ),
        ],
      ),
    );
  }

  Widget _qtyButton({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 26,
        height: 28,
        child: Icon(icon, color: AppColors.primary, size: 16),
      ),
    );
  }

  Widget _buildDeleteButton() {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        if (widget.onRemove != null) {
          widget.onRemove!();
        } else {
          widget.onAddToCart?.call();
        }
      },
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          color: widget.onRemove != null
              ? AppColors.error.withValues(alpha: 0.12)
              : AppColors.primary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(
          widget.onRemove != null
              ? Icons.delete_outline_rounded
              : Icons.add_shopping_cart_rounded,
          color: widget.onRemove != null
              ? AppColors.error
              : AppColors.surface,
          size: 16,
        ),
      ),
    );
  }

  Widget _metaCell({required String label, required String value}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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
}
