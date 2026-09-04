import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';
import 'package:geliyor_app/utils/courier_fee.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.unitPrice,
    required this.oldPrice,
    required this.discountPercent,
    this.weight = '',
    this.brand,
    this.skt = '',
    this.barcode = '',
    this.quantity = 1,
  });

  final String id;
  final String imagePath;
  final String title;
  final double unitPrice;
  final double oldPrice;
  final int discountPercent;
  final String weight;
  final String? brand;
  final String skt;
  final String barcode;
  int quantity;

  double get lineTotal => unitPrice * quantity;

  Map<String, dynamic> toMap() => {
        'id': id,
        'imagePath': imagePath,
        'title': title,
        'unitPrice': unitPrice,
        'oldPrice': oldPrice,
        'discountPercent': discountPercent,
        'weight': weight,
        'brand': brand,
        'skt': skt,
        'barcode': barcode,
        'quantity': quantity,
      };

  factory CartItem.fromMap(Map<String, dynamic> data) {
    return CartItem(
      id: (data['id'] as String?) ?? '',
      imagePath: (data['imagePath'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      oldPrice: (data['oldPrice'] as num?)?.toDouble() ?? 0,
      discountPercent: (data['discountPercent'] as num?)?.toInt() ?? 0,
      weight: (data['weight'] as String?) ?? '',
      brand: data['brand'] as String?,
      skt: (data['skt'] as String?) ?? '',
      barcode: (data['barcode'] as String?) ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
    );
  }
}

class CartStore extends ChangeNotifier {
  CartStore._() {
    _items = [];
  }

  static final CartStore instance = CartStore._();

  late final List<CartItem> _items;
  bool _suppressPersist = false;
  bool _hasRemote = false;
  Timer? _persistTimer;

  bool _isUploadedProduct(CartItem item) {
    final path = item.imagePath.trim().toLowerCase();
    return path.startsWith('http://') || path.startsWith('https://');
  }

  void _dropUnuploadedItems() {
    _items.removeWhere((item) => !_isUploadedProduct(item));
  }

  void clear() {
    if (_items.isEmpty) return;
    _items.clear();
    notifyListeners();
    _schedulePersist();
  }

  void clearLocal() {
    _persistTimer?.cancel();
    _suppressPersist = true;
    _hasRemote = false;
    _items.clear();
    _suppressPersist = false;
    notifyListeners();
  }

  void applyRemote(List<Map<String, dynamic>> rows) {
    _persistTimer?.cancel();
    _suppressPersist = true;
    _hasRemote = true;
    _items
      ..clear()
      ..addAll(
        rows
            .map(CartItem.fromMap)
            .where((item) => item.id.isNotEmpty && _isUploadedProduct(item)),
      );
    _suppressPersist = false;
    notifyListeners();
  }

  List<CartItem> get items {
    _dropUnuploadedItems();
    return List.unmodifiable(_items);
  }

  bool get hasRemote => _hasRemote;

  void mergeGuestItems(List<CartItem> guestItems) {
    if (guestItems.isEmpty) return;
    var changed = false;
    for (final guest in guestItems) {
      if (guest.id.isEmpty || !_isUploadedProduct(guest)) continue;
      final index = _items.indexWhere((item) => item.id == guest.id);
      if (index >= 0) {
        _items[index].quantity += guest.quantity;
        changed = true;
      } else {
        _items.add(guest);
        changed = true;
      }
    }
    if (!changed) return;
    notifyListeners();
    _schedulePersist();
  }

  int get totalQuantity {
    _dropUnuploadedItems();
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get cartTotal {
    _dropUnuploadedItems();
    return _items.fold(0.0, (sum, item) => sum + item.lineTotal);
  }

  double get cartOldTotal {
    _dropUnuploadedItems();
    return _items.fold(0.0, (sum, item) => sum + (item.oldPrice * item.quantity));
  }

  double get cartDiscount => cartOldTotal - cartTotal;

  double get courierFee => CourierFee.forSubtotal(cartTotal);

  double get payableTotal => CourierFee.payableTotal(cartTotal);

  void addItem({
    required String id,
    required String imagePath,
    required String title,
    required double unitPrice,
    required double oldPrice,
    int discountPercent = 0,
    String weight = '',
    String? brand,
    String skt = '',
    String barcode = '',
  }) {
    final existing = _items.where((e) => e.id == id);
    if (existing.isNotEmpty) {
      existing.first.quantity++;
    } else {
      final discount = discountPercent > 0
          ? discountPercent
          : oldPrice <= 0
              ? 0
              : (((oldPrice - unitPrice) / oldPrice) * 100).round();
      _items.add(
        CartItem(
          id: id,
          imagePath: imagePath,
          title: title,
          unitPrice: unitPrice,
          oldPrice: oldPrice,
          discountPercent: discount,
          weight: weight,
          brand: brand,
          skt: skt,
          barcode: barcode,
        ),
      );
    }
    notifyListeners();
    _schedulePersist();
  }

  void increaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    _items[index].quantity++;
    notifyListeners();
    _schedulePersist();
  }

  void decreaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].quantity <= 1) return;
    _items[index].quantity--;
    notifyListeners();
    _schedulePersist();
  }

  void removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
    _schedulePersist();
  }

  /// Geriye uyumluluk — navbar sayacı için.
  void setTotalQuantity(int value) {
    // Artık gerçek liste kullanılır; boş çağrılar yok sayılır.
    if (value == totalQuantity) return;
  }

  void _schedulePersist() {
    if (_suppressPersist) return;
    _persistTimer?.cancel();
    _persistTimer = Timer(const Duration(milliseconds: 400), () {
      unawaited(_persist());
    });
  }

  Future<void> persistNow() async {
    _persistTimer?.cancel();
    if (!_hasRemote && _items.isEmpty) return;
    await _persist();
  }

  Future<void> _persist() async {
    if (_suppressPersist) return;
    await UserDocPersist.merge({
      UserFields.cart: _items.map((item) => item.toMap()).toList(),
    });
  }
}
