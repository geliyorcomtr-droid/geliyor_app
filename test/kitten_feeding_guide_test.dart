import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/kitten_feeding_guide.dart';

void main() {
  setUp(() {
    KittenFeedingGuide.gramsOverride = const {};
  });

  test('kitten grams follow Excel kg × age cells', () {
    expect(
      KittenFeedingGuide.dailyGramsFor(weightLabel: '0,5 kg', months: 1),
      30,
    );
    expect(
      KittenFeedingGuide.dailyGramsFor(weightLabel: '1 kg', months: 2),
      45,
    );
    expect(
      KittenFeedingGuide.dailyGramsFor(weightLabel: '1 kg', months: 3),
      50,
    );
    expect(
      KittenFeedingGuide.dailyGramsFor(weightLabel: '5 kg', months: 6),
      100,
    );
  });

  test('empty Excel cell falls back to nearest filled kg in that month', () {
    expect(
      KittenFeedingGuide.dailyGramsFor(weightLabel: '2 kg', months: 1),
      50,
    );
  });

  test('weight labels include 0.5 kg and 1 kg', () {
    expect(KittenFeedingGuide.weightLabels.first, '0,5 kg');
    expect(KittenFeedingGuide.weightLabels, contains('1 kg'));
    expect(KittenFeedingGuide.weightLabels, contains('1,5 kg'));
  });

  test('admin override wins over Excel', () {
    KittenFeedingGuide.gramsOverride = {
      KittenFeedingGuide.cellKey('0,5 kg', '1-2 ay'): 22,
    };
    expect(
      KittenFeedingGuide.dailyGramsFor(weightLabel: '0,5 kg', months: 1),
      22,
    );
  });
}
