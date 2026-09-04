/// Uygulamada ve faturada gösterilen kısa sipariş numarası.
/// Firestore belgesinin son 6 karakteri (Siparişlerim ile aynı).
class OrderNo {
  OrderNo._();

  static String fromId(String id) {
    final raw = id.trim();
    if (raw.isEmpty) return '';
    if (raw.length <= 6) return raw.toUpperCase();
    return raw.substring(raw.length - 6).toUpperCase();
  }

  static String labeled(String id) => '#${fromId(id)}';
}
