import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/brand_feeding_guide.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/feeding_scale.dart';
import 'package:geliyor_app/data/feeding_variant.dart';
import 'package:geliyor_app/data/food_tracking_choices.dart';
import 'package:geliyor_app/data/pro_plan_mini_puppy_guide.dart';
import 'package:geliyor_app/state/pet_store.dart';

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

  test('yavru labeled brand copies are ignored in product match', () {
    const brands = [
      AppBrand(id: 'pro-plan', name: 'Pro Plan'),
      AppBrand(id: 'pro-plan-yavru', name: 'Pro Plan Yavru'),
    ];
    expect(BrandRepository.isYavruLabeled(brands[1]), isTrue);
    expect(
      BrandRepository.matchId(
        brands,
        brandName: 'Pro Plan',
        title: 'Yavru Kedi Mama 2kg',
      ),
      'pro-plan',
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
    expect(yavru.variant, FeedingVariant.catKitten);
    expect(yavru.label, 'Pro Plan Yavru Kedi');

    final adult = FoodTrackingChoice.resolveFromProduct(
      brandName: 'Pro Plan',
      title: 'Pro Plan Kedi Mama',
      brands: const [brand],
    );
    expect(adult.id, 'pro-plan');
    expect(adult.isPuppy, isFalse);
    expect(adult.variant, FeedingVariant.catAdult);
    expect(adult.label, 'Pro Plan Yetişkin Kedi');
  });

  test('picksFor lists each filled table with product-style names', () {
    const brand = AppBrand(
      id: 'pro-plan',
      name: 'Pro Plan',
      feeding: BrandFeedingGuide(
        catGrams: {'4.0': 60},
        catKittenGrams: {'4': 55},
        dogGrams: {'Medium': 240, 'Mini': 110},
        dogPuppyGrams: {'3': 255},
        dogMiniPuppyGrams: {'3': 110},
      ),
    );
    final picks = FoodTrackingChoice.picksFor(brand);
    expect(
      picks.map((pick) => pick.label).toList(),
      [
        'Pro Plan Yetişkin Kedi',
        'Pro Plan Yavru Kedi',
        'Pro Plan Yetişkin Köpek',
        'Pro Plan Yavru Köpek',
        'Pro Plan Mini Irk Köpek',
        'Pro Plan Small & Mini Puppy',
      ],
    );
  });

  test('product category Mini Irk Yavru maps to mini puppy table', () {
    const brand = AppBrand(
      id: 'pro-plan',
      name: 'Pro Plan',
      feeding: BrandFeedingGuide(
        dogGrams: {'Mini': 110},
        dogMiniPuppyGrams: {'4': 115},
      ),
    );
    final match = FoodTrackingChoice.resolveFromProduct(
      brandName: 'Pro Plan',
      title: 'Pro Plan Mini',
      mainCategory: 'dog',
      category: 'Mini Irk Yavru',
      brands: const [brand],
    );
    expect(match.variant, FeedingVariant.dogMiniPuppy);
    expect(match.label, 'Pro Plan Small & Mini Puppy');
  });

  test('standard grams stay as-is for ideal orta adult cat', () {
    const pet = PetData(
      name: 'Milo',
      species: 'Kedi',
      ageRange: 'Yetişkin',
      weight: '4 kg',
      bodyType: 'İdeal',
      activityLevel: 'Orta',
    );
    expect(
      FeedingScale.apply(
        standardGrams: 60,
        pet: pet,
        variant: FeedingVariant.catAdult,
      ),
      60,
    );
  });

  test('high activity and young age scale standard grams', () {
    const active = PetData(
      name: 'Milo',
      species: 'Kedi',
      ageRange: 'Yetişkin',
      weight: '4 kg',
      bodyType: 'İdeal',
      activityLevel: 'Yüksek',
    );
    expect(
      FeedingScale.apply(
        standardGrams: 60,
        pet: active,
        variant: FeedingVariant.catAdult,
      ),
      70,
    );

    const young = PetData(
      name: 'Milo',
      species: 'Kedi',
      ageRange: 'Genç',
      weight: '4 kg',
      bodyType: 'İdeal',
      activityLevel: 'Orta',
    );
    expect(
      FeedingScale.apply(
        standardGrams: 60,
        pet: young,
        variant: FeedingVariant.catAdult,
      ),
      65,
    );
  });

  test('replacing dog adult keeps mini adult grams', () {
    const guide = BrandFeedingGuide(
      dogGrams: {'Mini': 110, 'Medium': 240},
    );
    final next = guide.replacing(
      FeedingVariant.dogAdult,
      grams: const {'Medium': 250, 'Maxi': 400},
    );
    expect(next.dogGrams['Mini'], 110);
    expect(next.dogGrams['Medium'], 250);
    expect(next.dogGrams['Maxi'], 400);
  });

  test('pro plan mini puppy table uses expected adult kg and age band', () {
    const guide = BrandFeedingGuide(
      dogMiniPuppyCells: ProPlanMiniPuppyGuide.cells,
    );
    expect(ProPlanMiniPuppyGuide.parseCell('30-45'), 38);
    expect(ProPlanMiniPuppyGuide.parseCell('88'), 88);
    expect(
      guide.dailyGramsFor(
        isDog: true,
        isPuppy: true,
        isMiniBreed: true,
        weightLabel: '5 kg',
        ageMonths: 4,
      ),
      128,
    );
    expect(
      guide.dailyGramsFor(
        isDog: true,
        isPuppy: true,
        isMiniBreed: true,
        sizeLabel: 'Mini',
        ageMonths: 12,
      ),
      132,
    );
  });
}
