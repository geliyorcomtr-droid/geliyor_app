import 'package:flutter/material.dart';

class ProductAdvantageCategory {
  const ProductAdvantageCategory({
    required this.id,
    required this.label,
    this.color = defaultColorHex,
  });

  final String id;
  final String label;
  final String color;

  /// Eski varsayılan morun bir ton açığı.
  static const defaultColorHex = '#9637F3';

  static String normalizeColor(String raw) {
    var value = raw.trim();
    if (value.isEmpty) return '';
    if (value.startsWith('#')) value = value.substring(1);
    if (value.length == 3 && RegExp(r'^[0-9a-fA-F]{3}$').hasMatch(value)) {
      value = value.split('').map((char) => '$char$char').join();
    }
    if (!RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(value)) return '';
    return '#${value.toUpperCase()}';
  }

  /// Tailwind basamağında bir ton açar. `#EF4444` → `#F87171`.
  /// Palet dışı kodlarda açıklık aynı miktarda artar.
  static String lightenOneTone(String raw) {
    final normalized = normalizeColor(raw);
    if (normalized.isEmpty) return raw.trim();
    final step = _lighterTone[normalized];
    if (step != null) return step;
    final rgb = int.parse(normalized.substring(1), radix: 16);
    final hsl = HSLColor.fromColor(Color(0xFF000000 | rgb));
    final next = hsl.withLightness((hsl.lightness + 0.10).clamp(0.0, 0.92));
    final argb = next.toColor().toARGB32();
    final hex = (argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0');
    return '#${hex.toUpperCase()}';
  }

  static final Map<String, String> _lighterTone = _buildLighterTone();

  static Map<String, String> _buildLighterTone() {
    const scales = <List<String>>[
      ['#F8FAFC', '#F1F5F9', '#E2E8F0', '#CBD5E1', '#94A3B8', '#64748B', '#475569', '#334155', '#1E293B', '#0F172A', '#020617'],
      ['#F9FAFB', '#F3F4F6', '#E5E7EB', '#D1D5DB', '#9CA3AF', '#6B7280', '#4B5563', '#374151', '#1F2937', '#111827', '#030712'],
      ['#FAFAFA', '#F4F4F5', '#E4E4E7', '#D4D4D8', '#A1A1AA', '#71717A', '#52525B', '#3F3F46', '#27272A', '#18181B', '#09090B'],
      ['#F5F5F5', '#E5E5E5', '#D4D4D4', '#A3A3A3', '#737373', '#525252', '#404040', '#262626', '#171717', '#0A0A0A'],
      ['#FAFAF9', '#F5F5F4', '#E7E5E4', '#D6D3D1', '#A8A29E', '#78716C', '#57534E', '#44403C', '#292524', '#1C1917', '#0C0A09'],
      ['#FEF2F2', '#FEE2E2', '#FECACA', '#FCA5A5', '#F87171', '#EF4444', '#DC2626', '#B91C1C', '#991B1B', '#7F1D1D', '#450A0A'],
      ['#FFF7ED', '#FFEDD5', '#FED7AA', '#FDBA74', '#FB923C', '#F97316', '#EA580C', '#C2410C', '#9A3412', '#7C2D12', '#431407'],
      ['#FFFBEB', '#FEF3C7', '#FDE68A', '#FCD34D', '#FBBF24', '#F59E0B', '#D97706', '#B45309', '#92400E', '#78350F', '#451A03'],
      ['#FEFCE8', '#FEF9C3', '#FEF08A', '#FDE047', '#FACC15', '#EAB308', '#CA8A04', '#A16207', '#854D0E', '#713F12', '#422006'],
      ['#F7FEE7', '#ECFCCB', '#D9F99D', '#BEF264', '#A3E635', '#84CC16', '#65A30D', '#4D7C0F', '#3F6212', '#365314', '#1A2E05'],
      ['#F0FDF4', '#DCFCE7', '#BBF7D0', '#86EFAC', '#4ADE80', '#22C55E', '#16A34A', '#15803D', '#166534', '#14532D', '#052E16'],
      ['#ECFDF5', '#D1FAE5', '#A7F3D0', '#6EE7B7', '#34D399', '#10B981', '#059669', '#047857', '#065F46', '#064E3B', '#022C22'],
      ['#F0FDFA', '#CCFBF1', '#99F6E4', '#5EEAD4', '#2DD4BF', '#14B8A6', '#0D9488', '#0F766E', '#115E59', '#134E4A', '#042F2E'],
      ['#ECFEFF', '#CFFAFE', '#A5F3FC', '#67E8F9', '#22D3EE', '#06B6D4', '#0891B2', '#0E7490', '#155E75', '#164E63', '#083344'],
      ['#F0F9FF', '#E0F2FE', '#BAE6FD', '#7DD3FC', '#38BDF8', '#0EA5E9', '#0284C7', '#0369A1', '#075985', '#0C4A6E', '#082F49'],
      ['#EFF6FF', '#DBEAFE', '#BFDBFE', '#93C5FD', '#60A5FA', '#3B82F6', '#2563EB', '#1D4ED8', '#1E40AF', '#1E3A8A', '#172554'],
      ['#EEF2FF', '#E0E7FF', '#C7D2FE', '#A5B4FC', '#818CF8', '#6366F1', '#4F46E5', '#4338CA', '#3730A3', '#312E81', '#1E1B4B'],
      ['#F5F3FF', '#EDE9FE', '#DDD6FE', '#C4B5FD', '#A78BFA', '#8B5CF6', '#7C3AED', '#6D28D9', '#5B21B6', '#4C1D95', '#2E1065'],
      ['#FAF5FF', '#F3E8FF', '#E9D5FF', '#D8B4FE', '#C084FC', '#A855F7', '#9333EA', '#7E22CE', '#6B21A8', '#581C87', '#3B0764'],
      ['#FDF4FF', '#FAE8FF', '#F5D0FE', '#F0ABFC', '#E879F9', '#D946EF', '#C026D3', '#A21CAF', '#86198F', '#701A75', '#4A044E'],
      ['#FDF2F8', '#FCE7F3', '#FBCFE8', '#F9A8D4', '#F472B6', '#EC4899', '#DB2777', '#BE185D', '#9D174D', '#831843', '#500724'],
      ['#FFF1F2', '#FFE4E6', '#FECDD3', '#FDA4AF', '#FB7185', '#F43F5E', '#E11D48', '#BE123C', '#9F1239', '#881337', '#4C0519'],
    ];
    final map = <String, String>{};
    for (final scale in scales) {
      for (var i = 1; i < scale.length; i++) {
        map[scale[i]] = scale[i - 1];
      }
    }
    return map;
  }

  ProductAdvantageCategory copyWith({String? label, String? color}) {
    return ProductAdvantageCategory(
      id: id,
      label: label ?? this.label,
      color: color ?? this.color,
    );
  }

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
    Map<String, String> colors = const {},
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
    return [
      for (final item in list)
        item.copyWith(
          color: colors[item.id] ?? item.color,
        ),
    ];
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
