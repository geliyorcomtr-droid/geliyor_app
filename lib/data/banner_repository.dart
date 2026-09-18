import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

/// Sayfa bannerleri: ortak carousel yapısı, her bölümün kendi yüksekliği.
class BannerPlacement {
  const BannerPlacement({
    required this.id,
    required this.title,
    required this.height,
    this.description = '',
    this.boxWidth = width,
    this.boxRadius = radius,
    this.pageId = 'other',
    this.pageLabel = 'Diğer',
    this.slotLabel = '',
  });

  final String id;
  final String title;
  final double height;
  final String description;
  final double boxWidth;
  final double boxRadius;
  final String pageId;
  final String pageLabel;
  final String slotLabel;

  static const width = 361.0;
  static const radius = 24.0;

  String get pxLabel => '${boxWidth.toInt()} × ${height.toInt()} px';

  String get belongsLabel {
    final slot = slotLabel.trim().isEmpty ? title : slotLabel;
    return '$pageLabel · $slot';
  }

  String get sizeLabel =>
      '$pxLabel · radius ${boxRadius.toInt()}';

  static const home = BannerPlacement(
    id: 'home',
    title: 'Ana Sayfa — Üst',
    pageId: 'home',
    pageLabel: 'Ana Sayfa',
    slotLabel: 'Üst banner',
    height: 132,
    description: 'Kaydırmalı carousel · 3 sn otomatik',
  );
  static const homeBottom = BannerPlacement(
    id: 'home_bottom',
    title: 'Ana Sayfa — Alt',
    pageId: 'home',
    pageLabel: 'Ana Sayfa',
    slotLabel: 'Alt reklam kutusu',
    height: 82,
    boxRadius: 999,
    description: '361×82 · Dost Ekle / Pet Market / Sahiplendirme ile aynı',
  );
  static const homeAd1 = BannerPlacement(
    id: 'home_ad_1',
    title: 'Ana Sayfa — Reklam 1',
    pageId: 'home',
    pageLabel: 'Ana Sayfa',
    slotLabel: 'Reklam 1 · Hill’s',
    height: 84,
    boxWidth: 84,
    boxRadius: 18,
    description: 'Pet Market altı · 84×84',
  );
  static const homeAd2 = BannerPlacement(
    id: 'home_ad_2',
    title: 'Ana Sayfa — Reklam 2',
    pageId: 'home',
    pageLabel: 'Ana Sayfa',
    slotLabel: 'Reklam 2 · Royal Canin',
    height: 84,
    boxWidth: 84,
    boxRadius: 18,
    description: 'Pet Market altı · 84×84',
  );
  static const homeAd3 = BannerPlacement(
    id: 'home_ad_3',
    title: 'Ana Sayfa — Reklam 3',
    pageId: 'home',
    pageLabel: 'Ana Sayfa',
    slotLabel: 'Reklam 3 · N&D',
    height: 84,
    boxWidth: 84,
    boxRadius: 18,
    description: 'Pet Market altı · 84×84',
  );
  static const homeAd4 = BannerPlacement(
    id: 'home_ad_4',
    title: 'Ana Sayfa — Reklam 4',
    pageId: 'home',
    pageLabel: 'Ana Sayfa',
    slotLabel: 'Reklam 4 · Pro Plan',
    height: 84,
    boxWidth: 84,
    boxRadius: 18,
    description: 'Pet Market altı · 84×84',
  );
  static const homeDostEkle = BannerPlacement(
    id: 'home_dost_ekle',
    title: 'Dost Ekle — Ana sayfa şeridi',
    pageId: 'dost_ekle',
    pageLabel: 'Dost Ekle',
    slotLabel: 'Ana sayfa şeridi',
    height: 82,
    boxRadius: 999,
    description: '361×82 · tıklanınca Dost Ekle sayfası',
  );
  static const homePetMarket = BannerPlacement(
    id: 'home_pet_market',
    title: 'Pet Market — Ana sayfa şeridi',
    pageId: 'pet_market',
    pageLabel: 'Pet Market',
    slotLabel: 'Ana sayfa şeridi',
    height: 82,
    boxRadius: 999,
    description: '361×82 · tıklanınca Pet Market',
  );
  static const homeSahiplendirme = BannerPlacement(
    id: 'home_sahiplendirme',
    title: 'Sahiplendirme — Ana sayfa şeridi',
    pageId: 'sahiplendirme',
    pageLabel: 'Sahiplendirme',
    slotLabel: 'Ana sayfa şeridi',
    height: 82,
    boxRadius: 999,
    description: '361×82 · tıklanınca Sahiplendirme',
  );
  static const adoption = BannerPlacement(
    id: 'adoption',
    title: 'Sahiplendirme — Sayfa bannerı',
    pageId: 'sahiplendirme',
    pageLabel: 'Sahiplendirme',
    slotLabel: 'Sayfa bannerı',
    height: 108,
    description: '361×108 · Sahiplendirme sayfası üst banner',
  );
  static const healthTop = BannerPlacement(
    id: 'health_top',
    title: 'Pet E-nabız — Üst',
    pageId: 'health',
    pageLabel: 'Pet E-nabız',
    slotLabel: 'Üst banner',
    height: 118,
  );
  static const healthBottom = BannerPlacement(
    id: 'health_bottom',
    title: 'Pet E-nabız — Alt',
    pageId: 'health',
    pageLabel: 'Pet E-nabız',
    slotLabel: 'Alt banner',
    height: 100,
  );
  static const smartPlan = BannerPlacement(
    id: 'smart_plan',
    title: 'Akıllı Plan',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Sayfa bannerı',
    height: 160,
  );
  static const easyOrder = BannerPlacement(
    id: 'easy_order',
    title: 'Kolay Sipariş',
    pageId: 'easy_order',
    pageLabel: 'Kolay Sipariş',
    slotLabel: 'Sayfa bannerı',
    height: 132,
    boxWidth: 361,
    boxRadius: 24,
    description: '361×132 · Kolay Sipariş sayfa bannerı',
  );
  static const foodTracking = BannerPlacement(
    id: 'food_tracking',
    title: 'Mama Takibi',
    pageId: 'food_tracking',
    pageLabel: 'Mama Takibi',
    slotLabel: 'Sayfa bannerı',
    height: 140,
  );
  static const campaignsPoints = BannerPlacement(
    id: 'campaigns_points',
    title: 'Kampanya & Puan',
    pageId: 'campaigns_points',
    pageLabel: 'Kampanya & Puan',
    slotLabel: 'Sayfa bannerı',
    height: 150,
  );
  static const assistant = BannerPlacement(
    id: 'assistant',
    title: 'Asistan',
    pageId: 'assistant',
    pageLabel: 'Asistan',
    slotLabel: 'Sayfa bannerı',
    height: 148,
  );
  static const knowledge = BannerPlacement(
    id: 'knowledge',
    title: 'Bilgi Bankası',
    pageId: 'knowledge',
    pageLabel: 'Bilgi Bankası',
    slotLabel: 'Sayfa bannerı',
    height: 110,
  );
  static const articles = BannerPlacement(
    id: 'articles',
    title: 'Makaleler',
    pageId: 'articles',
    pageLabel: 'Makaleler',
    slotLabel: 'Sayfa bannerı',
    height: 96,
  );
  static const meetPet = BannerPlacement(
    id: 'meet_pet',
    title: 'Dostlarım',
    pageId: 'meet_pet',
    pageLabel: 'Dostlarım',
    slotLabel: 'Sayfa bannerı',
    height: 132,
    boxWidth: 361,
    boxRadius: 24,
    description: '361×132 · Dostlarım sayfa bannerı',
  );
  static const emergency = BannerPlacement(
    id: 'emergency',
    title: 'Acil Destek',
    pageId: 'emergency',
    pageLabel: 'Acil Destek',
    slotLabel: 'Sayfa bannerı',
    height: 120,
  );
  static const medicine = BannerPlacement(
    id: 'medicine',
    title: 'İlaç & Tedavi',
    pageId: 'medicine',
    pageLabel: 'İlaç & Tedavi',
    slotLabel: 'Sayfa bannerı',
    height: 100,
  );
  static const vaccine = BannerPlacement(
    id: 'vaccine',
    title: 'Aşı Takvimi',
    pageId: 'vaccine',
    pageLabel: 'Aşı Takvimi',
    slotLabel: 'Sayfa bannerı',
    height: 88,
  );
  static const featuredQuestions = BannerPlacement(
    id: 'featured_questions',
    title: 'Öne Çıkan Sorular',
    pageId: 'featured_questions',
    pageLabel: 'Öne Çıkan Sorular',
    slotLabel: 'Sayfa bannerı',
    height: 96,
  );
  static const allTopics = BannerPlacement(
    id: 'all_topics',
    title: 'Tüm Konular',
    pageId: 'all_topics',
    pageLabel: 'Tüm Konular',
    slotLabel: 'Sayfa bannerı',
    height: 100,
  );

  static const values = <BannerPlacement>[
    home,
    homeBottom,
    homeDostEkle,
    homePetMarket,
    homeSahiplendirme,
    adoption,
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

  static List<(String pageId, String pageLabel)> get pages {
    final seen = <String>{};
    return [
      for (final item in values)
        if (seen.add(item.pageId)) (item.pageId, item.pageLabel),
    ];
  }

  static List<BannerPlacement> forPage(String pageId) =>
      values.where((item) => item.pageId == pageId).toList();
}

class BannerLinkType {
  BannerLinkType._();

  static const none = '';
  static const product = 'product';
  static const article = 'article';
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
    this.linkType = BannerLinkType.none,
    this.linkId = '',
    this.linkLabel = '',
    this.updatedAt,
  });

  final String id;
  final String title;
  final String imageUrl;
  final String assetPath;
  final String placement;
  final int order;
  final bool active;
  final String linkType;
  final String linkId;
  final String linkLabel;
  final DateTime? updatedAt;

  String get displayImage => imageUrl.trim().isNotEmpty ? imageUrl : assetPath;

  BannerPlacement get placementInfo => BannerPlacement.byId(placement);

  bool get hasLink =>
      (linkType == BannerLinkType.product ||
          linkType == BannerLinkType.article) &&
      linkId.trim().isNotEmpty;

  String get actionLabel {
    final custom = linkLabel.trim();
    if (custom.isNotEmpty) return custom;
    if (linkType == BannerLinkType.article) return 'Makaleye git';
    return 'Ürüne git';
  }

  factory AppBanner.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppBanner(
      id: doc.id,
      title: (data[BannerFields.title] as String?) ?? '',
      imageUrl: (data[BannerFields.imageUrl] as String?) ?? '',
      assetPath: (data[BannerFields.assetPath] as String?) ?? '',
      placement: (data[BannerFields.placement] as String?) ?? '',
      order: (data[BannerFields.order] as num?)?.toInt() ?? 0,
      active: data[BannerFields.active] as bool? ?? true,
      linkType: (data[BannerFields.linkType] as String?) ?? BannerLinkType.none,
      linkId: (data[BannerFields.linkId] as String?) ?? '',
      linkLabel: (data[BannerFields.linkLabel] as String?) ?? '',
      updatedAt: data[BannerFields.updatedAt] is Timestamp
          ? (data[BannerFields.updatedAt] as Timestamp).toDate()
          : null,
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
    BannerFields.linkType: linkType.trim(),
    BannerFields.linkId: linkId.trim(),
    BannerFields.linkLabel: linkLabel.trim(),
    BannerFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppBanner copyWith({
    String? title,
    String? imageUrl,
    String? assetPath,
    String? placement,
    int? order,
    bool? active,
    String? linkType,
    String? linkId,
    String? linkLabel,
    DateTime? updatedAt,
  }) {
    return AppBanner(
      id: id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      assetPath: assetPath ?? this.assetPath,
      placement: placement ?? this.placement,
      order: order ?? this.order,
      active: active ?? this.active,
      linkType: linkType ?? this.linkType,
      linkId: linkId ?? this.linkId,
      linkLabel: linkLabel ?? this.linkLabel,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  static int storageUploadStamp(String imageUrl) {
    final decoded = Uri.decodeComponent(imageUrl.trim());
    final match = RegExp(r'banners/(\d+)_').firstMatch(decoded);
    return int.tryParse(match?.group(1) ?? '') ?? 0;
  }

  static AppBanner? latestLive(List<AppBanner> banners) {
    if (banners.isEmpty) return null;
    final ranked = [...banners]..sort((a, b) {
      final byUrl = (b.imageUrl.trim().isNotEmpty ? 1 : 0).compareTo(
        a.imageUrl.trim().isNotEmpty ? 1 : 0,
      );
      if (byUrl != 0) return byUrl;
      final byStamp = storageUploadStamp(
        b.imageUrl,
      ).compareTo(storageUploadStamp(a.imageUrl));
      if (byStamp != 0) return byStamp;
      final left = a.updatedAt;
      final right = b.updatedAt;
      if (left != null || right != null) {
        return (right ?? DateTime.fromMillisecondsSinceEpoch(0)).compareTo(
          left ?? DateTime.fromMillisecondsSinceEpoch(0),
        );
      }
      return b.order.compareTo(a.order);
    });
    return ranked.first;
  }

  static String liveNetworkPath(List<AppBanner> banners) {
    final live = latestLive(banners);
    final url = live?.imageUrl.trim() ?? '';
    if (url.isEmpty) return '';
    final stamp = live!.updatedAt?.millisecondsSinceEpoch;
    if (stamp == null) return url;
    return url.contains('?') ? '$url&v=$stamp' : '$url?v=$stamp';
  }
}

const defaultBanners = <AppBanner>[
  AppBanner(
    id: 'home-sahiplendirme',
    title: 'Sahiplendirme',
    assetPath: 'assets/images/home_sahiplendirme.png',
    placement: 'home_sahiplendirme',
  ),
  AppBanner(
    id: 'adoption-page',
    title: 'Sahiplendirme',
    assetPath: 'assets/images/sahiplendirme_banner.jpg',
    placement: 'adoption',
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
    title: 'Dostlarım',
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

  static const seededDocId = '_seeded';

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(FirestoreCollections.banners);

  bool _isBannerDoc(DocumentSnapshot<Map<String, dynamic>> doc) =>
      !doc.id.startsWith('_');

  Future<void> ensureDefaults() async {
    try {
      final snap = await _col.get();
      final existingIds = {for (final doc in snap.docs) doc.id};
      final alreadySeeded =
          existingIds.contains(seededDocId) || snap.docs.any(_isBannerDoc);
      final deletedIds = <String>{};
      if (existingIds.contains(seededDocId)) {
        final seededData =
            snap.docs.firstWhere((doc) => doc.id == seededDocId).data();
        final raw = seededData['deletedIds'];
        if (raw is Iterable) {
          deletedIds.addAll(raw.map((item) => item.toString()));
        }
      }
      if (!alreadySeeded) {
        final batch = FirebaseFirestore.instance.batch();
        for (final banner in defaultBanners) {
          if (deletedIds.contains(banner.id)) continue;
          batch.set(_col.doc(banner.id), banner.toMap());
        }
        batch.set(_col.doc(seededDocId), {
          'seeded': true,
          BannerFields.updatedAt: FieldValue.serverTimestamp(),
        });
        await batch.commit();
      }
      await pruneStaleStripBanners();
      await restoreHomeDostEkleIfMeetPetLeaked();
    } catch (_) {
      // Mobil istemci yazma yetkisine sahip olmayabilir.
    }
  }

  /// Ana sayfa Dost Ekle şeridine Dostlarım bannerı yazıldıysa geri al.
  Future<void> restoreHomeDostEkleIfMeetPetLeaked() async {
    try {
      final snap = await _col.get(const GetOptions(source: Source.server));
      final banners = snap.docs
          .where(_isBannerDoc)
          .map(AppBanner.fromDoc)
          .toList();
      final home = banners
          .where((item) => item.placement == 'home_dost_ekle')
          .toList();
      final meetUrls = banners
          .where((item) => item.placement == 'meet_pet')
          .map((item) => item.imageUrl.trim())
          .where((url) => url.isNotEmpty)
          .toSet();

      bool isMeetPetGraphic(AppBanner banner) {
        final asset = banner.assetPath.toLowerCase();
        if (asset.contains('dostunu_taniyalim')) return true;
        final title = banner.title.toLowerCase();
        if (title.contains('tanıyalım') || title.contains('taniyalim')) {
          return true;
        }
        final url = banner.imageUrl.trim();
        if (url.isNotEmpty && meetUrls.contains(url)) return true;
        return false;
      }

      var changed = false;
      final cutoff = DateTime(2026, 9, 17);
      for (final banner in home.where((item) => item.active)) {
        final leaked = isMeetPetGraphic(banner);
        final stamp = AppBanner.storageUploadStamp(banner.imageUrl);
        final when = stamp > 0
            ? DateTime.fromMillisecondsSinceEpoch(stamp)
            : banner.updatedAt;
        final uploadedToday =
            when != null && !when.isBefore(cutoff) && banner.imageUrl.trim().isNotEmpty;
        if (!leaked && !uploadedToday) continue;
        if (!leaked && uploadedToday) {
          final hasPrevious = home.any(
            (item) =>
                item.id != banner.id && item.imageUrl.trim().isNotEmpty,
          );
          if (!hasPrevious) continue;
        }
        await _col.doc(banner.id).set({
          BannerFields.active: false,
          if (leaked) BannerFields.assetPath: '',
          BannerFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        changed = true;
      }

      final remaining = home.where(
        (item) =>
            item.active &&
            !isMeetPetGraphic(item) &&
            item.displayImage.trim().isNotEmpty,
      );
      if (remaining.isNotEmpty) return;
      if (!changed && home.where((item) => item.active).isNotEmpty) return;

      final previous = home
          .where(
            (item) =>
                !isMeetPetGraphic(item) && item.imageUrl.trim().isNotEmpty,
          )
          .toList()
        ..sort((a, b) {
          final byStamp = AppBanner.storageUploadStamp(
            b.imageUrl,
          ).compareTo(AppBanner.storageUploadStamp(a.imageUrl));
          if (byStamp != 0) return byStamp;
          return (b.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0))
              .compareTo(a.updatedAt ?? DateTime.fromMillisecondsSinceEpoch(0));
        });
      if (previous.isEmpty) return;
      await _col.doc(previous.first.id).set({
        BannerFields.active: true,
        BannerFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  /// Aynı slottaki eski bannerleri kapatır ve Storage dosyalarını siler.
  Future<void> pruneStaleStripBanners() async {
    const placements = {
      'home_pet_market',
      'home_dost_ekle',
      'home_sahiplendirme',
    };
    try {
      final snap = await _col.get(const GetOptions(source: Source.server));
      final banners = snap.docs
          .where(_isBannerDoc)
          .map(AppBanner.fromDoc)
          .toList();
      for (final placement in placements) {
        final group = banners
            .where((item) => item.placement == placement && item.active)
            .toList();
        final keep = AppBanner.latestLive(group);
        if (keep == null) continue;
        if (keep.imageUrl.trim().isNotEmpty && keep.assetPath.trim().isNotEmpty) {
          await _col.doc(keep.id).set({
            BannerFields.assetPath: '',
          }, SetOptions(merge: true));
        }
        for (final banner in group) {
          if (banner.id == keep.id) continue;
          if (banner.imageUrl.trim().isNotEmpty) {
            await deleteStorageUrl(banner.imageUrl);
          }
          await _col.doc(banner.id).set({
            BannerFields.active: false,
            BannerFields.assetPath: '',
            BannerFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
      }
      await pruneOrphanBannerFiles();
    } catch (_) {}
  }

  Future<void> pruneOrphanBannerFiles() async {
    try {
      final snap = await _col.get(const GetOptions(source: Source.server));
      final used = <String>{};
      for (final doc in snap.docs.where(_isBannerDoc)) {
        final url = AppBanner.fromDoc(doc).imageUrl.trim();
        if (url.isEmpty || !url.startsWith('http')) continue;
        try {
          used.add(FirebaseStorage.instance.refFromURL(url).fullPath);
        } catch (_) {}
      }
      final listed = await FirebaseStorage.instance.ref('banners').listAll();
      for (final item in listed.items) {
        if (used.contains(item.fullPath)) continue;
        try {
          await item.delete();
        } catch (_) {}
      }
    } catch (_) {}
  }

  Future<void> deleteBanner(AppBanner banner) async {
    await deleteStorageUrl(banner.imageUrl);
    await _col.doc(banner.id).delete();
    await _col.doc(seededDocId).set({
      'seeded': true,
      'deletedIds': FieldValue.arrayUnion([banner.id]),
      BannerFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<AppBanner>> watchAll() {
    return watchAllMeta().map((item) => item.banners);
  }

  Stream<({List<AppBanner> banners, bool fromCache})> watchAllMeta() {
    return _col.snapshots(includeMetadataChanges: true).map((snap) {
      final list = snap.docs
          .where(_isBannerDoc)
          .map(AppBanner.fromDoc)
          .toList()
        ..sort((a, b) {
          final byPlacement = a.placement.compareTo(b.placement);
          if (byPlacement != 0) return byPlacement;
          return a.order.compareTo(b.order);
        });
      return (banners: list, fromCache: snap.metadata.isFromCache);
    });
  }

  Stream<List<AppBanner>> watchActive({String? placement}) {
    return watchAll().map((list) {
      return list
          .where(
            (item) =>
                item.active &&
                item.imageUrl.trim().isNotEmpty &&
                (placement == null || item.placement == placement),
          )
          .toList();
    });
  }

  Stream<({List<AppBanner> banners, bool fromCache})> watchActiveMeta({
    String? placement,
  }) {
    return watchAllMeta().map((item) {
      final banners = item.banners
          .where(
            (banner) =>
                banner.active &&
                banner.imageUrl.trim().isNotEmpty &&
                (placement == null || banner.placement == placement),
          )
          .toList();
      return (banners: banners, fromCache: item.fromCache);
    });
  }

  Future<List<AppBanner>> fetchActiveFromServer({String? placement}) async {
    final snap = await _col.get(const GetOptions(source: Source.server));
    return snap.docs
        .where(_isBannerDoc)
        .map(AppBanner.fromDoc)
        .where(
          (item) =>
              item.active &&
              item.imageUrl.trim().isNotEmpty &&
              (placement == null || item.placement == placement),
        )
        .toList();
  }

  static Future<void> deleteStorageUrl(String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty || !trimmed.startsWith('http')) return;
    try {
      await FirebaseStorage.instance.refFromURL(trimmed).delete();
    } catch (_) {}
  }
}
