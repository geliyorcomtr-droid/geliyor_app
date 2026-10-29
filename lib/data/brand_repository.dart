import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/brand_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_variant.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/pro_plan_mini_puppy_guide.dart';
import 'package:geliyor_app/utils/local_image_cache.dart';

class AppBrand {
  const AppBrand({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.certificateUrl = '',
    this.assetPath = '',
    this.order = 0,
    this.active = true,
    this.feeding = BrandFeedingGuide.empty,
  });

  final String id;
  final String name;
  final String imageUrl;
  /// Markanın yetki belgesi. Ürün detayında Yetkili Satıcı kutusundan açılır.
  final String certificateUrl;
  final String assetPath;
  final int order;
  final bool active;
  final BrandFeedingGuide feeding;

  String get displayImage {
    final url = imageUrl.trim();
    if (url.isNotEmpty) return url;
    return assetPath.trim();
  }

  bool get hasImage => displayImage.isNotEmpty;

  /// Mama takibi: Pro Plan mini yavru tablosu üretici verisiyle her zaman hazır.
  BrandFeedingGuide get trackingFeeding {
    if (!BrandRepository.isProPlanName(name)) return feeding;
    if (feeding.hasMiniPuppyTable) return feeding;
    return feeding.copyWith(dogMiniPuppyCells: ProPlanMiniPuppyGuide.cells);
  }

  factory AppBrand.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppBrand(
      id: doc.id,
      name: (data[BrandFields.name] as String?) ?? doc.id,
      imageUrl: (data[BrandFields.imageUrl] as String?) ?? '',
      certificateUrl: (data[BrandFields.certificateUrl] as String?) ?? '',
      assetPath: (data[BrandFields.assetPath] as String?) ?? '',
      order: (data[BrandFields.order] as num?)?.toInt() ?? 0,
      active: data[BrandFields.active] as bool? ?? true,
      feeding: BrandFeedingGuide.fromFirestore(
        data[BrandFields.feedingCat],
        data[BrandFields.feedingDog],
        data[BrandFields.feedingCatKitten],
        data[BrandFields.feedingDogPuppy],
        data[BrandFields.feedingDogMiniPuppy],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        BrandFields.name: name.trim(),
        BrandFields.imageUrl: imageUrl.trim(),
        BrandFields.certificateUrl: certificateUrl.trim(),
        BrandFields.assetPath: assetPath.trim(),
        BrandFields.order: order,
        BrandFields.active: active,
        BrandFields.updatedAt: FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toFeedingMap() => {
        BrandFields.feedingCat: feeding.toCatMap(),
        BrandFields.feedingDog: feeding.toDogMap(),
        BrandFields.feedingCatKitten: feeding.toCatKittenMap(),
        BrandFields.feedingDogPuppy: feeding.toDogPuppyMap(),
        BrandFields.feedingDogMiniPuppy: feeding.toDogMiniPuppyMap(),
        BrandFields.updatedAt: FieldValue.serverTimestamp(),
      };

  AppBrand copyWith({
    String? name,
    String? imageUrl,
    String? certificateUrl,
    String? assetPath,
    int? order,
    bool? active,
    BrandFeedingGuide? feeding,
  }) {
    return AppBrand(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      certificateUrl: certificateUrl ?? this.certificateUrl,
      assetPath: assetPath ?? this.assetPath,
      order: order ?? this.order,
      active: active ?? this.active,
      feeding: feeding ?? this.feeding,
    );
  }
}

const defaultBrands = <AppBrand>[
  AppBrand(
    id: 'royal-canin',
    name: 'Royal Canin',
    assetPath: 'assets/images/brands/royal_canin.png',
    order: 0,
  ),
  AppBrand(
    id: 'hills',
    name: "Hill's",
    assetPath: 'assets/images/brands/hills.png',
    order: 1,
  ),
  AppBrand(
    id: 'nd',
    name: 'N&D',
    assetPath: 'assets/images/brands/nd.png',
    order: 2,
  ),
  AppBrand(
    id: 'advance',
    name: 'Advance',
    assetPath: 'assets/images/brands/advance.png',
    order: 3,
  ),
  AppBrand(
    id: 'pro-plan',
    name: 'Pro Plan',
    assetPath: 'assets/images/brands/proplan.png',
    order: 4,
  ),
  AppBrand(
    id: 'purina-one',
    name: 'Purina ONE',
    assetPath: 'assets/images/brands/purina_one.png',
    order: 5,
  ),
  AppBrand(
    id: 'acana',
    name: 'Acana',
    assetPath: 'assets/images/brands/acana.png',
    order: 6,
  ),
  AppBrand(
    id: 'gimcat',
    name: 'GimCat',
    assetPath: 'assets/images/brands/gimcat.png',
    order: 7,
  ),
  AppBrand(
    id: 'wanpy',
    name: 'Wanpy',
    assetPath: 'assets/images/brands/wanpy.png',
    order: 8,
  ),
  AppBrand(
    id: 'felix',
    name: 'Felix',
    assetPath: 'assets/images/brands/felix.png',
    order: 9,
  ),
  AppBrand(
    id: 'dreamies',
    name: 'Dreamies',
    assetPath: 'assets/images/brands/dreamies.png',
    order: 10,
  ),
  AppBrand(
    id: 'cat-chow',
    name: 'Cat Chow',
    assetPath: 'assets/images/brands/catchow.png',
    order: 11,
  ),
  AppBrand(
    id: 'dog-chow',
    name: 'Dog Chow',
    assetPath: 'assets/images/brands/dogchow.png',
    order: 12,
  ),
  AppBrand(
    id: 'reflex',
    name: 'Reflex',
    assetPath: 'assets/images/brands/reflex.png',
    order: 13,
  ),
  AppBrand(
    id: 'proline',
    name: 'Proline',
    assetPath: 'assets/images/brands/proline.png',
    order: 14,
  ),
];

const _brandsMetaDocId = '_meta';

class BrandRepository extends ChangeNotifier {
  BrandRepository._();

  static final instance = BrandRepository._();

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.brands);

  List<AppBrand> _cached = const [];
  bool _listening = false;

  List<AppBrand> get cached => _cached;

  /// Mama takibi: yalnızca aktif ve gramajı girilmiş markalar.
  /// Adında yavru geçen kayıtlar ayrı marka değildir; ana markanın tablosudur.
  List<AppBrand> get feedingChoices => _cached
      .where(
        (brand) =>
            brand.active &&
            !brand.trackingFeeding.isEmpty &&
            !isYavruLabeled(brand) &&
            !isProductLineDuplicate(brand),
      )
      .toList(growable: false);

  /// "Pro Plan Yavru" gibi yaşam evresi adı taşıyan marka kopyaları.
  static bool isYavruLabeled(AppBrand brand) => isYavruLabeledName(brand.name);

  static bool isYavruLabeledName(String name) {
    final title = _normalize(name).replaceAll('ı', 'i').replaceAll('İ', 'i');
    return title.endsWith(' yavru') ||
        title.endsWith(' kitten') ||
        title.contains(' yavru ');
  }

  static bool isProPlanName(String name) {
    return FeedingVariant.isProPlanName(name);
  }

  /// "Pro Plan Small & Mini Puppy" ayrı marka olarak listelenmez; Pro Plan seçeneğidir.
  static bool isProductLineDuplicate(AppBrand brand) {
    final title = _normalize(brand.name).replaceAll('ı', 'i').replaceAll('İ', 'i');
    return isProPlanName(brand.name) &&
        title.contains('mini') &&
        (title.contains('puppy') || title.contains('yavru'));
  }

  void startListening() {
    if (_listening) return;
    _listening = true;
    unawaited(ensureDefaults());
    _collection.orderBy(BrandFields.order).snapshots().listen((snapshot) {
      _setCache(
        snapshot.docs.where(_isBrandDoc).map(AppBrand.fromDoc).toList(),
      );
    });
  }

  AppBrand? byId(String id) {
    final needle = id.trim();
    if (needle.isEmpty) return null;
    for (final brand in _cached) {
      if (brand.id == needle) return brand;
    }
    return null;
  }

  AppBrand? byName(String name) {
    final needle = _normalize(name);
    if (needle.isEmpty) return null;
    for (final brand in _cached) {
      if (_normalize(brand.name) == needle) return brand;
    }
    return null;
  }

  /// Sipariş / ürün metninden marka id. Eşleşme yoksa `null` (standart tablo).
  String? idFromProduct({
    String? brandName,
    String? title,
    String? subtitle,
  }) {
    return matchId(
      _cached,
      brandName: brandName,
      title: title,
      subtitle: subtitle,
    );
  }

  /// En uzun marka adı kazanır. Yavru ibreli kopyalar atlanır;
  /// yavru tablosu ana markanın varyantından seçilir.
  static String? matchId(
    List<AppBrand> brands, {
    String? brandName,
    String? title,
    String? subtitle,
  }) {
    final blob = _normalize('$brandName $title $subtitle');
    if (blob.isEmpty) return null;
    final compactBlob = _compact(blob);
    AppBrand? best;
    for (final brand in brands) {
      if (!brand.active) continue;
      if (isYavruLabeled(brand)) continue;
      if (isProductLineDuplicate(brand)) continue;
      final name = _normalize(brand.name);
      if (name.length < 3) continue;
      final compactName = _compact(name);
      final matched = blob.contains(name) ||
          (compactName.length >= 4 && compactBlob.contains(compactName));
      if (!matched) continue;
      if (best == null || name.length > _normalize(best.name).length) {
        best = brand;
      }
    }
    if (best != null) return best.id;

    final named = _normalize(brandName ?? '');
    if (named.isEmpty) return null;
    for (final brand in brands) {
      if (isYavruLabeled(brand)) continue;
      if (_normalize(brand.name) == named) return brand.id;
    }
    return null;
  }

  Stream<List<AppBrand>> watchAll({bool activeOnly = false}) {
    return _collection.orderBy(BrandFields.order).snapshots().map((snapshot) {
      final brands = snapshot.docs
          .where(_isBrandDoc)
          .map(AppBrand.fromDoc)
          .toList();
      _setCache(brands);
      return activeOnly
          ? brands.where((brand) => brand.active).toList()
          : brands;
    });
  }

  Future<List<AppBrand>> fetchAll({bool activeOnly = false}) async {
    final snapshot = await _collection.orderBy(BrandFields.order).get();
    final brands = snapshot.docs
        .where(_isBrandDoc)
        .map(AppBrand.fromDoc)
        .toList();
    _setCache(brands);
    return activeOnly ? brands.where((brand) => brand.active).toList() : brands;
  }

  /// Eksik katalog markalarını yazar; silinenleri geri getirmez.
  Future<void> ensureDefaults() async {
    try {
      final snapshot = await _collection.get();
      final existingIds = snapshot.docs.map((doc) => doc.id).toSet();
      Map<String, dynamic>? meta;
      for (final doc in snapshot.docs) {
        if (doc.id == _brandsMetaDocId) {
          meta = doc.data();
          break;
        }
      }
      final removedIds = _deletedIdsFrom(meta);
      final batch = FirebaseFirestore.instance.batch();
      var writes = 0;
      for (final brand in defaultBrands) {
        if (removedIds.contains(brand.id)) continue;
        if (existingIds.contains(brand.id)) continue;
        batch.set(_collection.doc(brand.id), brand.toMap());
        writes++;
      }
      if (writes > 0) await batch.commit();
      await ensureProPlanMiniPuppyTable();
    } catch (_) {}
  }

  /// Pro Plan Small & Mini Puppy üretici tablosunu mini ırk yavruya yazar.
  Future<void> ensureProPlanMiniPuppyTable() async {
    try {
      final snapshot = await _collection.get();
      for (final doc in snapshot.docs) {
        if (!_isBrandDoc(doc)) continue;
        final brand = AppBrand.fromDoc(doc);
        if (isYavruLabeled(brand)) continue;
        final name = _normalize(brand.name).replaceAll('ı', 'i');
        if (!name.contains('pro plan') && brand.id != 'pro-plan') continue;
        if (ProPlanMiniPuppyGuide.sameAsOfficial(
          brand.feeding.dogMiniPuppyCells,
        )) {
          continue;
        }
        await saveFeeding(
          brand.copyWith(
            feeding: brand.feeding.copyWith(
              dogMiniPuppyCells: ProPlanMiniPuppyGuide.cells,
              dogMiniPuppyGrams: const {},
            ),
          ),
        );
      }
    } catch (_) {}
  }

  bool _isBrandDoc(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    return doc.id != _brandsMetaDocId;
  }

  Future<void> save(AppBrand brand) {
    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      _collection.doc(brand.id),
      brand.toMap(),
      SetOptions(merge: true),
    );
    batch.set(_metaDoc, {
      BrandFields.deletedIds: FieldValue.arrayRemove([brand.id]),
      BrandFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return batch.commit();
  }

  Future<void> saveFeeding(AppBrand brand) {
    return _collection
        .doc(brand.id)
        .set(brand.toFeedingMap(), SetOptions(merge: true));
  }

  Future<void> delete(String id) async {
    final trimmed = id.trim();
    if (trimmed.isEmpty || trimmed == _brandsMetaDocId) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_collection.doc(trimmed));
    batch.set(_metaDoc, {
      BrandFields.deletedIds: FieldValue.arrayUnion([trimmed]),
      BrandFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  /// Mama tüketim listesindeki "… Yavru" marka kopyalarını siler.
  Future<int> deleteYavruLabeledBrands() async {
    final snapshot = await _collection.get();
    final batch = FirebaseFirestore.instance.batch();
    final removed = <String>[];
    for (final doc in snapshot.docs) {
      if (!_isBrandDoc(doc)) continue;
      final brand = AppBrand.fromDoc(doc);
      if (!isYavruLabeled(brand)) continue;
      batch.delete(doc.reference);
      removed.add(doc.id);
    }
    if (removed.isEmpty) return 0;
    batch.set(_metaDoc, {
      BrandFields.deletedIds: FieldValue.arrayUnion(removed),
      BrandFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
    return removed.length;
  }

  DocumentReference<Map<String, dynamic>> get _metaDoc =>
      _collection.doc(_brandsMetaDocId);

  static Set<String> _deletedIdsFrom(Map<String, dynamic>? data) {
    final raw = data?[BrandFields.deletedIds];
    if (raw is! Iterable) return {};
    return {
      for (final value in raw)
        if ('$value'.trim().isNotEmpty) '$value'.trim(),
    };
  }

  void _setCache(List<AppBrand> brands) {
    _cached = List<AppBrand>.unmodifiable(brands);
    notifyListeners();
    unawaited(
      LocalImageCache.instance.prefetch([
        for (final brand in brands)
          if (brand.imageUrl.trim().isNotEmpty) brand.imageUrl.trim(),
      ]),
    );
  }

  static String _compact(String value) {
    return _normalize(value).replaceAll(RegExp(r'[^a-z0-9]+'), '');
  }

  static String _normalize(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll('’', "'")
        .replaceAll('`', "'")
        .replaceAll(RegExp(r'\s+'), ' ');
  }
}
