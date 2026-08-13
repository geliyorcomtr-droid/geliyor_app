String formatProductPrice(
  double value, {
  bool withCurrency = true,
  bool withDecimals = false,
}) {
  final fixed = withDecimals ? value.toStringAsFixed(2) : value.round().toString();
  final parts = fixed.split('.');
  final whole = parts.first;
  final buffer = StringBuffer();

  for (int i = 0; i < whole.length; i++) {
    final remaining = whole.length - i;
    buffer.write(whole[i]);
    if (remaining > 1 && remaining % 3 == 1) {
      buffer.write('.');
    }
  }

  if (withDecimals && parts.length > 1) {
    return '${withCurrency ? '₺' : ''}${buffer.toString()},${parts.last}';
  }

  return '${withCurrency ? '₺' : ''}${buffer.toString()},00';
}

double? parseTurkishPrice(String value) {
  var cleaned = value.replaceAll('₺', '').trim();
  if (cleaned.contains(',')) {
    cleaned = cleaned.split(',').first;
  }
  cleaned = cleaned.replaceAll('.', '');
  return double.tryParse(cleaned);
}

int? discountPercentFromPrices(double price, double? oldPrice) {
  if (oldPrice == null || oldPrice <= price) return null;
  return (((oldPrice - price) / oldPrice) * 100).round();
}
