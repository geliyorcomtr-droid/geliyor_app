import 'package:flutter/foundation.dart';
import 'package:geliyor_app/state/cart_store.dart';

class FavoriteItem {
  const FavoriteItem({
    required this.id,
    required this.imagePath,
    required this.title,
    required this.unitPrice,
    required this.oldPrice,
    required this.discountPercent,
    this.weight = '1 adet',
    this.brand,
    this.category,
  });

  final String id;
  final String imagePath;
  final String title;
  final double unitPrice;
  final double oldPrice;
  final int discountPercent;
  final String weight;
  final String? brand;
  final String? category;

  factory FavoriteItem.fromCartItem(CartItem item) {
    return FavoriteItem(
      id: item.id,
      imagePath: item.imagePath,
      title: item.title,
      unitPrice: item.unitPrice,
      oldPrice: item.oldPrice,
      discountPercent: item.discountPercent,
      weight: item.weight,
      brand: item.brand,
    );
  }
}

class FavoriteStore extends ChangeNotifier {
  FavoriteStore._();

  static final FavoriteStore instance = FavoriteStore._();

  final List<FavoriteItem> _items = [];

  List<FavoriteItem> get items => List.unmodifiable(_items);

  bool isFavorite(String id) => _items.any((item) => item.id == id);

  void add(FavoriteItem item) {
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }

  void remove(String id) {
    final removed = _items.length;
    _items.removeWhere((item) => item.id == id);
    if (_items.length != removed) notifyListeners();
  }

  void toggle(FavoriteItem item) {
    if (isFavorite(item.id)) {
      remove(item.id);
    } else {
      add(item);
    }
  }
}
