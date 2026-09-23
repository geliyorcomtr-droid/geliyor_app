/// Pro Plan Small & Mini Puppy günlük tüketim (üretici tablosu).
///
/// Satır: beklenen yetişkin kg. Sütun: yaş aralığı.
/// Hücre: gram aralığı; hesapta orta değer kullanılır.
abstract final class ProPlanMiniPuppyGuide {
  static const kgRows = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10];

  static const ageBands = ['1.5-3', '4-5', '6-8', '9-11', '12-24'];

  static const ageBandLabels = [
    '1,5–3 ay',
    '4–5 ay',
    '6–8 ay',
    '9–11 ay',
    '12–24 ay',
  ];

  /// kg → yaş bandı → üretici hücresi.
  static const cells = <String, Map<String, String>>{
    '1': {
      '1.5-3': '30-45',
      '4-5': '50-45',
      '6-8': '45-40',
      '9-11': '40-35',
      '12-24': '35',
    },
    '2': {
      '1.5-3': '41-64',
      '4-5': '69-66',
      '6-8': '66-60',
      '9-11': '59-54',
      '12-24': '54',
    },
    '3': {
      '1.5-3': '52-82',
      '4-5': '88',
      '6-8': '88-80',
      '9-11': '78-72',
      '12-24': '72',
    },
    '4': {
      '1.5-3': '64-101',
      '4-5': '106-109',
      '6-8': '109-100',
      '9-11': '96-91',
      '12-24': '91',
    },
    '5': {
      '1.5-3': '75-120',
      '4-5': '125-130',
      '6-8': '130-120',
      '9-11': '115-110',
      '12-24': '110',
    },
    '6': {
      '1.5-3': '80-130',
      '4-5': '138-144',
      '6-8': '145-131',
      '9-11': '127-121',
      '12-24': '121',
    },
    '7': {
      '1.5-3': '85-140',
      '4-5': '151-158',
      '6-8': '160-142',
      '9-11': '139-132',
      '12-24': '132',
    },
    '8': {
      '1.5-3': '90-150',
      '4-5': '164-172',
      '6-8': '175-153',
      '9-11': '151-143',
      '12-24': '143',
    },
    '9': {
      '1.5-3': '95-160',
      '4-5': '177-186',
      '6-8': '190-164',
      '9-11': '163-154',
      '12-24': '154',
    },
    '10': {
      '1.5-3': '100-170',
      '4-5': '190-200',
      '6-8': '205-175',
      '9-11': '175-165',
      '12-24': '165',
    },
  };

  static String cellKey(int kg, String band) => '$kg|$band';

  static String ageBandForMonths(int? months) {
    final value = months ?? 4;
    if (value <= 3) return '1.5-3';
    if (value <= 5) return '4-5';
    if (value <= 8) return '6-8';
    if (value <= 11) return '9-11';
    return '12-24';
  }

  static int parseCell(dynamic raw) {
    if (raw is num) {
      final grams = raw.round();
      return grams > 0 ? grams : 0;
    }
    final text = '$raw'
        .trim()
        .toLowerCase()
        .replaceAll('g', '')
        .replaceAll(' ', '')
        .replaceAll('–', '-')
        .replaceAll('—', '-')
        .replaceAll(',', '.');
    if (text.isEmpty) return 0;
    final parts = text.split('-');
    if (parts.length >= 2) {
      final start = num.tryParse(parts[0]);
      final end = num.tryParse(parts[1]);
      if (start != null && end != null) {
        return ((start + end) / 2).round();
      }
    }
    return num.tryParse(text)?.round() ?? 0;
  }

  static bool sameAsOfficial(Map<String, Map<String, String>> current) {
    if (current.length != cells.length) return false;
    for (final kg in cells.keys) {
      final officialRow = cells[kg]!;
      final row = current[kg];
      if (row == null || row.length != officialRow.length) return false;
      for (final band in officialRow.keys) {
        if ((row[band] ?? '').trim() != officialRow[band]) return false;
      }
    }
    return true;
  }
}
