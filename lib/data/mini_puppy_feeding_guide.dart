import 'package:geliyor_app/data/feeding_factors.dart';

/// Mini ırk yavru köpek kuru mama tüketimi (g/gün).
/// Excel: hedef yetişkin kilo satırı × yaş dönemi sütunu.
/// Formül: Baz × aktivite × vücut × ek gıda
class MiniPuppyAgeColumn {
  const MiniPuppyAgeColumn({required this.label, required this.months});

  final String label;
  final List<int> months;

  bool covers(int month) => months.contains(month);
}

abstract final class MiniPuppyFeedingGuide {
  static Map<String, int> gramsOverride = const {};
  static MiniPuppyFactors factors = MiniPuppyFactors.defaults;

  static const List<double> kgRows = [
    1,
    2,
    3,
    4,
    5,
    6,
    7,
    8,
    9,
    10,
  ];

  static const List<MiniPuppyAgeColumn> ageColumns = [
    MiniPuppyAgeColumn(label: '2-3 ay', months: [1, 2, 3]),
    MiniPuppyAgeColumn(label: '4-5 ay', months: [4, 5]),
    MiniPuppyAgeColumn(label: '6-8 ay', months: [6, 7, 8]),
    MiniPuppyAgeColumn(label: '9-12 ay', months: [9, 10, 11, 12]),
  ];

  static List<String> get ageLabels => [
        for (final col in ageColumns) col.label,
      ];

  static List<String> get weightLabels => [
        for (final kg in kgRows) kgLabel(kg),
      ];

  /// Satırlar [kgRows], sütunlar [ageColumns].
  static const List<List<int>> table = [
    [40, 45, 45, 35],
    [50, 55, 50, 40],
    [65, 70, 65, 55],
    [75, 85, 75, 65],
    [85, 95, 85, 75],
    [95, 105, 100, 90],
    [105, 120, 110, 100],
    [115, 130, 125, 110],
    [125, 140, 135, 120],
    [135, 150, 150, 135],
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
        out[cellKey(kgLabel(kgRows[r]), ageColumns[c].label)] = table[r][c];
      }
    }
    return out;
  }

  static int columnIndexForMonth(int months) {
    final clamped = months.clamp(1, 12);
    for (var i = 0; i < ageColumns.length; i++) {
      if (ageColumns[i].covers(clamped)) return i;
    }
    return 1;
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

  static int _rawCell(int kgIndex, int colIndex) {
    final key = cellKey(kgLabel(kgRows[kgIndex]), ageColumns[colIndex].label);
    final override = gramsOverride[key];
    if (override != null && override > 0) return override;
    return table[kgIndex][colIndex];
  }

  static int gramsAt({required double kg, required int months}) {
    final kgIndex = kgIndexOf(kg.clamp(kgRows.first, kgRows.last));
    final colIndex = columnIndexForMonth(months);
    return _rawCell(kgIndex, colIndex);
  }

  static int? dailyGramsFor({
    String? weightLabel,
    int? months,
    String? ageLabel,
    String? activityLevel,
    String? bodyType,
    String? extraFood,
  }) {
    final kg = kgFromLabel(weightLabel);
    if (kg == null) return null;
    final month = months ??
        monthsFromAgeLabel(ageLabel) ??
        monthsFromAgeLabel(ageColumns[1].label);
    if (month == null || month <= 0) return null;
    final base = gramsAt(kg: kg, months: month);
    return finalizeGrams(
      baseGrams: base,
      activityLevel: activityLevel,
      bodyType: bodyType,
      extraFood: extraFood,
    );
  }

  static int finalizeGrams({
    required int baseGrams,
    String? activityLevel,
    String? bodyType,
    String? extraFood,
  }) {
    if (baseGrams <= 0) return 0;
    final raw = baseGrams *
        activityFactor(activityLevel) *
        bodyFactor(bodyType) *
        extraFoodFactor(extraFood);
    return raw.round().clamp(1, 2500);
  }

  static double activityFactor(String? activityLevel) {
    final v = (activityLevel ?? '').toLowerCase();
    if (v.contains('çok yüksek') || v.contains('cok yuksek')) {
      return factors.activityVeryHigh;
    }
    if (v.contains('yüksek') || v.contains('yuksek')) {
      return factors.activityHigh;
    }
    if (v.contains('düşük') || v.contains('dusuk')) {
      return factors.activityLow;
    }
    return factors.activityMid;
  }

  static double bodyFactor(String? bodyType) {
    final v = (bodyType ?? '').toLowerCase();
    if (v.contains('zayıf') || v.contains('zayif')) return factors.bodyThin;
    if (v.contains('kilolu') || v.contains('obez')) return factors.bodyHeavy;
    return factors.bodyIdeal;
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

  static String nearestAgeLabel(int? months) {
    if (months == null || months <= 0) return ageColumns[1].label;
    return ageColumns[columnIndexForMonth(months)].label;
  }

  static String? ageBandFromLabel(String? label) {
    final v = (label ?? '').toLowerCase().replaceAll('–', '-');
    for (final col in ageColumns) {
      final key = col.label.toLowerCase().replaceAll(' ', '');
      if (v.replaceAll(' ', '').contains(key)) return col.label;
    }
    return null;
  }

  static int? monthsFromAgeLabel(String? label) {
    final band = ageBandFromLabel(label);
    if (band != null) {
      return ageColumns.firstWhere((col) => col.label == band).months.last;
    }
    return null;
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
