class ProductAdvantageCategory {
  const ProductAdvantageCategory({required this.id, required this.label});

  final String id;
  final String label;

  static const tur = ProductAdvantageCategory(
    id: 'tur',
    label: 'Tür ve Yaşam Evresi',
  );
  static const legacyYasamEvresiId = 'yasam_evresi';
  static const icerik = ProductAdvantageCategory(
    id: 'icerik',
    label: 'Ürün İçeriği',
  );
  static const saglik = ProductAdvantageCategory(
    id: 'saglik',
    label: 'Sağlık Koşulları',
  );
  static const urunTipi = ProductAdvantageCategory(
    id: 'urun_tipi',
    label: 'Ürün Tipi',
  );
  static const protein = ProductAdvantageCategory(
    id: 'protein',
    label: 'Proteinler',
  );
  static const diger = ProductAdvantageCategory(id: 'diger', label: 'Diğer');

  static const values = <ProductAdvantageCategory>[
    tur,
    icerik,
    saglik,
    urunTipi,
    protein,
    diger,
  ];

  static const _byId = <String, String>{
    'kisir_kedi': 'tur',
    'kisir_kopek': 'tur',
    'kopek': 'tur',
    'normal_kedi': 'tur',
    'yavru_kopek': 'tur',
    'yavru_kedi': 'tur',
    'yetiskin_kopek': 'tur',
    'somon': 'icerik',
    'tavuk': 'icerik',
    'kuzu': 'icerik',
    'hindi': 'icerik',
    'inek': 'icerik',
    'ordek': 'icerik',
    'tavsan': 'icerik',
    'ton_baligi': 'icerik',
    'tahilsiz': 'icerik',
    'dogal_icerik': 'icerik',
    'bobrek': 'saglik',
    'sindirim': 'saglik',
    'tuy_deri': 'saglik',
    'kilo_kontrol': 'saglik',
    'bagisiklik': 'saglik',
    'kalp': 'saglik',
    'dis': 'saglik',
    'idrar': 'saglik',
    'eklem': 'saglik',
    'diyabet': 'saglik',
    'karaciger': 'saglik',
    'hypoallergenic': 'saglik',
    'parazit': 'saglik',
    'tuy_yumusak': 'saglik',
    'acil_durum': 'saglik',
    'zehirlenme': 'saglik',
    'yaralanma': 'saglik',
    'mama_kabi': 'urun_tipi',
    'ilac_tedavi': 'urun_tipi',
    'ilac': 'urun_tipi',
    'kuru_mama': 'urun_tipi',
    'yas_mama': 'urun_tipi',
    'konserve': 'urun_tipi',
    'malt': 'urun_tipi',
    'vitamin': 'urun_tipi',
    'takviye': 'urun_tipi',
    'protein': 'protein',
    'hayvansal-protein': 'protein',
    'dha': 'protein',
    'l_karnitin': 'protein',
    'asi_takvimi': 'diger',
    'sokak': 'diger',
    'favori': 'diger',
    'akilli_oneri': 'diger',
    'yapayzeka': 'diger',
    'tl': 'diger',
  };

  static ProductAdvantageCategory fromId(
    String raw, {
    List<ProductAdvantageCategory>? catalog,
  }) {
    final id = normalize(raw);
    final list = catalog ?? values;
    for (final item in list) {
      if (item.id == id) return item;
    }
    return ProductAdvantageCategory(id: id, label: id);
  }

  /// Boş ve eski `yasam_evresi` dışındaki kimlikleri olduğu gibi bırakır;
  /// özel kategoriler `diger`e düşmesin.
  static String normalize(String raw) {
    final id = raw.trim();
    if (id.isEmpty) return diger.id;
    if (id == legacyYasamEvresiId) return tur.id;
    return id;
  }

  static bool isBuiltIn(String id) {
    final trimmed = id.trim();
    for (final item in values) {
      if (item.id == trimmed) return true;
    }
    return false;
  }

  static String slugFromLabel(String label) {
    final folded = _fold(label).replaceAll(' ', '_');
    if (folded.isEmpty) return 'kategori';
    return folded.length > 40 ? folded.substring(0, 40) : folded;
  }

  static List<ProductAdvantageCategory> mergeCatalog({
    required Iterable<String> removedIds,
    required List<ProductAdvantageCategory> extras,
  }) {
    final removed = <String>{
      for (final id in removedIds)
        if (id.trim().isNotEmpty) id.trim(),
    };
    final extraById = <String, ProductAdvantageCategory>{};
    for (final extra in extras) {
      final id = extra.id.trim();
      final extraLabel = extra.label.trim();
      if (id.isEmpty || extraLabel.isEmpty) continue;
      extraById[id] = ProductAdvantageCategory(id: id, label: extraLabel);
    }
    final seen = <String>{};
    final list = <ProductAdvantageCategory>[];
    for (final item in values) {
      if (removed.contains(item.id) || seen.contains(item.id)) continue;
      seen.add(item.id);
      list.add(extraById[item.id] ?? item);
    }
    for (final extra in extraById.values) {
      if (removed.contains(extra.id) || seen.contains(extra.id)) continue;
      seen.add(extra.id);
      list.add(extra);
    }
    if (list.isEmpty) return const [diger];
    return list;
  }

  static String infer(String id, String name) {
    final mapped = _byId[id.trim()];
    if (mapped != null) return mapped;
    final q = _fold('$id $name');
    if (q.contains('kisir')) return tur.id;
    if (q.contains('yavru') || q.contains('yetiskin')) return tur.id;
    if (_containsAny(q, const [
      'tavuk',
      'kuzu',
      'ordek',
      'somon',
      'hindi',
      'inek',
      'sigir',
      'tavsan',
      'ton',
      'tahilsiz',
      'dogal icerik',
    ])) {
      return icerik.id;
    }
    if (_containsAny(q, const [
      'sindirim',
      'bobrek',
      'kalp',
      'bagisik',
      'dis ',
      'idrar',
      'eklem',
      'diyabet',
      'karaciger',
      'hipoalerjen',
      'hypoallergenic',
      'parazit',
      'kilo',
      'tuy',
      'deri',
      'zehir',
      'yaralan',
    ])) {
      return saglik.id;
    }
    if (_containsAny(q, const [
      'kuru mama',
      'yas mama',
      'konserve',
      'malt',
      'vitamin',
      'takviye',
      'mama kabi',
    ])) {
      return urunTipi.id;
    }
    if (_containsAny(q, const ['dha', 'karnitin', 'protein'])) {
      return protein.id;
    }
    if (q.contains('kedi') || q.contains('kopek')) return tur.id;
    return diger.id;
  }

  static bool _containsAny(String haystack, List<String> needles) {
    for (final needle in needles) {
      if (haystack.contains(needle.trim())) return true;
    }
    return false;
  }

  static String _fold(String raw) {
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
}
