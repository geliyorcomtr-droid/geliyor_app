import 'package:flutter/foundation.dart';

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
  int quantity;

  double get lineTotal => unitPrice * quantity;
}

class CartStore extends ChangeNotifier {
  CartStore._() {
    _items = [];
  }

  static final CartStore instance = CartStore._();

  late final List<CartItem> _items;

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
  }

  List<CartItem> get items {
    _dropUnuploadedItems();
    return List.unmodifiable(_items);
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
        ),
      );
    }
    notifyListeners();
  }

  void increaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    _items[index].quantity++;
    notifyListeners();
  }

  void decreaseQuantity(int index) {
    if (index < 0 || index >= _items.length) return;
    if (_items[index].quantity <= 1) return;
    _items[index].quantity--;
    notifyListeners();
  }

  void removeItem(int index) {
    if (index < 0 || index >= _items.length) return;
    _items.removeAt(index);
    notifyListeners();
  }

  /// Geriye uyumluluk — navbar sayacı için.
  void setTotalQuantity(int value) {
    // Artık gerçek liste kullanılır; boş çağrılar yok sayılır.
    if (value == totalQuantity) return;
  }
}
