import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_factors.dart';
import 'package:geliyor_app/data/feeding_variant.dart';
import 'package:geliyor_app/data/kitten_feeding_guide.dart';
import 'package:geliyor_app/data/mini_adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/mini_puppy_feeding_guide.dart';
import 'package:geliyor_app/data/product_bag_days.dart';
import 'package:geliyor_app/data/standard_puppy_feeding_guide.dart';

void main() {
  setUp(() {
    CatFeedingGuide.gramsOverride = const {};
    CatFeedingGuide.factors = FeedingFactors.defaults;
    KittenFeedingGuide.gramsOverride = const {};
    KittenFeedingGuide.factors = FeedingFactors.defaults;
    AdultDogFeedingGuide.gramsOverride = const {};
    AdultDogFeedingGuide.factors = MiniAdultDogFactors.defaults;
    MiniAdultDogFeedingGuide.gramsOverride = const {};
    MiniAdultDogFeedingGuide.factors = MiniAdultDogFactors.defaults;
    MiniPuppyFeedingGuide.gramsOverride = const {};
    MiniPuppyFeedingGuide.factors = MiniPuppyFactors.defaults;
    StandardPuppyFeedingGuide.gramsOverride = const {};
    StandardPuppyFeedingGuide.factors = StandardPuppyFactors.defaults;
  });

  test('typical daily grams match Excel normal averages', () {
    expect(ProductBagDays.typicalDailyGrams(FeedingVariant.catAdult), 55);
    expect(ProductBagDays.typicalDailyGrams(FeedingVariant.catKitten), 65);
    expect(ProductBagDays.typicalDailyGrams(FeedingVariant.dogAdult), 270);
    expect(ProductBagDays.typicalDailyGrams(FeedingVariant.dogPuppy), 285);
    expect(ProductBagDays.typicalDailyGrams(FeedingVariant.dogMiniAdult), 94);
    expect(ProductBagDays.typicalDailyGrams(FeedingVariant.dogMiniPuppy), 95);
  });

  test('2 kg adult cat food lasts 36 days', () {
    expect(
      ProductBagDays.daysFor(
        mainCategory: 'cat',
        category: 'Yetişkin',
        weight: '2 Kg',
      ),
      36,
    );
  });

  test('life-stage categories pick the matching table', () {
    expect(
      ProductBagDays.daysFor(
        mainCategory: 'cat',
        category: 'Yavru',
        weight: '2 kg',
      ),
      31,
    );
    expect(
      ProductBagDays.daysFor(
        mainCategory: 'dog',
        category: 'Yetişkin',
        weight: '15 kg',
      ),
      56,
    );
    expect(
      ProductBagDays.daysFor(
        mainCategory: 'dog',
        category: 'Yavru',
        weight: '12 kg',
      ),
      42,
    );
    expect(
      ProductBagDays.daysFor(
        mainCategory: 'dog',
        category: 'Mini Irk',
        weight: '3 kg',
      ),
      32,
    );
    expect(
      ProductBagDays.daysFor(
        mainCategory: 'dog',
        category: 'Mini Irk Yavru',
        weight: '2 kg',
      ),
      21,
    );
  });

  test('legacy percent is not shown as days', () {
    expect(ProductBagDays.looksLikeLegacyPercent('%78'), isTrue);
    expect(
      ProductBagDays.displayFor(
        mainCategory: 'smart',
        weight: '1 kg',
        stored: '%78',
      ),
      '',
    );
  });

  test('note explains a different pet for each product type', () {
    final cat = ProductBagDays.noteFor(
      mainCategory: 'cat',
      category: 'Yetişkin',
      weight: '10 kg',
    );
    expect(cat, isNotNull);
    expect(cat!.days, 182);
    expect(cat.title, '182 gün');
    expect(cat.body, contains('4 kg yetişkin bir kedi'));
    expect(cat.body, contains('55 g'));

    final dog = ProductBagDays.noteFor(
      mainCategory: 'dog',
      category: 'Yetişkin',
      weight: '15 kg',
    );
    expect(dog!.days, 56);
    expect(dog.body, contains('20 kg yetişkin bir köpek'));
    expect(dog.body, contains('270 g'));

    final kitten = ProductBagDays.noteFor(
      mainCategory: 'cat',
      category: 'Yavru',
      weight: '2 kg',
    );
    expect(kitten!.body, contains('yavru kedi'));
    expect(kitten.body, isNot(contains('köpek')));

    final mini = ProductBagDays.noteFor(
      mainCategory: 'dog',
      category: 'Mini Irk',
      weight: '3 kg',
    );
    expect(mini!.days, 32);
    expect(mini.body, contains('mini ırk yetişkin köpek'));
  });

  test('parses kg and gram labels', () {
    expect(ProductBagDays.bagKgFromLabel('2 Kg'), 2);
    expect(ProductBagDays.bagKgFromLabel('1,5kg'), 1.5);
    expect(ProductBagDays.bagKgFromLabel('400 g'), 0.4);
    expect(ProductBagDays.bagKgFromLabel('2'), 2);
  });
}
