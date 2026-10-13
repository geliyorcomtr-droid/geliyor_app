import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/health_product_groups.dart';

void main() {
  test('vitamin, takviye ve malt aynı kümeye bağlanır', () {
    expect(
      HealthProductGroup.vitamin.matches(
        advantageIds: const ['vitamin'],
        categoryTitles: const [],
      ),
      isTrue,
    );
    expect(
      HealthProductGroup.vitamin.matches(
        advantageIds: const [],
        categoryTitles: const ['Vitamin'],
      ),
      isTrue,
    );
    expect(
      HealthProductGroup.vitamin.matches(
        advantageIds: const [],
        categoryTitles: const ['Yetişkin'],
      ),
      isFalse,
    );
    expect(
      HealthProductGroup.forCategoryTitle('Maltlar'),
      HealthProductGroup.malt,
    );
    expect(
      HealthProductGroup.forCategoryTitle('Takviye Gıdalar')?.advantageId,
      'takviye',
    );
    expect(
      HealthProductGroup.forCategoryTitle('maltler'),
      HealthProductGroup.malt,
    );
    expect(
      HealthProductGroup.vitamin.iconPath,
      'assets/images/ilac_icon_vitamin.png',
    );
    expect(
      HealthProductGroup.supplement.iconPath,
      'assets/images/ilac_icon_takviye.png',
    );
    expect(
      HealthProductGroup.malt.iconPath,
      'assets/images/ilac_icon_malt.png',
    );
  });

  test('kedi ürününde vitamin seçimi kategoriyi de yazar', () {
    final ids = <String>['vitamin'];
    final extras = <String>{};
    HealthProductGroup.applyToProductSelection(
      advantageIds: ids,
      mainCategory: 'cat',
      primaryCategory: 'Yetişkin',
      extraCategories: extras,
      maxAdvantages: 6,
    );
    expect(extras, {'Vitamin'});
    expect(ids, ['vitamin']);
  });

  test('vitamin kategorisi ürün faydasını da seçer', () {
    final ids = <String>[];
    final extras = <String>{};
    HealthProductGroup.applyToProductSelection(
      advantageIds: ids,
      mainCategory: 'cat',
      primaryCategory: 'Takviye Gıdalar',
      extraCategories: extras,
      maxAdvantages: 6,
    );
    expect(ids, ['takviye']);
    expect(extras, isEmpty);
  });
}
