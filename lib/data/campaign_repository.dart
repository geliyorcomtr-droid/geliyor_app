import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

class AppCampaign {
  const AppCampaign({
    required this.id,
    required this.title,
    required this.subtitle,
    this.imageUrl = '',
    this.assetPath = '',
    this.mainCategory = 'cat',
    this.subCategory = '',
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final String assetPath;
  final String mainCategory;
  final String subCategory;
  final int order;
  final bool active;

  factory AppCampaign.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    return AppCampaign(
      id: doc.id,
      title: (data[CampaignFields.title] as String?) ?? '',
      subtitle: (data[CampaignFields.subtitle] as String?) ?? '',
      imageUrl: (data[CampaignFields.imageUrl] as String?) ?? '',
      assetPath: (data[CampaignFields.assetPath] as String?) ?? '',
      mainCategory: (data[CampaignFields.mainCategory] as String?) ?? 'cat',
      subCategory: (data[CampaignFields.subCategory] as String?) ?? '',
      order: (data[CampaignFields.order] as num?)?.toInt() ?? 0,
      active: data[CampaignFields.active] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    CampaignFields.title: title.trim(),
    CampaignFields.subtitle: subtitle.trim(),
    CampaignFields.imageUrl: imageUrl.trim(),
    CampaignFields.assetPath: assetPath.trim(),
    CampaignFields.mainCategory: mainCategory.trim(),
    CampaignFields.subCategory: subCategory.trim(),
    CampaignFields.order: order,
    CampaignFields.active: active,
    CampaignFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppCampaign copyWith({
    String? title,
    String? subtitle,
    String? imageUrl,
    String? assetPath,
    String? mainCategory,
    String? subCategory,
    int? order,
    bool? active,
  }) {
    return AppCampaign(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      assetPath: assetPath ?? this.assetPath,
      mainCategory: mainCategory ?? this.mainCategory,
      subCategory: subCategory ?? this.subCategory,
      order: order ?? this.order,
      active: active ?? this.active,
    );
  }
}

const defaultCampaigns = <AppCampaign>[
  AppCampaign(
    id: 'ayin-firsatlari',
    title: 'Ayın Fırsatları',
    subtitle: 'Ay boyunca geçerli indirimli ürünler',
    order: 0,
  ),
  AppCampaign(
    id: 'gunun-firsatlari',
    title: 'Günün Fırsatları',
    subtitle: 'Bugün geçerli sınırlı süreli fırsatlar',
    order: 1,
  ),
  AppCampaign(
    id: 'kedi-kampanyalari',
    title: 'Kedi Kampanyaları',
    subtitle: 'Kedi ürünlerinde özel indirimler',
    assetPath: 'assets/images/urunler_kedi.png',
    mainCategory: 'cat',
    order: 2,
  ),
  AppCampaign(
    id: 'kopek-kampanyalari',
    title: 'Köpek Kampanyaları',
    subtitle: 'Köpek ürünlerinde özel indirimler',
    assetPath: 'assets/images/urunler_kopek.png',
    mainCategory: 'dog',
    order: 3,
  ),
  AppCampaign(
    id: 'indirimli-mamalar',
    title: 'İndirimli Mamalar',
    subtitle: 'Seçili mamalarda avantajlı fiyatlar',
    assetPath: 'assets/images/petmarket_mama.png',
    subCategory: 'Mama',
    order: 4,
  ),
  AppCampaign(
    id: 'sepete-ozel',
    title: 'Sepete Özel Fırsatlar',
    subtitle: 'Ekstra indirim ve hediye kampanyaları',
    assetPath: 'assets/images/cok_satan_urunler.png',
    order: 5,
  ),
];

class CampaignRepository {
  CampaignRepository._();
  static final CampaignRepository instance = CampaignRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(FirestoreCollections.campaigns);

  Future<void> ensureDefaults() async {
    try {
      final existing = await _col.limit(1).get();
      if (existing.docs.isNotEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final campaign in defaultCampaigns) {
        batch.set(_col.doc(campaign.id), campaign.toMap());
      }
      await batch.commit();
    } catch (_) {
      // İstemcide yazma yetkisi olmayabilir.
    }
  }

  Stream<List<AppCampaign>> watchAll() {
    return _col.snapshots().map((snap) {
      final list = snap.docs.map(AppCampaign.fromDoc).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }
}
