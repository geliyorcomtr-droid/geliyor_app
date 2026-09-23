import 'package:geliyor_app/data/feeding_factors.dart';

/// Yetişkin köpek kuru mama tüketimi (g/gün), 1–60 kg.
/// Formül: Baz × kısır × aktivite × vücut × ek gıda
class AdultDogFeedingRow {
  const AdultDogFeedingRow({
    required this.kg,
    required this.dailyGrams,
  });

  final int kg;
  final int dailyGrams;

  String get kgLabel => AdultDogFeedingGuide.kgLabel(kg);
}

abstract final class AdultDogFeedingGuide {
  static Map<String, int> gramsOverride = const {};
  static MiniAdultDogFactors factors = MiniAdultDogFactors.defaults;

  /// Excel: kilo → baz g/gün (normal aktivite, ideal vücut, kısır değil).
  static const List<int> _grams = [
    35, 50, 65, 80, 95, 110, 125, 135, 150, 160,
    170, 185, 195, 210, 220, 230, 240, 250, 260, 270,
    280, 290, 295, 305, 315, 325, 330, 340, 345, 355,
    365, 370, 380, 385, 395, 405, 410, 420, 425, 435,
    445, 450, 460, 465, 475, 480, 490, 495, 505, 510,
    515, 525, 530, 535, 540, 550, 555, 560, 570, 575,
  ];

  static List<AdultDogFeedingRow> get rows => [
        for (var i = 0; i < _grams.length; i++)
          AdultDogFeedingRow(kg: i + 1, dailyGrams: _grams[i]),
      ];

  static List<String> get weightLabels => [
        for (final row in rows) row.kgLabel,
      ];

  static Map<String, int> get defaultGrams => {
        for (final row in rows) row.kgLabel: row.dailyGrams,
      };

  static String kgLabel(int kg) => '$kg kg';

  static AdultDogFeedingRow lookup(double kg) {
    final clamped = kg.round().clamp(rows.first.kg, rows.last.kg);
    return rows[clamped - 1];
  }

  static String nearestWeightLabel(String? label) {
    final kg = kgFromLabel(label);
    if (kg == null) return weightLabels.first;
    return lookup(kg).kgLabel;
  }

  static int? dailyGramsFor({
    String? weightLabel,
    String? activityLevel,
    String? bodyType,
    String? neutered,
    String? extraFood,
  }) {
    final kg = kgFromLabel(weightLabel);
    if (kg == null) return null;
    final row = lookup(kg);
    final base = gramsOverride[row.kgLabel] ?? row.dailyGrams;
    if (base <= 0) return null;
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
