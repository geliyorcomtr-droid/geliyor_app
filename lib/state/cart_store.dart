import 'package:flutter/foundation.dart';

class CartItem {
  CartItem({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.unitPrice,
    required this.oldPrice,
    required this.discountPercent,
    this.weight = '5 Kg',
    this.brand,
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
  int quantity;

  double get lineTotal => unitPrice * quantity;
}

class CartStore extends ChangeNotifier {
  CartStore._() {
    _items = [
      CartItem(
        id: 'hills-8kg',
        imagePath: 'assets/images/nd_kuzu_kisir.jpg',
        title:
            "Hill's SCIENCE PLAN Somonlu Kısırlaştırılmış Kedi Maması 8kg + 2kg HEDİYE",
        unitPrice: 4799,
        oldPrice: 6199,
        discountPercent: 22,
        weight: '8 Kg',
      ),
      CartItem(
        id: 'hills-3kg',
        imagePath: 'assets/images/nd_kuzu_kisir.jpg',
        title: "Hill's SCIENCE PLAN Somonlu Kısırlaştırılmış Kedi Maması 3kg",
        unitPrice: 2399,
        oldPrice: 2799,
        discountPercent: 14,
        weight: '3 Kg',
      ),
      CartItem(
        id: 'proplan-14kg',
        imagePath: 'assets/images/nd_kuzu_kisir.jpg',
        title: 'Pro Plan Hindili Kısırlaştırılmış Kedi Maması 14kg',
        unitPrice: 6399,
        oldPrice: 7459,
        discountPercent: 14,
        weight: '14 Kg',
      ),
    ];
  }

  static final CartStore instance = CartStore._();

  late final List<CartItem> _items;

  List<CartItem> get items => List.unmodifiable(_items);

  int get totalQuantity =>
      _items.fold(0, (sum, item) => sum + item.quantity);

  double get cartTotal =>
      _items.fold(0.0, (sum, item) => sum + item.lineTotal);

  double get cartOldTotal =>
      _items.fold(0.0, (sum, item) => sum + (item.oldPrice * item.quantity));

  double get cartDiscount => cartOldTotal - cartTotal;

  void addItem({
    required String id,
    required String imagePath,
    required String title,
    required double unitPrice,
    required double oldPrice,
    int discountPercent = 0,
    String weight = '5 Kg',
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
    if (_items.length <= 1) return;
    _items.removeAt(index);
    notifyListeners();
  }

  /// Geriye uyumluluk — navbar sayacı için.
  void setTotalQuantity(int value) {
    // Artık gerçek liste kullanılır; boş çağrılar yok sayılır.
    if (value == totalQuantity) return;
  }
}
