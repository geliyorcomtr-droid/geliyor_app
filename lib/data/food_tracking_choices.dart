import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/feeding_scale.dart';
import 'package:geliyor_app/data/feeding_variant.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/state/pet_store.dart';

class FoodTrackingMatch {
  const FoodTrackingMatch({
    required this.id,
    required this.label,
    this.variant,
    bool? isPuppy,
    bool? isMiniBreed,
  })  : _isPuppy = isPuppy,
        _isMiniBreed = isMiniBreed;

  final String id;
  final String label;
  final FeedingVariant? variant;
  final bool? _isPuppy;
  final bool? _isMiniBreed;

  bool get isPuppy => variant?.isPuppy ?? _isPuppy ?? false;

  bool get isMiniBreed => variant?.isMini ?? _isMiniBreed ?? false;

  bool get isDog => variant?.isDog ?? false;
}

/// Mama takibi seçenekleri.
///
/// - Standart / seçim yok → sistem kedi-köpek tablosu
/// - Admin’de gramajı girilmiş marka → o markanın tablosu ve mini görseli
/// - Aynı markada dolu her tablo ayrı seçenek olur (yetişkin kedi, yavru kedi…)
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

  /// Siparişteki üründen marka + ürün kategorisine göre tablo.
  static FoodTrackingMatch resolveFromProduct({
    String? brandName,
    String? title,
    String? subtitle,
    String? category,
    String? mainCategory,
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
    final variant = FeedingVariant.fromProduct(
      mainCategory: mainCategory,
      category: category,
      brandName: brandName,
      title: title,
      subtitle: subtitle,
    );
    if (isStandard(id)) {
      return FoodTrackingMatch(
        id: standardId,
        label: standardLabel,
        variant: variant,
        isPuppy: variant.isPuppy,
        isMiniBreed: variant.isMini,
      );
    }
    final brand = _brandById(source, id) ?? BrandRepository.instance.byId(id);
    final picks = picksFor(brand);
    for (final pick in picks) {
      if (pick.variant == variant) return pick;
    }
    for (final pick in picks) {
      if (pick.isPuppy == variant.isPuppy && pick.isMiniBreed == variant.isMini) {
        return pick;
      }
    }
    if (picks.isNotEmpty) return picks.first;
    return FoodTrackingMatch(
      id: id,
      label: variant.displayName(brand?.name ?? labelOf(id, brands: source)),
      variant: variant,
      isPuppy: variant.isPuppy,
      isMiniBreed: variant.isMini,
    );
  }

  /// Markanın dolu tüketim tabloları — her biri ayrı seçenek.
  static List<FoodTrackingMatch> picksFor(AppBrand? brand) {
    if (brand == null) return const [];
    final feeding = brand.trackingFeeding;
    if (feeding.isEmpty) return const [];
    return [
      for (final variant in FeedingVariant.values)
        if (feeding.hasVariant(variant))
          FoodTrackingMatch(
            id: brand.id,
            label: variant.displayName(brand.name),
            variant: variant,
            isPuppy: variant.isPuppy,
            isMiniBreed: variant.isMini,
          ),
    ];
  }

  /// Markaya özel günlük gram. Tablo yoksa `null` → standart hesap.
  /// Admin değeri standarttır; dostun kilo/yaş/aktivitesi ile ölçeklenir.
  static int? brandDailyGrams({
    required String foodId,
    required PetData pet,
    PetLifeStageProfile? profile,
    bool? foodIsPuppy,
    bool? foodIsMini,
    FeedingVariant? variant,
  }) {
    if (isStandard(foodId)) return null;
    final brand = BrandRepository.instance.byId(foodId);
    if (brand == null) return null;
    final feeding = brand.trackingFeeding;
    if (feeding.isEmpty) return null;
    final isDog = variant?.isDog ??
        (pet.species.toLowerCase().contains('köpek') ||
            pet.species.toLowerCase().contains('kopek'));
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
    final table = variant ??
        FeedingVariant.resolve(
          isDog: isDog,
          isPuppy: life.isPuppy,
          isMiniBreed: life.isMiniBreed,
        );
    final standard = feeding.dailyGramsFor(
      isDog: table.isDog,
      isPuppy: table.isPuppy,
      isMiniBreed: table.isMini,
      variant: table,
      weightLabel: pet.weight,
      sizeLabel: table.isMini ? 'Mini' : pet.ageRange,
      ageMonths: life.ageMonths,
    );
    if (standard == null || standard <= 0) return null;
    return FeedingScale.apply(
      standardGrams: standard,
      pet: pet,
      variant: table,
    );
  }

  static AppBrand? _brandById(List<AppBrand> brands, String id) {
    for (final brand in brands) {
      if (brand.id == id) return brand;
    }
    return null;
  }
}
