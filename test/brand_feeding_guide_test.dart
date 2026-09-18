import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/brand_feeding_guide.dart';
import 'package:geliyor_app/data/brand_repository.dart';
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

  test('kitten grams use closest month', () {
    const guide = BrandFeedingGuide(
      catKittenGrams: {'2': 40, '6': 65, '12': 70},
    );

    expect(
      guide.dailyGramsFor(isDog: false, isPuppy: true, ageMonths: 2),
      40,
    );
    expect(
      guide.dailyGramsFor(isDog: false, isPuppy: true, ageMonths: 7),
      65,
    );
    expect(
      guide.dailyGramsFor(isDog: false, isPuppy: true, ageMonths: 11),
      70,
    );
  });

  test('puppy grams split standard and mini breed', () {
    const guide = BrandFeedingGuide(
      dogPuppyGrams: {'3': 255, '8': 230},
      dogMiniPuppyGrams: {'3': 110, '8': 90},
    );

    expect(
      guide.dailyGramsFor(isDog: true, isPuppy: true, ageMonths: 3),
      255,
    );
    expect(
      guide.dailyGramsFor(
        isDog: true,
        isPuppy: true,
        isMiniBreed: true,
        ageMonths: 3,
      ),
      110,
    );
    expect(
      guide.dailyGramsFor(
        isDog: true,
        isPuppy: true,
        isMiniBreed: true,
        ageMonths: 8,
      ),
      90,
    );
  });

  test('yavru table empty falls back to adult cat kg', () {
    const guide = BrandFeedingGuide(
      catGrams: {'3.0': 48, '5.0': 72},
    );
    expect(
      guide.dailyGramsFor(
        isDog: false,
        isPuppy: true,
        ageMonths: 4,
        weightLabel: '5 kg',
      ),
      72,
    );
  });

  test('product text prefers Pro Plan Yavru brand over Pro Plan', () {
    const brands = [
      AppBrand(id: 'pro-plan', name: 'Pro Plan'),
      AppBrand(id: 'pro-plan-yavru', name: 'Pro Plan Yavru'),
    ];
    expect(
      BrandRepository.matchId(
        brands,
        brandName: 'Pro Plan',
        title: 'Yavru Kedi Mama 2kg',
      ),
      'pro-plan-yavru',
    );
    expect(
      BrandRepository.matchId(
        brands,
        brandName: 'Pro Plan',
        title: 'Yetişkin Kedi Mama 2kg',
      ),
      'pro-plan',
    );
  });

  test('resolveFromProduct picks yavru table for Pro Plan yavru mama', () {
    const brand = AppBrand(
      id: 'pro-plan',
      name: 'Pro Plan',
      feeding: BrandFeedingGuide(
        catGrams: {'4.0': 60},
        catKittenGrams: {'4': 55},
      ),
    );
    final yavru = FoodTrackingChoice.resolveFromProduct(
      brandName: 'Pro Plan',
      title: 'Pro Plan Yavru Kedi',
      brands: const [brand],
    );
    expect(yavru.id, 'pro-plan');
    expect(yavru.isPuppy, isTrue);
    expect(yavru.label, 'Pro Plan Yavru');

    final adult = FoodTrackingChoice.resolveFromProduct(
      brandName: 'Pro Plan',
      title: 'Pro Plan Kedi Mama',
      brands: const [brand],
    );
    expect(adult.id, 'pro-plan');
    expect(adult.isPuppy, isFalse);
    expect(adult.label, 'Pro Plan');
  });
}
