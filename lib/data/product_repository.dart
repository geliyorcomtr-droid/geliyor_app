import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/pet_market_catalog.dart';
import 'package:geliyor_app/utils/product_skt.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(FirestoreCollections.products);

  Stream<List<AdminProduct>> watchAll({bool activeOnly = true}) {
    return _col
        .orderBy(ProductFields.updatedAt, descending: true)
        .snapshots()
        .map((snap) {
          final items = snap.docs.map(AdminProduct.fromDoc).toList();
          if (!activeOnly) return items;
          return items.where((p) => p.active).toList();
        });
  }

  Stream<List<MarketProductData>> watchMarketProducts({
    String? mainCategory,
    String? subCategory,
    String? searchQuery,
  }) {
    return watchAll(activeOnly: true).map((products) {
      var filtered = products;

      if (mainCategory != null && mainCategory.isNotEmpty) {
        final main = mainCategory.trim().toLowerCase();
        filtered = filtered.where((p) {
          final saved = p.mainCategory.trim().toLowerCase();
          return saved.isEmpty || saved == main;
        }).toList();
      }

      if (subCategory != null && subCategory.trim().isNotEmpty) {
        final sub = subCategory.trim().toLowerCase();
        filtered = filtered.where((p) => _matchesSubCategory(p, sub)).toList();
      }

      var list = filtered.map(toMarketProduct).toList();

      final q = searchQuery?.trim().toLowerCase() ?? '';
      if (q.isNotEmpty) {
        list = list.where((p) {
          final haystack =
              '${p.title} ${p.subtitle} ${p.brand} ${p.dietTag} ${p.petTag}'
                  .toLowerCase();
          return haystack.contains(q);
        }).toList();
      }

      return list;
    });
  }

  static bool _matchesSubCategory(AdminProduct product, String subLower) {
    final category = product.category.trim().toLowerCase();
    if (category.isEmpty) return true;
    if (subLower == 'akıllı pet' || subLower == 'akilli pet') {
      return true;
    }
    return category == subLower ||
        category.contains(subLower) ||
        subLower.contains(category);
  }

  static MarketProductData toMarketProduct(AdminProduct product) {
    final weight = product.weight.trim().isEmpty
        ? '1 Kg'
        : product.weight.trim();
    final unit = product.unitPrice;
    final old = product.oldPrice > 0 ? product.oldPrice : unit;
    final discount = product.discountPercent > 0
        ? product.discountPercent
        : (old > unit ? (((old - unit) / old) * 100).round() : 0);

    final petTag = switch (product.mainCategory.trim().toLowerCase()) {
      'dog' => 'Köpek',
      'smart' => 'Akıllı Pet',
      'bird' => 'Kuş',
      'rodent' => 'Kemirgen',
      _ => 'Kedi',
    };

    final features = switch (product.mainCategory.trim().toLowerCase()) {
      'dog' => petMarketDogFeatures,
      'smart' => petMarketSmartFeatures,
      _ => petMarketCatFeatures,
    };

    final image = product.imageUrl.trim().isNotEmpty
        ? product.imageUrl.trim()
        : 'assets/images/nd_kuzu_kisir.jpg';

    return MarketProductData(
      id: product.id,
      imagePath: image,
      title: product.title,
      subtitle: product.description.trim().isNotEmpty
          ? product.description.trim()
          : (product.brand.trim().isNotEmpty
                ? product.brand.trim()
                : product.category),
      petTag: petTag,
      dietTag: product.category.trim().isEmpty
          ? 'Genel'
          : product.category.trim(),
      rating: product.rating > 0 ? product.rating : 4.8,
      reviewCount: product.reviewCount,
      discount: discount,
      weights: [weight],
      prices: [unit],
      oldPrices: [old],
      features: features,
      brand: product.brand.trim().isEmpty ? 'Marka' : product.brand.trim(),
      skt: ProductSkt.display(product.skt),
      expiryLabel: ProductSkt.label(product.skt),
      trustBadgeIds: product.trustBadgeIds,
      productAdvantageIds: product.productAdvantageIds,
      productAdvantageValues: product.productAdvantageValues,
      proteinValue: product.proteinValue,
      preferredRank: product.preferredRank,
      repurchaseRate: product.repurchaseRate,
    );
  }
}
