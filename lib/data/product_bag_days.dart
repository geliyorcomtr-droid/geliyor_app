import 'package:geliyor_app/data/adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_variant.dart';
import 'package:geliyor_app/data/kitten_feeding_guide.dart';
import 'package:geliyor_app/data/mini_adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/mini_puppy_feeding_guide.dart';
import 'package:geliyor_app/data/standard_puppy_feeding_guide.dart';

/// Paket kilosu × türün normal tüketim ortalaması → bir dosta kaç gün yeter.
abstract final class ProductBagDays {
  static const typicalCatKg = '4 kg';
  static const typicalKittenKg = '2 kg';
  static const typicalKittenMonths = 4;
  static const typicalDogKg = '20 kg';
  static const typicalPuppyKg = '20 kg';
  static const typicalPuppyMonths = 4;
  static const typicalMiniKg = '5 kg';
  static const typicalMiniPuppyKg = '5 kg';
  static const typicalMiniPuppyMonths = 4;

  static bool supportsMainCategory(String? mainCategory) {
    final main = (mainCategory ?? '').trim().toLowerCase();
    return main.isEmpty || main == 'cat' || main == 'dog';
  }

  static int? typicalDailyGrams(FeedingVariant variant) {
    return switch (variant) {
      FeedingVariant.catAdult => CatFeedingGuide.dailyGramsFor(
          weightLabel: typicalCatKg,
        ),
      FeedingVariant.catKitten => KittenFeedingGuide.dailyGramsFor(
          weightLabel: typicalKittenKg,
          months: typicalKittenMonths,
        ),
      FeedingVariant.dogAdult => AdultDogFeedingGuide.dailyGramsFor(
          weightLabel: typicalDogKg,
        ),
      FeedingVariant.dogPuppy => StandardPuppyFeedingGuide.dailyGramsFor(
          weightLabel: typicalPuppyKg,
          months: typicalPuppyMonths,
        ),
      FeedingVariant.dogMiniAdult => MiniAdultDogFeedingGuide.dailyGramsFor(
          weightLabel: typicalMiniKg,
        ),
      FeedingVariant.dogMiniPuppy => MiniPuppyFeedingGuide.dailyGramsFor(
          weightLabel: typicalMiniPuppyKg,
          months: typicalMiniPuppyMonths,
        ),
    };
  }

  static int? daysFor({
    String? mainCategory,
    String? category,
    String? weight,
    String? title,
    String? brand,
  }) {
    if (!supportsMainCategory(mainCategory)) return null;
    final bagKg = bagKgFromLabel(weight);
    if (bagKg == null || bagKg <= 0) return null;
    final variant = FeedingVariant.fromProduct(
      mainCategory: mainCategory,
      category: category,
      brandName: brand,
      title: title,
    );
    final daily = typicalDailyGrams(variant);
    if (daily == null || daily <= 0) return null;
    return ((bagKg * 1000) / daily).round().clamp(1, 9999);
  }

  static String storedValue({
    String? mainCategory,
    String? category,
    String? weight,
    String? title,
    String? brand,
  }) {
    final days = daysFor(
      mainCategory: mainCategory,
      category: category,
      weight: weight,
      title: title,
      brand: brand,
    );
    return days == null ? '' : '$days';
  }

  static String displayFor({
    String? mainCategory,
    String? category,
    String? weight,
    String? title,
    String? brand,
    String? stored,
  }) {
    final live = storedValue(
      mainCategory: mainCategory,
      category: category,
      weight: weight,
      title: title,
      brand: brand,
    );
    if (live.isNotEmpty) return live;
    if (looksLikeLegacyPercent(stored)) return '';
    return digits(stored);
  }

  static String digits(String? raw) {
    final value = (raw ?? '').replaceAll('%', '').trim();
    if (value.isEmpty) return '';
    final match = RegExp(r'\d+').firstMatch(value);
    return match?.group(0) ?? '';
  }

  static bool looksLikeLegacyPercent(String? raw) {
    return (raw ?? '').contains('%');
  }

  /// "2 Kg", "1,5kg", "400 g", "85g", "2".
  static double? bagKgFromLabel(String? text) {
    if (text == null) return null;
    final raw = text.trim().toLowerCase().replaceAll(',', '.');
    if (raw.isEmpty) return null;

    final gram = RegExp(r'(\d+(?:\.\d+)?)\s*g(?:ram)?\b').firstMatch(raw);
    final kilo = RegExp(r'(\d+(?:\.\d+)?)\s*kg').firstMatch(raw);
    if (gram != null && kilo == null) {
      final grams = double.tryParse(gram.group(1)!);
      if (grams == null || grams <= 0) return null;
      return grams / 1000;
    }
    if (kilo != null) {
      final kg = double.tryParse(kilo.group(1)!);
      if (kg == null || kg <= 0) return null;
      return kg;
    }

    final number = RegExp(r'(\d+(?:\.\d+)?)').firstMatch(raw);
    if (number == null) return null;
    final value = double.tryParse(number.group(1)!);
    if (value == null || value <= 0) return null;
    if (value >= 100) return value / 1000;
    return value;
  }
}
