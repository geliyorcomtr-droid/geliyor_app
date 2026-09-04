/// 599 TL altı siparişlerde 99 TL getirme ücreti; üzeri ücretsiz kurye.
class CourierFee {
  CourierFee._();

  static const double freeThreshold = 599;
  static const double amount = 99;

  static double forSubtotal(double subtotal) {
    if (subtotal <= 0) return 0;
    return subtotal < freeThreshold ? amount : 0;
  }

  static double payableTotal(double subtotal) =>
      subtotal + forSubtotal(subtotal);

  static double remainingForFree(double subtotal) {
    if (subtotal >= freeThreshold) return 0;
    return freeThreshold - subtotal;
  }

  static bool isFree(double subtotal) =>
      subtotal > 0 && subtotal >= freeThreshold;
}
