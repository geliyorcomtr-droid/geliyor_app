import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/product_margin.dart';

void main() {
  test('KDV dahil 150, alış 100, KDV %20 → net 125, marj %20', () {
    expect(ProductMargin.netOfVat(150, 20), closeTo(125, 0.001));
    expect(
      ProductMargin.percent(
        purchasePrice: 100,
        discountedPrice: 150,
        vatRate: 20,
      ),
      closeTo(20, 0.001),
    );
  });

  test('KDV değişince marj değişir', () {
    final atTen = ProductMargin.percent(
      purchasePrice: 100,
      discountedPrice: 150,
      vatRate: 10,
    );
    final atTwenty = ProductMargin.percent(
      purchasePrice: 100,
      discountedPrice: 150,
      vatRate: 20,
    );
    expect(atTen, isNotNull);
    expect(atTwenty, isNotNull);
    expect(atTen! > atTwenty!, isTrue);
  });

  test('Satış üzeri çizili, indirimli asıl fiyat indirim yüzdesini üretir', () {
    expect(
      ProductMargin.discountPercent(listPrice: 200, discountedPrice: 150),
      25,
    );
  });
}
