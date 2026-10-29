/// Sepet limiti altındaki siparişlerde getirme ücreti; limit ve üzerinde ücretsiz kurye.
///
/// Varsayılanlar 599 TL limit ve 99 TL ücrettir. Admin paneli bu değerleri
/// `settings/courier_fee` belgesinden günceller.
class CourierFee {
  CourierFee._();

  static const double defaultFreeThreshold = 599;
  static const double defaultAmount = 99;

  static double freeThreshold = defaultFreeThreshold;
  static double amount = defaultAmount;

  static void apply({required double freeThreshold, required double amount}) {
    if (freeThreshold.isFinite && freeThreshold >= 0) {
      CourierFee.freeThreshold = freeThreshold;
    }
    if (amount.isFinite && amount >= 0) {
      CourierFee.amount = amount;
    }
  }

  static void resetDefaults() {
    freeThreshold = defaultFreeThreshold;
    amount = defaultAmount;
  }

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

  static String formatTl(double value) {
    if (!value.isFinite) return '0';
    if ((value - value.roundToDouble()).abs() < 0.001) {
      return value.round().toString();
    }
    return value.toStringAsFixed(2).replaceAll('.', ',');
  }
}
