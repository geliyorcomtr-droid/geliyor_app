import 'package:geliyor_app/data/feeding_factors.dart';

/// Mini ırk yetişkin köpek kuru mama tüketimi (g/gün).
/// Formül: Baz × kısır × aktivite × vücut × ek gıda
class MiniAdultDogFeedingRow {
  const MiniAdultDogFeedingRow({
    required this.kg,
    required this.dailyGrams,
  });

  final double kg;
  final int dailyGrams;

  String get kgLabel => MiniAdultDogFeedingGuide.kgLabel(kg);
}

abstract final class MiniAdultDogFeedingGuide {
  static Map<String, int> gramsOverride = const {};
  static MiniAdultDogFactors factors = MiniAdultDogFactors.defaults;

  static const List<MiniAdultDogFeedingRow> rows = [
    MiniAdultDogFeedingRow(kg: 1, dailyGrams: 36),
    MiniAdultDogFeedingRow(kg: 2, dailyGrams: 47),
    MiniAdultDogFeedingRow(kg: 3, dailyGrams: 64),
    MiniAdultDogFeedingRow(kg: 4, dailyGrams: 79),
    MiniAdultDogFeedingRow(kg: 5, dailyGrams: 94),
    MiniAdultDogFeedingRow(kg: 6, dailyGrams: 108),
    MiniAdultDogFeedingRow(kg: 7, dailyGrams: 122),
    MiniAdultDogFeedingRow(kg: 8, dailyGrams: 134),
    MiniAdultDogFeedingRow(kg: 9, dailyGrams: 146),
    MiniAdultDogFeedingRow(kg: 10, dailyGrams: 158),
  ];

  static List<String> get weightLabels => [
        for (final row in rows) row.kgLabel,
      ];

  static Map<String, int> get defaultGrams => {
        for (final row in rows) row.kgLabel: row.dailyGrams,
      };

  static String kgLabel(double kg) {
    if (kg == kg.roundToDouble()) return '${kg.toInt()} kg';
    return '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }

  static MiniAdultDogFeedingRow lookup(double kg) {
    final clamped = kg.clamp(rows.first.kg, rows.last.kg);
    var best = rows.first;
    var bestDelta = (best.kg - clamped).abs();
    for (final row in rows.skip(1)) {
      final delta = (row.kg - clamped).abs();
      if (delta < bestDelta) {
        best = row;
        bestDelta = delta;
      }
    }
    return best;
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
    if (v.contains('normal') || v.contains('orta')) {
      return factors.activityMid;
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
