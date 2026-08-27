import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

class AppBrand {
  const AppBrand({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.assetPath = '',
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final String imageUrl;
  final String assetPath;
  final int order;
  final bool active;

  factory AppBrand.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppBrand(
      id: doc.id,
      name: (data[BrandFields.name] as String?) ?? doc.id,
      imageUrl: (data[BrandFields.imageUrl] as String?) ?? '',
      assetPath: (data[BrandFields.assetPath] as String?) ?? '',
      order: (data[BrandFields.order] as num?)?.toInt() ?? 0,
      active: data[BrandFields.active] as bool? ?? true,
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

  AppBrand copyWith({
    String? name,
    String? imageUrl,
    String? assetPath,
    int? order,
    bool? active,
  }) {
    return AppBrand(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      assetPath: assetPath ?? this.assetPath,
      order: order ?? this.order,
      active: active ?? this.active,
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

class BrandRepository {
  BrandRepository._();

  static final instance = BrandRepository._();

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.brands);

  Stream<List<AppBrand>> watchAll({bool activeOnly = false}) {
    return _collection.orderBy(BrandFields.order).snapshots().map((snapshot) {
      final brands = snapshot.docs.map(AppBrand.fromDoc).toList();
      return activeOnly
          ? brands.where((brand) => brand.active).toList()
          : brands;
    });
  }

  Future<List<AppBrand>> fetchAll({bool activeOnly = false}) async {
    final snapshot = await _collection.orderBy(BrandFields.order).get();
    final brands = snapshot.docs.map(AppBrand.fromDoc).toList();
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

  Future<void> delete(String id) => _collection.doc(id).delete();
}
