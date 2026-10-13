import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/state/order_store.dart';

/// Abonelik açıksa, ilk siparişten sonraki her sepette %5 indirim.
class SubscriptionDiscount {
  SubscriptionDiscount._();

  static const String name = 'Abonelik';
  static const int percent = 5;

  static bool get applies =>
      NotificationSettingsStore.instance.subscriptionEnabled &&
      OrderStore.instance.lastOrderId.trim().isNotEmpty;

  static double amountFor(double subtotal) {
    if (!applies || subtotal <= 0) return 0;
    return subtotal * percent / 100;
  }

  static double payable({
    required double subtotal,
    required double couponDiscount,
    required double courierFee,
  }) {
    final products = subtotal - amountFor(subtotal) - couponDiscount;
    return (products < 0 ? 0 : products) + courierFee;
  }
}
