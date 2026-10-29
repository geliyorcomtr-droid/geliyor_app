import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

class AppTrustBadge {
  const AppTrustBadge({
    required this.id,
    required this.name,
    this.imageUrl = '',
    this.detailImageUrl = '',
    this.assetPath = '',
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final String imageUrl;
  /// İkona tıklanınca açılan görsel; ikondan bağımsızdır.
  final String detailImageUrl;
  final String assetPath;
  final int order;
  final bool active;

  factory AppTrustBadge.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppTrustBadge(
      id: doc.id,
      name: (data[TrustBadgeFields.name] as String?) ?? doc.id,
      imageUrl: (data[TrustBadgeFields.imageUrl] as String?) ?? '',
      detailImageUrl: (data[TrustBadgeFields.detailImageUrl] as String?) ?? '',
      assetPath: (data[TrustBadgeFields.assetPath] as String?) ?? '',
      order: (data[TrustBadgeFields.order] as num?)?.toInt() ?? 0,
      active: data[TrustBadgeFields.active] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    TrustBadgeFields.name: name.trim(),
    TrustBadgeFields.imageUrl: imageUrl.trim(),
    TrustBadgeFields.detailImageUrl: detailImageUrl.trim(),
    TrustBadgeFields.assetPath: assetPath.trim(),
    TrustBadgeFields.order: order,
    TrustBadgeFields.active: active,
    TrustBadgeFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppTrustBadge copyWith({
    String? name,
    String? imageUrl,
    String? detailImageUrl,
    String? assetPath,
    int? order,
    bool? active,
  }) {
    return AppTrustBadge(
      id: id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      detailImageUrl: detailImageUrl ?? this.detailImageUrl,
      assetPath: assetPath ?? this.assetPath,
      order: order ?? this.order,
      active: active ?? this.active,
    );
  }
}

const defaultTrustBadges = <AppTrustBadge>[
  AppTrustBadge(
    id: 'favorilere-ekle',
    name: 'Favorilere Ekle',
    assetPath: 'assets/images/app_ikonlar/kalp.png',
    order: 0,
  ),
  AppTrustBadge(id: 'degerlendirme', name: 'Değerlendirme', order: 1),
  AppTrustBadge(
    id: 'en-cok-tercih',
    name: 'Çok Satan Ürün',
    assetPath: 'assets/images/app_ikonlar/tercih_urun.png',
    order: 2,
  ),
  AppTrustBadge(
    id: 'tekrar-alim',
    name: 'Tekrar Alım',
    assetPath: 'assets/images/app_ikonlar/tekrar_alim.png',
    order: 4,
  ),
  AppTrustBadge(
    id: 'uygun-fiyat',
    name: 'Uygun Fiyat',
    assetPath: 'assets/images/app_ikonlar/uygun_fiyat.png',
    order: 5,
  ),
  AppTrustBadge(
    id: 'yetkili-satici',
    name: 'Yetkili Satıcı',
    order: 3,
  ),
];

class TrustBadgeRepository {
  TrustBadgeRepository._();

  static final instance = TrustBadgeRepository._();

  static String displayName(AppTrustBadge badge) {
    final name = badge.name.trim();
    if (name.isNotEmpty) return name;
    final id = badge.id.toLowerCase();
    if (id == 'en-cok-tercih') return 'Çok Satan Ürün';
    if (id == proteinBadgeId) return 'Protein Değeri';
    if (id == repurchaseBadgeId) return 'Tekrar Alım';
    if (id == affordableBadgeId) return 'Uygun Fiyat';
    if (id == authorizedSellerBadgeId) return 'Yetkili Satıcı';
    return badge.id;
  }

  static bool isSmartSuggestionBadge(AppTrustBadge badge) {
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return id == 'akilli-oneri' ||
        id.contains('akilli') ||
        name.contains('akıllı') ||
        name.contains('akilli');
  }

  static const preferredIconPath = 'assets/images/app_ikonlar/tercih_urun.png';
  static const proteinBadgeId = 'protein';
  static const proteinIconPath = 'assets/images/app_ikonlar/protein.png';
  static const repurchaseBadgeId = 'tekrar-alim';
  static const repurchaseIconPath = 'assets/images/app_ikonlar/tekrar_alim.png';
  static const affordableBadgeId = 'uygun-fiyat';
  static const affordableIconPath = 'assets/images/app_ikonlar/uygun_fiyat.png';
  static const ratingBadgeId = 'degerlendirme';
  static const authorizedSellerBadgeId = 'yetkili-satici';
  static const certificateOverlayWidth = 361.0;
  static const certificateOverlayHeight = 510.0;

  static bool isRatingBadge(AppTrustBadge badge) {
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return id == ratingBadgeId ||
        id.contains('puan') ||
        name.contains('puan') ||
        name.contains('değerlendirme') ||
        name.contains('degerlendirme') ||
        name.contains('rating');
  }

  static String formatPreferredRank(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '2.';
    return value.endsWith('.') ? value : '$value.';
  }

  static String formatRate(String raw, {String fallback = '%78'}) {
    final value = raw.trim();
    if (value.isEmpty) return fallback;
    return value.startsWith('%') ? value : '%$value';
  }

  static bool isProteinBadge(AppTrustBadge badge) {
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return id == proteinBadgeId || name.contains('protein');
  }

  static AppTrustBadge get defaultRepurchaseBadge =>
      defaultTrustBadges.firstWhere((badge) => badge.id == repurchaseBadgeId);

  static AppTrustBadge get defaultAffordableBadge =>
      defaultTrustBadges.firstWhere((badge) => badge.id == affordableBadgeId);

  static bool isAffordableBadge(AppTrustBadge badge) {
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return id == affordableBadgeId ||
        name.contains('uygun fiyat') ||
        name.contains('fiyat avantaj');
  }

  static bool isRepurchaseBadge(AppTrustBadge badge) {
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return id == repurchaseBadgeId ||
        name.contains('tekrar alım') ||
        name.contains('tekrar alim');
  }

  static AppTrustBadge get defaultAuthorizedSellerBadge =>
      defaultTrustBadges.firstWhere(
        (badge) => badge.id == authorizedSellerBadgeId,
      );

  static bool isAuthorizedSellerBadge(AppTrustBadge badge) {
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return id == authorizedSellerBadgeId ||
        id.contains('yetkili-satici') ||
        id.contains('yetkili_satici') ||
        name.contains('yetkili satıcı') ||
        name.contains('yetkili satici') ||
        name.contains('yetki belgesi');
  }

  static bool isPreferredBadge(AppTrustBadge badge) {
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return id == 'en-cok-tercih' ||
        name.contains('en çok tercih') ||
        name.contains('en cok tercih') ||
        name.contains('çok satan') ||
        name.contains('cok satan') ||
        name.contains('tercih ürün') ||
        name.contains('tercih urun');
  }

  static String displayImageUrl(AppTrustBadge badge) => badge.imageUrl.trim();

  static String displayDetailImageUrl(AppTrustBadge badge) =>
      badge.detailImageUrl.trim();

  static String displayAssetPath(AppTrustBadge badge) {
    final asset = badge.assetPath.trim();
    if (asset.isNotEmpty) return asset;
    return defaultAssetPathFor(badge);
  }

  static String defaultAssetPathFor(AppTrustBadge badge) {
    for (final item in defaultTrustBadges) {
      if (item.id == badge.id) return item.assetPath.trim();
    }
    if (isPreferredBadge(badge)) return preferredIconPath;
    if (isRepurchaseBadge(badge)) return repurchaseIconPath;
    if (isAffordableBadge(badge)) return affordableIconPath;
    if (isProteinBadge(badge)) return proteinIconPath;
    return '';
  }

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(FirestoreCollections.trustBadges);

  List<AppTrustBadge> _cached = const [];
  List<AppTrustBadge> get cached => _cached;

  Stream<List<AppTrustBadge>> watchAll({bool activeOnly = false}) {
    return _collection.orderBy(TrustBadgeFields.order).snapshots().map((
      snapshot,
    ) {
      final badges = snapshot.docs.map(AppTrustBadge.fromDoc).toList();
      _cached = List<AppTrustBadge>.unmodifiable(badges);
      return activeOnly
          ? badges.where((badge) => badge.active).toList()
          : badges;
    });
  }

  Future<List<AppTrustBadge>> fetchAll({bool activeOnly = false}) async {
    final snapshot = await _collection.orderBy(TrustBadgeFields.order).get();
    final badges = snapshot.docs.map(AppTrustBadge.fromDoc).toList();
    return activeOnly ? badges.where((badge) => badge.active).toList() : badges;
  }

  Stream<List<AppTrustBadge>> watchActiveEnsured() async* {
    await ensureDefaults();
    yield* watchAll(activeOnly: true);
  }

  Future<void> ensureDefaults() async {
    try {
      final snapshot = await _collection.get();
      final existingById = {for (final doc in snapshot.docs) doc.id: doc};
      final batch = FirebaseFirestore.instance.batch();
      var hasWrites = false;

      if (snapshot.docs.isEmpty) {
        for (final badge in defaultTrustBadges) {
          batch.set(_collection.doc(badge.id), badge.toMap());
          hasWrites = true;
        }
      }

      for (final doc in snapshot.docs) {
        final badge = AppTrustBadge.fromDoc(doc);
        if (isProteinBadge(badge)) {
          batch.delete(_collection.doc(doc.id));
          hasWrites = true;
        }
      }

      const preferredId = 'en-cok-tercih';
      final preferredDoc = existingById[preferredId];
      if (preferredDoc != null) {
        final data = preferredDoc.data();
        if (_needsDefaultIcon(
          data,
          staleAssetSuffixes: const ['/akilli_oneri.png'],
        )) {
          batch.set(_collection.doc(preferredId), {
            TrustBadgeFields.assetPath: preferredIconPath,
            TrustBadgeFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          hasWrites = true;
        }
      }

      final repurchaseDoc = existingById[repurchaseBadgeId];
      if (repurchaseDoc == null) {
        final repurchase = defaultTrustBadges.firstWhere(
          (badge) => badge.id == repurchaseBadgeId,
        );
        batch.set(_collection.doc(repurchase.id), repurchase.toMap());
        hasWrites = true;
      } else if (_needsDefaultIcon(repurchaseDoc.data())) {
        batch.set(_collection.doc(repurchaseBadgeId), {
          TrustBadgeFields.assetPath: repurchaseIconPath,
          TrustBadgeFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        hasWrites = true;
      }

      final hasAuthorizedSeller = snapshot.docs.any(
        (doc) => isAuthorizedSellerBadge(AppTrustBadge.fromDoc(doc)),
      );
      if (snapshot.docs.isNotEmpty && !hasAuthorizedSeller) {
        batch.set(
          _collection.doc(authorizedSellerBadgeId),
          defaultAuthorizedSellerBadge.toMap(),
        );
        hasWrites = true;
      }

      final affordableDoc = existingById[affordableBadgeId];
      if (affordableDoc == null) {
        final affordable = defaultTrustBadges.firstWhere(
          (badge) => badge.id == affordableBadgeId,
        );
        batch.set(_collection.doc(affordable.id), affordable.toMap());
        hasWrites = true;
      } else if (_needsDefaultIcon(affordableDoc.data())) {
        batch.set(_collection.doc(affordableBadgeId), {
          TrustBadgeFields.assetPath: affordableIconPath,
          TrustBadgeFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        hasWrites = true;
      }

      if (hasWrites) await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return;
      rethrow;
    }
  }

  static bool _needsDefaultIcon(
    Map<String, dynamic>? data, {
    List<String> staleAssetSuffixes = const [],
  }) {
    if (data == null) return true;
    final imageUrl = ((data[TrustBadgeFields.imageUrl] as String?) ?? '').trim();
    if (imageUrl.isNotEmpty) return false;
    final assetPath =
        ((data[TrustBadgeFields.assetPath] as String?) ?? '').trim();
    if (assetPath.isEmpty) return true;
    return staleAssetSuffixes.any(assetPath.endsWith);
  }

  Future<void> save(AppTrustBadge badge) {
    return _collection
        .doc(badge.id)
        .set(badge.toMap(), SetOptions(merge: true));
  }

  Future<void> delete(String id) => _collection.doc(id).delete();
}
