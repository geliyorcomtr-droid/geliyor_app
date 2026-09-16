import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/brand_feeding_guide.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

class AppBrand {
  const AppBrand({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.assetPath = '',
    this.order = 0,
    this.active = true,
    this.feeding = BrandFeedingGuide.empty,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String assetPath;
  final int order;
  final bool active;
  final BrandFeedingGuide feeding;

  factory AppBrand.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppBrand(
      id: doc.id,
      name: (data[BrandFields.name] as String?) ?? doc.id,
      imageUrl: (data[BrandFields.imageUrl] as String?) ?? '',
      assetPath: (data[BrandFields.assetPath] as String?) ?? '',
      order: (data[BrandFields.order] as num?)?.toInt() ?? 0,
      active: data[BrandFields.active] as bool? ?? true,
      feeding: BrandFeedingGuide.fromFirestore(
        data[BrandFields.feedingCat],
        data[BrandFields.feedingDog],
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        BrandFields.name: name.trim(),
        BrandFields.imageUrl: imageUrl.trim(),
        BrandFields.assetPath: assetPath.trim(),
        BrandFields.order: order,
        BrandFields.active: active,
        BrandFields.updatedAt: FieldValue.serverTimestamp(),
      };

  Map<String, dynamic> toFeedingMap() => {
        BrandFields.feedingCat: feeding.toCatMap(),
        BrandFields.feedingDog: feeding.toDogMap(),
        BrandFields.updatedAt: FieldValue.serverTimestamp(),
      };

  AppBrand copyWith({
    String? name,
    String? imageUrl,
    String? assetPath,
    int? order,
    bool? active,
    BrandFeedingGuide? feeding,
  }) {
    return AppBrand(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
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

class BrandRepository extends ChangeNotifier {
  BrandRepository._();

  static final instance = BrandRepository._();

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.brands);

  List<AppBrand> _cached = List<AppBrand>.unmodifiable(defaultBrands);
  bool _listening = false;

  List<AppBrand> get cached => _cached;

  void startListening() {
    if (_listening) return;
    _listening = true;
    unawaited(ensureDefaults());
    _collection.orderBy(BrandFields.order).snapshots().listen((snapshot) {
      if (snapshot.docs.isEmpty) return;
      _setCache(snapshot.docs.map(AppBrand.fromDoc).toList());
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
    final named = byName(brandName ?? '');
    if (named != null) return named.id;

    final blob = _normalize('$brandName $title $subtitle');
    if (blob.isEmpty) return null;
    final compactBlob = _compact(blob);
    AppBrand? best;
    for (final brand in _cached) {
      if (!brand.active) continue;
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
    return best?.id;
  }

  Stream<List<AppBrand>> watchAll({bool activeOnly = false}) {
    return _collection.orderBy(BrandFields.order).snapshots().map((snapshot) {
      final brands = snapshot.docs.map(AppBrand.fromDoc).toList();
      if (brands.isNotEmpty) _setCache(brands);
      return activeOnly
          ? brands.where((brand) => brand.active).toList()
          : brands;
    });
  }

  Future<List<AppBrand>> fetchAll({bool activeOnly = false}) async {
    final snapshot = await _collection.orderBy(BrandFields.order).get();
    final brands = snapshot.docs.map(AppBrand.fromDoc).toList();
    if (brands.isNotEmpty) _setCache(brands);
    return activeOnly ? brands.where((brand) => brand.active).toList() : brands;
  }

  Future<void> ensureDefaults() async {
    final snapshot = await _collection.limit(1).get();
    if (snapshot.docs.isNotEmpty) return;

    final batch = FirebaseFirestore.instance.batch();
    for (final brand in defaultBrands) {
      batch.set(_collection.doc(brand.id), brand.toMap());
    }
    await batch.commit();
  }

  Future<void> save(AppBrand brand) {
    return _collection
        .doc(brand.id)
        .set(brand.toMap(), SetOptions(merge: true));
  }

  Future<void> saveFeeding(AppBrand brand) {
    return _collection
        .doc(brand.id)
        .set(brand.toFeedingMap(), SetOptions(merge: true));
  }

  Future<void> delete(String id) => _collection.doc(id).delete();

  void _setCache(List<AppBrand> brands) {
    _cached = List<AppBrand>.unmodifiable(brands);
    notifyListeners();
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
