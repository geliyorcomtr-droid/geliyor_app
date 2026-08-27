import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

/// Sayfa bannerleri: ortak carousel yapısı, her bölümün kendi yüksekliği.
class BannerPlacement {
  const BannerPlacement({
    required this.id,
    required this.title,
    required this.height,
    this.description = '',
  });

  final String id;
  final String title;
  final double height;
  final String description;

  static const width = 361.0;
  static const radius = 24.0;

  String get sizeLabel =>
      '${width.toInt()} × ${height.toInt()} px · radius ${radius.toInt()}';

  static const home = BannerPlacement(
    id: 'home',
    title: 'Ana Sayfa',
    height: 132,
    description: 'Kaydırmalı carousel',
  );
  static const healthTop = BannerPlacement(
    id: 'health_top',
    title: 'Sağlık — Üst',
    height: 118,
  );
  static const healthBottom = BannerPlacement(
    id: 'health_bottom',
    title: 'Sağlık — Alt',
    height: 100,
  );
  static const smartPlan = BannerPlacement(
    id: 'smart_plan',
    title: 'Akıllı Plan',
    height: 160,
  );
  static const easyOrder = BannerPlacement(
    id: 'easy_order',
    title: 'Kolay Sipariş',
    height: 160,
  );
  static const foodTracking = BannerPlacement(
    id: 'food_tracking',
    title: 'Mama Takibi',
    height: 140,
  );
  static const campaignsPoints = BannerPlacement(
    id: 'campaigns_points',
    title: 'Kampanya & Puan',
    height: 150,
  );
  static const assistant = BannerPlacement(
    id: 'assistant',
    title: 'Asistan',
    height: 148,
  );
  static const knowledge = BannerPlacement(
    id: 'knowledge',
    title: 'Bilgi Bankası',
    height: 110,
  );
  static const articles = BannerPlacement(
    id: 'articles',
    title: 'Makaleler',
    height: 96,
  );
  static const meetPet = BannerPlacement(
    id: 'meet_pet',
    title: 'Dostunu Tanıyalım',
    height: 120,
  );
  static const emergency = BannerPlacement(
    id: 'emergency',
    title: 'Acil Destek',
    height: 120,
  );
  static const medicine = BannerPlacement(
    id: 'medicine',
    title: 'İlaç & Tedavi',
    height: 100,
  );
  static const vaccine = BannerPlacement(
    id: 'vaccine',
    title: 'Aşı Takvimi',
    height: 88,
  );
  static const featuredQuestions = BannerPlacement(
    id: 'featured_questions',
    title: 'Öne Çıkan Sorular',
    height: 96,
  );
  static const allTopics = BannerPlacement(
    id: 'all_topics',
    title: 'Tüm Konular',
    height: 100,
  );

  static const values = <BannerPlacement>[
    home,
    healthTop,
    healthBottom,
    smartPlan,
    easyOrder,
    foodTracking,
    campaignsPoints,
    assistant,
    knowledge,
    articles,
    meetPet,
    emergency,
    medicine,
    vaccine,
    featuredQuestions,
    allTopics,
  ];

  static BannerPlacement byId(String id) {
    for (final item in values) {
      if (item.id == id) return item;
    }
    return home;
  }
}

class AppBanner {
  const AppBanner({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.assetPath = '',
    this.placement = 'home',
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String assetPath;
  final String placement;
  final int order;
  final bool active;

  String get displayImage => imageUrl.trim().isNotEmpty ? imageUrl : assetPath;

  BannerPlacement get placementInfo => BannerPlacement.byId(placement);

  factory AppBanner.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppBanner(
      id: doc.id,
      title: (data[BannerFields.title] as String?) ?? '',
      imageUrl: (data[BannerFields.imageUrl] as String?) ?? '',
      assetPath: (data[BannerFields.assetPath] as String?) ?? '',
      placement:
          (data[BannerFields.placement] as String?) ?? BannerPlacement.home.id,
      order: (data[BannerFields.order] as num?)?.toInt() ?? 0,
      active: data[BannerFields.active] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    BannerFields.title: title.trim(),
    BannerFields.imageUrl: imageUrl.trim(),
    BannerFields.assetPath: assetPath.trim(),
    BannerFields.placement: placement.trim().isEmpty
        ? BannerPlacement.home.id
        : placement.trim(),
    BannerFields.order: order,
    BannerFields.active: active,
    BannerFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppBanner copyWith({
    String? title,
    String? imageUrl,
    String? assetPath,
    String? placement,
    int? order,
    bool? active,
  }) {
    return AppBanner(
      id: id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      assetPath: assetPath ?? this.assetPath,
      placement: placement ?? this.placement,
      order: order ?? this.order,
      active: active ?? this.active,
    );
  }
}

const defaultBanners = <AppBanner>[
  AppBanner(
    id: 'mutlu-patiler',
    title: 'Mutlu Patiler',
    assetPath: 'assets/images/banner_mutlu_patiler.png',
    placement: 'home',
    order: 0,
  ),
  AppBanner(
    id: 'geliyor',
    title: 'geliyor.tr',
    assetPath: 'assets/images/banner_geliyor.png',
    placement: 'home',
    order: 1,
  ),
  AppBanner(
    id: 'banner-1',
    title: 'Kampanya',
    assetPath: 'assets/images/banner1.png',
    placement: 'home',
    order: 2,
  ),
  AppBanner(
    id: 'health-top',
    title: 'Sağlık',
    assetPath: 'assets/images/saglik_banner.png',
    placement: 'health_top',
  ),
  AppBanner(
    id: 'health-bottom',
    title: 'Sağlık Alt',
    assetPath: 'assets/images/saglik_alt_banner.png',
    placement: 'health_bottom',
  ),
  AppBanner(
    id: 'smart-plan',
    title: 'Akıllı Plan',
    assetPath: 'assets/images/akilli_plan_banner.png',
    placement: 'smart_plan',
  ),
  AppBanner(
    id: 'easy-order',
    title: 'Kolay Sipariş',
    assetPath: 'assets/images/kolay_siparis_banner.png',
    placement: 'easy_order',
  ),
  AppBanner(
    id: 'food-tracking',
    title: 'Mama Takibi',
    assetPath: 'assets/images/mama_takibi_banner.png',
    placement: 'food_tracking',
  ),
  AppBanner(
    id: 'campaigns-points',
    title: 'Kampanya & Puan',
    assetPath: 'assets/images/kampanya_puan_banner.png',
    placement: 'campaigns_points',
  ),
  AppBanner(
    id: 'assistant',
    title: 'Asistan',
    assetPath: 'assets/images/asistan_banner.png',
    placement: 'assistant',
  ),
  AppBanner(
    id: 'knowledge',
    title: 'Bilgi Bankası',
    assetPath: 'assets/images/bilgi_bankasi_banner.png',
    placement: 'knowledge',
  ),
  AppBanner(
    id: 'articles',
    title: 'Makaleler',
    assetPath: 'assets/images/bilgi_bankasi_banner.png',
    placement: 'articles',
  ),
  AppBanner(
    id: 'meet-pet',
    title: 'Dostunu Tanıyalım',
    assetPath: 'assets/images/dostunu_taniyalim_banner.png',
    placement: 'meet_pet',
  ),
  AppBanner(
    id: 'emergency',
    title: 'Acil Destek',
    assetPath: 'assets/images/acil_destek_banner.png',
    placement: 'emergency',
  ),
  AppBanner(
    id: 'medicine',
    title: 'İlaç & Tedavi',
    assetPath: 'assets/images/ilac_tedavi_banner.png',
    placement: 'medicine',
  ),
  AppBanner(
    id: 'vaccine',
    title: 'Aşı Takvimi',
    assetPath: 'assets/images/asi_takvimi_banner.png',
    placement: 'vaccine',
  ),
  AppBanner(
    id: 'featured-questions',
    title: 'Öne Çıkan Sorular',
    assetPath: 'assets/images/one_cikan_sorular_banner.png',
    placement: 'featured_questions',
  ),
  AppBanner(
    id: 'all-topics',
    title: 'Tüm Konular',
    assetPath: 'assets/images/tum_konular_banner.png',
    placement: 'all_topics',
  ),
];

class BannerRepository {
  BannerRepository._();
  static final BannerRepository instance = BannerRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(FirestoreCollections.banners);

  Future<void> ensureDefaults() async {
    try {
      final snap = await _col.get();
      final existingIds = {for (final doc in snap.docs) doc.id};
      final batch = FirebaseFirestore.instance.batch();
      var writes = 0;

      for (final banner in defaultBanners) {
        if (!existingIds.contains(banner.id)) {
          batch.set(_col.doc(banner.id), banner.toMap());
          writes++;
        }
      }

      for (final doc in snap.docs) {
        final data = doc.data();
        if ((data[BannerFields.placement] as String?)?.trim().isEmpty ??
            true) {
          batch.set(doc.reference, {
            BannerFields.placement: BannerPlacement.home.id,
          }, SetOptions(merge: true));
          writes++;
        }
      }

      if (writes > 0) await batch.commit();
    } catch (_) {
      // Mobil istemci yazma yetkisine sahip olmayabilir; fallback asset’ler kullanılır.
    }
  }

  Stream<List<AppBanner>> watchAll() {
    return _col.snapshots().map((snap) {
      final list = snap.docs.map(AppBanner.fromDoc).toList()
        ..sort((a, b) {
          final byPlacement = a.placement.compareTo(b.placement);
          if (byPlacement != 0) return byPlacement;
          return a.order.compareTo(b.order);
        });
      return list;
    });
  }

  Stream<List<AppBanner>> watchActive({String? placement}) {
    return watchAll().map((list) {
      return list
          .where(
            (item) =>
                item.active &&
                item.displayImage.isNotEmpty &&
                (placement == null || item.placement == placement),
          )
          .toList();
    });
  }
}
