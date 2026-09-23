import 'package:geliyor_app/data/adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/kitten_feeding_guide.dart';
import 'package:geliyor_app/data/mini_adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/mini_puppy_feeding_guide.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/data/standard_puppy_feeding_guide.dart';
import 'package:geliyor_app/state/pet_store.dart';

/// Dost profiline göre günlük kuru mama (g).
abstract final class PetConsumption {
  static bool isDog(PetData pet) {
    final species = pet.species.toLowerCase();
    return species.contains('köpek') || species.contains('kopek');
  }

  static int? dailyGrams(PetData pet) {
    final puppy = PetLifeStage.inferIsPuppy(ageRange: pet.ageRange);
    final mini = PetLifeStage.inferIsMini(ageRange: pet.ageRange);
    final months = PetLifeStage.monthsFromLabel(pet.ageRange) ?? 4;
    if (isDog(pet)) {
      if (puppy) {
        if (mini) {
          return MiniPuppyFeedingGuide.dailyGramsFor(
            weightLabel: pet.weight,
            months: MiniPuppyFeedingGuide.monthsFromAgeLabel(pet.ageRange) ??
                months,
            ageLabel: pet.ageRange,
            activityLevel: pet.activityLevel,
            bodyType: pet.bodyType,
            extraFood: pet.extraFood,
          );
        }
        return StandardPuppyFeedingGuide.dailyGramsFor(
          weightLabel: pet.weight,
          months: StandardPuppyFeedingGuide.monthsFromAgeLabel(pet.ageRange) ??
              months,
          ageLabel: pet.ageRange,
          activityLevel: pet.activityLevel,
          bodyType: pet.bodyType,
          neutered: pet.neutered,
          extraFood: pet.extraFood,
        );
      }
      if (mini) {
        return MiniAdultDogFeedingGuide.dailyGramsFor(
          weightLabel: pet.weight,
          activityLevel: pet.activityLevel,
          bodyType: pet.bodyType,
          neutered: pet.neutered,
          extraFood: pet.extraFood,
        );
      }
      return AdultDogFeedingGuide.dailyGramsFor(
        weightLabel: pet.weight,
        activityLevel: pet.activityLevel,
        bodyType: pet.bodyType,
        neutered: pet.neutered,
        extraFood: pet.extraFood,
      );
    }
    if (puppy) {
      return KittenFeedingGuide.dailyGramsFor(
        weightLabel: pet.weight,
        months: months,
      );
    }
    return CatFeedingGuide.dailyGramsFor(
      weightLabel: pet.weight,
      bodyType: pet.bodyType,
      activityLevel: pet.activityLevel,
      neutered: pet.neutered,
      extraFood: pet.extraFood,
    );
  }
}
