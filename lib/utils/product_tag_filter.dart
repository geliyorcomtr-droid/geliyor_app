import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';

/// Seçilen ihtiyaç/sağlık etiketine göre ürün listesini süzer.
class ProductTagFilter {
  ProductTagFilter._();

  static List<MarketProductData> apply({
    required List<MarketProductData> catalog,
    required Iterable<String> tags,
    String? petLabel,
    bool matchAll = true,
  }) {
    final tagList = [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
    if (tagList.isEmpty) return const [];

    return [
      for (final item in catalog)
        if ((petLabel == null ||
                petLabel.isEmpty ||
                item.petTag == petLabel) &&
            ProductAdvantageRepository.productMatchesTags(
              productAdvantageIds: item.productAdvantageIds,
              tags: tagList,
              matchAll: matchAll,
            ))
          item,
    ];
  }
}
