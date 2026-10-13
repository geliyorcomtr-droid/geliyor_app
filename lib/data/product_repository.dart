import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/health_product_groups.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/data/pet_market_catalog.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/data/product_bag_days.dart';
import 'package:geliyor_app/utils/product_ingredients.dart';
import 'package:geliyor_app/utils/product_skt.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';

class ProductRepository {
  ProductRepository._();
  static final ProductRepository instance = ProductRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(FirestoreCollections.products);

  List<AdminProduct> _cached = const [];
  bool _catalogReady = false;
  StreamSubscription<List<AdminProduct>>? _warmSub;

  bool get catalogReady => _catalogReady;
  List<AdminProduct> get cached => _cached;

  void ensureWarm() {
    _warmSub ??= watchAll(activeOnly: true, inStockOnly: true).listen((_) {});
  }

  Stream<List<AdminProduct>> watchAll({
    bool activeOnly = true,
    bool inStockOnly = false,
  }) {
    return _col
        .orderBy(ProductFields.updatedAt, descending: true)
        .snapshots()
        .map((snap) {
          _cached = List<AdminProduct>.unmodifiable(
            snap.docs.map(AdminProduct.fromDoc).toList(),
          );
          _catalogReady = true;
          return _applyWatchFilters(
            _cached,
            activeOnly: activeOnly,
            inStockOnly: inStockOnly,
          );
        });
  }

  static List<AdminProduct> _applyWatchFilters(
    List<AdminProduct> products, {
    required bool activeOnly,
    required bool inStockOnly,
  }) {
    var items = products;
    if (activeOnly) {
      items = [for (final product in items) if (product.active) product];
    }
    if (inStockOnly) {
      items = [for (final product in items) if (product.isInStock) product];
    }
    return items;
  }

  Stream<List<MarketProductData>> watchActiveProducts() {
    return watchAll(activeOnly: true).map(
      (products) => products.map(toMarketProduct).toList(),
    );
  }

  List<MarketProductData> cachedActiveProducts() {
    return [
      for (final product in _cached)
        if (product.active) toMarketProduct(product),
    ];
  }

  Stream<List<MarketProductData>> watchMarketProducts({
    String? mainCategory,
    String? subCategory,
    String? searchQuery,
  }) {
    return watchAll(activeOnly: true, inStockOnly: true).map((products) {
      return marketProductsFrom(
        products,
        mainCategory: mainCategory,
        subCategory: subCategory,
        searchQuery: searchQuery,
      );
    });
  }

  List<MarketProductData> cachedMarketProducts({
    String? mainCategory,
    String? subCategory,
    String? searchQuery,
  }) {
    if (_cached.isEmpty) return const [];
    return marketProductsFrom(
      _applyWatchFilters(_cached, activeOnly: true, inStockOnly: true),
      mainCategory: mainCategory,
      subCategory: subCategory,
      searchQuery: searchQuery,
    );
  }

  static List<MarketProductData> marketProductsFrom(
    List<AdminProduct> products, {
    String? mainCategory,
    String? subCategory,
    String? searchQuery,
  }) {
    var filtered = products;

    if (mainCategory != null && mainCategory.isNotEmpty) {
      final main = mainCategory.trim().toLowerCase();
      filtered = filtered.where((product) {
        final saved = product.mainCategory.trim().toLowerCase();
        return saved.isEmpty || saved == main;
      }).toList();
    }

    if (subCategory != null && subCategory.trim().isNotEmpty) {
      final sub = subCategory.trim().toLowerCase();
      filtered = filtered
          .where((product) => _matchesSubCategory(product, sub))
          .toList();
    }

    var list = filtered.map(toMarketProduct).toList();

    final q = searchQuery?.trim().toLowerCase() ?? '';
    if (q.isNotEmpty) {
      final tagIds = ProductAdvantageRepository.matchingIds(q);
      list = list.where((product) {
        if (tagIds.isNotEmpty &&
            product.productAdvantageIds.any(tagIds.contains)) {
          return true;
        }
        final haystack =
            '${product.title} ${product.subtitle} ${product.brand} ${product.dietTag} ${product.petTag}'
                .toLowerCase();
        return haystack.contains(q);
      }).toList();
    }

    return list;
  }

  Future<MarketProductData?> getMarketProduct(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty) return null;
    final doc = await _col.doc(trimmed).get();
    if (!doc.exists) return null;
    final product = AdminProduct.fromDoc(doc);
    if (!product.active) return null;
    return toMarketProduct(product);
  }

  static bool inCategory(
    AdminProduct product, {
    required String mainCategory,
    required String subCategory,
  }) {
    final main = mainCategory.trim().toLowerCase();
    if (main.isNotEmpty) {
      final saved = product.mainCategory.trim().toLowerCase();
      if (saved.isNotEmpty && saved != main) return false;
    }
    final sub = subCategory.trim().toLowerCase();
    if (sub.isEmpty) return true;
    return _matchesSubCategory(product, sub);
  }

  static bool _matchesSubCategory(AdminProduct product, String subLower) {
    if (subLower == 'akıllı pet' || subLower == 'akilli pet') {
      return true;
    }

    final wanted = PetLifeStage.normalizeTitle(subLower);
    final healthGroup = HealthProductGroup.forCategoryTitle(wanted);
    if (healthGroup != null &&
        product.productAdvantageIds.any(
          (id) => id.trim() == healthGroup.advantageId,
        )) {
      return true;
    }
    final titles = [
      product.category,
      ...product.extraCategories,
    ]
        .map(PetLifeStage.normalizeTitle)
        .where((title) => title.isNotEmpty)
        .toList();

    if (titles.isEmpty) {
      return PetLifeStage.isAdultFoodTitle(wanted);
    }

    if (PetLifeStage.isLifeStageTitle(wanted)) {
      return titles.any(
        (title) => PetLifeStage.isSameLifeStageCategory(title, wanted),
      );
    }

    bool matches(String raw) {
      final category = PetLifeStage.normalizeTitle(raw);
      if (category.isEmpty) return false;
      if (PetLifeStage.isLifeStageTitle(category)) return false;
      return category == wanted ||
          category.contains(wanted) ||
          wanted.contains(category);
    }

    if (matches(product.category)) return true;
    return product.extraCategories.any(matches);
  }

  static MarketProductData toMarketProduct(AdminProduct product) {
    final weight = product.weight.trim().isEmpty
        ? '1 Kg'
        : product.weight.trim();
    final unit = product.unitPrice;
    final old = product.oldPrice;
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
      categoryTitles: [
        product.category,
        ...product.extraCategories,
      ],
      productAdvantageValues: product.productAdvantageValues,
      proteinValue: product.proteinValue,
      animalProteinValue: product.animalProteinValue,
      preferredRank: product.preferredRank,
      repurchaseRate: ProductBagDays.displayFor(
        mainCategory: product.mainCategory,
        category: product.category,
        weight: product.weight,
        title: product.title,
        brand: product.brand,
        stored: product.repurchaseRate,
      ),
      barcode: product.barcode.trim(),
      gallery: [
        for (final url in product.gallery)
          if (url.trim().isNotEmpty) url.trim(),
      ],
      boughtTogetherIds: product.boughtTogetherIds,
      ingredients: product.ingredients.trim().isNotEmpty
          ? product.ingredients.trim()
          : (ProductIngredients.looksLike(product.description)
              ? product.description.trim()
              : ''),
      createdAt: product.createdAt,
    );
  }

  /// Eski "Mama" alt kategorisini Yetişkin olarak taşır.
  static Future<int>? _mamaToYetiskinBackfill;

  Future<int> migrateMamaCategoryToYetiskin() {
    return _mamaToYetiskinBackfill ??= _runMamaToYetiskinBackfill();
  }

  Future<int> _runMamaToYetiskinBackfill() async {
    try {
      final snap = await _col.get();
      var updated = 0;
      WriteBatch? batch;
      var ops = 0;

      Future<void> commit() async {
        final current = batch;
        if (current == null || ops == 0) return;
        await current.commit();
        batch = null;
        ops = 0;
      }

      bool isLegacyMama(String raw) =>
          PetLifeStage.normalizeTitle(raw) == 'mama';

      for (final doc in snap.docs) {
        final data = doc.data();
        final main = (data[ProductFields.mainCategory] as String?) ?? '';
        if (main != 'cat' && main != 'dog') continue;

        final category = (data[ProductFields.category] as String?) ?? '';
        final extras = data[ProductFields.extraCategories];
        final extraList = <String>[
          if (extras is List)
            for (final item in extras)
              if (item is String) item,
        ];
        final nextCategory =
            isLegacyMama(category) ? PetLifeStage.catAdult : category;
        final nextExtras = [
          for (final title in extraList)
            isLegacyMama(title) ? PetLifeStage.catAdult : title,
        ];
        var extrasChanged = extraList.length != nextExtras.length;
        if (!extrasChanged) {
          for (var i = 0; i < extraList.length; i++) {
            if (extraList[i] != nextExtras[i]) {
              extrasChanged = true;
              break;
            }
          }
        }
        if (nextCategory == category && !extrasChanged) continue;

        batch ??= FirebaseFirestore.instance.batch();
        batch!.update(doc.reference, {
          ProductFields.category: nextCategory,
          ProductFields.extraCategories: nextExtras,
        });
        ops++;
        updated++;
        if (ops >= 400) await commit();
      }
      await commit();
      return updated;
    } catch (_) {
      _mamaToYetiskinBackfill = null;
      return 0;
    }
  }

  /// Mevcut ürünlerin tekrar-alım kutusunu paket gününe çevirir.
  static Future<int>? _bagDaysBackfill;

  Future<int> backfillBagDays() {
    return _bagDaysBackfill ??= _runBagDaysBackfill();
  }

  Future<int> _runBagDaysBackfill() async {
    try {
      final snap = await _col.get();
      var updated = 0;
      WriteBatch? batch;
      var ops = 0;

      Future<void> commit() async {
        final current = batch;
        if (current == null || ops == 0) return;
        await current.commit();
        batch = null;
        ops = 0;
      }

      for (final doc in snap.docs) {
        final product = AdminProduct.fromDoc(doc);
        final days = ProductBagDays.daysFor(
          mainCategory: product.mainCategory,
          category: product.category,
          weight: product.weight,
          title: product.title,
          brand: product.brand,
        );
        final next = days == null ? '' : '$days';
        final raw = doc.data()[ProductFields.repurchaseRate];
        final rawText = raw is num ? '${raw.round()}' : (raw as String? ?? '');
        final current = ProductBagDays.digits(rawText);
        final shouldClearLegacy = days == null &&
            ProductBagDays.looksLikeLegacyPercent(rawText);
        if (!shouldClearLegacy && current == next) continue;
        if (next.isEmpty && !shouldClearLegacy) continue;

        batch ??= FirebaseFirestore.instance.batch();
        batch!.update(doc.reference, {
          ProductFields.repurchaseRate: next,
          ProductFields.updatedAt: FieldValue.serverTimestamp(),
        });
        ops++;
        updated++;
        if (ops >= 400) await commit();
      }
      await commit();
      return updated;
    } catch (_) {
      _bagDaysBackfill = null;
      return 0;
    }
  }
}
