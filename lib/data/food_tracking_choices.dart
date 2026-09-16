import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/state/pet_store.dart';

/// Mama takibi seçenekleri.
///
/// - Standart / seçim yok → sistem kedi-köpek tablosu
/// - Marka seçili ve admin gramaj girmiş → o markanın tablosu
/// - Marka seçili ama gramaj yok → standart tabloya düşer
abstract final class FoodTrackingChoice {
  static const standardId = 'standard';
  static const standardLabel = 'Standart mama';

  static bool isStandard(String? id) {
    final value = (id ?? '').trim();
    return value.isEmpty || value == standardId;
  }

  static String labelOf(String id, {List<AppBrand>? brands}) {
    if (isStandard(id)) return standardLabel;
    final source = brands ?? BrandRepository.instance.cached;
    for (final brand in source) {
      if (brand.id == id) return brand.name;
    }
    return BrandRepository.instance.byId(id)?.name ?? standardLabel;
  }

  static String idFromName(String name, [List<AppBrand>? brands]) {
    final needle = name.trim().toLowerCase();
    if (needle.isEmpty || needle == standardLabel.toLowerCase()) {
      return standardId;
    }
    final source = brands ?? BrandRepository.instance.cached;
    for (final brand in source) {
      if (brand.name.trim().toLowerCase() == needle) return brand.id;
    }
    return BrandRepository.instance.byName(name)?.id ?? standardId;
  }

  /// Siparişteki üründen marka id. Marka yoksa standart.
  static String resolveFromProduct({
    String? brandName,
    String? title,
    String? subtitle,
  }) {
    return BrandRepository.instance.idFromProduct(
          brandName: brandName,
          title: title,
          subtitle: subtitle,
        ) ??
        standardId;
  }

  /// Markaya özel günlük gram. Tablo yoksa `null` → standart hesap.
  static int? brandDailyGrams({
    required String foodId,
    required PetData pet,
  }) {
    if (isStandard(foodId)) return null;
    final brand = BrandRepository.instance.byId(foodId);
    if (brand == null || brand.feeding.isEmpty) return null;
    final isDog = pet.species.toLowerCase().contains('köpek') ||
        pet.species.toLowerCase().contains('kopek');
    return brand.feeding.dailyGramsFor(
      isDog: isDog,
      weightLabel: pet.weight,
      sizeLabel: pet.ageRange,
    );
  }
}
