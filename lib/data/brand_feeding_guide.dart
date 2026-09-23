import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_variant.dart';
import 'package:geliyor_app/data/kitten_feeding_guide.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/data/pro_plan_mini_puppy_guide.dart';
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
    this.dogMiniPuppyCells = const {},
  });

  /// Kedi yetişkin: kilo anahtarı (`2.0`, `4.5`) → gram.
  final Map<String, int> catGrams;

  /// Köpek yetişkin: beden (`X-Small`, `Mini`, `Medium`, `Maxi`, `Giant`) → gram.
  final Map<String, int> dogGrams;

  /// Yavru kedi: ay anahtarı (`2`, `6`) → gram.
  final Map<String, int> catKittenGrams;

  /// Yavru köpek (standart ırk): ay → gram.
  final Map<String, int> dogPuppyGrams;

  /// Mini ırk yavru köpek (eski): ay → gram.
  final Map<String, int> dogMiniPuppyGrams;

  /// Mini ırk yavru: beklenen yetişkin kg → yaş bandı → gram/aralık.
  final Map<String, Map<String, String>> dogMiniPuppyCells;

  static const empty = BrandFeedingGuide();

  bool get isEmpty =>
      !hasCat && !hasDog && !hasCatKitten && !hasDogPuppy && !hasDogMiniPuppy;

  bool get hasCat => catGrams.values.any((grams) => grams > 0);

  bool get hasDog => dogGrams.values.any((grams) => grams > 0);

  bool get hasDogAdult => _hasDogSizes(dogAdultSizes);

  bool get hasDogMiniAdult => _hasDogSizes(dogMiniAdultSizes);

  bool get hasCatKitten => catKittenGrams.values.any((grams) => grams > 0);

  bool get hasDogPuppy => dogPuppyGrams.values.any((grams) => grams > 0);

  bool get hasDogMiniPuppy =>
      hasMiniPuppyTable ||
      dogMiniPuppyGrams.values.any((grams) => grams > 0);

  bool get hasMiniPuppyTable => dogMiniPuppyCells.values.any(
        (row) => row.values.any((cell) => ProPlanMiniPuppyGuide.parseCell(cell) > 0),
      );

  bool hasVariant(FeedingVariant variant) => switch (variant) {
        FeedingVariant.catAdult => hasCat,
        FeedingVariant.catKitten => hasCatKitten,
        FeedingVariant.dogAdult => hasDogAdult,
        FeedingVariant.dogMiniAdult => hasDogMiniAdult,
        FeedingVariant.dogPuppy => hasDogPuppy,
        FeedingVariant.dogMiniPuppy => hasDogMiniPuppy,
      };

  List<FeedingVariant> get filledVariants => [
        for (final variant in FeedingVariant.values)
          if (hasVariant(variant)) variant,
      ];

  int filledCountFor(FeedingVariant variant) => switch (variant) {
        FeedingVariant.catAdult => filledCatCount(),
        FeedingVariant.catKitten => filledCatKittenCount(),
        FeedingVariant.dogAdult => _filledDogSizeCount(dogAdultSizes),
        FeedingVariant.dogMiniAdult => _filledDogSizeCount(dogMiniAdultSizes),
        FeedingVariant.dogPuppy =>
          dogPuppyGrams.values.where((grams) => grams > 0).length,
        FeedingVariant.dogMiniPuppy => filledMiniPuppyCount(),
      };

  bool _hasDogSizes(List<String> sizes) => dogGrams.entries.any(
        (entry) => sizes.contains(entry.key) && entry.value > 0,
      );

  int _filledDogSizeCount(List<String> sizes) => dogGrams.entries
      .where((entry) => sizes.contains(entry.key) && entry.value > 0)
      .length;

  BrandFeedingGuide copyWith({
    Map<String, int>? catGrams,
    Map<String, int>? dogGrams,
    Map<String, int>? catKittenGrams,
    Map<String, int>? dogPuppyGrams,
    Map<String, int>? dogMiniPuppyGrams,
    Map<String, Map<String, String>>? dogMiniPuppyCells,
  }) {
    return BrandFeedingGuide(
      catGrams: catGrams ?? this.catGrams,
      dogGrams: dogGrams ?? this.dogGrams,
      catKittenGrams: catKittenGrams ?? this.catKittenGrams,
      dogPuppyGrams: dogPuppyGrams ?? this.dogPuppyGrams,
      dogMiniPuppyGrams: dogMiniPuppyGrams ?? this.dogMiniPuppyGrams,
      dogMiniPuppyCells: dogMiniPuppyCells ?? this.dogMiniPuppyCells,
    );
  }

  BrandFeedingGuide replacing(
    FeedingVariant variant, {
    Map<String, int>? grams,
    Map<String, Map<String, String>>? cells,
  }) {
    final next = grams ?? const <String, int>{};
    return switch (variant) {
      FeedingVariant.catAdult => copyWith(catGrams: next),
      FeedingVariant.catKitten => copyWith(catKittenGrams: next),
      FeedingVariant.dogAdult => copyWith(
          dogGrams: _replaceSizes(dogGrams, next, dogAdultSizes),
        ),
      FeedingVariant.dogMiniAdult => copyWith(
          dogGrams: _replaceSizes(dogGrams, next, dogMiniAdultSizes),
        ),
      FeedingVariant.dogPuppy => copyWith(dogPuppyGrams: next),
      FeedingVariant.dogMiniPuppy => copyWith(
          dogMiniPuppyCells: cells ?? const {},
          dogMiniPuppyGrams: const {},
        ),
    };
  }

  static Map<String, int> _replaceSizes(
    Map<String, int> existing,
    Map<String, int> incoming,
    List<String> sizes,
  ) {
    final out = <String, int>{};
    existing.forEach((key, value) {
      if (!sizes.contains(key) && value > 0) out[key] = value;
    });
    incoming.forEach((key, value) {
      if (sizes.contains(key) && value > 0) out[key] = value;
    });
    return out;
  }

  int filledCatCount() =>
      catGrams.values.where((grams) => grams > 0).length;

  int filledDogCount() =>
      dogGrams.values.where((grams) => grams > 0).length;

  int filledCatKittenCount() =>
      catKittenGrams.values.where((grams) => grams > 0).length;

  int filledDogPuppyCount() =>
      dogPuppyGrams.values.where((grams) => grams > 0).length +
      filledMiniPuppyCount();

  int filledMiniPuppyCount() {
    if (hasMiniPuppyTable) {
      var count = 0;
      dogMiniPuppyCells.forEach((_, row) {
        for (final cell in row.values) {
          if (ProPlanMiniPuppyGuide.parseCell(cell) > 0) count++;
        }
      });
      return count;
    }
    return dogMiniPuppyGrams.values.where((grams) => grams > 0).length;
  }

  factory BrandFeedingGuide.fromFirestore(
    dynamic catRaw,
    dynamic dogRaw, [
    dynamic catKittenRaw,
    dynamic dogPuppyRaw,
    dynamic dogMiniPuppyRaw,
  ]) {
    final miniCells = _cellTable(dogMiniPuppyRaw);
    return BrandFeedingGuide(
      catGrams: _gramsMap(catRaw),
      dogGrams: _gramsMap(dogRaw),
      catKittenGrams: _gramsMap(catKittenRaw),
      dogPuppyGrams: _gramsMap(dogPuppyRaw),
      dogMiniPuppyGrams: miniCells.isEmpty ? _gramsMap(dogMiniPuppyRaw) : const {},
      dogMiniPuppyCells: miniCells,
    );
  }

  Map<String, int> toCatMap() => _positiveOnly(catGrams);

  Map<String, int> toDogMap() => _positiveOnly(dogGrams);

  Map<String, int> toCatKittenMap() => _positiveOnly(catKittenGrams);

  Map<String, int> toDogPuppyMap() => _positiveOnly(dogPuppyGrams);

  Map<String, dynamic> toDogMiniPuppyMap() {
    if (hasMiniPuppyTable) {
      return {
        for (final entry in dogMiniPuppyCells.entries)
          if (entry.value.values.any(
            (cell) => ProPlanMiniPuppyGuide.parseCell(cell) > 0,
          ))
            entry.key: {
              for (final cell in entry.value.entries)
                if (cell.value.trim().isNotEmpty) cell.key: cell.value.trim(),
            },
      };
    }
    return _positiveOnly(dogMiniPuppyGrams);
  }

  int? dailyGramsFor({
    required bool isDog,
    bool isPuppy = false,
    bool isMiniBreed = false,
    FeedingVariant? variant,
    String? weightLabel,
    String? sizeLabel,
    int? ageMonths,
  }) {
    final table = variant ??
        FeedingVariant.resolve(
          isDog: isDog,
          isPuppy: isPuppy,
          isMiniBreed: isMiniBreed,
        );
    return switch (table) {
      FeedingVariant.catAdult => catGramsForWeight(weightLabel),
      FeedingVariant.catKitten =>
        monthGramsFor(catKittenGrams, ageMonths) ??
            catGramsForWeight(weightLabel),
      FeedingVariant.dogAdult => _lookupDogTable(sizeLabel, dogAdultSizes),
      FeedingVariant.dogMiniAdult =>
        dogGramsForSize('Mini') ??
            _lookupDogTable(sizeLabel, dogMiniAdultSizes),
      FeedingVariant.dogPuppy =>
        monthGramsFor(dogPuppyGrams, ageMonths) ??
            dogGramsForSize(sizeLabel),
      FeedingVariant.dogMiniPuppy =>
        miniPuppyGramsFor(
          weightLabel: weightLabel,
          sizeLabel: sizeLabel,
          ageMonths: ageMonths,
        ) ??
            monthGramsFor(dogMiniPuppyGrams, ageMonths) ??
            dogGramsForSize('Mini') ??
            dogGramsForSize(sizeLabel),
    };
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

  int? dogGramsForSize(String? sizeLabel, {List<String>? allowed}) {
    if (!hasDog) return null;
    final size = DogFeedingGuide.fromSizeLabel(sizeLabel)?.size;
    if (size == null) return null;
    if (allowed != null && !allowed.contains(size)) return null;
    for (final entry in dogGrams.entries) {
      if (entry.value <= 0) continue;
      if (allowed != null && !allowed.contains(entry.key)) continue;
      if (entry.key.toLowerCase() == size.toLowerCase()) return entry.value;
    }
    return null;
  }

  int? _lookupDogTable(String? sizeLabel, List<String> allowed) {
    final exact = dogGramsForSize(sizeLabel, allowed: allowed);
    if (exact != null) return exact;
    final size = DogFeedingGuide.fromSizeLabel(sizeLabel)?.size;
    if (size != null && allowed.contains(size)) return null;
    return dogGramsForSize(sizeLabel) ?? _firstFilledSize(allowed);
  }

  int? _firstFilledSize(List<String> sizes) {
    for (final size in sizes) {
      final grams = dogGrams[size];
      if (grams != null && grams > 0) return grams;
    }
    return null;
  }

  int? miniPuppyGramsFor({
    String? weightLabel,
    String? sizeLabel,
    int? ageMonths,
  }) {
    if (!hasMiniPuppyTable) return null;
    final kg = expectedAdultKg(weightLabel: weightLabel, sizeLabel: sizeLabel);
    final band = ProPlanMiniPuppyGuide.ageBandForMonths(ageMonths);
    final rowKey = closestMiniPuppyKgKey(kg);
    if (rowKey == null) return null;
    final grams = ProPlanMiniPuppyGuide.parseCell(
      dogMiniPuppyCells[rowKey]?[band],
    );
    return grams > 0 ? grams : null;
  }

  String? closestMiniPuppyKgKey(int kg) {
    String? bestKey;
    var bestDelta = 999;
    dogMiniPuppyCells.forEach((key, row) {
      if (row.values.every((cell) => ProPlanMiniPuppyGuide.parseCell(cell) <= 0)) {
        return;
      }
      final rowKg = int.tryParse(key) ?? double.tryParse(key)?.round();
      if (rowKg == null) return;
      final delta = (rowKg - kg).abs();
      if (delta < bestDelta) {
        bestDelta = delta;
        bestKey = key;
      }
    });
    return bestKey;
  }

  static int expectedAdultKg({String? weightLabel, String? sizeLabel}) {
    final fromWeight = CatFeedingGuide.kgFromLabel(weightLabel);
    if (fromWeight != null) {
      return fromWeight.round().clamp(1, 10);
    }
    final size = DogFeedingGuide.fromSizeLabel(sizeLabel)?.size;
    return switch (size) {
      'X-Small' => 3,
      'Mini' => 7,
      _ => 5,
    };
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
    if (raw.values.any((value) => value is Map)) return const {};
    final out = <String, int>{};
    raw.forEach((key, value) {
      final grams = ProPlanMiniPuppyGuide.parseCell(value);
      if (grams > 0) out['$key'] = grams;
    });
    return Map.unmodifiable(out);
  }

  static Map<String, Map<String, String>> _cellTable(dynamic raw) {
    if (raw is! Map) return const {};
    if (!raw.values.any((value) => value is Map)) return const {};
    final out = <String, Map<String, String>>{};
    raw.forEach((key, value) {
      if (value is! Map) return;
      final row = <String, String>{};
      value.forEach((band, cell) {
        final text = '$cell'.trim();
        if (text.isNotEmpty && ProPlanMiniPuppyGuide.parseCell(text) > 0) {
          row['$band'] = text;
        }
      });
      if (row.isNotEmpty) out['$key'] = Map.unmodifiable(row);
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

  static const dogAdultSizes = ['X-Small', 'Medium', 'Maxi', 'Giant'];

  static const dogMiniAdultSizes = ['Mini'];

  static List<int> get monthRows => PetLifeStage.monthOptions;

  static List<int> get kittenMonthRows => KittenFeedingGuide.monthRows;

  static List<int> get puppyMonthRows => PuppyFeedingGuide.monthRows;
}
