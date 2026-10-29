import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/courier_fee_repository.dart';
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
    CourierFeeRepository.instance.addListener(notifyListeners);
  }

  static final CartStore instance = CartStore._();

  late final List<CartItem> _items;
  bool _suppressPersist = false;
  bool _hasRemote = false;
  Timer? _persistTimer;
  Future<void>? _persistTail;
  int _editGeneration = 0;
  int _ackedGeneration = 0;
  int _writeFailures = 0;

  bool get _hasPendingEdit => _editGeneration != _ackedGeneration;

  void _touch() {
    _editGeneration++;
    _writeFailures = 0;
  }

  bool _isUploadedProduct(CartItem item) {
    final path = item.imagePath.trim().toLowerCase();
    return path.startsWith('http://') || path.startsWith('https://');
  }

  void _dropUnuploadedItems() {
    _items.removeWhere((item) => !_isUploadedProduct(item));
  }

  void clear() {
    if (_items.isEmpty) return;
    _touch();
    _items.clear();
    notifyListeners();
    _schedulePersist();
  }

  void clearLocal() {
    _persistTimer?.cancel();
    _suppressPersist = true;
    _hasRemote = false;
    _editGeneration = 0;
    _ackedGeneration = 0;
    _items.clear();
    _suppressPersist = false;
    notifyListeners();
  }

  void applyRemote(List<Map<String, dynamic>> rows) {
    // Adet değişimi henüz yazılmadıysa eski sunucu anlık görüntüsü
    // yerel sepeti geri almasın ve bekleyen kaydı iptal etmesin.
    if (_hasRemote && _hasPendingEdit) return;
    _persistTimer?.cancel();
    _suppressPersist = true;
    _hasRemote = true;
    _editGeneration = 0;
    _ackedGeneration = 0;
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
    _touch();
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
    return _items.fold(
      0.0,
      (sum, item) => sum + (item.oldPrice * item.quantity),
    );
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
    _touch();
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

  void setQuantity(String id, int quantity) {
    if (quantity < 1) return;
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0 || _items[index].quantity == quantity) return;
    _touch();
    _items[index].quantity = quantity;
    notifyListeners();
    _schedulePersist();
  }

  void increaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    setQuantity(_items[index].id, _items[index].quantity + 1);
  }

  void decreaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    setQuantity(_items[index].id, _items[index].quantity - 1);
  }

  void removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    removeById(_items[index].id);
  }

  void removeById(String id) {
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) return;
    _touch();
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
    if (!_hasRemote && _items.isEmpty && !_hasPendingEdit) return;
    await _persist();
  }

  Future<void> _persist() {
    final previous = _persistTail;
    late final Future<void> current;
    current = () async {
      if (previous != null) {
        try {
          await previous;
        } catch (_) {}
      }
      await _writeLatest();
    }();
    _persistTail = current;
    return current.whenComplete(() {
      if (identical(_persistTail, current)) _persistTail = null;
    });
  }

  Future<void> _writeLatest() async {
    if (_suppressPersist || !_hasPendingEdit) return;
    final generation = _editGeneration;
    final payload = _items.map((item) => item.toMap()).toList();
    final wrote = await UserDocPersist.merge({UserFields.cart: payload});
    if (!wrote) {
      if (_writeFailures < 4 && _hasPendingEdit) {
        _writeFailures++;
        _persistTimer?.cancel();
        _persistTimer = Timer(const Duration(seconds: 2), () {
          unawaited(_persist());
        });
      }
      return;
    }
    _writeFailures = 0;
    if (generation == _editGeneration) {
      _ackedGeneration = generation;
    }
  }
}
