import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/feeding_factors.dart';
import 'package:geliyor_app/data/mini_puppy_feeding_guide.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';

void main() {
  setUp(() {
    MiniPuppyFeedingGuide.gramsOverride = const {};
    MiniPuppyFeedingGuide.factors = MiniPuppyFactors.defaults;
  });

  test('mini puppy grams follow Excel kg × age cells', () {
    expect(
      MiniPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '1 kg',
        ageLabel: '2-3 ay',
      ),
      40,
    );
    expect(
      MiniPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '5 kg',
        ageLabel: '4-5 ay',
      ),
      95,
    );
    expect(
      MiniPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '10 kg',
        ageLabel: '9-12 ay',
      ),
      135,
    );
  });

  test('month number maps into Excel age bands', () {
    expect(
      MiniPuppyFeedingGuide.dailyGramsFor(weightLabel: '4 kg', months: 3),
      75,
    );
    expect(
      MiniPuppyFeedingGuide.dailyGramsFor(weightLabel: '4 kg', months: 5),
      85,
    );
    expect(
      MiniPuppyFeedingGuide.dailyGramsFor(weightLabel: '4 kg', months: 7),
      75,
    );
    expect(
      MiniPuppyFeedingGuide.dailyGramsFor(weightLabel: '4 kg', months: 12),
      65,
    );
  });

  test('çarpanlar baz × aktivite × vücut × ek gıda', () {
    expect(
      MiniPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '5 kg',
        ageLabel: '4-5 ay',
        activityLevel: 'Düşük',
        bodyType: 'Zayıf',
        extraFood: 'Yaş mama',
      ),
      80,
    );
  });

  test('add-pet label is Mini Irk Yavru', () {
    expect(PetLifeStage.petDogMiniPuppy, 'Mini Irk Yavru');
    expect(PetLifeStage.dogTypeOptions, contains('Mini Irk Yavru'));
    expect(MiniPuppyFeedingGuide.ageLabels, [
      '2-3 ay',
      '4-5 ay',
      '6-8 ay',
      '9-12 ay',
    ]);
  });

  test('admin override wins over Excel', () {
    MiniPuppyFeedingGuide.gramsOverride = {
      MiniPuppyFeedingGuide.cellKey('1 kg', '2-3 ay'): 22,
    };
    expect(
      MiniPuppyFeedingGuide.dailyGramsFor(
        weightLabel: '1 kg',
        ageLabel: '2-3 ay',
      ),
      22,
    );
  });
}
