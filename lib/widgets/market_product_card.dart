import 'package:flutter/material.dart';
import 'package:geliyor_app/state/favorite_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_price.dart';

class MarketProductFeature {
  const MarketProductFeature({
    required this.icon,
    required this.iconColor,
    required this.bgColor,
    this.title = '',
    this.subtitle = '',
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final Color bgColor;
}

class MarketProductData {
  const MarketProductData({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.subtitle,
    required this.petTag,
    required this.dietTag,
    required this.rating,
    required this.reviewCount,
    required this.discount,
    required this.weights,
    required this.prices,
    required this.oldPrices,
    required this.features,
    this.brand = 'Pro Plan',
    this.expiryLabel = 'SKT: 12.2027',
    this.deliveryLabel = '3 saatte kapında',
  });

  final String id;
  final String imagePath;
  final String title;
  final String subtitle;
  final String petTag;
  final String dietTag;
  final double rating;
  final int reviewCount;
  final int discount;
  final List<String> weights;
  final List<double> prices;
  final List<double> oldPrices;
  final List<MarketProductFeature> features;
  final String brand;
  final String expiryLabel;
  final String deliveryLabel;
}

/// Pet Market ürün kartı — 393×852 tuvale sığacak kompakt mockup kartı.
class MarketProductCard extends StatefulWidget {
  const MarketProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
    this.initialQuantity = 1,
    this.onQuantityChanged,
    this.showAddToCart = true,
    this.showWeightPicker = true,
    this.footerTrailing,
    this.initialIsFavorite = false,
    this.onFavoriteToggle,
  });

  final MarketProductData product;
  final VoidCallback? onTap;
  final void Function(String weight, double price, double oldPrice, int quantity)?
      onAddToCart;
  final int initialQuantity;
  final ValueChanged<int>? onQuantityChanged;
  final bool showAddToCart;
  final bool showWeightPicker;
  final Widget? footerTrailing;
  final bool initialIsFavorite;
  final ValueChanged<bool>? onFavoriteToggle;

  static const double listCardHeight = 142;
  static const double productCardGap = 8;

  @override
  State<MarketProductCard> createState() => _MarketProductCardState();
}

class _MarketProductCardState extends State<MarketProductCard> {
  int _weightIndex = 0;
  late int _quantity;

  MarketProductData get p => widget.product;

  bool get _compactControls =>
      !widget.showAddToCart || p.weights.length == 1;

  @override
  void initState() {
    super.initState();
    _quantity = widget.initialQuantity;
  }

  @override
  void didUpdateWidget(covariant MarketProductCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialQuantity != widget.initialQuantity) {
      _quantity = widget.initialQuantity;
    }
  }

  void _toggleFavorite() {
    final index = _weightIndex.clamp(0, p.prices.length - 1);
    FavoriteStore.instance.toggle(
      FavoriteItem(
        id: p.id,
        imagePath: p.imagePath,
        title: p.title,
        unitPrice: p.prices[index],
        oldPrice: p.oldPrices[index],
        discountPercent: p.discount,
        weight: p.weights[index],
        brand: p.brand,
        category: p.petTag,
      ),
    );
    widget.onFavoriteToggle?.call(FavoriteStore.instance.isFavorite(p.id));
  }

  void _updateQuantity(int next) {
    if (next < 1 || next == _quantity) return;
    setState(() => _quantity = next);
    widget.onQuantityChanged?.call(next);
  }

  @override
  Widget build(BuildContext context) {
    final price = p.prices[_weightIndex];
    final oldPrice = p.oldPrices[_weightIndex];

    return GestureDetector(
      onTap: widget.onTap,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final expand = constraints.maxHeight.isFinite;

          return Container(
            width: double.infinity,
            height: expand ? constraints.maxHeight : null,
            padding: const EdgeInsets.all(8),
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
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.start,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  p.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w900,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 4),
                              ListenableBuilder(
                                listenable: FavoriteStore.instance,
                                builder: (context, _) {
                                  final isFavorite =
                                      FavoriteStore.instance.isFavorite(p.id);
                                  return GestureDetector(
                                    onTap: _toggleFavorite,
                                    behavior: HitTestBehavior.opaque,
                                    child: Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isFavorite
                                            ? AppColors.error
                                                .withValues(alpha: 0.12)
                                            : AppColors.selected,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isFavorite
                                              ? AppColors.error
                                              : AppColors.primary,
                                          width: 1.2,
                                        ),
                                      ),
                                      child: Icon(
                                        isFavorite
                                            ? Icons.favorite_rounded
                                            : Icons.favorite_border_rounded,
                                        color: isFavorite
                                            ? AppColors.error
                                            : AppColors.primary,
                                        size: 14,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          if (p.subtitle.trim().isNotEmpty) ...[
                            const SizedBox(height: 1),
                            Text(
                              p.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.subText,
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 4),
                          const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                        ],
                      ),
                      if (expand)
                        Expanded(
                          child: Align(
                            alignment: const Alignment(0, 0.25),
                            child: _buildWeightAndPrice(price, oldPrice),
                          ),
                        )
                      else ...[
                        const SizedBox(height: 4),
                        _buildWeightAndPrice(price, oldPrice),
                        const SizedBox(height: 4),
                      ],
                      _buildFooter(price, oldPrice),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildImage() {
    return Container(
      width: 80,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Image.asset(
                p.imagePath,
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
                    Icons.local_fire_department_rounded,
                    color: AppColors.surface,
                    size: 10,
                  ),
                  const SizedBox(width: 1),
                  Text(
                    '%${p.discount}',
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
    );
  }

  Widget _buildWeightAndPrice(double price, double oldPrice) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 6,
          child: widget.showWeightPicker
              ? _buildWeightPickerBlock()
              : _buildWeightInfoBlock(),
        ),
        const SizedBox(width: 6),
        Expanded(
          flex: 4,
          child: Align(
            alignment: Alignment.center,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        formatProductPrice(oldPrice),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.subText.withValues(alpha: 0.9),
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          decoration: TextDecoration.lineThrough,
                          decorationColor:
                              AppColors.subText.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        '%${p.discount}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  formatProductPrice(price),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 3),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.local_shipping_outlined,
                      size: 12,
                      color: AppColors.success,
                    ),
                    const SizedBox(width: 2),
                    Flexible(
                      child: Text(
                        p.deliveryLabel,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: AppColors.success,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
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
    );
  }

  Widget _buildWeightInfoBlock() {
    const infoStyle = TextStyle(
      color: AppColors.text,
      fontSize: 13.5,
      fontWeight: FontWeight.w900,
      height: 1.25,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Marka: ${p.brand}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: infoStyle,
        ),
        const SizedBox(height: 2),
        Text(
          p.expiryLabel,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: infoStyle,
        ),
        const SizedBox(height: 2),
        Text(
          'Ağırlık ${p.weights.isNotEmpty ? p.weights[_weightIndex] : '-'}',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: infoStyle,
        ),
      ],
    );
  }

  Widget _buildWeightPickerBlock() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Marka: ${p.brand}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  height: 1.1,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              p.expiryLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
          ],
        ),
        const SizedBox(height: 3),
        const Text(
          'Ağırlık Seçin',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: [
            for (int i = 0; i < p.weights.length; i++) ...[
              if (i > 0) const SizedBox(width: 4),
              if (_compactControls && p.weights.length == 1)
                _weightChip(i)
              else
                Expanded(child: _weightChip(i)),
            ],
          ],
        ),
      ],
    );
  }

  Widget _weightChip(int index) {
    final selected = _weightIndex == index;
    final compact = _compactControls;
    return GestureDetector(
      onTap: () => setState(() => _weightIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: compact ? 22 : 24,
        width: compact && p.weights.length == 1 ? 68 : null,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.06)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: 0.8,
          ),
        ),
        child: Text(
          p.weights[index],
          style: TextStyle(
            color: selected ? AppColors.primaryLight : AppColors.text,
            fontSize: compact ? 9 : 9.5,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    );
  }

  Widget _buildFooter(double price, double oldPrice) {
    final compactQty = _compactControls;
    final quantityBar = Container(
      height: compactQty ? 28 : 26,
      width: compactQty ? 86 : null,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border, width: 1.1),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => _updateQuantity(_quantity - 1),
              child: Center(
                child: Icon(
                  Icons.remove_rounded,
                  color: AppColors.text,
                  size: compactQty ? 15 : 13,
                ),
              ),
            ),
          ),
          Text(
            '$_quantity',
            style: TextStyle(
              color: AppColors.text,
              fontSize: compactQty ? 12 : 11,
              fontWeight: FontWeight.w900,
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () => _updateQuantity(_quantity + 1),
              child: Center(
                child: Icon(
                  Icons.add_rounded,
                  color: AppColors.text,
                  size: compactQty ? 15 : 13,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        if (compactQty) quantityBar else Expanded(child: quantityBar),
        if (widget.footerTrailing != null) ...[
          const SizedBox(width: 8),
          widget.footerTrailing!,
        ],
        if (widget.showAddToCart) ...[
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () {
                widget.onAddToCart?.call(
                  p.weights[_weightIndex],
                  price,
                  oldPrice,
                  _quantity,
                );
              },
              child: Container(
                height: compactQty ? 22 : 24,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.primary,
                      size: 13,
                    ),
                    SizedBox(width: 4),
                    Text(
                      'Sepete Ekle',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ] else
          const Spacer(),
      ],
    );
  }
}

/// Pet Market / Ürünler sayfası — 3 sütunluk kompakt ürün kartı.
class MarketCompactProductCard extends StatelessWidget {
  const MarketCompactProductCard({
    super.key,
    required this.product,
    this.onTap,
    this.onAddToCart,
  });

  final MarketProductData product;
  final VoidCallback? onTap;
  final VoidCallback? onAddToCart;

  static const double cardHeight = 148;
  static const double cardGap = 8;

  @override
  Widget build(BuildContext context) {
    final price = product.prices.isNotEmpty ? product.prices.first : 0.0;
    final weight = product.weights.isNotEmpty ? product.weights.first : '';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Center(
                child: Image.asset(
                  product.imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_outlined,
                    color: AppColors.subText,
                    size: 36,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              weight,
              style: const TextStyle(
                color: AppColors.subText,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    formatProductPrice(price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onAddToCart,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_rounded,
                      size: 12,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
