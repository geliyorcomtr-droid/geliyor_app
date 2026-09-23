import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_variant.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/state/pet_store.dart';

/// Admin gramajı İdeal + Orta bazdır. Dostun kilo / beden satırı seçildikten
/// sonra vücut tipi, aktivite ve yaş grubu ile çarpılır.
abstract final class FeedingScale {
  static int apply({
    required int standardGrams,
    required PetData pet,
    required FeedingVariant variant,
  }) {
    if (standardGrams <= 0) return 0;
    final scaled =
        (standardGrams * factor(pet: pet, variant: variant)).round();
    return scaled.clamp(1, 2500);
  }

  static double factor({
    required PetData pet,
    required FeedingVariant variant,
  }) {
    final age = ageFactor(pet.ageRange, variant);
    if (variant.isDog) return activityDog(pet) * age;
    if (variant.isPuppy) return kittenAdjust(pet) * age;
    return catBodyActivity(pet) * age;
  }

  /// Yetişkin kedi: seçilen hücrenin İdeal+Orta’ya oranı.
  static double catBodyActivity(PetData pet) {
    return CatFeedingGuide.bodyFactor(pet.bodyType) *
        CatFeedingGuide.activityFactor(pet.activityLevel);
  }

  /// Yavru tabloda vücut/aktivite kolonu yok; yetişkin oranının sade hali.
  static double kittenAdjust(PetData pet) {
    final body = CatFeedingGuide.normalizeBody(pet.bodyType);
    final activity = CatFeedingGuide.normalizeActivity(pet.activityLevel);
    final bodyFactor = switch (body) {
      'Zayıf' => 1.10,
      'Kilolu' => 0.90,
      _ => 1.0,
    };
    final activityFactor = switch (activity) {
      'Düşük' => 0.92,
      'Yüksek' => 1.12,
      _ => 1.0,
    };
    return bodyFactor * activityFactor;
  }

  static double activityDog(PetData pet) {
    final row = DogFeedingGuide.fromSizeLabel(pet.ageRange) ??
        DogFeedingGuide.fromSizeLabel(
          PetLifeStage.inferIsMini(ageRange: pet.ageRange) ? 'Mini' : 'Medium',
        );
    if (row == null) return 1;
    final mid = row.gramsFor('Orta');
    if (mid <= 0) return 1;
    return row.gramsFor(pet.activityLevel) / mid;
  }

  /// Yavru tabloda ay zaten seçilir; yaş çarpanı yalnızca yetişkine uygulanır.
  static double ageFactor(String? ageRange, FeedingVariant variant) {
    if (variant.isPuppy) return 1;
    return 1;
  }
}
