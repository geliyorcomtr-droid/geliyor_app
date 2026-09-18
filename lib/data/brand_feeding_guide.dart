import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/data/kitten_feeding_guide.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/data/puppy_feeding_guide.dart';

/// Admin’in marka bazında girdiği günlük tüketim (g/gün).
///
/// Yetişkin kedi: kg. Yavru kedi: ay.
/// Yetişkin köpek: beden. Yavru köpek: ay (standart / mini ırk).
///
/// Boş tablo → standart kedi/köpek rehberi kullanılır.
class BrandFeedingGuide {
  const BrandFeedingGuide({
    this.catGrams = const {},
    this.dogGrams = const {},
    this.catKittenGrams = const {},
    this.dogPuppyGrams = const {},
    this.dogMiniPuppyGrams = const {},
  });

  /// Kedi yetişkin: kilo anahtarı (`2.0`, `4.5`) → gram.
  final Map<String, int> catGrams;

  /// Köpek yetişkin: beden (`X-Small`, `Mini`, `Medium`, `Maxi`, `Giant`) → gram.
  final Map<String, int> dogGrams;

  /// Yavru kedi: ay anahtarı (`2`, `6`) → gram.
  final Map<String, int> catKittenGrams;

  /// Yavru köpek (standart ırk): ay → gram.
  final Map<String, int> dogPuppyGrams;

  /// Mini ırk yavru köpek: ay → gram.
  final Map<String, int> dogMiniPuppyGrams;

  static const empty = BrandFeedingGuide();

  bool get isEmpty =>
      !hasCat && !hasDog && !hasCatKitten && !hasDogPuppy && !hasDogMiniPuppy;

  bool get hasCat => catGrams.values.any((grams) => grams > 0);

  bool get hasDog => dogGrams.values.any((grams) => grams > 0);

  bool get hasCatKitten => catKittenGrams.values.any((grams) => grams > 0);

  bool get hasDogPuppy => dogPuppyGrams.values.any((grams) => grams > 0);

  bool get hasDogMiniPuppy =>
      dogMiniPuppyGrams.values.any((grams) => grams > 0);

  int filledCatCount() =>
      catGrams.values.where((grams) => grams > 0).length;

  int filledDogCount() =>
      dogGrams.values.where((grams) => grams > 0).length;

  int filledCatKittenCount() =>
      catKittenGrams.values.where((grams) => grams > 0).length;

  int filledDogPuppyCount() =>
      dogPuppyGrams.values.where((grams) => grams > 0).length +
      dogMiniPuppyGrams.values.where((grams) => grams > 0).length;

  factory BrandFeedingGuide.fromFirestore(
    dynamic catRaw,
    dynamic dogRaw, [
    dynamic catKittenRaw,
    dynamic dogPuppyRaw,
    dynamic dogMiniPuppyRaw,
  ]) {
    return BrandFeedingGuide(
      catGrams: _gramsMap(catRaw),
      dogGrams: _gramsMap(dogRaw),
      catKittenGrams: _gramsMap(catKittenRaw),
      dogPuppyGrams: _gramsMap(dogPuppyRaw),
      dogMiniPuppyGrams: _gramsMap(dogMiniPuppyRaw),
    );
  }

  Map<String, int> toCatMap() => _positiveOnly(catGrams);

  Map<String, int> toDogMap() => _positiveOnly(dogGrams);

  Map<String, int> toCatKittenMap() => _positiveOnly(catKittenGrams);

  Map<String, int> toDogPuppyMap() => _positiveOnly(dogPuppyGrams);

  Map<String, int> toDogMiniPuppyMap() => _positiveOnly(dogMiniPuppyGrams);

  int? dailyGramsFor({
    required bool isDog,
    bool isPuppy = false,
    bool isMiniBreed = false,
    String? weightLabel,
    String? sizeLabel,
    int? ageMonths,
  }) {
    if (isPuppy) {
      if (isDog) {
        final puppy = monthGramsFor(
          isMiniBreed ? dogMiniPuppyGrams : dogPuppyGrams,
          ageMonths,
        );
        if (puppy != null) return puppy;
        if (isMiniBreed) {
          return dogGramsForSize('Mini') ?? dogGramsForSize(sizeLabel);
        }
        return dogGramsForSize(sizeLabel);
      }
      return monthGramsFor(catKittenGrams, ageMonths) ??
          catGramsForWeight(weightLabel);
    }
    if (isDog) {
      if (isMiniBreed) {
        return dogGramsForSize('Mini') ?? dogGramsForSize(sizeLabel);
      }
      return dogGramsForSize(sizeLabel);
    }
    return catGramsForWeight(weightLabel);
  }

  int? catGramsForWeight(String? weightLabel) {
    final key = closestCatKey(weightLabel);
    if (key == null) return null;
    final grams = catGrams[key];
    return grams != null && grams > 0 ? grams : null;
  }

  String? closestCatKey(String? weightLabel) {
    if (!hasCat) return null;
    final kg = CatFeedingGuide.kgFromLabel(weightLabel);
    if (kg == null) return null;
    String? bestKey;
    var bestDelta = double.infinity;
    catGrams.forEach((key, grams) {
      if (grams <= 0) return;
      final rowKg = double.tryParse(key.replaceAll(',', '.'));
      if (rowKg == null) return;
      final delta = (rowKg - kg).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        bestKey = key;
      }
    });
    return bestKey;
  }

  int? dogGramsForSize(String? sizeLabel) {
    if (!hasDog) return null;
    final size = DogFeedingGuide.fromSizeLabel(sizeLabel)?.size;
    if (size == null) return null;
    for (final entry in dogGrams.entries) {
      if (entry.value <= 0) continue;
      if (entry.key.toLowerCase() == size.toLowerCase()) return entry.value;
    }
    return null;
  }

  int? monthGramsFor(Map<String, int> source, int? months) {
    if (source.values.every((grams) => grams <= 0)) return null;
    final key = closestMonthKey(source, months);
    if (key == null) return null;
    final grams = source[key];
    return grams != null && grams > 0 ? grams : null;
  }

  String? closestMonthKey(Map<String, int> source, int? months) {
    if (months == null || months <= 0) return null;
    String? bestKey;
    var bestDelta = 999;
    source.forEach((key, grams) {
      if (grams <= 0) return;
      final rowMonths = int.tryParse(key);
      if (rowMonths == null) return;
      final delta = (rowMonths - months).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        bestKey = key;
      }
    });
    return bestKey;
  }

  static Map<String, int> _gramsMap(dynamic raw) {
    if (raw is! Map) return const {};
    final out = <String, int>{};
    raw.forEach((key, value) {
      final grams = value is num
          ? value.round()
          : int.tryParse('$value'.trim()) ?? 0;
      if (grams > 0) out['$key'] = grams;
    });
    return Map.unmodifiable(out);
  }

  static Map<String, int> _positiveOnly(Map<String, int> source) {
    return {
      for (final entry in source.entries)
        if (entry.value > 0) entry.key: entry.value,
    };
  }

  static String catKey(double kg) => kg.toStringAsFixed(1);

  static String monthKey(int months) => '$months';

  static List<double> get catKgRows => [
        for (final row in CatFeedingGuide.rows) row.catKg,
      ];

  static List<String> get dogSizeRows => [
        for (final row in DogFeedingGuide.rows) row.size,
      ];

  static List<int> get monthRows => PetLifeStage.monthOptions;

  static List<int> get kittenMonthRows => KittenFeedingGuide.monthRows;

  static List<int> get puppyMonthRows => PuppyFeedingGuide.monthRows;
}
