import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_factors.dart';
import 'package:geliyor_app/data/kitten_feeding_guide.dart';
import 'package:geliyor_app/data/mini_adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/mini_puppy_feeding_guide.dart';
import 'package:geliyor_app/data/pet_consumption.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/data/standard_puppy_feeding_guide.dart';
import 'package:geliyor_app/state/pet_store.dart';

PetData _pet({
  required String species,
  required String ageRange,
  required String weight,
  String? activityLevel,
  String? bodyType,
  String? neutered,
  String? extraFood,
}) {
  return PetData(
    name: 'Test',
    species: species,
    ageRange: ageRange,
    weight: weight,
    activityLevel: activityLevel,
    bodyType: bodyType,
    neutered: neutered,
    extraFood: extraFood,
  );
}

void main() {
  setUp(() {
    CatFeedingGuide.gramsOverride = const {};
    CatFeedingGuide.factors = FeedingFactors.defaults;
    KittenFeedingGuide.gramsOverride = const {};
    AdultDogFeedingGuide.gramsOverride = const {};
    AdultDogFeedingGuide.factors = MiniAdultDogFactors.defaults;
    MiniAdultDogFeedingGuide.gramsOverride = const {};
    MiniAdultDogFeedingGuide.factors = MiniAdultDogFactors.defaults;
    MiniPuppyFeedingGuide.gramsOverride = const {};
    MiniPuppyFeedingGuide.factors = MiniPuppyFactors.defaults;
    StandardPuppyFeedingGuide.gramsOverride = const {};
    StandardPuppyFeedingGuide.factors = StandardPuppyFactors.defaults;
  });

  test('yetişkin kedi uses Excel kg × factors', () {
    expect(
      PetConsumption.dailyGrams(
        _pet(species: 'Kedi', ageRange: 'Yetişkin', weight: '4 kg'),
      ),
      55,
    );
  });

  test('yavru kedi uses kg × month', () {
    expect(
      PetConsumption.dailyGrams(
        _pet(species: 'Kedi', ageRange: 'Yavru · 4 ay', weight: '2 kg'),
      ),
      65,
    );
  });

  test('yetişkin köpek uses 1–60 kg table', () {
    expect(
      PetConsumption.dailyGrams(
        _pet(species: 'Köpek', ageRange: 'Köpek', weight: '20 kg'),
      ),
      270,
    );
  });

  test('köpek yavru uses kg × Excel age band including 13-18 ay', () {
    expect(
      PetConsumption.dailyGrams(
        _pet(
          species: 'Köpek',
          ageRange: 'Köpek Yavru · 4-5 ay',
          weight: '20 kg',
        ),
      ),
      285,
    );
    expect(
      PetConsumption.dailyGrams(
        _pet(
          species: 'Köpek',
          ageRange: 'Köpek Yavru · 16-18 ay',
          weight: '30 kg',
        ),
      ),
      320,
    );
  });

  test('mini ırk yetişkin uses 1–10 kg table', () {
    expect(
      PetConsumption.dailyGrams(
        _pet(
          species: 'Köpek',
          ageRange: 'Mini Irk Yetişkin',
          weight: '5 kg',
        ),
      ),
      94,
    );
  });

  test('mini ırk yavru uses hedef kg × age band', () {
    expect(
      PetConsumption.dailyGrams(
        _pet(
          species: 'Köpek',
          ageRange: 'Mini Irk Yavru · 4-5 ay',
          weight: '5 kg',
        ),
      ),
      95,
    );
  });

  test('13-18 ay label is still a puppy', () {
    expect(
      PetLifeStage.inferIsPuppy(ageRange: 'Köpek Yavru · 16-18 ay'),
      isTrue,
    );
    expect(PetLifeStage.monthsFromLabel('Köpek Yavru · 16-18 ay'), 18);
  });
}
