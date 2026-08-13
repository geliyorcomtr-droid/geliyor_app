import 'package:flutter/material.dart';
import 'package:geliyor_app/data/pet_market_catalog.dart';
import 'package:geliyor_app/utils/product_price.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';

Widget marketProductListCard({
  required MarketProductData product,
  VoidCallback? onTap,
  void Function(String weight, double price, double oldPrice, int quantity)?
      onAddToCart,
  int initialQuantity = 1,
  ValueChanged<int>? onQuantityChanged,
  bool showAddToCart = true,
  bool showWeightPicker = true,
  Widget? footerTrailing,
  bool initialIsFavorite = false,
  ValueChanged<bool>? onFavoriteToggle,
}) {
  return SizedBox(
    height: MarketProductCard.listCardHeight,
    child: MarketProductCard(
      product: product,
      onTap: onTap,
      onAddToCart: onAddToCart,
      initialQuantity: initialQuantity,
      onQuantityChanged: onQuantityChanged,
      showAddToCart: showAddToCart,
      showWeightPicker: showWeightPicker,
      footerTrailing: footerTrailing,
      initialIsFavorite: initialIsFavorite,
      onFavoriteToggle: onFavoriteToggle,
    ),
  );
}

MarketProductData buildSimpleMarketProduct({
  required String id,
  required String imagePath,
  required String title,
  String subtitle = '',
  String petTag = 'Ürün',
  String dietTag = 'Standart',
  double rating = 4.5,
  int reviewCount = 48,
  required double price,
  required double oldPrice,
  String weight = '1 adet',
  List<String>? weights,
  List<double>? prices,
  List<double>? oldPrices,
  String brand = 'Pro Plan',
  String expiryLabel = 'SKT: 12.2027',
  int? discount,
}) {
  final disc =
      discount ?? discountPercentFromPrices(price, oldPrice) ?? 15;

  return MarketProductData(
    id: id,
    imagePath: imagePath,
    title: title,
    subtitle: subtitle,
    petTag: petTag,
    dietTag: dietTag,
    rating: rating,
    reviewCount: reviewCount,
    discount: disc,
    weights: weights ?? [weight],
    prices: prices ?? [price],
    oldPrices: oldPrices ?? [oldPrice],
    features: petMarketCatFeatures,
    brand: brand,
    expiryLabel: expiryLabel,
  );
}
