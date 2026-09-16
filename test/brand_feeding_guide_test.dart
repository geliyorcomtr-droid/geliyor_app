import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/brand_feeding_guide.dart';
import 'package:geliyor_app/data/food_tracking_choices.dart';

void main() {
  test('standard and empty food ids use fallback path', () {
    expect(FoodTrackingChoice.isStandard(null), isTrue);
    expect(FoodTrackingChoice.isStandard(''), isTrue);
    expect(FoodTrackingChoice.isStandard('standard'), isTrue);
    expect(FoodTrackingChoice.isStandard('pro-plan'), isFalse);
  });

  test('cat grams pick closest filled weight row', () {
    const guide = BrandFeedingGuide(
      catGrams: {'3.0': 48, '5.0': 72, '8.0': 95},
    );

    expect(guide.dailyGramsFor(isDog: false, weightLabel: '3 kg'), 48);
    expect(guide.dailyGramsFor(isDog: false, weightLabel: '4-5 kg'), 72);
    expect(guide.dailyGramsFor(isDog: false, weightLabel: '7,8 kg'), 95);
    expect(guide.dailyGramsFor(isDog: true, sizeLabel: 'Medium'), isNull);
  });

  test('dog grams use size label and ignore empty rows', () {
    const guide = BrandFeedingGuide(
      dogGrams: {'Mini': 110, 'Medium': 240},
    );

    expect(
      guide.dailyGramsFor(isDog: true, sizeLabel: 'Medium (11-25 kg)'),
      240,
    );
    expect(guide.dailyGramsFor(isDog: true, sizeLabel: 'Mini'), 110);
    expect(guide.dailyGramsFor(isDog: true, sizeLabel: 'Giant (45 kg+)'), isNull);
    expect(guide.dailyGramsFor(isDog: false, weightLabel: '4 kg'), isNull);
  });

  test('empty brand guide reports no tables', () {
    expect(BrandFeedingGuide.empty.isEmpty, isTrue);
    expect(BrandFeedingGuide.empty.hasCat, isFalse);
    expect(BrandFeedingGuide.empty.hasDog, isFalse);
    expect(
      BrandFeedingGuide.empty.dailyGramsFor(
        isDog: false,
        weightLabel: '4 kg',
      ),
      isNull,
    );
  });
}
