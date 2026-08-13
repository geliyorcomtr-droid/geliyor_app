import 'package:flutter/foundation.dart';

/// Kullanıcının “Mama Takibini Başlat” ile girdiği manuel stok.
class FoodTrackingStore extends ChangeNotifier {
  FoodTrackingStore._();

  static final FoodTrackingStore instance = FoodTrackingStore._();

  bool _isActive = false;
  String _foodName = '';
  double _bagKg = 0;
  DateTime _purchaseDate = DateTime.now();

  bool get isActive => _isActive;
  String get foodName => _foodName;
  double get bagKg => _bagKg;
  DateTime get purchaseDate => _purchaseDate;

  void start({
    required String foodName,
    required double bagKg,
    required DateTime purchaseDate,
  }) {
    if (bagKg <= 0) return;
    _isActive = true;
    _foodName = foodName.trim();
    _bagKg = bagKg;
    _purchaseDate = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    );
    notifyListeners();
  }

  void stop() {
    _isActive = false;
    _foodName = '';
    _bagKg = 0;
    notifyListeners();
  }
}
