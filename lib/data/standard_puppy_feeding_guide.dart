import 'package:geliyor_app/data/feeding_factors.dart';

/// Standart yavru köpek kuru mama tüketimi (g/gün).
/// Excel: hedef yetişkin kilo satırı × yaş dönemi sütunu (1–60 kg).
/// Formül: Baz × kısır × aktivite × vücut × ek gıda
class StandardPuppyAgeColumn {
  const StandardPuppyAgeColumn({required this.label, required this.months});

  final String label;
  final List<int> months;

  bool covers(int month) => months.contains(month);
}

abstract final class StandardPuppyFeedingGuide {
  static Map<String, int> gramsOverride = const {};
  static StandardPuppyFactors factors = StandardPuppyFactors.defaults;

  static const List<int> kgRows = [
    1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20,
    21, 22, 23, 24, 25, 26, 27, 28, 29, 30,
    31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
    51, 52, 53, 54, 55, 56, 57, 58, 59, 60,
  ];

  static const List<StandardPuppyAgeColumn> ageColumns = [
    StandardPuppyAgeColumn(label: '2-3 ay', months: [1, 2, 3]),
    StandardPuppyAgeColumn(label: '4-5 ay', months: [4, 5]),
    StandardPuppyAgeColumn(label: '6-8 ay', months: [6, 7, 8]),
    StandardPuppyAgeColumn(label: '9-12 ay', months: [9, 10, 11, 12]),
    StandardPuppyAgeColumn(label: '13-15 ay', months: [13, 14, 15]),
    StandardPuppyAgeColumn(label: '16-18 ay', months: [16, 17, 18]),
  ];

  static List<String> get ageLabels => [
        for (final col in ageColumns) col.label,
      ];

  static List<String> get weightLabels => [
        for (final kg in kgRows) kgLabel(kg),
      ];

  /// Satırlar [kgRows], sütunlar [ageColumns].
  static const List<List<int>> table = [
    [35, 40, 35, 30, 30, 30],
    [45, 55, 50, 40, 40, 40],
    [60, 70, 65, 55, 55, 55],
    [75, 85, 80, 65, 65, 65],
    [85, 100, 95, 80, 80, 80],
    [100, 115, 110, 95, 95, 95],
    [110, 130, 125, 105, 105, 105],
    [120, 145, 135, 115, 115, 115],
    [130, 155, 145, 125, 125, 125],
    [140, 165, 155, 135, 135, 135],
    [150, 180, 175, 155, 140, 140],
    [155, 195, 195, 175, 150, 150],
    [165, 205, 210, 185, 160, 160],
    [170, 220, 220, 195, 170, 170],
    [180, 230, 235, 205, 180, 180],
    [185, 240, 245, 215, 190, 190],
    [195, 250, 260, 225, 195, 195],
    [200, 265, 270, 230, 205, 205],
    [210, 275, 285, 240, 210, 210],
    [215, 285, 295, 250, 220, 220],
    [220, 295, 305, 260, 230, 230],
    [225, 305, 315, 270, 235, 235],
    [225, 310, 330, 275, 245, 245],
    [230, 320, 340, 285, 250, 250],
    [235, 330, 350, 295, 260, 260],
    [250, 345, 370, 305, 270, 270],
    [265, 355, 385, 315, 285, 285],
    [280, 370, 405, 330, 295, 295],
    [295, 380, 420, 340, 310, 310],
    [310, 395, 440, 350, 320, 320],
    [315, 400, 450, 360, 330, 330],
    [315, 410, 460, 365, 335, 335],
    [320, 415, 470, 375, 345, 345],
    [320, 425, 480, 380, 350, 350],
    [325, 430, 490, 390, 360, 360],
    [330, 435, 500, 400, 370, 370],
    [335, 440, 510, 405, 375, 375],
    [335, 450, 525, 415, 385, 385],
    [340, 455, 535, 420, 390, 390],
    [345, 460, 545, 430, 400, 400],
    [350, 470, 555, 440, 410, 410],
    [350, 475, 565, 450, 415, 415],
    [350, 480, 575, 460, 420, 420],
    [355, 490, 585, 470, 430, 430],
    [365, 500, 595, 480, 430, 430],
    [370, 510, 605, 490, 435, 435],
    [375, 515, 615, 500, 440, 440],
    [385, 525, 625, 510, 450, 450],
    [390, 530, 635, 520, 455, 455],
    [395, 540, 645, 530, 460, 460],
    [400, 550, 655, 540, 470, 465],
    [405, 555, 665, 550, 475, 475],
    [415, 565, 675, 555, 485, 480],
    [420, 570, 685, 565, 490, 490],
    [425, 580, 695, 575, 500, 495],
    [430, 590, 705, 585, 505, 500],
    [435, 595, 715, 595, 515, 510],
    [445, 605, 720, 600, 520, 515],
    [450, 610, 730, 610, 530, 525],
    [455, 620, 740, 620, 535, 530],
  ];

  static String kgLabel(int kg) => '$kg kg';

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
    final clamped = months.clamp(1, 18);
    for (var i = 0; i < ageColumns.length; i++) {
      if (ageColumns[i].covers(clamped)) return i;
    }
    return 1;
  }

  static int kgIndexOf(double kg) {
    final clamped = kg.round().clamp(kgRows.first, kgRows.last);
    return clamped - 1;
  }

  static int _rawCell(int kgIndex, int colIndex) {
    final key = cellKey(kgLabel(kgRows[kgIndex]), ageColumns[colIndex].label);
    final override = gramsOverride[key];
    if (override != null && override > 0) return override;
    return table[kgIndex][colIndex];
  }

  static int gramsAt({required double kg, required int months}) {
    final kgIndex = kgIndexOf(kg);
    final colIndex = columnIndexForMonth(months);
    return _rawCell(kgIndex, colIndex);
  }

  static int? dailyGramsFor({
    String? weightLabel,
    int? months,
    String? ageLabel,
    String? activityLevel,
    String? bodyType,
    String? neutered,
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
      neutered: neutered,
      extraFood: extraFood,
    );
  }

  static int finalizeGrams({
    required int baseGrams,
    String? activityLevel,
    String? bodyType,
    String? neutered,
    String? extraFood,
  }) {
    if (baseGrams <= 0) return 0;
    final raw = baseGrams *
        neuteredFactor(neutered) *
        activityFactor(activityLevel) *
        bodyFactor(bodyType) *
        extraFoodFactor(extraFood);
    return raw.round().clamp(1, 2500);
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
    for (final col in ageColumns.reversed) {
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
