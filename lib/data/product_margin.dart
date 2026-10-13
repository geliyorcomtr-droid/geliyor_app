/// Alış, indirimli satış ve KDV üzerinden kâr marjı.
///
/// Alış KDV hariç, indirimli fiyat KDV dahil kabul edilir.
abstract final class ProductMargin {
  static double netOfVat(double gross, int vatRate) {
    final rate = vatRate <= 0 ? 0.0 : vatRate / 100.0;
    return gross / (1 + rate);
  }

  static double vatAmount(double discountedPrice, int vatRate) {
    return discountedPrice - netOfVat(discountedPrice, vatRate);
  }

  /// (Net satış − alış) / net satış × 100.
  static double? percent({
    required double purchasePrice,
    required double discountedPrice,
    int vatRate = 20,
  }) {
    if (discountedPrice <= 0) return null;
    final netSale = netOfVat(discountedPrice, vatRate);
    if (netSale <= 0) return null;
    return ((netSale - purchasePrice) / netSale) * 100;
  }

  static int discountPercent({
    required double listPrice,
    required double discountedPrice,
  }) {
    if (listPrice <= 0 ||
        discountedPrice <= 0 ||
        listPrice <= discountedPrice) {
      return 0;
    }
    return (((listPrice - discountedPrice) / listPrice) * 100).round();
  }

  static String percentLabel(double? value) {
    if (value == null) return '—';
    return '%${value.toStringAsFixed(1)}';
  }
}
