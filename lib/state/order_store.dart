import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'subtitle': subtitle,
        'weight': weight,
        'price': price,
        'oldPrice': oldPrice,
        'imagePath': imagePath,
        'quantity': quantity,
      };

  factory LastOrderItem.fromMap(Map<String, dynamic> data) {
    return LastOrderItem(
      id: (data['id'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      subtitle: (data['subtitle'] as String?) ?? '',
      weight: (data['weight'] as String?) ?? '',
      price: (data['price'] as num?)?.toDouble() ?? 0,
      oldPrice: (data['oldPrice'] as num?)?.toDouble() ?? 0,
      imagePath: (data['imagePath'] as String?) ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class OrderStore extends ChangeNotifier {
  OrderStore._();

  static final OrderStore instance = OrderStore._();

  String _lastOrderId = '';
  DateTime _lastOrderAt = DateTime.now();

  /// Müşterinin en son verdiği sipariş içeriği.
  List<LastOrderItem> _lastOrderItems = const [];
  bool _suppressPersist = false;

  String get lastOrderId => _lastOrderId;
  DateTime get lastOrderAt => _lastOrderAt;
  String get lastOrderDate =>
      '${_lastOrderAt.day.toString().padLeft(2, '0')}.'
      '${_lastOrderAt.month.toString().padLeft(2, '0')}.'
      '${_lastOrderAt.year}';
  List<LastOrderItem> get lastOrderItems {
    _lastOrderItems = _lastOrderItems
        .where((item) {
          final path = item.imagePath.trim().toLowerCase();
          return path.startsWith('http://') || path.startsWith('https://');
        })
        .toList(growable: false);
    return List.unmodifiable(_lastOrderItems);
  }

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
    _persist();
  }

  void clearLocal() {
    _suppressPersist = true;
    _lastOrderId = '';
    _lastOrderAt = DateTime.now();
    _lastOrderItems = const [];
    _suppressPersist = false;
    notifyListeners();
  }

  void applyRemote({
    required String orderId,
    required DateTime orderedAt,
    required List<LastOrderItem> items,
  }) {
    _suppressPersist = true;
    _lastOrderId = orderId;
    _lastOrderAt = orderedAt;
    _lastOrderItems = List.unmodifiable(items);
    _suppressPersist = false;
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

  void _persist() {
    if (_suppressPersist) return;
    unawaited(_write());
  }

  Future<void> persistNow() async {
    if (_lastOrderItems.isEmpty) return;
    await _write();
  }

  Future<void> _write() async {
    await UserDocPersist.merge({
      UserFields.lastOrder: {
        'id': _lastOrderId,
        'orderedAt':
            '${_lastOrderAt.year.toString().padLeft(4, '0')}-'
            '${_lastOrderAt.month.toString().padLeft(2, '0')}-'
            '${_lastOrderAt.day.toString().padLeft(2, '0')}',
        'items': _lastOrderItems.map((item) => item.toMap()).toList(),
      },
    });
  }
}
