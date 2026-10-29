import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/health_product_groups.dart';
import 'package:geliyor_app/data/product_advantage_category.dart';
import 'package:geliyor_app/data/product_advantage_guides.dart';

class AppProductAdvantage {
  const AppProductAdvantage({
    required this.id,
    required this.name,
    this.fullName = '',
    this.description = '',
    this.value = '',
    this.isStat = false,
    this.imageUrl = '',
    this.detailImageUrl = '',
    this.assetPath = '',
    this.categoryId = '',
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String name;
  /// İkona tıklanınca açılan tam başlık. Boşsa `name` kullanılır.
  final String fullName;
  final String description;
  /// İstatistik kartında üstte gösterilir (ör. "% 41"). Ürün bazında ezilebilir.
  final String value;
  /// true ise ikon yerine değer + etiket gösterilir.
  final bool isStat;
  final String imageUrl;
  /// İkona tıklanınca açılan görsel; ikondan bağımsızdır.
  final String detailImageUrl;
  final String assetPath;
  final String categoryId;
  final int order;
  final bool active;

  String get overlayTitle {
    final full = fullName.trim();
    return full.isEmpty ? name.trim() : full;
  }

  String get resolvedCategoryId {
    final stored = ProductAdvantageCategory.normalize(categoryId);
    if (stored != ProductAdvantageCategory.diger.id ||
        categoryId.trim() == ProductAdvantageCategory.diger.id) {
      return stored;
    }
    return ProductAdvantageCategory.infer(id, name);
  }

  factory AppProductAdvantage.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AppProductAdvantage(
      id: doc.id,
      name: (data[ProductAdvantageFields.name] as String?) ?? doc.id,
      fullName: (data[ProductAdvantageFields.fullName] as String?) ?? '',
      description: (data[ProductAdvantageFields.description] as String?) ?? '',
      value: (data[ProductAdvantageFields.value] as String?) ?? '',
      isStat: data[ProductAdvantageFields.isStat] as bool? ?? false,
      imageUrl: (data[ProductAdvantageFields.imageUrl] as String?) ?? '',
      detailImageUrl:
          (data[ProductAdvantageFields.detailImageUrl] as String?) ?? '',
      assetPath: (data[ProductAdvantageFields.assetPath] as String?) ?? '',
      categoryId: (data[ProductAdvantageFields.categoryId] as String?) ?? '',
      order: (data[ProductAdvantageFields.order] as num?)?.toInt() ?? 0,
      active: data[ProductAdvantageFields.active] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    ProductAdvantageFields.name: name.trim(),
    ProductAdvantageFields.fullName: fullName.trim(),
    ProductAdvantageFields.description: description.trim(),
    ProductAdvantageFields.value: value.trim(),
    ProductAdvantageFields.isStat: isStat,
    ProductAdvantageFields.imageUrl: imageUrl.trim(),
    ProductAdvantageFields.detailImageUrl: detailImageUrl.trim(),
    ProductAdvantageFields.assetPath: assetPath.trim(),
    ProductAdvantageFields.categoryId: ProductAdvantageCategory.normalize(
      categoryId.trim().isEmpty ? resolvedCategoryId : categoryId,
    ),
    ProductAdvantageFields.order: order,
    ProductAdvantageFields.active: active,
    ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppProductAdvantage copyWith({
    String? name,
    String? fullName,
    String? description,
    String? value,
    bool? isStat,
    String? imageUrl,
    String? detailImageUrl,
    String? assetPath,
    String? categoryId,
    int? order,
    bool? active,
  }) {
    return AppProductAdvantage(
      id: id,
      name: name ?? this.name,
      fullName: fullName ?? this.fullName,
      description: description ?? this.description,
      value: value ?? this.value,
      isStat: isStat ?? this.isStat,
      imageUrl: imageUrl ?? this.imageUrl,
      detailImageUrl: detailImageUrl ?? this.detailImageUrl,
      assetPath: assetPath ?? this.assetPath,
      categoryId: categoryId ?? this.categoryId,
      order: order ?? this.order,
      active: active ?? this.active,
    );
  }
}

AppProductAdvantage _defaultAdvantage(
  String id,
  String name,
  int order, {
  String description = '',
  String value = '',
  bool isStat = false,
  String? assetPath,
  String? categoryId,
}) {
  return AppProductAdvantage(
    id: id,
    name: name,
    description: description,
    value: value,
    isStat: isStat,
    assetPath: assetPath ?? 'assets/images/app_ikonlar/$id.png',
    categoryId:
        categoryId ?? ProductAdvantageCategory.infer(id, name),
    order: order,
  );
}

final defaultProductAdvantages = <AppProductAdvantage>[
  _defaultAdvantage(
    'kisir_kedi',
    'Kısır Kediler İçin',
    0,
    description:
        'Kısırlaştırılmış kedilerin yavaşlayan metabolizmasına uygun, kilo kontrolüne yardımcı formüldür.',
  ),
  _defaultAdvantage(
    'bobrek',
    'Böbrek Sağlığını Destekler',
    1,
    description:
        'Böbrek yükünü azaltmaya yardımcı dengeli mineral içeriğiyle günlük beslenmeyi destekler.',
  ),
  _defaultAdvantage(
    'sindirim',
    'Sindirim Sağlığını Destekler',
    2,
    description:
        'Sindirimi kolay protein ve lif dengesiyle mide-bağırsak konforuna katkı sağlar.',
  ),
  _defaultAdvantage(
    'somon',
    'Somonlu Formül',
    3,
    description:
        'Somon proteini ve omega yağ asitleriyle lezzet ve tüy sağlığını birlikte destekler.',
  ),
  _defaultAdvantage(
    'tuy_deri',
    'Tüy ve Deri Sağlığı',
    4,
    description:
        'Tüy kalitesini ve deri bariyerini destekleyen yağ asitleri ve besin ögeleri içerir.',
  ),
  _defaultAdvantage(
    'kilo_kontrol',
    'Kilo Kontrolü',
    5,
    description:
        'Düşük kalori dengesiyle ideal kilonun korunmasına yardımcı olur, doyurucu formüldür.',
  ),
  _defaultAdvantage(
    'bagisiklik',
    'Bağışıklık Desteği',
    6,
    description:
        'Antioksidan ve vitamin desteğiyle bağışıklık sisteminin güçlü kalmasına katkı sağlar.',
  ),
  _defaultAdvantage(
    'dogal_icerik',
    'Doğal İçerik',
    7,
    description:
        'Gereksiz katkılardan arındırılmış, doğal kaynaklı içeriklerle hazırlanmış formüldür.',
  ),
  _defaultAdvantage(
    'kalp',
    'Kalp Sağlığı',
    8,
    description:
        'Kalp ve dolaşımı destekleyen besin ögeleriyle uzun vadeli sağlıklı beslenmeye yardımcı olur.',
  ),
  _defaultAdvantage(
    'dis',
    'Diş Sağlığı',
    9,
    description:
        'Çiğneme dokusu ve diş dostu formülle plak oluşumunun azaltılmasına katkı sağlar.',
  ),
  _defaultAdvantage(
    'tahilsiz',
    'Tahılsız Formül',
    10,
    description:
        'Tahıl içermez; hassas sindirimli evcil dostlar için sade ve yüksek proteinli bir seçenektir.',
  ),
  _defaultAdvantage(
    'idrar',
    'İdrar Yolu Sağlığı',
    11,
    description:
        'İdrar yolu sağlığını destekleyen mineral dengesiyle idrar kristali riskini azaltmaya yardımcı olur.',
    assetPath: '',
  ),
  _defaultAdvantage(
    'eklem',
    'Eklem Desteği',
    12,
    description:
        'Eklem ve hareket kabiliyetini destekleyen besin ögeleriyle günlük aktiviteye katkı sağlar.',
  ),
  _defaultAdvantage(
    'diyabet',
    'Diyabet Desteği',
    13,
    description:
        'Kan şekeri dengesine yardımcı, kontrollü karbonhidratlı özel beslenme formülüdür.',
  ),
  _defaultAdvantage(
    'karaciger',
    'Karaciğer Desteği',
    14,
    description:
        'Karaciğer fonksiyonlarını destekleyen dengeli protein ve besin ögesi içeriğine sahiptir.',
  ),
  _defaultAdvantage(
    'hypoallergenic',
    'Hipoalerjenik',
    15,
    description:
        'Hassas bünyeler için seçilmiş protein kaynağıyla alerji riskini azaltmaya yardımcı olur.',
  ),
  _defaultAdvantage(
    'parazit',
    'Parazit Koruması',
    16,
    description:
        'İç ve dış parazitlere karşı koruma programını tamamlayan ürün grubudur.',
  ),
  _defaultAdvantage(
    'normal_kedi',
    'Yetişkin Kedi İçin',
    17,
    description:
        'Yetişkin kedilerin günlük enerji ve besin ihtiyacına göre dengelenmiş tam formüldür.',
  ),
  _defaultAdvantage(
    'kopek',
    'Köpekler İçin',
    18,
    description:
        'Köpeklerin yaş ve aktivitesine uygun protein-enerji dengesiyle günlük beslenmeyi karşılar.',
  ),
  _defaultAdvantage(
    'tavuk',
    'Tavuklu Formül',
    19,
    description:
        'Yüksek sindirilebilir tavuk proteiniyle lezzetli ve besleyici bir öğün sunar.',
  ),
  _defaultAdvantage(
    'kuzu',
    'Kuzulu Formül',
    20,
    description:
        'Kuzu proteiniyle hassas damaklar ve özel diyet ihtiyaçları için alternatif bir kaynaktır.',
  ),
  _defaultAdvantage(
    'mama_kabi',
    'Mama Kabı',
    21,
    description:
        'Günlük mama ve su ihtiyacı için pratik, hijyenik beslenme kabı çözümüdür.',
  ),
  _defaultAdvantage(
    'asi_takvimi',
    'Aşı Takvimi',
    22,
    description:
        'Aşı takvimini takip etmenizi kolaylaştırır; koruyucu sağlık planını kaçırmamanıza yardımcı olur.',
  ),
  _defaultAdvantage(
    'ilac_tedavi',
    'İlaç ve Tedavi',
    23,
    description:
        'Tedavi sürecinde ihtiyaç duyulan ilaç ve bakım ürünlerine hızlı erişim sağlar.',
  ),
  _defaultAdvantage(
    'acil_durum',
    'Acil Durum',
    24,
    description:
        'Ani sağlık durumlarında ilk müdahale ve acil bakım ürünlerini bir arada sunar.',
  ),
  _defaultAdvantage(
    'zehirlenme',
    'Zehirlenme',
    25,
    description:
        'Zehirlenme şüphesinde hızlı yönlendirme ve gerekli bakım ürünlerine ulaşmayı kolaylaştırır.',
  ),
  _defaultAdvantage(
    'yaralanma',
    'Yaralanma',
    26,
    description:
        'Küçük yaralanmalarda ilk bakım ve yara temizliğine yardımcı ürünleri kapsar.',
  ),
  _defaultAdvantage(
    'sokak',
    'Sokak Dostları',
    27,
    description:
        'Sokak hayvanlarının temel beslenme ve bakım ihtiyacına uygun, ekonomik seçenekler sunar.',
  ),
  _defaultAdvantage(
    'hindi',
    'Hindili Formül',
    28,
    description:
        'Hindi proteiniyle hafif, sindirimi kolay ve lezzetli bir alternatif formüldür.',
  ),
  _defaultAdvantage(
    'inek',
    'Sığır Etli Formül',
    29,
    description:
        'Sığır eti proteiniyle yüksek palatabilite ve doyurucu bir öğün dengesi sağlar.',
  ),
  _defaultAdvantage(
    'ordek',
    'Ördekli Formül',
    30,
    description:
        'Ördek proteiniyle tahılsız veya hassas diyetlerde alternatif bir protein kaynağıdır.',
  ),
  _defaultAdvantage(
    'tavsan',
    'Tavşanlı Formül',
    31,
    description:
        'Tavşan proteiniyle alerjiye yatkın evcil dostlar için yeni bir protein seçeneği sunar.',
  ),
  _defaultAdvantage(
    'ton_baligi',
    'Ton Balıklı Formül',
    32,
    description:
        'Ton balığı lezzeti ve omega desteğiyle iştahı açık tutan, protein zengini formüldür.',
  ),
  _defaultAdvantage(
    'kisir_kopek',
    'Kısır Köpekler İçin',
    33,
    description:
        'Kısırlaştırılmış köpeklerin metabolizmasına uygun, kilo kontrolüne yardımcı formüldür.',
  ),
  _defaultAdvantage(
    'yavru_kopek',
    'Yavru Köpekler İçin',
    34,
    description:
        'Büyüme dönemindeki yavru köpeklerin kemik, kas ve bağışıklık ihtiyacını destekler.',
  ),
  _defaultAdvantage(
    'tuy_yumusak',
    'Yumuşak ve Parlak Tüyler',
    35,
    description:
        'Tüy yumuşaklığı ve parlaklığını destekleyen yağ asitleri ve vitaminler içerir.',
  ),
  _defaultAdvantage(
    'ilac',
    'İlaç Desteği',
    36,
    description:
        'Veteriner önerili takviye ve ilaç ürünleriyle tedavi sürecini tamamlamaya yardımcı olur.',
  ),
  _defaultAdvantage(
    'favori',
    'Favori Ürün',
    37,
    description:
        'Kullanıcıların en çok beğendiği ve tekrar tercih ettiği ürünler arasındadır.',
  ),
  _defaultAdvantage(
    'akilli_oneri',
    'Akıllı Öneri',
    38,
    description:
        'Petinizin yaşı, kilosu ve ihtiyaçlarına göre önerilen akıllı seçimdir.',
  ),
  _defaultAdvantage(
    'yapayzeka',
    'Yapay Zekâ Önerisi',
    39,
    description:
        'Yapay zekâ analiziyle petinizin profiline en uygun ürün önerisini sunar.',
  ),
  _defaultAdvantage(
    'tl',
    'Fiyat Avantajı',
    40,
    description:
        'Kaliteden ödün vermeden uygun fiyatlı, bütçe dostu bir alışveriş seçeneğidir.',
  ),
  _defaultAdvantage(
    'protein',
    'Protein Değeri',
    41,
    isStat: true,
    value: '%42',
    description:
        'Kas gelişimi ve tokluk için yüksek kaliteli protein oranı sunar.',
  ),
  _defaultAdvantage(
    'hayvansal-protein',
    'Hayvansal Protein',
    42,
    isStat: true,
    value: '%70',
    assetPath: 'assets/images/app_ikonlar/protein.png',
    description:
        'Formüldeki hayvansal protein oranını gösterir; et kaynaklı protein payıdır.',
  ),
  _defaultAdvantage(
    'yavru_kedi',
    'Yavru Kedi İçin',
    43,
    description:
        'Büyüme dönemindeki yavru kedilerin enerji, bağışıklık ve gelişim ihtiyacını destekler.',
    assetPath: 'assets/images/app_ikonlar/normal_kedi.png',
  ),
  _defaultAdvantage(
    'yetiskin_kopek',
    'Yetişkin Köpek İçin',
    44,
    description:
        'Yetişkin köpeklerin günlük protein ve enerji ihtiyacına göre dengelenmiş tam formüldür.',
    assetPath: 'assets/images/app_ikonlar/kopek.png',
  ),
  _defaultAdvantage(
    'kuru_mama',
    'Kuru Mama',
    45,
    description:
        'Kuru mama formülü; pratik saklama ve diş sağlığına yardımcı çiğneme dokusu sunar.',
    assetPath: 'assets/images/app_ikonlar/mama_kabi.png',
  ),
  _defaultAdvantage(
    'yas_mama',
    'Yaş Mama',
    46,
    description:
        'Yüksek nemli yaş mama; iştahı açık tutar ve sıvı alımına katkı sağlar.',
    assetPath: 'assets/images/app_ikonlar/mama_kabi.png',
  ),
  _defaultAdvantage(
    'konserve',
    'Konserve',
    47,
    description:
        'Konserve mama; lezzet ve nem dengesiyle öğünü tamamlayan pratik bir seçenektir.',
    assetPath: 'assets/images/app_ikonlar/mama_kabi.png',
  ),
  _defaultAdvantage(
    'malt',
    'Malt',
    48,
    description:
        'Tüy yumağı kontrolüne yardımcı malt macunu veya malt destekli formüldür.',
    assetPath: HealthProductGroup.malt.iconPath,
  ),
  _defaultAdvantage(
    'vitamin',
    'Vitamin',
    49,
    description:
        'Günlük vitamin desteğiyle bağışıklık ve genel sağlığın tamamlanmasına katkı sağlar.',
    assetPath: HealthProductGroup.vitamin.iconPath,
  ),
  _defaultAdvantage(
    'takviye',
    'Takviye',
    50,
    description:
        'Özel ihtiyaçlar için vitamin, mineral veya fonksiyonel takviye ürünüdür.',
    assetPath: HealthProductGroup.supplement.iconPath,
  ),
  _defaultAdvantage(
    'dha',
    'DHA',
    51,
    description:
        'DHA desteğiyle beyin, görme ve gelişim dönemindeki beslenmeyi güçlendirir.',
    assetPath: 'assets/images/app_ikonlar/protein.png',
  ),
  _defaultAdvantage(
    'l_karnitin',
    'L-Karnitin',
    52,
    description:
        'L-karnitin ile yağ metabolizması ve kilo kontrolüne yardımcı formüldür.',
    assetPath: 'assets/images/app_ikonlar/protein.png',
  ),
];

class ProductAdvantageRepository {
  ProductAdvantageRepository._();

  static final instance = ProductAdvantageRepository._();

  /// Ürün görselinin sağındaki sabit slot sayısı.
  static const int heroSlotCount = 6;

  /// Bir ürüne seçilebilecek özellik üst sınırı (sağ ikon sütunu).
  static const int maxPerProduct = 6;

  /// Tüm ikonlara tıklanınca açılan ortak kalıp görsel belgesi.
  static const overlayTemplateId = '__overlay_template';
  static const hangiMamaConfigId = '__hangi_mama';
  static const deletedIdsDocId = '__deleted';
  static const categoriesDocId = '__categories';

  static bool isSystemDocId(String id) =>
      id == overlayTemplateId ||
      id == hangiMamaConfigId ||
      id == deletedIdsDocId ||
      id == categoriesDocId;

  static List<AppProductAdvantage> orderedForProduct({
    required List<String>? selectedIds,
    required List<AppProductAdvantage> catalog,
  }) {
    if (selectedIds == null) {
      return catalog.where((item) => !isSystemDocId(item.id)).toList();
    }
    final byCatalogId = {for (final item in catalog) item.id: item};
    final items = <AppProductAdvantage>[];
    for (final id in selectedIds) {
      if (isSystemDocId(id)) continue;
      final key = id.trim();
      final item = byCatalogId[key];
      if (item != null) {
        _addHealthOnce(items, item);
        continue;
      }
      final group = HealthProductGroup.forAdvantageId(key);
      if (group == null) continue;
      final standIn = liveForHealthGroup(group, catalog);
      if (standIn != null) _addHealthOnce(items, standIn);
    }
    return items;
  }

  static void _addHealthOnce(
    List<AppProductAdvantage> items,
    AppProductAdvantage item,
  ) {
    final group = HealthProductGroup.forAdvantage(item.id, item.name);
    if (group == null) {
      items.add(item);
      return;
    }
    final index = items.indexWhere(
      (current) =>
          HealthProductGroup.forAdvantage(current.id, current.name) == group,
    );
    if (index < 0) {
      items.add(item);
      return;
    }
    final current = items[index];
    if (current.imageUrl.trim().isEmpty && item.imageUrl.trim().isNotEmpty) {
      items[index] = item;
    }
  }

  /// Seçilmiş hayvansal proteini, değeri varsa sağ sütunun ilk 6 slotuna taşır.
  /// Katalogda yazıyor diye seçilmemiş ürüne eklemez.
  static List<AppProductAdvantage> pinAnimalProtein({
    required List<AppProductAdvantage> items,
    required String animalProteinValue,
  }) {
    if (animalProteinValue.trim().isEmpty) return items;
    final next = List<AppProductAdvantage>.from(items);
    final index = next.indexWhere(isAnimalProteinAdvantage);
    if (index < 0 || index < heroSlotCount) return next;
    final item = next.removeAt(index);
    next.insert(heroSlotCount - 1, item);
    return next;
  }

  static List<AppProductAdvantage> forProductDetail({
    required List<String>? selectedIds,
    required List<AppProductAdvantage> catalog,
    String animalProteinValue = '',
  }) {
    return pinAnimalProtein(
      items: orderedForProduct(selectedIds: selectedIds, catalog: catalog),
      animalProteinValue: animalProteinValue,
    );
  }

  static String foldSearch(String raw) {
    return raw
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim()
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static const _genericSearchQueries = {
    'saglik',
    'health',
    'kedi',
    'kopek',
    'kus',
    'kemirgen',
    'mama',
    'urun',
    'pet',
    'formul',
    'destek',
    'icin',
    'urunler',
  };

  static const _searchAliases = <String, List<String>>{
    'kisir': ['kisir_kedi', 'kisir_kopek'],
    'kisirlastirma': ['kisir_kedi', 'kisir_kopek'],
    'kisirlastirilmis': ['kisir_kedi', 'kisir_kopek'],
    'steril': ['kisir_kedi', 'kisir_kopek'],
    'indoor': ['kisir_kedi'],
    'ic mekan': ['kisir_kedi'],
    'kilo': ['kilo_kontrol'],
    'kilo kontrol': ['kilo_kontrol'],
    'kilo kontrolu': ['kilo_kontrol'],
    'diyet': ['kilo_kontrol'],
    'obez': ['kilo_kontrol'],
    'obezite': ['kilo_kontrol'],
    'bobrek': ['bobrek'],
    'renal': ['bobrek'],
    'sindirim': ['sindirim'],
    'hassas': ['sindirim', 'hypoallergenic'],
    'sensitive': ['sindirim'],
    'digest': ['sindirim'],
    'deri': ['tuy_deri', 'tuy_yumusak'],
    'tuy': ['tuy_deri', 'tuy_yumusak'],
    'deri tuy': ['tuy_deri'],
    'skin': ['tuy_deri'],
    'coat': ['tuy_deri'],
    'omega': ['tuy_deri'],
    'omega 3': ['tuy_deri'],
    'dogal': ['dogal_icerik'],
    'dogal icerik': ['dogal_icerik'],
    'natural': ['dogal_icerik'],
    'somon': ['somon'],
    'salmon': ['somon'],
    'protein': ['protein'],
    'hayvansal protein': ['hayvansal-protein'],
    'hayvansal': ['hayvansal-protein'],
    'tahilsiz': ['tahilsiz'],
    'idrar': ['idrar'],
    'urinary': ['idrar'],
    'sistit': ['idrar'],
    'eklem': ['eklem'],
    'kalp': ['kalp'],
    'diyabet': ['diyabet'],
    'seker': ['diyabet'],
    'karaciger': ['karaciger'],
    'alerji': ['hypoallergenic'],
    'hipoalerjenik': ['hypoallergenic'],
    'hipo': ['hypoallergenic'],
    'mide': ['sindirim'],
    'bobre': ['bobrek'],
    'bagisiklik': ['bagisiklik'],
    'dis': ['dis'],
    'tavuk': ['tavuk'],
    'kuzu': ['kuzu'],
    'hindi': ['hindi'],
    'ordek': ['ordek'],
    'tavsan': ['tavsan'],
    'ton': ['ton_baligi'],
    'ton baligi': ['ton_baligi'],
    'sigir': ['inek'],
    'parazit': ['parazit'],
    'asi': ['asi_takvimi'],
    'yavru kopek': ['yavru_kopek'],
  };

  static List<AppProductAdvantage> _mergedCatalog(
    List<AppProductAdvantage>? catalog,
  ) {
    if (catalog == null || catalog.isEmpty) return defaultProductAdvantages;
    final ids = {for (final item in catalog) item.id};
    return [
      ...catalog,
      for (final item in defaultProductAdvantages)
        if (!ids.contains(item.id)) item,
    ];
  }

  static AppProductAdvantage? byId(
    String id, {
    List<AppProductAdvantage>? catalog,
  }) {
    final needle = id.trim();
    if (needle.isEmpty) return null;
    for (final item in _mergedCatalog(catalog)) {
      if (item.id == needle) return item;
    }
    return null;
  }

  /// Arama veya filtre metninin karşılık geldiği özellik kimlikleri.
  static Set<String> matchingIds(
    String query, {
    List<AppProductAdvantage>? catalog,
  }) {
    final q = foldSearch(query);
    if (q.isEmpty || _genericSearchQueries.contains(q)) return {};

    final items = _mergedCatalog(catalog);
    final ids = <String>{};

    final aliasIds = _searchAliases[q];
    if (aliasIds != null) ids.addAll(aliasIds);

    for (final item in items) {
      final name = foldSearch(item.name);
      final full = foldSearch(item.fullName);
      final idText = foldSearch(item.id.replaceAll('_', ' '));
      if (name == q ||
          full == q ||
          item.id == query.trim() ||
          idText == q) {
        ids.add(item.id);
        continue;
      }
      if (q.length >= 4 &&
          (name.contains(q) || full.contains(q) || idText.contains(q))) {
        ids.add(item.id);
      }
    }
    return ids;
  }

  /// Ekrandaki ihtiyaç/sağlık etiketinin karşılık geldiği ürün özellikleri.
  static const tagAdvantageIds = <String, List<String>>{
    'diyabet': ['diyabet'],
    'bobrek': ['bobrek'],
    'bobre': ['bobrek'],
    'tuy': ['tuy_deri', 'tuy_yumusak'],
    'eklem': ['eklem'],
    'sindirim': ['sindirim'],
    'mide': ['sindirim'],
    'bagisiklik': ['bagisiklik'],
    'idrar': ['idrar'],
    'kalp': ['kalp'],
    'dis': ['dis'],
    'karaciger': ['karaciger'],
    'hipo': ['hypoallergenic'],
    'kilo': ['kilo_kontrol'],
    'kisir': ['kisir_kedi', 'kisir_kopek'],
    'tahilsiz': ['tahilsiz'],
  };

  /// Seçilen etiket için ürünlerde aranacak özellik kimlikleri.
  static Set<String> idsForTag(String tag, {String? title}) {
    final raw = tag.trim();
    if (raw.isEmpty) return {};
    final ids = <String>{
      ...?tagAdvantageIds[raw],
      ...matchingIds(raw),
      if (title != null && title.trim().isNotEmpty) ...matchingIds(title),
    };
    if (ids.isEmpty) ids.add(raw);
    return ids;
  }

  /// Ürün, seçilen etiketlerin özelliklerine sahip mi?
  /// [matchAll] true ise her etiket için en az bir özellik gerekir.
  static bool productMatchesTags({
    required List<String> productAdvantageIds,
    required Iterable<String> tags,
    bool matchAll = true,
    String? title,
  }) {
    final tagList = [
      for (final tag in tags)
        if (tag.trim().isNotEmpty) tag.trim(),
    ];
    if (tagList.isEmpty || productAdvantageIds.isEmpty) return false;

    bool matchesOne(String tag) {
      final ids = idsForTag(tag, title: title);
      return productAdvantageIds.any(ids.contains);
    }

    if (matchAll) return tagList.every(matchesOne);
    return tagList.any(matchesOne);
  }

  static bool productMatchesFeature({
    required List<String> productAdvantageIds,
    required String haystack,
    required String feature,
    List<AppProductAdvantage>? catalog,
  }) {
    final ids = matchingIds(feature, catalog: catalog);
    if (ids.isNotEmpty && productAdvantageIds.any(ids.contains)) {
      return true;
    }
    if (productAdvantageIds.contains(feature.trim())) return true;
    final q = foldSearch(feature);
    if (q.isEmpty || q.length < 3) return false;
    return foldSearch(haystack).contains(q);
  }

  static String guideFor(AppProductAdvantage item) {
    final fromMap = productAdvantageGuides[item.id]?.trim() ?? '';
    if (fromMap.isNotEmpty) return fromMap;
    final summary = explanationFor(item).trim();
    if (summary.isNotEmpty) {
      return '$summary\n\n'
          'Bu etiket, ürünün bu ihtiyaca göre seçildiğini gösterir. '
          'Dostunuzun yaşı, kilosu ve yaşam tarzıyla birlikte değerlendirin. '
          'Özel bir sağlık durumunuz varsa mama değişimini veterinerinizle planlayın.';
    }
    return 'Bu özellik, ürünün belirli bir beslenme veya bakım ihtiyacına göre '
        'etiketlendiğini belirtir. Aynı etikete sahip diğer ürünlere göz atarak '
        'ihtiyacınıza uygun alternatifleri görebilirsiniz.';
  }

  final CollectionReference<Map<String, dynamic>> _collection =
      FirebaseFirestore.instance.collection(
        FirestoreCollections.productAdvantages,
      );

  List<AppProductAdvantage> _cached = const [];
  List<AppProductAdvantage> get cached => _cached;

  List<ProductAdvantageCategory> _cachedCategories =
      ProductAdvantageCategory.values;
  List<ProductAdvantageCategory> get cachedCategories => _cachedCategories;
  StreamSubscription<List<ProductAdvantageCategory>>? _categoryWatch;

  void _ensureCategoryWatch() {
    _categoryWatch ??= watchCategories().listen((_) {});
  }

  Stream<List<AppProductAdvantage>> watchAll({bool activeOnly = false}) {
    _ensureCategoryWatch();
    return _collection.orderBy(ProductAdvantageFields.order).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs
          .map(AppProductAdvantage.fromDoc)
          .where((item) => !isSystemDocId(item.id))
          .toList();
      _cached = List<AppProductAdvantage>.unmodifiable(items);
      return activeOnly ? items.where((item) => item.active).toList() : items;
    });
  }

  Future<List<AppProductAdvantage>> fetchAll({bool activeOnly = false}) async {
    final snapshot = await _collection
        .orderBy(ProductAdvantageFields.order)
        .get();
    final items = snapshot.docs
        .map(AppProductAdvantage.fromDoc)
        .where((item) => !isSystemDocId(item.id))
        .toList();
    return activeOnly ? items.where((item) => item.active).toList() : items;
  }

  Stream<List<ProductAdvantageCategory>> watchCategories() {
    return _categoriesDoc.snapshots().map((snap) {
      final list = categoriesFromData(snap.data());
      _cachedCategories = List<ProductAdvantageCategory>.unmodifiable(list);
      return _cachedCategories;
    });
  }

  Future<List<ProductAdvantageCategory>> fetchCategories() async {
    final snap = await _categoriesDoc.get();
    final list = categoriesFromData(snap.data());
    _cachedCategories = List<ProductAdvantageCategory>.unmodifiable(list);
    return _cachedCategories;
  }

  static List<ProductAdvantageCategory> categoriesFromData(
    Map<String, dynamic>? data,
  ) {
    return ProductAdvantageCategory.mergeCatalog(
      removedIds: _stringIds(data?[ProductAdvantageFields.removedIds]),
      extras: _extrasFrom(data),
      colors: _displayColors(data),
    );
  }

  /// Kayıtlı kategori renkleri. `colorTone` 1 değilse her renk bir ton açıktır.
  static Map<String, String> _displayColors(Map<String, dynamic>? data) {
    final stored = _colorsFrom(data);
    final tone =
        (data?[ProductAdvantageFields.colorTone] as num?)?.toInt() ?? 0;
    if (tone >= 1) return stored;
    return {
      for (final entry in stored.entries)
        entry.key: ProductAdvantageCategory.lightenOneTone(entry.value),
    };
  }

  static List<String> _stringIds(dynamic raw) {
    if (raw is! List) return const [];
    return [
      for (final value in raw)
        if ('$value'.trim().isNotEmpty) '$value'.trim(),
    ];
  }

  static Map<String, String> _colorsFrom(Map<String, dynamic>? data) {
    final raw = data?[ProductAdvantageFields.colors];
    if (raw is! Map) return const {};
    final colors = <String, String>{};
    for (final entry in raw.entries) {
      final id = '${entry.key}'.trim();
      final color = ProductAdvantageCategory.normalizeColor('${entry.value}');
      if (id.isEmpty || color.isEmpty) continue;
      colors[id] = color;
    }
    return colors;
  }

  Future<void> setCategoryColor({
    required String categoryId,
    required String color,
  }) async {
    final id = categoryId.trim();
    final next = ProductAdvantageCategory.normalizeColor(color);
    if (id.isEmpty || isSystemDocId(id)) {
      throw ArgumentError('Bu kategorinin rengi değiştirilemez.');
    }
    if (next.isEmpty) {
      throw ArgumentError('Renk kodu #RRGGBB formatında olmalı.');
    }
    final snap = await _categoriesDoc.get();
    final data = snap.data();
    final tone =
        (data?[ProductAdvantageFields.colorTone] as num?)?.toInt() ?? 0;
    final colors = {..._colorsFrom(data)};
    if (tone < 1) {
      final lightened = {
        for (final entry in colors.entries)
          entry.key: ProductAdvantageCategory.lightenOneTone(entry.value),
      };
      colors
        ..clear()
        ..addAll(lightened);
    }
    colors[id] = next;
    await _categoriesDoc.set({
      ProductAdvantageFields.colors: colors,
      ProductAdvantageFields.colorTone: 1,
      ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// Kayıtlı kategori renklerini bir kez bir ton açar.
  Future<void> _migrateCategoryColorTone() async {
    final snap = await _categoriesDoc.get();
    final data = snap.data();
    final tone =
        (data?[ProductAdvantageFields.colorTone] as num?)?.toInt() ?? 0;
    if (tone >= 1) return;
    final stored = _colorsFrom(data);
    final lightened = {
      for (final entry in stored.entries)
        entry.key: ProductAdvantageCategory.lightenOneTone(entry.value),
    };
    await _categoriesDoc.set({
      if (lightened.isNotEmpty) ProductAdvantageFields.colors: lightened,
      ProductAdvantageFields.colorTone: 1,
      ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static List<ProductAdvantageCategory> _extrasFrom(Map<String, dynamic>? data) {
    final raw = data?[ProductAdvantageFields.extras];
    if (raw is! List) return const [];
    final parsed = <({int order, ProductAdvantageCategory category})>[];
    for (final item in raw) {
      if (item is! Map) continue;
      final id = '${item['id'] ?? ''}'.trim();
      final label = '${item['label'] ?? ''}'.trim();
      if (id.isEmpty || label.isEmpty) continue;
      parsed.add((
        order: (item['order'] as num?)?.toInt() ?? 0,
        category: ProductAdvantageCategory(id: id, label: label),
      ));
    }
    parsed.sort((a, b) => a.order.compareTo(b.order));
    return [for (final item in parsed) item.category];
  }

  Map<String, dynamic> _categoryConfigMap({
    required List<ProductAdvantageCategory> extras,
    required Iterable<String> removedIds,
  }) {
    return {
      ProductAdvantageFields.name: 'Kategoriler',
      ProductAdvantageFields.active: false,
      ProductAdvantageFields.order: -4,
      ProductAdvantageFields.extras: [
        for (var i = 0; i < extras.length; i++)
          {
            'id': extras[i].id,
            'label': extras[i].label,
            'order': i,
          },
      ],
      ProductAdvantageFields.removedIds: [
        for (final id in removedIds)
          if (id.trim().isNotEmpty) id.trim(),
      ],
      ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
    };
  }

  Future<void> addCategory(String label) async {
    final trimmed = label.trim();
    if (trimmed.isEmpty) {
      throw ArgumentError('Kategori adı boş olamaz.');
    }
    final snap = await _categoriesDoc.get();
    final data = snap.data();
    final removed = {..._stringIds(data?[ProductAdvantageFields.removedIds])};
    var extras = [..._extrasFrom(data)];
    final current = categoriesFromData(data);
    final usedIds = {for (final category in current) category.id};

    var base = ProductAdvantageCategory.slugFromLabel(trimmed);
    if (isSystemDocId(base) || base.startsWith('__')) {
      base = 'kategori_$base';
    }
    var id = base;
    var n = 2;
    while (usedIds.contains(id) || isSystemDocId(id)) {
      id = '${base}_$n';
      n += 1;
    }

    if (ProductAdvantageCategory.isBuiltIn(id)) {
      removed.remove(id);
    } else {
      extras.add(ProductAdvantageCategory(id: id, label: trimmed));
    }
    await _categoriesDoc.set(
      _categoryConfigMap(extras: extras, removedIds: removed),
      SetOptions(merge: true),
    );
  }

  Future<void> renameCategory({
    required String categoryId,
    required String label,
  }) async {
    final id = categoryId.trim();
    final trimmed = label.trim();
    if (id.isEmpty || isSystemDocId(id)) {
      throw ArgumentError('Bu kategori adı değiştirilemez.');
    }
    if (trimmed.isEmpty) {
      throw ArgumentError('Kategori adı boş olamaz.');
    }
    final snap = await _categoriesDoc.get();
    final data = snap.data();
    final current = categoriesFromData(data);
    if (!current.any((category) => category.id == id)) {
      throw StateError('Kategori bulunamadı.');
    }
    final extras = [..._extrasFrom(data)];
    final next = ProductAdvantageCategory(id: id, label: trimmed);
    final index = extras.indexWhere((category) => category.id == id);
    if (index >= 0) {
      extras[index] = next;
    } else {
      extras.add(next);
    }
    await _categoriesDoc.set(
      _categoryConfigMap(
        extras: extras,
        removedIds: _stringIds(data?[ProductAdvantageFields.removedIds]),
      ),
      SetOptions(merge: true),
    );
  }

  Future<void> deleteCategory({
    required String categoryId,
    required List<AppProductAdvantage> catalog,
  }) async {
    final id = categoryId.trim();
    if (id.isEmpty || isSystemDocId(id)) return;
    final snap = await _categoriesDoc.get();
    final data = snap.data();
    final current = categoriesFromData(data);
    if (current.length <= 1) {
      throw StateError('En az bir kategori kalmalı.');
    }
    final remaining = [
      for (final category in current)
        if (category.id != id) category,
    ];
    if (remaining.length == current.length) return;
    final fallback = remaining.any(
          (category) => category.id == ProductAdvantageCategory.diger.id,
        )
        ? ProductAdvantageCategory.diger.id
        : remaining.first.id;
    final removed = {..._stringIds(data?[ProductAdvantageFields.removedIds])};
    final extras = [
      for (final category in _extrasFrom(data))
        if (category.id != id) category,
    ];
    if (ProductAdvantageCategory.isBuiltIn(id)) {
      removed.add(id);
    }

    final batch = FirebaseFirestore.instance.batch();
    batch.set(
      _categoriesDoc,
      _categoryConfigMap(extras: extras, removedIds: removed),
      SetOptions(merge: true),
    );
    var order = 0;
    for (final item in catalog) {
      if (isSystemDocId(item.id)) continue;
      final dest =
          item.resolvedCategoryId == id ? fallback : item.resolvedCategoryId;
      batch.set(_collection.doc(item.id), {
        ProductAdvantageFields.categoryId: dest,
        ProductAdvantageFields.order: order,
        ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      order += 1;
    }
    await batch.commit();
  }

  Stream<List<AppProductAdvantage>> watchActiveEnsured() async* {
    await ensureDefaults();
    yield* watchAll(activeOnly: true);
  }

  Future<void> ensureDefaults() async {
    try {
      final snapshot = await _collection.get();
      final existingById = {
        for (final doc in snapshot.docs) doc.id: doc,
      };
      final batch = FirebaseFirestore.instance.batch();
      var hasWrites = false;

      final deletedDoc = existingById[deletedIdsDocId];
      final removedRaw =
          deletedDoc?.data()[ProductAdvantageFields.removedIds];
      final removedIds = <String>{
        for (final value in (removedRaw is List ? removedRaw : const []))
          if ('$value'.trim().isNotEmpty) '$value'.trim(),
      };

      for (final item in defaultProductAdvantages) {
        if (removedIds.contains(item.id)) continue;
        if (!existingById.containsKey(item.id)) {
          batch.set(_collection.doc(item.id), item.toMap());
          hasWrites = true;
        } else if (item.description.isNotEmpty) {
          final data = existingById[item.id]!.data();
          final existingDesc =
              (data[ProductAdvantageFields.description] as String?) ?? '';
          if (existingDesc.trim().isEmpty) {
            batch.set(_collection.doc(item.id), {
              ProductAdvantageFields.description: item.description,
              ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
            }, SetOptions(merge: true));
            hasWrites = true;
          }
        }
      }

      for (final group in HealthProductGroup.values) {
        final doc = existingById[group.advantageId];
        if (doc == null) continue;
        final data = doc.data();
        final imageUrl =
            ((data[ProductAdvantageFields.imageUrl] as String?) ?? '').trim();
        if (imageUrl.isNotEmpty) continue;
        String donorUrl = '';
        for (final other in snapshot.docs) {
          if (other.id == group.advantageId || isSystemDocId(other.id)) {
            continue;
          }
          final otherData = other.data();
          final otherUrl =
              ((otherData[ProductAdvantageFields.imageUrl] as String?) ?? '')
                  .trim();
          if (otherUrl.isEmpty) continue;
          final otherName =
              (otherData[ProductAdvantageFields.name] as String?) ?? other.id;
          if (!group.matchesTitle(otherName) &&
              !group.matchesTitle(other.id.replaceAll('_', ' '))) {
            continue;
          }
          donorUrl = otherUrl;
          break;
        }
        if (donorUrl.isEmpty) continue;
        batch.set(_collection.doc(group.advantageId), {
          ProductAdvantageFields.imageUrl: donorUrl,
          ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        hasWrites = true;
      }

      final proteinDoc = existingById['protein'];
      if (proteinDoc != null) {
        final data = proteinDoc.data();
        final imageUrl =
            ((data[ProductAdvantageFields.imageUrl] as String?) ?? '').trim();
        final assetPath =
            ((data[ProductAdvantageFields.assetPath] as String?) ?? '').trim();
        final updates = <String, dynamic>{};
        if (data[ProductAdvantageFields.isStat] != true) {
          updates[ProductAdvantageFields.isStat] = true;
        }
        if (imageUrl.isEmpty && assetPath.isEmpty) {
          updates[ProductAdvantageFields.assetPath] = proteinIconPath;
        }
        if (updates.isNotEmpty) {
          updates[ProductAdvantageFields.updatedAt] =
              FieldValue.serverTimestamp();
          batch.set(
            _collection.doc('protein'),
            updates,
            SetOptions(merge: true),
          );
          hasWrites = true;
        }
      }

      for (final doc in snapshot.docs) {
        if (isSystemDocId(doc.id)) continue;
        final item = AppProductAdvantage.fromDoc(doc);
        if (!isAnimalProteinAdvantage(item)) continue;
        if (item.isStat) continue;
        batch.set(doc.reference, {
          ProductAdvantageFields.isStat: true,
          ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        hasWrites = true;
      }

      final animalDoc = existingById[animalProteinAdvantageId];
      if (animalDoc != null) {
        final data = animalDoc.data();
        final imageUrl =
            ((data[ProductAdvantageFields.imageUrl] as String?) ?? '').trim();
        final assetPath =
            ((data[ProductAdvantageFields.assetPath] as String?) ?? '').trim();
        final updates = <String, dynamic>{};
        if (data[ProductAdvantageFields.isStat] != true) {
          updates[ProductAdvantageFields.isStat] = true;
        }
        if (imageUrl.isEmpty &&
            (assetPath.isEmpty || assetPath.contains('hayvansal-protein'))) {
          updates[ProductAdvantageFields.assetPath] = proteinIconPath;
        }
        if (updates.isNotEmpty) {
          updates[ProductAdvantageFields.updatedAt] =
              FieldValue.serverTimestamp();
          batch.set(
            _collection.doc(animalProteinAdvantageId),
            updates,
            SetOptions(merge: true),
          );
          hasWrites = true;
        }
      }

      for (final doc in snapshot.docs) {
        if (isSystemDocId(doc.id)) continue;
        final data = doc.data();
        final stored =
            ((data[ProductAdvantageFields.categoryId] as String?) ?? '').trim();
        if (stored == ProductAdvantageCategory.legacyYasamEvresiId) {
          batch.set(doc.reference, {
            ProductAdvantageFields.categoryId: ProductAdvantageCategory.tur.id,
            ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          hasWrites = true;
          continue;
        }
        if (stored.isNotEmpty) continue;
        final item = AppProductAdvantage.fromDoc(doc);
        batch.set(doc.reference, {
          ProductAdvantageFields.categoryId: item.resolvedCategoryId,
          ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        hasWrites = true;
      }

      if (_queueAdrarIconRebind(batch, snapshot.docs)) {
        hasWrites = true;
      }

      if (hasWrites) await batch.commit();
      await _rebindKnowledgeAdrarIcons(snapshot.docs);
      await _migrateCategoryColorTone();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return;
      rethrow;
    }
  }

  /// İstatistik kartı olarak gösterilir (değer alanı ürün formunda açılır).
  static const proteinAdvantageId = 'protein';
  static const animalProteinAdvantageId = 'hayvansal-protein';
  static const proteinIconPath = 'assets/images/app_ikonlar/protein.png';

  static bool isAnimalProteinId(String id) {
    final raw = id.trim().toLowerCase();
    if (raw == animalProteinAdvantageId) return true;
    if (raw.startsWith('$animalProteinAdvantageId-')) return true;
    final folded = foldSearch(id.replaceAll('-', ' ').replaceAll('_', ' '));
    return folded == 'hayvansal protein' ||
        folded.startsWith('hayvansal protein ');
  }

  static bool isAnimalProteinAdvantage(AppProductAdvantage item) {
    if (isAnimalProteinId(item.id)) return true;
    return foldSearch(item.name).contains('hayvansal protein');
  }

  static bool isProteinStat(AppProductAdvantage item) {
    if (isAnimalProteinAdvantage(item)) return false;
    if (item.id == proteinAdvantageId) return true;
    if (item.isStat && foldSearch(item.name).contains('protein')) return true;
    return false;
  }

  static bool displaysAsStat(AppProductAdvantage item) {
    if (isAnimalProteinAdvantage(item) || isProteinStat(item)) return true;
    if (item.isStat) return true;
    if (item.id == proteinAdvantageId || isAnimalProteinId(item.id)) {
      return true;
    }
    return false;
  }

  static String formatProteinDisplay(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    return value.startsWith('%') ? value : '%$value';
  }

  static String displayImageUrl(AppProductAdvantage item) =>
      item.imageUrl.trim();

  /// Ürün kartı, yüklenmiş fayda görseli yoksa aynı malt/vitamin/takviye
  /// kaydındaki görseli kullanır.
  static String sharedDisplayImageUrl(
    AppProductAdvantage item, {
    List<AppProductAdvantage> catalog = const [],
  }) {
    final own = item.imageUrl.trim();
    if (own.isNotEmpty) return own;
    final group = HealthProductGroup.forAdvantage(item.id, item.name);
    if (group == null) return '';
    final source = catalog.isNotEmpty ? catalog : instance.cached;
    for (final other in source) {
      if (other.id == item.id || isSystemDocId(other.id)) continue;
      if (!group.matchesAdvantage(other.id, other.name)) continue;
      final url = other.imageUrl.trim();
      if (url.isNotEmpty) return url;
    }
    return '';
  }

  static String displayDetailImageUrl(AppProductAdvantage item) =>
      item.detailImageUrl.trim();

  static String displayAssetPath(AppProductAdvantage item) {
    final asset = item.assetPath.trim();
    if (asset.isNotEmpty && !_isRetiredAdrarAsset(asset)) return asset;
    if (_isAdrarYoluAdvantage(item)) return '';
    return defaultAssetPathForId(item.id, name: item.name, isStat: item.isStat);
  }

  /// Kayıtlı faydalar arasından bu grubun görselini seçer.
  /// Silinen faydanın eski ikonu varsayılan dosyadan geri gelmez.
  static AppProductAdvantage? liveForHealthGroup(
    HealthProductGroup group,
    List<AppProductAdvantage> catalog,
  ) {
    AppProductAdvantage? canonical;
    AppProductAdvantage? uploaded;
    AppProductAdvantage? named;
    for (final item in catalog) {
      if (isSystemDocId(item.id)) continue;
      if (!group.matchesAdvantage(item.id, item.name)) continue;
      named ??= item;
      if (item.id == group.advantageId) canonical = item;
      if (uploaded == null && item.imageUrl.trim().isNotEmpty) {
        uploaded = item;
      }
    }
    if (canonical != null && canonical.imageUrl.trim().isNotEmpty) {
      return canonical;
    }
    return uploaded ?? canonical ?? named;
  }

  /// İlaç sayfası, pet market ve ürün kartı aynı fayda görselini kullanır.
  static String iconForHealthGroup(
    HealthProductGroup group, {
    List<AppProductAdvantage> catalog = const [],
  }) {
    final chosen = liveForHealthGroup(group, catalog);
    if (chosen == null) return '';
    final url = chosen.imageUrl.trim();
    if (url.isNotEmpty) return url;
    final shared = sharedDisplayImageUrl(chosen, catalog: catalog);
    if (shared.isNotEmpty) return shared;
    return displayAssetPath(chosen);
  }

  static String displayPath(AppProductAdvantage item) {
    if (_usesRetiredAdrarIcon(item)) {
      final uriner = _urinerAdvantage(instance.cached);
      if (uriner != null && uriner.id != item.id) {
        final path = _ownDisplayPath(uriner);
        if (path.isNotEmpty) return path;
      }
    }
    return _ownDisplayPath(item);
  }

  static String _ownDisplayPath(AppProductAdvantage item) {
    final url = displayImageUrl(item);
    if (url.isNotEmpty) return url;
    final asset = item.assetPath.trim();
    if (asset.isNotEmpty && !_isRetiredAdrarAsset(asset)) return asset;
    if (_isAdrarYoluAdvantage(item)) return '';
    return defaultAssetPathForId(item.id, name: item.name, isStat: item.isStat);
  }

  static bool _isRetiredAdrarAsset(String value) {
    final path = value.trim().toLowerCase().replaceAll('\\', '/');
    return path.endsWith('/idrar.png') || path.endsWith('app_ikonlar/idrar.png');
  }

  static bool _isAdrarYoluAdvantage(AppProductAdvantage item) {
    final folded = foldSearch('${item.name} ${item.fullName} ${item.id}');
    return folded.contains('idrar yolu') || folded.contains('adrar yolu');
  }

  static bool _isUrinerAdvantage(AppProductAdvantage item) {
    final folded = foldSearch('${item.name} ${item.fullName} ${item.id}');
    return folded.contains('uriner') || folded.contains('urinary');
  }

  static bool _usesRetiredAdrarIcon(AppProductAdvantage item) {
    if (_isUrinerAdvantage(item)) return false;
    if (_isAdrarYoluAdvantage(item)) return true;
    return _isRetiredAdrarAsset(item.assetPath) ||
        _isRetiredAdrarAsset(item.imageUrl) ||
        _isRetiredAdrarAsset(item.detailImageUrl);
  }

  static AppProductAdvantage? _urinerAdvantage(
    Iterable<AppProductAdvantage> catalog,
  ) {
    AppProductAdvantage? named;
    for (final item in catalog) {
      if (isSystemDocId(item.id) || !_isUrinerAdvantage(item)) continue;
      named ??= item;
      if (_ownDisplayPath(item).isNotEmpty) return item;
    }
    return named;
  }

  /// Adrar yolu sağlığı ikonunu siler; bağlı görselleri Üriner ikonuna taşır.
  static bool _queueAdrarIconRebind(
    WriteBatch batch,
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
  ) {
    final items = [
      for (final doc in docs)
        if (!isSystemDocId(doc.id)) AppProductAdvantage.fromDoc(doc),
    ];
    final uriner = _urinerAdvantage(items);
    if (uriner == null) return false;
    final urinerPath = _ownDisplayPath(uriner);
    if (urinerPath.isEmpty) return false;
    final urinerUrl = uriner.imageUrl.trim();
    final urinerAsset = _isRetiredAdrarAsset(uriner.assetPath)
        ? ''
        : uriner.assetPath.trim();
    final oldPaths = <String>{
      'assets/images/app_ikonlar/idrar.png',
    };
    for (final item in items) {
      if (item.id == uriner.id || !_usesRetiredAdrarIcon(item)) continue;
      for (final value in [item.imageUrl, item.assetPath, item.detailImageUrl]) {
        final path = value.trim();
        if (path.isNotEmpty && path != urinerPath) oldPaths.add(path);
      }
    }

    var changed = false;
    for (final doc in docs) {
      if (isSystemDocId(doc.id) || doc.id == uriner.id) continue;
      final item = AppProductAdvantage.fromDoc(doc);
      final usesOld = _usesRetiredAdrarIcon(item) ||
          oldPaths.contains(item.imageUrl.trim()) ||
          oldPaths.contains(item.assetPath.trim()) ||
          oldPaths.contains(item.detailImageUrl.trim());
      if (!usesOld) continue;
      final nextUrl = urinerUrl.isNotEmpty ? urinerUrl : '';
      final nextAsset = nextUrl.isEmpty ? urinerAsset : '';
      if (item.imageUrl.trim() == nextUrl &&
          item.assetPath.trim() == nextAsset &&
          !_isRetiredAdrarAsset(item.detailImageUrl)) {
        continue;
      }
      batch.set(doc.reference, {
        ProductAdvantageFields.imageUrl: nextUrl,
        ProductAdvantageFields.assetPath: nextAsset,
        if (_isRetiredAdrarAsset(item.detailImageUrl) ||
            oldPaths.contains(item.detailImageUrl.trim()))
          ProductAdvantageFields.detailImageUrl: '',
        ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      changed = true;
    }
    return changed;
  }

  static Future<void> _rebindKnowledgeAdrarIcons(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> advantageDocs,
  ) async {
    final items = [
      for (final doc in advantageDocs)
        if (!isSystemDocId(doc.id)) AppProductAdvantage.fromDoc(doc),
    ];
    final uriner = _urinerAdvantage(items);
    if (uriner == null) return;
    final urinerPath = _ownDisplayPath(uriner);
    if (urinerPath.isEmpty) return;
    final urinerUrl = uriner.imageUrl.trim();
    final topics = FirebaseFirestore.instance.collection(
      FirestoreCollections.knowledgeTopics,
    );
    final snap = await topics.get();
    final batch = FirebaseFirestore.instance.batch();
    var changed = false;
    for (final doc in snap.docs) {
      final data = doc.data();
      final iconUrl = ((data[KnowledgeTopicFields.iconUrl] as String?) ?? '')
          .trim();
      final assetPath =
          ((data[KnowledgeTopicFields.assetPath] as String?) ?? '').trim();
      final title = (data[KnowledgeTopicFields.title] as String?) ?? '';
      final folded = foldSearch('$title ${doc.id}');
      final linkedToAdrar = folded.contains('idrar yolu') ||
          folded.contains('adrar yolu') ||
          doc.id == 'idrar';
      final usesOld = _isRetiredAdrarAsset(iconUrl) ||
          _isRetiredAdrarAsset(assetPath) ||
          (linkedToAdrar &&
              (iconUrl.isNotEmpty || assetPath.isNotEmpty) &&
              iconUrl != urinerPath &&
              assetPath != urinerPath);
      if (!linkedToAdrar && !usesOld) continue;
      final nextUrl = urinerUrl.isNotEmpty ? urinerUrl : '';
      final nextAsset = nextUrl.isEmpty ? uriner.assetPath.trim() : '';
      if (iconUrl == nextUrl && assetPath == nextAsset) continue;
      batch.set(doc.reference, {
        KnowledgeTopicFields.iconUrl: nextUrl,
        KnowledgeTopicFields.assetPath: nextUrl.isEmpty ? nextAsset : '',
        KnowledgeTopicFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      changed = true;
    }
    if (changed) await batch.commit();
  }

  static String defaultAssetPathForId(
    String id, {
    String name = '',
    bool isStat = false,
  }) {
    for (final item in defaultProductAdvantages) {
      if (item.id == id) return item.assetPath.trim();
    }
    if (isStat ||
        id == proteinAdvantageId ||
        id == animalProteinAdvantageId ||
        name.toLowerCase().contains('protein')) {
      return proteinIconPath;
    }
    return '';
  }

  static String explanationFor(AppProductAdvantage item) {
    final stored = item.description.trim();
    if (stored.isNotEmpty) return stored;
    for (final fallback in defaultProductAdvantages) {
      if (fallback.id == item.id) return fallback.description;
    }
    return '';
  }

  Future<void> save(AppProductAdvantage item) async {
    if (isSystemDocId(item.id)) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.set(_collection.doc(item.id), item.toMap(), SetOptions(merge: true));
    batch.set(_deletedDoc, {
      ProductAdvantageFields.removedIds: FieldValue.arrayRemove([item.id]),
      ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  static Map<String, List<AppProductAdvantage>> grouped(
    List<AppProductAdvantage> items, {
    List<ProductAdvantageCategory>? categories,
  }) {
    final cats = categories ?? ProductAdvantageCategory.values;
    final map = <String, List<AppProductAdvantage>>{
      for (final category in cats) category.id: <AppProductAdvantage>[],
    };
    final fallback = map.containsKey(ProductAdvantageCategory.diger.id)
        ? ProductAdvantageCategory.diger.id
        : (cats.isEmpty
              ? ProductAdvantageCategory.diger.id
              : cats.first.id);
    map.putIfAbsent(fallback, () => <AppProductAdvantage>[]);
    for (final item in items) {
      final key = map.containsKey(item.resolvedCategoryId)
          ? item.resolvedCategoryId
          : fallback;
      map[key]!.add(item);
    }
    for (final list in map.values) {
      list.sort((a, b) {
        final byOrder = a.order.compareTo(b.order);
        if (byOrder != 0) return byOrder;
        return a.name.compareTo(b.name);
      });
    }
    return map;
  }

  Future<void> moveToCategory({
    required List<AppProductAdvantage> catalog,
    required String id,
    required String categoryId,
    String? beforeId,
    List<ProductAdvantageCategory>? categories,
  }) async {
    if (id.trim().isEmpty) return;
    final dest = ProductAdvantageCategory.normalize(categoryId);
    if (dest.isEmpty) return;
    final cats = categories ?? _cachedCategories;
    if (!cats.any((category) => category.id == dest)) return;
    AppProductAdvantage? moved;
    for (final item in catalog) {
      if (item.id == id) {
        moved = item;
        break;
      }
    }
    if (moved == null) return;
    if (moved.resolvedCategoryId == dest &&
        (beforeId == null || beforeId == id)) {
      return;
    }

    final groupedItems = grouped([
      for (final item in catalog)
        if (item.id == id) item.copyWith(categoryId: dest) else item,
    ], categories: cats);
    final destList = groupedItems[dest] ?? <AppProductAdvantage>[];
    destList.removeWhere((item) => item.id == id);
    var insertAt = destList.length;
    if (beforeId != null && beforeId != id) {
      final idx = destList.indexWhere((item) => item.id == beforeId);
      if (idx >= 0) insertAt = idx;
    }
    destList.insert(insertAt, moved.copyWith(categoryId: dest));
    groupedItems[dest] = destList;

    final batch = FirebaseFirestore.instance.batch();
    var order = 0;
    for (final category in cats) {
      for (final item in groupedItems[category.id] ?? const <AppProductAdvantage>[]) {
        batch.set(_collection.doc(item.id), {
          ProductAdvantageFields.categoryId: category.id,
          ProductAdvantageFields.order: order,
          ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        order += 1;
      }
    }
    await batch.commit();
  }

  Future<void> delete(String id) async {
    if (isSystemDocId(id)) return;
    final batch = FirebaseFirestore.instance.batch();
    batch.delete(_collection.doc(id));
    batch.set(_deletedDoc, {
      ProductAdvantageFields.name: 'Silinen faydalar',
      ProductAdvantageFields.active: false,
      ProductAdvantageFields.order: -3,
      ProductAdvantageFields.removedIds: FieldValue.arrayUnion([id]),
      ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    await batch.commit();
  }

  DocumentReference<Map<String, dynamic>> get _deletedDoc =>
      _collection.doc(deletedIdsDocId);

  DocumentReference<Map<String, dynamic>> get _categoriesDoc =>
      _collection.doc(categoriesDocId);

  DocumentReference<Map<String, dynamic>> get _overlayDoc =>
      _collection.doc(overlayTemplateId);

  Stream<String> watchOverlayTemplateUrl() {
    return _overlayDoc.snapshots().map((snap) {
      final data = snap.data();
      return ((data?[ProductAdvantageFields.imageUrl] as String?) ?? '').trim();
    });
  }

  Future<String> fetchOverlayTemplateUrl() async {
    final snap = await _overlayDoc.get();
    final data = snap.data();
    return ((data?[ProductAdvantageFields.imageUrl] as String?) ?? '').trim();
  }

  Future<void> saveOverlayTemplateUrl(String url) {
    return _overlayDoc.set({
      ProductAdvantageFields.name: 'Açılan görsel kalıbı',
      ProductAdvantageFields.description: '',
      ProductAdvantageFields.imageUrl: url.trim(),
      ProductAdvantageFields.detailImageUrl: '',
      ProductAdvantageFields.assetPath: '',
      ProductAdvantageFields.active: false,
      ProductAdvantageFields.order: -1,
      ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
