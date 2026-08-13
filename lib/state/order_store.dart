import 'package:flutter/foundation.dart';
import 'package:geliyor_app/state/cart_store.dart';

class LastOrderItem {
  const LastOrderItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.weight,
    required this.price,
    required this.oldPrice,
    required this.imagePath,
    this.quantity = 1,
  });

  final String id;
  final String title;
  final String subtitle;
  final String weight;
  final double price;
  final double oldPrice;
  final String imagePath;
  final int quantity;
}

class OrderStore extends ChangeNotifier {
  OrderStore._();

  static final OrderStore instance = OrderStore._();

  String _lastOrderId = 'GL-10428';
  DateTime _lastOrderAt = DateTime(2026, 7, 16);

  /// Müşterinin en son verdiği sipariş içeriği.
  List<LastOrderItem> _lastOrderItems = const [
    LastOrderItem(
      id: 'hills-8kg',
      title: "Hill's SCIENCE PLAN Somonlu",
      subtitle: 'Kısırlaştırılmış Kedi Maması',
      weight: '8 kg + 2 kg',
      price: 4799,
      oldPrice: 6199,
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      quantity: 1,
    ),
    LastOrderItem(
      id: 'hills-3kg',
      title: "Hill's SCIENCE PLAN Somonlu",
      subtitle: 'Kısırlaştırılmış Kedi Maması',
      weight: '3 kg',
      price: 2399,
      oldPrice: 2799,
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      quantity: 1,
    ),
    LastOrderItem(
      id: 'proplan-14kg',
      title: 'Pro Plan Hindili',
      subtitle: 'Kısırlaştırılmış Kedi Maması',
      weight: '14 kg',
      price: 6399,
      oldPrice: 7459,
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      quantity: 1,
    ),
  ];

  String get lastOrderId => _lastOrderId;
  DateTime get lastOrderAt => _lastOrderAt;
  String get lastOrderDate =>
      '${_lastOrderAt.day.toString().padLeft(2, '0')}.'
      '${_lastOrderAt.month.toString().padLeft(2, '0')}.'
      '${_lastOrderAt.year}';
  List<LastOrderItem> get lastOrderItems =>
      List.unmodifiable(_lastOrderItems);

  bool get hasLastOrder => _lastOrderItems.isNotEmpty;

  void setLastOrder({
    required List<LastOrderItem> items,
    String? orderId,
    String? orderDate,
  }) {
    if (items.isEmpty) return;
    final now = DateTime.now();
    _lastOrderId = orderId ??
        'GL-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';
    _lastOrderAt = _parseOrderDate(orderDate) ?? now;
    _lastOrderItems = List.unmodifiable(items);
    notifyListeners();
  }

  void saveLastOrderFromCart({
    String? orderId,
    String? orderDate,
  }) {
    final cartItems = CartStore.instance.items;
    if (cartItems.isEmpty) return;

    setLastOrder(
      orderId: orderId,
      orderDate: orderDate,
      items: cartItems
          .map(
            (item) => LastOrderItem(
              id: item.id,
              title: _titleFromCart(item.title),
              subtitle: _subtitleFromCart(item.title),
              weight: _weightFromCartItem(item),
              price: item.unitPrice,
              oldPrice: item.oldPrice,
              imagePath: item.imagePath,
              quantity: item.quantity,
            ),
          )
          .toList(),
    );
  }

  String _titleFromCart(String fullTitle) {
    final parts = fullTitle.split(' ');
    if (parts.length <= 3) return fullTitle;
    return parts.take(3).join(' ');
  }

  String _subtitleFromCart(String fullTitle) {
    if (fullTitle.toLowerCase().contains('kedi')) {
      return 'Kedi Maması';
    }
    if (fullTitle.toLowerCase().contains('köpek')) {
      return 'Köpek Maması';
    }
    return 'Pet ürünü';
  }

  String _weightFromCartItem(CartItem item) {
    final fromTitle = _kgPhrase(item.title);
    if (fromTitle != null) return fromTitle;
    if (item.weight.trim().isNotEmpty) return item.weight.trim();
    return '1 adet';
  }

  String? _kgPhrase(String text) {
    final matches = RegExp(
      r'(\d+(?:[.,]\d+)?\s*kg(?:\s*\+\s*\d+(?:[.,]\d+)?\s*kg)?)',
      caseSensitive: false,
    ).allMatches(text);
    if (matches.isEmpty) return null;
    return matches.first.group(1)!.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  DateTime? _parseOrderDate(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final parts = value.split('.');
    if (parts.length != 3) return null;
    final day = int.tryParse(parts[0]);
    final month = int.tryParse(parts[1]);
    final year = int.tryParse(parts[2]);
    if (day == null || month == null || year == null) return null;
    return DateTime(year, month, day);
  }
}
