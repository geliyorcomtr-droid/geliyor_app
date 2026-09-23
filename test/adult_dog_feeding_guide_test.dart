import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_factors.dart';

void main() {
  setUp(() {
    AdultDogFeedingGuide.gramsOverride = const {};
    AdultDogFeedingGuide.factors = MiniAdultDogFactors.defaults;
  });

  test('adult dog grams follow Excel kg rows', () {
    expect(AdultDogFeedingGuide.dailyGramsFor(weightLabel: '1 kg'), 35);
    expect(AdultDogFeedingGuide.dailyGramsFor(weightLabel: '20 kg'), 270);
    expect(AdultDogFeedingGuide.dailyGramsFor(weightLabel: '60 kg'), 575);
  });

  test('weight labels are 1–60 kg', () {
    expect(AdultDogFeedingGuide.weightLabels.first, '1 kg');
    expect(AdultDogFeedingGuide.weightLabels.last, '60 kg');
    expect(AdultDogFeedingGuide.weightLabels.length, 60);
  });

  test('range labels map to midpoint kg', () {
    expect(
      AdultDogFeedingGuide.nearestWeightLabel('10-20 kg'),
      '15 kg',
    );
  });

  test('Excel çarpanları baz × kısır × aktivite × vücut × ek gıda', () {
    expect(
      AdultDogFeedingGuide.dailyGramsFor(
        weightLabel: '20 kg',
        neutered: 'Evet',
        activityLevel: 'Düşük',
        bodyType: 'Zayıf',
        extraFood: 'Yaş mama',
      ),
      193,
    );
  });
}
