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

  final List<FavoriteItem> _items = [
    const FavoriteItem(
      id: 'p1',
      category: 'Kuru Mama',
      title: 'Royal Canin Labrador Adult',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      unitPrice: 2349,
      oldPrice: 2599,
      discountPercent: 10,
    ),
    const FavoriteItem(
      id: 'p2',
      category: 'Kuru Mama',
      title: "Hill's Science Plan Somonlu",
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      unitPrice: 1899,
      oldPrice: 2199,
      discountPercent: 14,
    ),
    const FavoriteItem(
      id: 'p3',
      category: 'Takviye',
      title: 'GimCat Malt Soft Extra',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      unitPrice: 249,
      oldPrice: 287,
      discountPercent: 13,
    ),
    const FavoriteItem(
      id: 'p4',
      category: 'Kuru Mama',
      title: 'Pro Plan Sterilised Somonlu',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      unitPrice: 1649,
      oldPrice: 1849,
      discountPercent: 11,
    ),
    const FavoriteItem(
      id: 'p5',
      category: 'Kuru Mama',
      title: 'N&D Kuzu Kısır Kedi Maması',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      unitPrice: 1249,
      oldPrice: 1436,
      discountPercent: 13,
    ),
    const FavoriteItem(
      id: 'p6',
      category: 'Ödül',
      title: 'Felix Party Mix Ödül Maması',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      unitPrice: 189,
      oldPrice: 217,
      discountPercent: 13,
    ),
  ];

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
