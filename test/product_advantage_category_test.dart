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

  test('kategori renkleri bir ton açılır', () {
    expect(ProductAdvantageCategory.lightenOneTone('#EF4444'), '#F87171');
    expect(ProductAdvantageCategory.lightenOneTone('#22C55E'), '#4ADE80');
    expect(ProductAdvantageCategory.lightenOneTone('#F59E0B'), '#FBBF24');
    expect(ProductAdvantageCategory.lightenOneTone('#8B5CF6'), '#A78BFA');
    expect(ProductAdvantageCategory.lightenOneTone('#EC4899'), '#F472B6');
    expect(ProductAdvantageCategory.lightenOneTone('#DC2626'), '#EF4444');
    expect(ProductAdvantageCategory.lightenOneTone('#16A34A'), '#22C55E');
    expect(ProductAdvantageCategory.lightenOneTone('#0EA5E9'), '#38BDF8');
    expect(ProductAdvantageCategory.lightenOneTone('#14B8A6'), '#2DD4BF');
    expect(ProductAdvantageCategory.lightenOneTone('#84CC16'), '#A3E635');
    expect(ProductAdvantageCategory.lightenOneTone('#2563EB'), '#3B82F6');
    expect(ProductAdvantageCategory.lightenOneTone('#B91C1C'), '#DC2626');
    expect(ProductAdvantageCategory.lightenOneTone('#65A30D'), '#84CC16');
    expect(ProductAdvantageCategory.lightenOneTone('#DB2777'), '#EC4899');
    expect(
      ProductAdvantageCategory.lightenOneTone('#7D0EE9'),
      ProductAdvantageCategory.defaultColorHex,
    );
    expect(
      ProductAdvantageCategory.lightenOneTone('ef4444'),
      '#F87171',
    );
  });
}
