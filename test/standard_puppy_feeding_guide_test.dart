import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/feeding_factors.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/data/standard_puppy_feeding_guide.dart';

void main() {
  setUp(() {
    StandardPuppyFeedingGuide.gramsOverride = const {};
    StandardPuppyFeedingGuide.factors = StandardPuppyFactors.defaults;
  });

  test('standard puppy grams follow Excel kg × age cells', () {
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '1 kg',
        ageLabel: '2-3 ay',
      ),
      35,
    );
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '20 kg',
        ageLabel: '4-5 ay',
      ),
      285,
    );
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '60 kg',
        ageLabel: '6-8 ay',
      ),
      740,
    );
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '30 kg',
        ageLabel: '16-18 ay',
      ),
      320,
    );
  });

  test('month number maps into Excel age bands', () {
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(weightLabel: '15 kg', months: 3),
      180,
    );
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(weightLabel: '15 kg', months: 5),
      230,
    );
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(weightLabel: '15 kg', months: 14),
      180,
    );
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(weightLabel: '15 kg', months: 18),
      180,
    );
  });

  test('range labels map to midpoint kg', () {
    expect(
      StandardPuppyFeedingGuide.nearestWeightLabel('10-20 kg'),
      '15 kg',
    );
  });

  test('çarpanlar baz × kısır × aktivite × vücut × ek gıda', () {
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '20 kg',
        ageLabel: '4-5 ay',
        neutered: 'Evet',
        activityLevel: 'Düşük',
        bodyType: 'Zayıf',
        extraFood: 'Yaş mama',
      ),
      228,
    );
  });

  test('add-pet label is Köpek Yavru with Excel month bands', () {
    expect(PetLifeStage.petDogPuppy, 'Köpek Yavru');
    expect(PetLifeStage.dogTypeOptions, contains('Köpek Yavru'));
    expect(StandardPuppyFeedingGuide.ageLabels, [
      '2-3 ay',
      '4-5 ay',
      '6-8 ay',
      '9-12 ay',
      '13-15 ay',
      '16-18 ay',
    ]);
  });

  test('persisted Köpek Yavru · 13-15 ay maps to 13-15 band', () {
    expect(
      StandardPuppyFeedingGuide.ageBandFromLabel('Köpek Yavru · 13-15 ay'),
      '13-15 ay',
    );
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '40 kg',
        ageLabel: 'Köpek Yavru · 13-15 ay',
      ),
      400,
    );
  });

  test('admin override wins over Excel', () {
    StandardPuppyFeedingGuide.gramsOverride = {
      StandardPuppyFeedingGuide.cellKey('1 kg', '2-3 ay'): 22,
    };
    expect(
      StandardPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '1 kg',
        ageLabel: '2-3 ay',
      ),
      22,
    );
  });
}
