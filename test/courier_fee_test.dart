import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/utils/courier_fee.dart';

void main() {
  tearDown(CourierFee.resetDefaults);

  test('varsayılan limit altında 99 TL, üzerinde ücretsiz', () {
    expect(CourierFee.forSubtotal(598), 99);
    expect(CourierFee.forSubtotal(599), 0);
    expect(CourierFee.remainingForFree(500), 99);
    expect(CourierFee.isFree(599), isTrue);
  });

  test('admin değerleri sepet limiti ve getirme ücretini değiştirir', () {
    CourierFee.apply(freeThreshold: 400, amount: 50);
    expect(CourierFee.forSubtotal(399), 50);
    expect(CourierFee.forSubtotal(400), 0);
    expect(CourierFee.remainingForFree(350), 50);
    expect(CourierFee.payableTotal(100), 150);
  });

  test('sıfır ücret ve sıfır limit ücretsiz kurye demektir', () {
    CourierFee.apply(freeThreshold: 0, amount: 0);
    expect(CourierFee.forSubtotal(10), 0);
    expect(CourierFee.isFree(10), isTrue);
  });

  test('boş sepet getirme ücreti üretmez', () {
    CourierFee.apply(freeThreshold: 100, amount: 20);
    expect(CourierFee.forSubtotal(0), 0);
    expect(CourierFee.isFree(0), isFalse);
  });
}
