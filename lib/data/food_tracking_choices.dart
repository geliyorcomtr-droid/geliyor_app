import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/state/pet_store.dart';

class FoodTrackingMatch {
  const FoodTrackingMatch({
    required this.id,
    required this.label,
    required this.isPuppy,
    this.isMiniBreed = false,
  });

  final String id;
  final String label;
  final bool isPuppy;
  final bool isMiniBreed;
}

/// Mama takibi seçenekleri.
///
/// - Standart / seçim yok → sistem kedi-köpek tablosu
/// - Admin’de gramajı girilmiş marka → o markanın tablosu ve mini görseli
/// - Aynı markada yetişkin + yavru gramaj varsa iki seçenek çıkar
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

  /// Siparişteki üründen marka + yavru/yetişkin. Marka yoksa standart.
  static FoodTrackingMatch resolveFromProduct({
    String? brandName,
    String? title,
    String? subtitle,
    String? category,
    List<AppBrand>? brands,
  }) {
    final source = brands ?? BrandRepository.instance.cached;
    final id = BrandRepository.matchId(
          source,
          brandName: brandName,
          title: title,
          subtitle: subtitle,
        ) ??
        standardId;
    final textPuppy = PetLifeStage.inferIsPuppyFromFood(
      brandName: brandName,
      title: title,
      subtitle: subtitle,
      category: category,
    );
    if (isStandard(id)) {
      return FoodTrackingMatch(
        id: standardId,
        label: standardLabel,
        isPuppy: textPuppy,
      );
    }
    final brand = _brandById(source, id) ?? BrandRepository.instance.byId(id);
    final picks = picksFor(brand);
    if (picks.length == 1) return picks.first;
    for (final pick in picks) {
      if (pick.isPuppy == textPuppy) return pick;
    }
    return picks.isEmpty
        ? FoodTrackingMatch(
            id: id,
            label: brand?.name ?? labelOf(id, brands: source),
            isPuppy: textPuppy || PetLifeStage.isPuppyTitle(brand?.name ?? ''),
          )
        : picks.first;
  }

  /// Markanın yetişkin / yavru tüketim seçenekleri.
  static List<FoodTrackingMatch> picksFor(AppBrand? brand) {
    if (brand == null || brand.feeding.isEmpty) return const [];
    final namePuppy = PetLifeStage.isPuppyTitle(brand.name);
    final hasAdult = brand.feeding.hasCat || brand.feeding.hasDog;
    final hasPuppy = brand.feeding.hasCatKitten ||
        brand.feeding.hasDogPuppy ||
        brand.feeding.hasDogMiniPuppy;
    final picks = <FoodTrackingMatch>[];
    if (hasAdult && !namePuppy) {
      picks.add(
        FoodTrackingMatch(
          id: brand.id,
          label: brand.name,
          isPuppy: false,
        ),
      );
    }
    if (hasPuppy || namePuppy) {
      picks.add(
        FoodTrackingMatch(
          id: brand.id,
          label: namePuppy ? brand.name : '${brand.name} Yavru',
          isPuppy: true,
          isMiniBreed: brand.feeding.hasDogMiniPuppy &&
              !brand.feeding.hasDogPuppy &&
              !brand.feeding.hasDog,
        ),
      );
    }
    if (picks.isEmpty) {
      picks.add(
        FoodTrackingMatch(
          id: brand.id,
          label: brand.name,
          isPuppy: namePuppy,
        ),
      );
    }
    return picks;
  }

  /// Markaya özel günlük gram. Tablo yoksa `null` → standart hesap.
  static int? brandDailyGrams({
    required String foodId,
    required PetData pet,
    PetLifeStageProfile? profile,
    bool? foodIsPuppy,
    bool? foodIsMini,
  }) {
    if (isStandard(foodId)) return null;
    final brand = BrandRepository.instance.byId(foodId);
    if (brand == null || brand.feeding.isEmpty) return null;
    final isDog = pet.species.toLowerCase().contains('köpek') ||
        pet.species.toLowerCase().contains('kopek');
    final inferred = PetLifeStageProfile(
      isPuppy: PetLifeStage.inferIsPuppy(ageRange: pet.ageRange),
      isMiniBreed: PetLifeStage.inferIsMini(ageRange: pet.ageRange),
      ageMonths: PetLifeStage.monthsFromLabel(pet.ageRange) ?? 4,
    );
    final life = PetLifeStageProfile(
      isPuppy: foodIsPuppy ?? profile?.isPuppy ?? inferred.isPuppy,
      isMiniBreed: foodIsMini ?? profile?.isMiniBreed ?? inferred.isMiniBreed,
      ageMonths: profile?.ageMonths ?? inferred.ageMonths,
    );
    return brand.feeding.dailyGramsFor(
      isDog: isDog,
      isPuppy: life.isPuppy,
      isMiniBreed: life.isMiniBreed,
      weightLabel: pet.weight,
      sizeLabel: pet.ageRange,
      ageMonths: life.ageMonths,
    );
  }

  static AppBrand? _brandById(List<AppBrand> brands, String id) {
    for (final brand in brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }
}
