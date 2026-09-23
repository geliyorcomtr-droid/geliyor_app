import 'package:geliyor_app/data/feeding_factors.dart';

/// Yetişkin kedi kuru mama tüketimi — Excel: Temel Gram × çarpanlar.
///
/// Formül: Temel Gram × Kısır × Vücut × Aktivite × Ek Besin
/// Sonuç temel tüketimin %75–%125 aralığında tutulur, en yakın grama yuvarlanır.
class CatFeedingRow {
  const CatFeedingRow({
    required this.catKg,
    required this.baseGrams,
  });

  final double catKg;
  final int baseGrams;

  int get dailyGrams => baseGrams;

  String get catKgLabel => CatFeedingGuide.kgLabel(catKg);

  String get dailyLabel => '$dailyGrams g';

  String get monthlyLabel => _monthlyLabel(dailyGrams);

  String get daysFor10kgLabel => '${daysForBagKg(10)} gün';

  int gramsFor({
    String? bodyType,
    String? activityLevel,
    String? neutered,
    String? extraFood,
  }) {
    return CatFeedingGuide.finalizeGrams(
      baseGrams: baseGrams,
      bodyType: bodyType,
      activityLevel: activityLevel,
      neutered: neutered,
      extraFood: extraFood,
    );
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
  /// Admin kaydı; boşsa Excel satırları kullanılır.
  static Map<String, int> gramsOverride = const {};
  static FeedingFactors factors = FeedingFactors.defaults;

  static const List<CatFeedingRow> rows = [
    CatFeedingRow(catKg: 2.0, baseGrams: 31),
    CatFeedingRow(catKg: 2.5, baseGrams: 37),
    CatFeedingRow(catKg: 3.0, baseGrams: 44),
    CatFeedingRow(catKg: 3.5, baseGrams: 49),
    CatFeedingRow(catKg: 4.0, baseGrams: 55),
    CatFeedingRow(catKg: 4.5, baseGrams: 59),
    CatFeedingRow(catKg: 5.0, baseGrams: 64),
    CatFeedingRow(catKg: 5.5, baseGrams: 69),
    CatFeedingRow(catKg: 6.0, baseGrams: 74),
    CatFeedingRow(catKg: 6.5, baseGrams: 78),
    CatFeedingRow(catKg: 7.0, baseGrams: 82),
    CatFeedingRow(catKg: 7.5, baseGrams: 86),
    CatFeedingRow(catKg: 8.0, baseGrams: 90),
    CatFeedingRow(catKg: 9.0, baseGrams: 98),
    CatFeedingRow(catKg: 10.0, baseGrams: 105),
  ];

  static const weightLabels = [
    '2 kg',
    '2,5 kg',
    '3 kg',
    '3,5 kg',
    '4 kg',
    '4,5 kg',
    '5 kg',
    '5,5 kg',
    '6 kg',
    '6,5 kg',
    '7 kg',
    '7,5 kg',
    '8 kg',
    '9 kg',
    '10 kg',
    '10+ kg',
  ];

  static String kgLabel(double kg) {
    if (kg > 10) return '10+ kg';
    if (kg == kg.roundToDouble()) {
      return '${kg.toInt()} kg';
    }
    return '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }

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

  static double bodyFactor(String? bodyType) {
    return switch (normalizeBody(bodyType)) {
      'Zayıf' => factors.bodyThin,
      'Kilolu' => factors.bodyHeavy,
      _ => factors.bodyIdeal,
    };
  }

  static double activityFactor(String? activityLevel) {
    return switch (normalizeActivity(activityLevel)) {
      'Düşük' => factors.activityLow,
      'Yüksek' => factors.activityHigh,
      _ => factors.activityMid,
    };
  }

  static double neuteredFactor(String? neutered) {
    final v = (neutered ?? '').toLowerCase();
    if (v == 'hayır' ||
        v == 'hayir' ||
        v.contains('değil') ||
        v.contains('degil')) {
      return factors.neuteredNo;
    }
    if (v == 'evet' || v.contains('kısır') || v.contains('kisir')) {
      return factors.neuteredYes;
    }
    return factors.neuteredNo;
  }

  static double extraFoodFactor(String? extraFood) {
    final v = (extraFood ?? '').toLowerCase();
    if (v.contains('her ikisi')) return factors.extraBoth;
    if (v.contains('yaş') || v.contains('yas')) return factors.extraWet;
    if (v.contains('ödül') || v.contains('odul')) return factors.extraTreat;
    return factors.extraNone;
  }

  static int finalizeGrams({
    required int baseGrams,
    String? bodyType,
    String? activityLevel,
    String? neutered,
    String? extraFood,
  }) {
    if (baseGrams <= 0) return 0;
    final raw = baseGrams *
        neuteredFactor(neutered) *
        bodyFactor(bodyType) *
        activityFactor(activityLevel) *
        extraFoodFactor(extraFood);
    final lo = baseGrams * factors.clampLow;
    final hi = baseGrams * factors.clampHigh;
    return raw.clamp(lo, hi).round();
  }

  static List<CatFeedingRow> get liveRows {
    if (gramsOverride.isEmpty) return rows;
    return [
      for (final row in rows)
        CatFeedingRow(
          catKg: row.catKg,
          baseGrams: gramsOverride[row.catKgLabel] ?? row.baseGrams,
        ),
    ];
  }

  static CatFeedingRow lookup(double catKg) {
    final table = liveRows;
    if (catKg > 10) {
      final plus = gramsOverride['10+ kg'];
      if (plus != null && plus > 0) {
        return CatFeedingRow(catKg: 10.5, baseGrams: plus);
      }
      return table.last;
    }
    final clamped = catKg.clamp(table.first.catKg, table.last.catKg);
    CatFeedingRow best = table.first;
    var bestDelta = (best.catKg - clamped).abs();
    for (final row in table.skip(1)) {
      final delta = (row.catKg - clamped).abs();
      if (delta < bestDelta) {
        best = row;
        bestDelta = delta;
      }
    }
    return best;
  }

  static CatFeedingRow? fromWeightLabel(String? label) {
    final text = label ?? '';
    if (text.contains('+') || text.contains('>')) {
      final plus = gramsOverride['10+ kg'];
      if (plus != null && plus > 0) {
        return CatFeedingRow(catKg: 10.5, baseGrams: plus);
      }
    }
    final kg = kgFromLabel(label);
    if (kg == null) return null;
    return lookup(kg);
  }

  static String nearestWeightLabel(String? label) {
    final kg = kgFromLabel(label);
    if (kg == null) return weightLabels.first;
    if ((label ?? '').contains('+') || kg > 10) return '10+ kg';
    return lookup(kg).catKgLabel;
  }

  static int? dailyGramsFor({
    String? weightLabel,
    String? bodyType,
    String? activityLevel,
    String? neutered,
    String? extraFood,
  }) {
    final row = fromWeightLabel(weightLabel);
    if (row == null) return null;
    return row.gramsFor(
      bodyType: bodyType,
      activityLevel: activityLevel,
      neutered: neutered,
      extraFood: extraFood,
    );
  }

  static double? kgFromLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    if (label.contains('+') || label.contains('>')) return 10.0;
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
