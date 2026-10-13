import 'package:geliyor_app/data/feeding_factors.dart';

/// Yavru kedi kuru mama tüketimi (g/gün).
/// Excel: kilo satırı × yaş sütunu. Formül: baz × kısır × vücut × aktivite × ek besin.
class KittenAgeColumn {
  const KittenAgeColumn({required this.label, required this.months});

  final String label;
  final List<int> months;

  bool covers(int month) => months.contains(month);
}

abstract final class KittenFeedingGuide {
  static Map<String, int> gramsOverride = const {};
  static FeedingFactors factors = FeedingFactors.defaults;

  static const List<double> kgRows = [
    0.5,
    1.0,
    1.5,
    2.0,
    2.5,
    3.0,
    3.5,
    4.0,
    4.5,
    5.0,
  ];

  static const List<KittenAgeColumn> ageColumns = [
    KittenAgeColumn(label: '1-2 ay', months: [1, 2]),
    KittenAgeColumn(label: '3 ay', months: [3]),
    KittenAgeColumn(label: '4 ay', months: [4]),
    KittenAgeColumn(label: '5 ay', months: [5]),
    KittenAgeColumn(label: '6 ay', months: [6]),
    KittenAgeColumn(label: '7 ay', months: [7]),
    KittenAgeColumn(label: '8 ay', months: [8]),
    KittenAgeColumn(label: '9 ay', months: [9]),
    KittenAgeColumn(label: '10 ay', months: [10]),
    KittenAgeColumn(label: '11 ay', months: [11]),
    KittenAgeColumn(label: '12 ay', months: [12]),
  ];

  static const List<int> monthRows = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  static List<String> get weightLabels => [
        for (final kg in kgRows) kgLabel(kg),
      ];

  /// Satırlar [kgRows], sütunlar [ageColumns].
  static const List<List<int?>> table = [
    [30, 30, 30, 30, 30, 30, 30, 30, 30, 30, 30],
    [45, 50, 50, 50, 50, 45, 45, 45, 40, 40, 40],
    [50, 55, 60, 60, 60, 55, 55, 55, 50, 50, 50],
    [null, 60, 65, 70, 70, 65, 65, 60, 60, 55, 55],
    [null, 65, 70, 70, 75, 70, 70, 70, 65, 65, 60],
    [null, null, 75, 75, 80, 75, 75, 75, 70, 70, 65],
    [null, null, 80, 80, 85, 80, 80, 80, 75, 75, 70],
    [null, null, null, 85, 90, 85, 85, 80, 80, 75, 75],
    [null, null, null, null, 95, 90, 90, 85, 85, 80, 80],
    [null, null, null, null, 100, 95, 95, 90, 85, 85, 80],
  ];

  static String kgLabel(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toInt()} kg';
    return '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }

  static String cellKey(String kgLabel, String ageLabel) =>
      '$kgLabel|$ageLabel';

  static List<String> get cellKeys => [
        for (final kg in kgRows)
          for (final col in ageColumns) cellKey(kgLabel(kg), col.label),
      ];

  static Map<String, int> get defaultGrams {
    final out = <String, int>{};
    for (var r = 0; r < kgRows.length; r++) {
      for (var c = 0; c < ageColumns.length; c++) {
        final grams = table[r][c];
        if (grams == null || grams <= 0) continue;
        out[cellKey(kgLabel(kgRows[r]), ageColumns[c].label)] = grams;
      }
    }
    return out;
  }

  static int columnIndexForMonth(int months) {
    final clamped = months.clamp(1, 12);
    for (var i = 0; i < ageColumns.length; i++) {
      if (ageColumns[i].covers(clamped)) return i;
    }
    return 0;
  }

  static int kgIndexOf(double kg) {
    var best = 0;
    var bestDelta = (kgRows.first - kg).abs();
    for (var i = 1; i < kgRows.length; i++) {
      final delta = (kgRows[i] - kg).abs();
      if (delta < bestDelta) {
        best = i;
        bestDelta = delta;
      }
    }
    return best;
  }

  static int? _rawCell(int kgIndex, int colIndex) {
    final key = cellKey(kgLabel(kgRows[kgIndex]), ageColumns[colIndex].label);
    final override = gramsOverride[key];
    if (override != null && override > 0) return override;
    return table[kgIndex][colIndex];
  }

  static int? gramsAt({required double kg, required int months}) {
    final kgIndex = kgIndexOf(kg.clamp(kgRows.first, kgRows.last));
    final colIndex = columnIndexForMonth(months);
    final exact = _rawCell(kgIndex, colIndex);
    if (exact != null) return exact;

    var bestKg = -1;
    var bestDelta = double.infinity;
    for (var r = 0; r < kgRows.length; r++) {
      if (_rawCell(r, colIndex) == null) continue;
      final delta = (kgRows[r] - kgRows[kgIndex]).abs();
      if (delta < bestDelta) {
        bestKg = r;
        bestDelta = delta;
      }
    }
    if (bestKg >= 0) return _rawCell(bestKg, colIndex);

    var bestCol = -1;
    var bestMonthDelta = 99;
    for (var c = 0; c < ageColumns.length; c++) {
      if (_rawCell(kgIndex, c) == null) continue;
      final delta = (ageColumns[c].months.first - months).abs();
      if (delta < bestMonthDelta) {
        bestCol = c;
        bestMonthDelta = delta;
      }
    }
    if (bestCol >= 0) return _rawCell(kgIndex, bestCol);
    return null;
  }

  static int? dailyGramsFor({
    String? weightLabel,
    int? months,
    String? bodyType,
    String? activityLevel,
    String? neutered,
    String? extraFood,
  }) {
    final kg = kgFromLabel(weightLabel);
    if (kg == null || months == null || months <= 0) return null;
    final base = gramsAt(kg: kg, months: months);
    if (base == null) return null;
    return finalizeGrams(
      baseGrams: base,
      bodyType: bodyType,
      activityLevel: activityLevel,
      neutered: neutered,
      extraFood: extraFood,
    );
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

  static double bodyFactor(String? bodyType) {
    final v = (bodyType ?? '').toLowerCase();
    if (v.contains('zayıf') || v.contains('zayif')) return factors.bodyThin;
    if (v.contains('kilolu') || v.contains('obez')) return factors.bodyHeavy;
    return factors.bodyIdeal;
  }

  static double activityFactor(String? activityLevel) {
    final v = (activityLevel ?? '').toLowerCase();
    if (v.contains('yüksek') || v.contains('yuksek') || v.contains('aktif')) {
      return factors.activityHigh;
    }
    if (v.contains('düşük') || v.contains('dusuk')) return factors.activityLow;
    return factors.activityMid;
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

  static String nearestWeightLabel(String? label) {
    final kg = kgFromLabel(label);
    if (kg == null) return weightLabels.first;
    return kgLabel(kgRows[kgIndexOf(kg)]);
  }

  static double? kgFromLabel(String? label) {
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
