import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';

/// Admin’in marka bazında girdiği günlük tüketim (g/gün).
///
/// Boş tablo → standart kedi/köpek rehberi kullanılır.
class BrandFeedingGuide {
  const BrandFeedingGuide({
    this.catGrams = const {},
    this.dogGrams = const {},
  });

  /// Kedi: kilo anahtarı (`2.0`, `4.5`) → gram.
  final Map<String, int> catGrams;

  /// Köpek: beden (`X-Small`, `Mini`, `Medium`, `Maxi`, `Giant`) → gram.
  final Map<String, int> dogGrams;

  static const empty = BrandFeedingGuide();

  bool get isEmpty => !hasCat && !hasDog;

  bool get hasCat => catGrams.values.any((grams) => grams > 0);

  bool get hasDog => dogGrams.values.any((grams) => grams > 0);

  int filledCatCount() =>
      catGrams.values.where((grams) => grams > 0).length;

  int filledDogCount() =>
      dogGrams.values.where((grams) => grams > 0).length;

  factory BrandFeedingGuide.fromFirestore(dynamic catRaw, dynamic dogRaw) {
    return BrandFeedingGuide(
      catGrams: _gramsMap(catRaw),
      dogGrams: _gramsMap(dogRaw),
    );
  }

  Map<String, int> toCatMap() => _positiveOnly(catGrams);

  Map<String, int> toDogMap() => _positiveOnly(dogGrams);

  int? dailyGramsFor({
    required bool isDog,
    String? weightLabel,
    String? sizeLabel,
  }) {
    if (isDog) return dogGramsForSize(sizeLabel);
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

  static List<double> get catKgRows => [
        for (final row in CatFeedingGuide.rows) row.catKg,
      ];

  static List<String> get dogSizeRows => [
        for (final row in DogFeedingGuide.rows) row.size,
      ];
}
