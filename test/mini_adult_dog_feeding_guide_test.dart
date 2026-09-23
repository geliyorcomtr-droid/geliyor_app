import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/feeding_factors.dart';
import 'package:geliyor_app/data/mini_adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';

void main() {
  setUp(() {
    MiniAdultDogFeedingGuide.gramsOverride = const {};
    MiniAdultDogFeedingGuide.factors = MiniAdultDogFactors.defaults;
  });

  test('mini adult dog grams follow Excel kg rows', () {
    expect(
      MiniAdultDogFeedingGuide.dailyGramsFor(weightLabel: '1 kg'),
      36,
    );
    expect(
      MiniAdultDogFeedingGuide.dailyGramsFor(weightLabel: '5 kg'),
      94,
    );
    expect(
      MiniAdultDogFeedingGuide.dailyGramsFor(weightLabel: '10 kg'),
      158,
    );
  });

  test('add-pet label is Mini Irk Yetişkin', () {
    expect(PetLifeStage.petDogMini, 'Mini Irk Yetişkin');
    expect(PetLifeStage.dogTypeOptions, contains('Mini Irk Yetişkin'));
  });

  test('weight labels are 1–10 kg', () {
    expect(MiniAdultDogFeedingGuide.weightLabels.first, '1 kg');
    expect(MiniAdultDogFeedingGuide.weightLabels.last, '10 kg');
    expect(MiniAdultDogFeedingGuide.weightLabels.length, 10);
  });

  test('Excel çarpanları baz × kısır × aktivite × vücut × ek gıda', () {
    expect(
      MiniAdultDogFeedingGuide.dailyGramsFor(
        weightLabel: '5 kg',
        neutered: 'Evet',
        activityLevel: 'Düşük',
        bodyType: 'Zayıf',
        extraFood: 'Yaş mama',
      ),
      67,
    );
    expect(
      MiniAdultDogFeedingGuide.dailyGramsFor(
        weightLabel: '1 kg',
        neutered: 'Hayır',
        activityLevel: 'Çok yüksek',
        bodyType: 'Kilolu',
        extraFood: 'Her ikisi',
      ),
      31,
    );
  });
}
