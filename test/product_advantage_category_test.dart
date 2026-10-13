import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/product_advantage_category.dart';

void main() {
  test('known advantage ids map to the expected categories', () {
    expect(ProductAdvantageCategory.infer('kisir_kedi', 'Kısır Kediler İçin'),
        ProductAdvantageCategory.tur.id);
    expect(ProductAdvantageCategory.infer('yavru_kopek', 'Yavru Köpekler İçin'),
        ProductAdvantageCategory.tur.id);
    expect(
      ProductAdvantageCategory.normalize('yasam_evresi'),
      ProductAdvantageCategory.tur.id,
    );
    expect(ProductAdvantageCategory.normalize('ozel_kategori'), 'ozel_kategori');
    expect(
      ProductAdvantageCategory.normalize(''),
      ProductAdvantageCategory.diger.id,
    );
    expect(
      ProductAdvantageCategory.mergeCatalog(
        removedIds: const ['protein'],
        extras: const [
          ProductAdvantageCategory(id: 'ozel', label: 'Özel'),
        ],
      ).map((item) => item.id).toList(),
      [
        ProductAdvantageCategory.tur.id,
        ProductAdvantageCategory.icerik.id,
        ProductAdvantageCategory.saglik.id,
        ProductAdvantageCategory.urunTipi.id,
        ProductAdvantageCategory.diger.id,
        'ozel',
      ],
    );
    expect(ProductAdvantageCategory.slugFromLabel('Tüy & Deri'), 'tuy_deri');
    expect(
      ProductAdvantageCategory.mergeCatalog(
        removedIds: const [],
        extras: const [
          ProductAdvantageCategory(id: 'tur', label: 'Tür'),
        ],
      ).first.label,
      'Tür',
    );
    expect(ProductAdvantageCategory.infer('tavuk', 'Tavuklu Formül'),
        ProductAdvantageCategory.icerik.id);
    expect(ProductAdvantageCategory.infer('sindirim', 'Sindirim'),
        ProductAdvantageCategory.saglik.id);
    expect(ProductAdvantageCategory.infer('kuru_mama', 'Kuru Mama'),
        ProductAdvantageCategory.urunTipi.id);
    expect(ProductAdvantageCategory.infer('dha', 'DHA'),
        ProductAdvantageCategory.protein.id);
  });
}
