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
  static const homeSmartPlan = BannerPlacement(
    id: 'home_smart_plan',
    title: 'Akıllı Plan — Ana sayfa kutusu',
    pageId: 'home',
    pageLabel: 'Ana Sayfa',
    slotLabel: 'Akıllı Plan kutusu',
    height: 82,
    boxWidth: 361,
    boxRadius: 999,
    description: '361×82 · Pet Market / Dost Ekle / Sahiplendirme ile aynı',
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
  static const adoptionBoxAdopt = BannerPlacement(
    id: 'adoption_box_adopt',
    title: 'Sahiplendirme kutusu',
    pageId: 'sahiplendirme',
    pageLabel: 'Sahiplendirme',
    slotLabel: 'Sahiplendirme kutusu',
    height: 118,
    boxWidth: 115,
    boxRadius: 18,
    description:
        '115×118 · Sahiplendirme ve İlan Ekle. Görsel değişince iki sayfa da güncellenir.',
  );
  static const adoptionBoxLost = BannerPlacement(
    id: 'adoption_box_lost',
    title: 'Aranıyor kutusu',
    pageId: 'sahiplendirme',
    pageLabel: 'Sahiplendirme',
    slotLabel: 'Aranıyor kutusu',
    height: 118,
    boxWidth: 115,
    boxRadius: 18,
    description:
        '115×118 · Sahiplendirme ve İlan Ekle. Görsel değişince iki sayfa da güncellenir.',
  );
  static const adoptionBoxFound = BannerPlacement(
    id: 'adoption_box_found',
    title: 'Bulundu kutusu',
    pageId: 'sahiplendirme',
    pageLabel: 'Sahiplendirme',
    slotLabel: 'Bulundu kutusu',
    height: 118,
    boxWidth: 115,
    boxRadius: 18,
    description:
        '115×118 · Sahiplendirme ve İlan Ekle. Görsel değişince iki sayfa da güncellenir.',
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
  static const smartPlanAutoOrderStrip = BannerPlacement(
    id: 'smart_plan_auto_order_strip',
    title: 'Abonelik',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Abonelik şeridi',
    height: 139,
    boxWidth: 361,
    boxRadius: 24,
    description:
        '361×139 · Alttaki beyaz alanda “Hemen abone ol” ve anahtar uygulamada çalışır',
  );
  static const smartPlanReminderStrip = BannerPlacement(
    id: 'smart_plan_reminder_strip',
    title: 'Akıllı Hatırlatma şeridi',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Akıllı hatırlatma şeridi',
    height: 139,
    boxWidth: 361,
    boxRadius: 24,
    description:
        '361×139 · Alttaki beyaz kutu uygulama tarafından gelir, görsel değiştirilebilir',
  );
  static const smartPlanOrderTrackStrip = BannerPlacement(
    id: 'smart_plan_order_track_strip',
    title: 'Siparişten Otomatik Takip',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Siparişten otomatik takip',
    height: 139,
    boxWidth: 361,
    boxRadius: 24,
    description:
        '361×139 · Görselin herhangi bir yerine tıklanınca sipariş takibi açılır',
  );
  static const smartPlanManualTrackStrip = BannerPlacement(
    id: 'smart_plan_manual_track_strip',
    title: 'Manuel Takip',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Manuel takip',
    height: 139,
    boxWidth: 361,
    boxRadius: 24,
    description:
        '361×139 · Görselin herhangi bir yerine tıklanınca mama takip sayfası açılır',
  );
  static const smartPlanAutoOrder = BannerPlacement(
    id: 'smart_plan_auto_order',
    title: 'Otomatik Sipariş',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Otomatik Sipariş',
    height: 160,
    boxWidth: 115,
    boxRadius: 18,
    description: '115×160 · Sayfadaki 3 kutudan ilki',
  );
  static const smartPlanReminder = BannerPlacement(
    id: 'smart_plan_reminder',
    title: 'Akıllı Hatırlatma',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Akıllı Hatırlatma',
    height: 160,
    boxWidth: 115,
    boxRadius: 18,
    description: '115×160 · Sayfadaki 3 kutudan ikincisi',
  );
  static const smartPlanFoodTrack = BannerPlacement(
    id: 'smart_plan_food_track',
    title: 'Mama Takibi',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Mama Takibi',
    height: 160,
    boxWidth: 115,
    boxRadius: 18,
    description: '115×160 · Sayfadaki 3 kutudan üçüncüsü',
  );
  static const smartPlanAutoOrderDetail = BannerPlacement(
    id: 'smart_plan_auto_order_detail',
    title: 'Otomatik Sipariş ayrıntı',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Otomatik Sipariş ayrıntı',
    height: 280,
    boxWidth: 361,
    boxRadius: 28,
    description: '361×280 · Kutuya tıklanınca açılır',
  );
  static const smartPlanReminderDetail = BannerPlacement(
    id: 'smart_plan_reminder_detail',
    title: 'Akıllı Hatırlatma ayrıntı',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Akıllı Hatırlatma ayrıntı',
    height: 280,
    boxWidth: 361,
    boxRadius: 28,
    description: '361×280 · Kutuya tıklanınca açılır',
  );
  static const smartPlanFoodTrackDetail = BannerPlacement(
    id: 'smart_plan_food_track_detail',
    title: 'Mama Takibi ayrıntı',
    pageId: 'smart_plan',
    pageLabel: 'Akıllı Plan',
    slotLabel: 'Mama Takibi ayrıntı',
    height: 280,
    boxWidth: 361,
    boxRadius: 28,
    description: '361×280 · Kutuya tıklanınca açılır',
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
  static const giftSelect = BannerPlacement(
    id: 'gift_select',
    title: 'Hediye Seç',
    pageId: 'gift_select',
    pageLabel: 'Hediye Seç',
    slotLabel: 'Sayfa bannerı',
    height: 140,
    boxWidth: 361,
    boxRadius: 24,
    description: '361×140 · Hediye Seç sayfa bannerı',
  );
  static const hangiMama = BannerPlacement(
    id: 'hangi_mama',
    title: 'Hangi Mama',
    pageId: 'hangi_mama',
    pageLabel: 'Hangi Mama',
    slotLabel: 'Sayfa bannerı',
    height: 140,
    boxWidth: 361,
    boxRadius: 24,
    description: '361×140 · Kedi ve köpek kutularının üstü',
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
  static const campaignDiscount = BannerPlacement(
    id: 'campaign_discount',
    title: 'Abonelere %5 İndirim',
    pageId: 'kampanyalar',
    pageLabel: 'Kampanyalar',
    slotLabel: '%5 İndirim',
    height: 115,
    boxWidth: 115,
    boxRadius: 18,
    description: '115×115 · tıklanmaz. Silinince veya değişince kutu güncellenir.',
  );
  static const campaignDouble = BannerPlacement(
    id: 'campaign_double',
    title: 'İlk Siparişe 2 Kat Ödül',
    pageId: 'kampanyalar',
    pageLabel: 'Kampanyalar',
    slotLabel: '2 Kat Ödül',
    height: 115,
    boxWidth: 115,
    boxRadius: 18,
    description: '115×115 · tıklanmaz. Silinince veya değişince kutu güncellenir.',
  );
  static const campaignDonate = BannerPlacement(
    id: 'campaign_donate',
    title: 'Sokaktaki Dostlar',
    pageId: 'kampanyalar',
    pageLabel: 'Kampanyalar',
    slotLabel: 'Puan Bağışı',
    height: 115,
    boxWidth: 115,
    boxRadius: 18,
    description:
        '115×115 · tıklanınca dost puanı sokaktaki dostlar için bağışlanır.',
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
    height: 140,
    boxWidth: 361,
    boxRadius: 24,
    description: '361×140 · Acil Destek sayfa bannerı',
  );
  static const emergencyNotice = BannerPlacement(
    id: 'emergency_notice',
    title: 'Acil Destek — Alt uyarı',
    pageId: 'emergency',
    pageLabel: 'Acil Destek',
    slotLabel: 'Alt uyarı bannerı',
    height: 120,
    boxWidth: 361,
    boxRadius: 24,
    description: '361×120 · Sayfanın en altı. Silinince veya değişince kutu güncellenir.',
  );
  static const specialFoods = BannerPlacement(
    id: 'special_foods',
    title: 'Özel Sağlık Mamaları',
    pageId: 'special_foods',
    pageLabel: 'Özel Sağlık Mamaları',
    slotLabel: 'Sayfa bannerı',
    height: 140,
    boxWidth: 361,
    boxRadius: 24,
    description: '361×140 · Sayfanın en üstü',
  );
  static const medicine = BannerPlacement(
    id: 'medicine',
    title: 'İlaç ve Tedavi',
    pageId: 'medicine',
    pageLabel: 'İlaç ve Tedavi',
    slotLabel: 'Sayfa bannerı',
    height: 140,
    boxWidth: 361,
    boxRadius: 24,
    description: '361×140 · Arama kutusunun üstü',
  );
  static const vaccine = BannerPlacement(
    id: 'vaccine',
    title: 'Aşı Takvimi',
    pageId: 'vaccine',
    pageLabel: 'Aşı Takvimi',
    slotLabel: 'Sayfa bannerı',
    height: 165,
    boxWidth: 361,
    boxRadius: 24,
    description: '361×165 · Aşı Takvimi sayfa bannerı',
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
    homeSmartPlan,
    homeDostEkle,
    homePetMarket,
    homeSahiplendirme,
    adoption,
    adoptionBoxAdopt,
    adoptionBoxLost,
    adoptionBoxFound,
    healthTop,
    healthBottom,
    smartPlanAutoOrderStrip,
    smartPlanReminderStrip,
    smartPlanOrderTrackStrip,
    smartPlanManualTrackStrip,
    smartPlanAutoOrder,
    smartPlanReminder,
    smartPlanFoodTrack,
    smartPlanAutoOrderDetail,
    smartPlanReminderDetail,
    smartPlanFoodTrackDetail,
    easyOrder,
    hangiMama,
    giftSelect,
    foodTracking,
    campaignsPoints,
    campaignDiscount,
    campaignDouble,
    campaignDonate,
    assistant,
    knowledge,
    articles,
    meetPet,
    emergency,
    emergencyNotice,
    medicine,
    specialFoods,
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
    return live?.imageUrl.trim() ?? '';
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
    id: 'home-smart-plan',
    title: 'Akıllı Plan',
    assetPath: 'assets/images/home_akilli_plan.jpg',
    placement: 'home_smart_plan',
  ),
  AppBanner(
    id: 'adoption-page',
    title: 'Sahiplendirme',
    assetPath: 'assets/images/sahiplendirme_banner.jpg',
    placement: 'adoption',
  ),
  AppBanner(
    id: 'adoption-box-adopt',
    title: 'Sahiplendirme',
    assetPath: 'assets/images/sahiplendirme_kutu.jpg',
    placement: 'adoption_box_adopt',
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
    id: 'smart-plan-auto-order-strip',
    title: 'Abonelik',
    assetPath: 'assets/images/smart_plan_auto_order_strip.jpg',
    placement: 'smart_plan_auto_order_strip',
  ),
  AppBanner(
    id: 'smart-plan-reminder-strip',
    title: 'Akıllı Hatırlatma',
    assetPath: 'assets/images/smart_plan_reminder_strip.jpg',
    placement: 'smart_plan_reminder_strip',
  ),
  AppBanner(
    id: 'smart-plan-auto-order',
    title: 'Otomatik Sipariş',
    assetPath: 'assets/images/smart_plan_auto_order.jpg',
    placement: 'smart_plan_auto_order',
  ),
  AppBanner(
    id: 'smart-plan-reminder',
    title: 'Akıllı Hatırlatma',
    assetPath: 'assets/images/smart_plan_reminder.jpg',
    placement: 'smart_plan_reminder',
  ),
  AppBanner(
    id: 'smart-plan-food-track',
    title: 'Mama Takibi',
    assetPath: 'assets/images/smart_plan_food_track.jpg',
    placement: 'smart_plan_food_track',
  ),
  AppBanner(
    id: 'smart-plan-order-track-strip',
    title: 'Siparişten Otomatik Takip',
    assetPath: 'assets/images/smart_plan_order_track_strip.jpg',
    placement: 'smart_plan_order_track_strip',
  ),
  AppBanner(
    id: 'smart-plan-manual-track-strip',
    title: 'Manuel Takip',
    assetPath: 'assets/images/smart_plan_manual_track_strip.jpg',
    placement: 'smart_plan_manual_track_strip',
  ),
  AppBanner(
    id: 'easy-order',
    title: 'Kolay Sipariş',
    assetPath: 'assets/images/kolay_siparis_banner.png',
    placement: 'easy_order',
  ),
  AppBanner(
    id: 'hangi-mama',
    title: 'Tedarik Ediyoruz',
    assetPath: 'assets/images/hangi_mama_banner.jpg',
    placement: 'hangi_mama',
  ),
  AppBanner(
    id: 'hediye-sec',
    title: 'Ne Severiz',
    assetPath: 'assets/images/hediye_sec_banner.jpg',
    placement: 'gift_select',
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
    id: 'campaign-discount',
    title: 'Abonelere %5 İndirim',
    assetPath: 'assets/images/kampanya_yuzde5_indirim.jpg',
    placement: 'campaign_discount',
    order: 0,
  ),
  AppBanner(
    id: 'campaign-double',
    title: 'İlk Siparişe 2 Kat Ödül',
    assetPath: 'assets/images/kampanya_ilk_siparis_2kat.jpg',
    placement: 'campaign_double',
    order: 1,
  ),
  AppBanner(
    id: 'campaign-donate',
    title: 'Sokaktaki Dostlar',
    assetPath: 'assets/images/kampanya_sokak_bagis.jpg',
    placement: 'campaign_donate',
    order: 2,
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
    id: 'emergency-notice',
    title: 'Acil Destek Uyarı',
    assetPath: 'assets/images/acil_destek_uyari_banner.jpg',
    placement: 'emergency_notice',
    order: 1,
  ),
  AppBanner(
    id: 'medicine',
    title: 'İlaç ve Tedavi',
    assetPath: 'assets/images/ilac_tedavi_banner.jpg',
    placement: 'medicine',
  ),
  AppBanner(
    id: 'special-foods',
    title: 'Özel Sağlık Mamaları',
    assetPath: 'assets/images/ozel_saglik_mamalari_banner.jpg',
    placement: 'special_foods',
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
      } else {
        final batch = FirebaseFirestore.instance.batch();
        var hasWrites = false;
        for (final banner in defaultBanners) {
          if (deletedIds.contains(banner.id)) continue;
          if (existingIds.contains(banner.id)) continue;
          batch.set(_col.doc(banner.id), banner.toMap());
          hasWrites = true;
        }
        for (final doc in snap.docs.where(_isBannerDoc)) {
          final placement =
              (doc.data()[BannerFields.placement] as String?) ?? '';
          if (placement != 'smart_plan') continue;
          batch.set(doc.reference, {
            BannerFields.active: false,
            BannerFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          hasWrites = true;
        }
        if (hasWrites) await batch.commit();
      }
      await pruneStaleStripBanners();
      await retireRemovedFoodTrackBanners();
      await restoreHomeDostEkleIfMeetPetLeaked();
      await refreshMedicineBannerAsset();
    } catch (_) {
      // Mobil istemci yazma yetkisine sahip olmayabilir.
    }
  }

  /// Eski ilaç bannerını, özel görsel yüklenmediyse yeni görselle değiştirir.
  Future<void> refreshMedicineBannerAsset() async {
    const nextAsset = 'assets/images/ilac_tedavi_banner.jpg';
    final doc = await _col.doc('medicine').get();
    if (!doc.exists) return;
    final data = doc.data() ?? {};
    final imageUrl = (data[BannerFields.imageUrl] as String?)?.trim() ?? '';
    if (imageUrl.isNotEmpty) return;
    final asset = (data[BannerFields.assetPath] as String?)?.trim() ?? '';
    if (asset == nextAsset) return;
    await doc.reference.set({
      BannerFields.title: 'İlaç ve Tedavi',
      BannerFields.assetPath: nextAsset,
      BannerFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
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

  /// Kaldırılan mama tüketim kartı ve iç görsellerini kayıttan siler.
  Future<void> retireRemovedFoodTrackBanners() async {
    const retiredPlacements = {
      'smart_plan_food_track_card',
      'smart_plan_food_track_inner_auto',
      'smart_plan_food_track_inner_manual',
    };
    try {
      final snap = await _col.get(const GetOptions(source: Source.server));
      for (final doc in snap.docs.where(_isBannerDoc)) {
        final banner = AppBanner.fromDoc(doc);
        if (!retiredPlacements.contains(banner.placement)) continue;
        await deleteBanner(banner);
      }
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

  Future<void> moveBanner({
    required List<AppBanner> catalog,
    required String id,
    required String placement,
    String? beforeId,
  }) async {
    final dest = placement.trim();
    final bannerId = id.trim();
    if (bannerId.isEmpty || dest.isEmpty) return;
    if (!BannerPlacement.values.any((item) => item.id == dest)) return;

    AppBanner? moved;
    for (final item in catalog) {
      if (item.id == bannerId) {
        moved = item;
        break;
      }
    }
    if (moved == null) return;
    if (moved.placement == dest && beforeId == bannerId) return;
    if (moved.placement == dest && beforeId == null) {
      final ordered = catalog
          .where((item) => item.placement == dest)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      if (ordered.isNotEmpty && ordered.last.id == bannerId) return;
    }

    final source = moved.placement;
    final destItems = catalog
        .where((item) => item.placement == dest && item.id != bannerId)
        .toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    var insertAt = destItems.length;
    if (beforeId != null && beforeId != bannerId) {
      final index = destItems.indexWhere((item) => item.id == beforeId);
      if (index >= 0) insertAt = index;
    }
    destItems.insert(insertAt, moved);

    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < destItems.length; i++) {
      batch.set(_col.doc(destItems[i].id), {
        BannerFields.placement: dest,
        BannerFields.order: i,
        BannerFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    if (source != dest) {
      final sourceItems = catalog
          .where((item) => item.placement == source && item.id != bannerId)
          .toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      for (var i = 0; i < sourceItems.length; i++) {
        batch.set(_col.doc(sourceItems[i].id), {
          BannerFields.order: i,
          BannerFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    }
    await batch.commit();
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
    return _activeFrom(snap, placement: placement);
  }

  Future<List<AppBanner>> fetchActiveFromCache({String? placement}) async {
    final snap = await _col.get(const GetOptions(source: Source.cache));
    return _activeFrom(snap, placement: placement);
  }

  List<AppBanner> _activeFrom(
    QuerySnapshot<Map<String, dynamic>> snap, {
    String? placement,
  }) {
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
