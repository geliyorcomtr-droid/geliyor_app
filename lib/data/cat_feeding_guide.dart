/// Yetişkin kedi kuru mama tüketimi (g/gün).
/// Sütunlar: vücut tipi × aktivite. Baz = İdeal + Orta.
class CatFeedingRow {
  const CatFeedingRow({
    required this.catKg,
    required this.baseGrams,
    required this.thinLow,
    required this.thinMid,
    required this.thinHigh,
    required this.idealLow,
    required this.idealMid,
    required this.idealHigh,
    required this.heavyLow,
    required this.heavyMid,
    required this.heavyHigh,
  });

  final double catKg;
  final int baseGrams;
  final int thinLow;
  final int thinMid;
  final int thinHigh;
  final int idealLow;
  final int idealMid;
  final int idealHigh;
  final int heavyLow;
  final int heavyMid;
  final int heavyHigh;

  /// Varsayılan: İdeal + Orta (baz).
  int get dailyGrams => idealMid;

  String get catKgLabel =>
      '${catKg.toStringAsFixed(1).replaceAll('.', ',')} kg';

  String get dailyLabel => '$dailyGrams g';

  String get monthlyLabel => _monthlyLabel(dailyGrams);

  String get daysFor10kgLabel => '${daysForBagKg(10)} gün';

  int gramsFor({String? bodyType, String? activityLevel}) {
    final body = CatFeedingGuide.normalizeBody(bodyType);
    final activity = CatFeedingGuide.normalizeActivity(activityLevel);
    return switch ((body, activity)) {
      ('Zayıf', 'Düşük') => thinLow,
      ('Zayıf', 'Orta') => thinMid,
      ('Zayıf', 'Yüksek') => thinHigh,
      ('İdeal', 'Düşük') => idealLow,
      ('İdeal', 'Orta') => idealMid,
      ('İdeal', 'Yüksek') => idealHigh,
      ('Kilolu', 'Düşük') => heavyLow,
      ('Kilolu', 'Orta') => heavyMid,
      ('Kilolu', 'Yüksek') => heavyHigh,
      _ => idealMid,
    };
  }

  int daysForBagKg(double bagKg, {int? daily}) {
    final grams = daily ?? dailyGrams;
    if (grams <= 0 || bagKg <= 0) return 0;
    return ((bagKg * 1000) / grams).round();
  }

  String monthlyFor(int daily) => _monthlyLabel(daily);

  static String _monthlyLabel(int daily) {
    final kg = daily * 30 / 1000;
    return '${kg.toStringAsFixed(2).replaceAll('.', ',')} kg';
  }
}

abstract final class CatFeedingGuide {
  static const List<CatFeedingRow> rows = [
    CatFeedingRow(
      catKg: 2.0, baseGrams: 30,
      thinLow: 30, thinMid: 35, thinHigh: 40,
      idealLow: 25, idealMid: 30, idealHigh: 35,
      heavyLow: 25, heavyMid: 25, heavyHigh: 30,
    ),
    CatFeedingRow(
      catKg: 2.5, baseGrams: 40,
      thinLow: 40, thinMid: 45, thinHigh: 50,
      idealLow: 35, idealMid: 40, idealHigh: 45,
      heavyLow: 30, heavyMid: 35, heavyHigh: 40,
    ),
    CatFeedingRow(
      catKg: 3.0, baseGrams: 50,
      thinLow: 50, thinMid: 55, thinHigh: 65,
      idealLow: 45, idealMid: 50, idealHigh: 55,
      heavyLow: 40, heavyMid: 40, heavyHigh: 50,
    ),
    CatFeedingRow(
      catKg: 3.5, baseGrams: 55,
      thinLow: 55, thinMid: 60, thinHigh: 70,
      idealLow: 50, idealMid: 55, idealHigh: 65,
      heavyLow: 40, heavyMid: 45, heavyHigh: 55,
    ),
    CatFeedingRow(
      catKg: 4.0, baseGrams: 60,
      thinLow: 60, thinMid: 65, thinHigh: 75,
      idealLow: 55, idealMid: 60, idealHigh: 70,
      heavyLow: 45, heavyMid: 50, heavyHigh: 60,
    ),
    CatFeedingRow(
      catKg: 4.5, baseGrams: 65,
      thinLow: 65, thinMid: 70, thinHigh: 80,
      idealLow: 60, idealMid: 65, idealHigh: 75,
      heavyLow: 50, heavyMid: 55, heavyHigh: 65,
    ),
    CatFeedingRow(
      catKg: 5.0, baseGrams: 70,
      thinLow: 70, thinMid: 75, thinHigh: 90,
      idealLow: 65, idealMid: 70, idealHigh: 80,
      heavyLow: 55, heavyMid: 60, heavyHigh: 70,
    ),
    CatFeedingRow(
      catKg: 5.5, baseGrams: 75,
      thinLow: 75, thinMid: 80, thinHigh: 95,
      idealLow: 70, idealMid: 75, idealHigh: 85,
      heavyLow: 55, heavyMid: 65, heavyHigh: 75,
    ),
    CatFeedingRow(
      catKg: 6.0, baseGrams: 80,
      thinLow: 80, thinMid: 90, thinHigh: 100,
      idealLow: 70, idealMid: 80, idealHigh: 90,
      heavyLow: 60, heavyMid: 70, heavyHigh: 80,
    ),
    CatFeedingRow(
      catKg: 6.5, baseGrams: 85,
      thinLow: 85, thinMid: 95, thinHigh: 110,
      idealLow: 75, idealMid: 85, idealHigh: 100,
      heavyLow: 65, heavyMid: 70, heavyHigh: 85,
    ),
    CatFeedingRow(
      catKg: 7.0, baseGrams: 90,
      thinLow: 90, thinMid: 100, thinHigh: 115,
      idealLow: 80, idealMid: 90, idealHigh: 105,
      heavyLow: 70, heavyMid: 75, heavyHigh: 90,
    ),
    CatFeedingRow(
      catKg: 7.5, baseGrams: 95,
      thinLow: 95, thinMid: 105, thinHigh: 120,
      idealLow: 85, idealMid: 95, idealHigh: 110,
      heavyLow: 75, heavyMid: 80, heavyHigh: 95,
    ),
    CatFeedingRow(
      catKg: 8.0, baseGrams: 100,
      thinLow: 100, thinMid: 110, thinHigh: 125,
      idealLow: 90, idealMid: 100, idealHigh: 115,
      heavyLow: 75, heavyMid: 85, heavyHigh: 100,
    ),
    CatFeedingRow(
      catKg: 8.5, baseGrams: 100,
      thinLow: 100, thinMid: 110, thinHigh: 125,
      idealLow: 90, idealMid: 100, idealHigh: 115,
      heavyLow: 75, heavyMid: 85, heavyHigh: 100,
    ),
    CatFeedingRow(
      catKg: 9.0, baseGrams: 100,
      thinLow: 100, thinMid: 110, thinHigh: 125,
      idealLow: 90, idealMid: 100, idealHigh: 115,
      heavyLow: 75, heavyMid: 85, heavyHigh: 100,
    ),
    CatFeedingRow(
      catKg: 9.5, baseGrams: 105,
      thinLow: 105, thinMid: 115, thinHigh: 135,
      idealLow: 95, idealMid: 105, idealHigh: 120,
      heavyLow: 80, heavyMid: 90, heavyHigh: 105,
    ),
    CatFeedingRow(
      catKg: 10.0, baseGrams: 110,
      thinLow: 110, thinMid: 120, thinHigh: 140,
      idealLow: 100, idealMid: 110, idealHigh: 125,
      heavyLow: 85, heavyMid: 95, heavyHigh: 110,
    ),
  ];

  static String normalizeBody(String? value) {
    final v = (value ?? '').toLowerCase();
    if (v.contains('zayıf') || v.contains('zayif')) return 'Zayıf';
    if (v.contains('kilolu') || v.contains('obez')) return 'Kilolu';
    return 'İdeal';
  }

  static String normalizeActivity(String? value) {
    final v = (value ?? '').toLowerCase();
    if (v.contains('yüksek') || v.contains('yuksek') || v.contains('aktif')) {
      return 'Yüksek';
    }
    if (v.contains('düşük') || v.contains('dusuk')) return 'Düşük';
    return 'Orta';
  }

  static String profileLabel({String? bodyType, String? activityLevel}) {
    return '${normalizeBody(bodyType)} + ${normalizeActivity(activityLevel)}';
  }

  static CatFeedingRow lookup(double catKg) {
    final clamped = catKg.clamp(rows.first.catKg, rows.last.catKg);
    CatFeedingRow best = rows.first;
    var bestDelta = (best.catKg - clamped).abs();
    for (final row in rows.skip(1)) {
      final delta = (row.catKg - clamped).abs();
      if (delta < bestDelta) {
        best = row;
        bestDelta = delta;
      }
    }
    return best;
  }

  /// Dost Ekle kilo etiketinden ("2-3 kg", "4,5 kg") satır üretir.
  static CatFeedingRow? fromWeightLabel(String? label) {
    final kg = _kgFromLabel(label);
    if (kg == null) return null;
    return lookup(kg);
  }

  static int? dailyGramsFor({
    String? weightLabel,
    String? bodyType,
    String? activityLevel,
  }) {
    final row = fromWeightLabel(weightLabel);
    if (row == null) return null;
    return row.gramsFor(bodyType: bodyType, activityLevel: activityLevel);
  }

  static double? _kgFromLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    final numbers = RegExp(r'(\d+(?:[.,]\d+)?)')
        .allMatches(label)
        .map((m) => double.tryParse(m.group(1)!.replaceAll(',', '.')))
        .whereType<double>()
        .toList();
    if (numbers.isEmpty) return null;
    return numbers.length == 1
        ? numbers.first
        : (numbers.first + numbers.last) / 2;
  }
}
