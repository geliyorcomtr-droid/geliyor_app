import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';
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

  Map<String, dynamic> toMap() => {
        'id': id,
        'imagePath': imagePath,
        'title': title,
        'unitPrice': unitPrice,
        'oldPrice': oldPrice,
        'discountPercent': discountPercent,
        'weight': weight,
        'brand': brand,
        'category': category,
      };

  factory FavoriteItem.fromMap(Map<String, dynamic> data) {
    return FavoriteItem(
      id: (data['id'] as String?) ?? '',
      imagePath: (data['imagePath'] as String?) ?? '',
      title: (data['title'] as String?) ?? '',
      unitPrice: (data['unitPrice'] as num?)?.toDouble() ?? 0,
      oldPrice: (data['oldPrice'] as num?)?.toDouble() ?? 0,
      discountPercent: (data['discountPercent'] as num?)?.toInt() ?? 0,
      weight: (data['weight'] as String?) ?? '1 adet',
      brand: data['brand'] as String?,
      category: data['category'] as String?,
    );
  }

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
  bool _suppressPersist = false;
  bool _hasRemote = false;

  List<FavoriteItem> get items => List.unmodifiable(_items);

  bool get hasRemote => _hasRemote;

  bool isFavorite(String id) => _items.any((item) => item.id == id);

  void clearLocal() {
    _suppressPersist = true;
    _hasRemote = false;
    _items.clear();
    _suppressPersist = false;
    notifyListeners();
  }

  void applyRemote(List<Map<String, dynamic>> rows) {
    _suppressPersist = true;
    _hasRemote = true;
    _items
      ..clear()
      ..addAll(
        rows
            .map(FavoriteItem.fromMap)
            .where((item) => item.id.isNotEmpty),
      );
    _suppressPersist = false;
    notifyListeners();
  }

  void add(FavoriteItem item) {
    final index = _items.indexWhere((entry) => entry.id == item.id);
    if (index >= 0) {
      _items[index] = item;
    } else {
      _items.add(item);
    }
    notifyListeners();
    _persist();
  }

  void remove(String id) {
    final removed = _items.length;
    _items.removeWhere((item) => item.id == id);
    if (_items.length != removed) {
      notifyListeners();
      _persist();
    }
  }

  void toggle(FavoriteItem item) {
    if (isFavorite(item.id)) {
      remove(item.id);
    } else {
      add(item);
    }
  }

  void mergeGuestItems(List<FavoriteItem> guestItems) {
    var changed = false;
    for (final item in guestItems) {
      if (item.id.isEmpty || isFavorite(item.id)) continue;
      _items.add(item);
      changed = true;
    }
    if (!changed) return;
    notifyListeners();
    _persist();
  }

  void _persist() {
    if (_suppressPersist) return;
    unawaited(_write());
  }

  Future<void> persistNow() async {
    if (!_hasRemote && _items.isEmpty) return;
    await _write();
  }

  Future<void> _write() async {
    await UserDocPersist.merge({
      UserFields.favorites: _items.map((item) => item.toMap()).toList(),
    });
  }
}
