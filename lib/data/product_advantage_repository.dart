import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/product_advantage_guides.dart';

class AppProductAdvantage {
  const AppProductAdvantage({
    required this.id,
    required this.name,
    this.description = '',
    this.value = '',
    this.isStat = false,
    this.imageUrl = '',
    this.assetPath = '',
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String name;
  final String description;
  /// İstatistik kartında üstte gösterilir (ör. "% 41"). Ürün bazında ezilebilir.
  final String value;
  /// true ise ikon yerine değer + etiket gösterilir.
  final bool isStat;
  final String imageUrl;
  final String assetPath;
  final int order;
  final bool active;

  factory AppProductAdvantage.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AppProductAdvantage(
      id: doc.id,
      name: (data[ProductAdvantageFields.name] as String?) ?? doc.id,
      description: (data[ProductAdvantageFields.description] as String?) ?? '',
      value: (data[ProductAdvantageFields.value] as String?) ?? '',
      isStat: data[ProductAdvantageFields.isStat] as bool? ?? false,
      imageUrl: (data[ProductAdvantageFields.imageUrl] as String?) ?? '',
      assetPath: (data[ProductAdvantageFields.assetPath] as String?) ?? '',
      order: (data[ProductAdvantageFields.order] as num?)?.toInt() ?? 0,
      active: data[ProductAdvantageFields.active] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    ProductAdvantageFields.name: name.trim(),
    ProductAdvantageFields.description: description.trim(),
    ProductAdvantageFields.value: value.trim(),
    ProductAdvantageFields.isStat: isStat,
    ProductAdvantageFields.imageUrl: imageUrl.trim(),
    ProductAdvantageFields.assetPath: assetPath.trim(),
    ProductAdvantageFields.order: order,
    ProductAdvantageFields.active: active,
    ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppProductAdvantage copyWith({
    String? name,
    String? description,
    String? value,
    bool? isStat,
    String? imageUrl,
    String? assetPath,
    int? order,
    bool? active,
  }) {
    return AppProductAdvantage(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      value: value ?? this.value,
      isStat: isStat ?? this.isStat,
      imageUrl: imageUrl ?? this.imageUrl,
      assetPath: assetPath ?? this.assetPath,
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
}) {
  return AppProductAdvantage(
    id: id,
    name: name,
    description: description,
    value: value,
    isStat: isStat,
    assetPath: 'assets/images/app_ikonlar/$id.png',
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
    'Protein İçerir',
    41,
    isStat: true,
    value: '%42',
    description:
        'Kas gelişimi ve tokluk için yüksek kaliteli protein oranı sunar.',
  ),
];

class ProductAdvantageRepository {
  ProductAdvantageRepository._();

  static final instance = ProductAdvantageRepository._();

  /// Ürün görselinin sağındaki sabit slot sayısı.
  static const int heroSlotCount = 5;

  /// Bir ürüne seçilebilecek özellik üst sınırı.
  /// İlk 5 sağ ikonlarda, fazlası yalnızca alt listedeki Ürün Özellikleri'nde.
  static const int maxPerProduct = 24;

  static List<AppProductAdvantage> orderedForProduct({
    required List<String>? selectedIds,
    required List<AppProductAdvantage> catalog,
  }) {
    if (selectedIds == null) return catalog;
    return [
      for (final id in selectedIds)
        ...catalog.where((item) => item.id == id),
    ];
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
      final idText = foldSearch(item.id.replaceAll('_', ' '));
      if (name == q || item.id == query.trim() || idText == q) {
        ids.add(item.id);
        continue;
      }
      if (q.length >= 4 && (name.contains(q) || idText.contains(q))) {
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

  Stream<List<AppProductAdvantage>> watchAll({bool activeOnly = false}) {
    return _collection.orderBy(ProductAdvantageFields.order).snapshots().map((
      snapshot,
    ) {
      final items = snapshot.docs.map(AppProductAdvantage.fromDoc).toList();
      return activeOnly ? items.where((item) => item.active).toList() : items;
    });
  }

  Future<List<AppProductAdvantage>> fetchAll({bool activeOnly = false}) async {
    final snapshot = await _collection
        .orderBy(ProductAdvantageFields.order)
        .get();
    final items = snapshot.docs.map(AppProductAdvantage.fromDoc).toList();
    return activeOnly ? items.where((item) => item.active).toList() : items;
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

      for (final item in defaultProductAdvantages) {
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

      final proteinDoc = existingById['protein'];
      if (proteinDoc != null) {
        final data = proteinDoc.data();
        final assetPath = (data[ProductAdvantageFields.assetPath] as String?) ?? '';
        final needsIcon =
            assetPath.isEmpty || !assetPath.endsWith('/protein.png');
        if (needsIcon || data[ProductAdvantageFields.isStat] != true) {
          batch.set(_collection.doc('protein'), {
            ProductAdvantageFields.name: 'Protein İçerir',
            ProductAdvantageFields.isStat: true,
            ProductAdvantageFields.value: '%42',
            ProductAdvantageFields.assetPath:
                'assets/images/app_ikonlar/protein.png',
            ProductAdvantageFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
          hasWrites = true;
        }
      }

      if (hasWrites) await batch.commit();
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return;
      rethrow;
    }
  }

  /// İstatistik kartı olarak gösterilir (değer alanı ürün formunda açılır).
  static const proteinAdvantageId = 'protein';
  static const proteinIconPath = 'assets/images/app_ikonlar/protein.png';

  static bool displaysAsStat(AppProductAdvantage item) {
    if (item.isStat) return true;
    if (item.id == proteinAdvantageId) return true;
    return item.name.toLowerCase().contains('protein');
  }

  static String formatProteinDisplay(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return '';
    return value.startsWith('%') ? value : '%$value';
  }

  static String explanationFor(AppProductAdvantage item) {
    final stored = item.description.trim();
    if (stored.isNotEmpty) return stored;
    for (final fallback in defaultProductAdvantages) {
      if (fallback.id == item.id) return fallback.description;
    }
    return '';
  }

  Future<void> save(AppProductAdvantage item) {
    return _collection.doc(item.id).set(item.toMap(), SetOptions(merge: true));
  }

  Future<void> delete(String id) => _collection.doc(id).delete();
}
