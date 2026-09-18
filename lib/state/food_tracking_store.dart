import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/state/auth_store.dart';

/// Kullanıcının “Mama Takibini Başlat” ile girdiği manuel stok.
class FoodTrackingStore extends ChangeNotifier {
  FoodTrackingStore._();

  static final FoodTrackingStore instance = FoodTrackingStore._();

  bool _isActive = false;
  String _foodName = '';
  String _foodId = '';
  double _bagKg = 0;
  DateTime _purchaseDate = DateTime.now();
  String? _petName;
  String? _petSpecies;
  String _lifeStage = PetLifeStage.adult;
  bool _isMiniBreed = false;
  int _ageMonths = 4;
  bool _suppressPersist = false;
  bool _bound = false;

  bool get isActive => _isActive;
  String get foodName => _foodName;
  String get foodId => _foodId;
  double get bagKg => _bagKg;
  DateTime get purchaseDate => _purchaseDate;
  String? get petName => _petName;
  String? get petSpecies => _petSpecies;
  String get lifeStage => _lifeStage;
  bool get isMiniBreed => _isMiniBreed;
  int get ageMonths => _ageMonths;
  bool get isPuppy => _lifeStage == PetLifeStage.puppy;

  PetLifeStageProfile get lifeProfile => PetLifeStageProfile(
        isPuppy: isPuppy,
        isMiniBreed: _isMiniBreed,
        ageMonths: _ageMonths,
      );

  void clearLocal() {
    _suppressPersist = true;
    _bound = false;
    _isActive = false;
    _foodName = '';
    _foodId = '';
    _bagKg = 0;
    _purchaseDate = DateTime.now();
    _petName = null;
    _petSpecies = null;
    _lifeStage = PetLifeStage.adult;
    _isMiniBreed = false;
    _ageMonths = 4;
    _suppressPersist = false;
    notifyListeners();
  }

  void applyRemote(Map<String, dynamic>? data) {
    final remoteActive =
        data != null && data[FoodTrackingFields.active] == true;
    _suppressPersist = true;
    _bound = true;
    if (!remoteActive) {
      _isActive = false;
      _foodName = '';
      _foodId = '';
      _bagKg = 0;
      _petName = null;
      _petSpecies = null;
      _lifeStage = PetLifeStage.adult;
      _isMiniBreed = false;
      _ageMonths = 4;
    } else {
      _isActive = true;
      _foodName = (data[FoodTrackingFields.foodName] as String?)?.trim() ?? '';
      _foodId = (data[FoodTrackingFields.foodId] as String?)?.trim() ?? '';
      _bagKg = (data[FoodTrackingFields.bagKg] as num?)?.toDouble() ?? 0;
      _purchaseDate = _parseDate(data[FoodTrackingFields.purchaseDate]) ??
          DateTime.now();
      _petName = data[FoodTrackingFields.petName] as String?;
      _petSpecies = data[FoodTrackingFields.petSpecies] as String?;
      _lifeStage =
          (data[FoodTrackingFields.lifeStage] as String?)?.trim() ==
              PetLifeStage.puppy
          ? PetLifeStage.puppy
          : PetLifeStage.adult;
      _isMiniBreed = data[FoodTrackingFields.isMiniBreed] == true;
      _ageMonths =
          ((data[FoodTrackingFields.ageMonths] as num?)?.toInt() ?? 4)
              .clamp(1, 12);
    }
    _suppressPersist = false;
    notifyListeners();
  }

  void start({
    required String foodName,
    String foodId = '',
    required double bagKg,
    required DateTime purchaseDate,
    String? petName,
    String? petSpecies,
    bool isPuppy = false,
    bool isMiniBreed = false,
    int ageMonths = 4,
  }) {
    if (bagKg <= 0) return;
    _isActive = true;
    _foodName = foodName.trim();
    _foodId = foodId.trim();
    _bagKg = bagKg;
    _purchaseDate = DateTime(
      purchaseDate.year,
      purchaseDate.month,
      purchaseDate.day,
    );
    _petName = petName;
    _petSpecies = petSpecies;
    _lifeStage = isPuppy ? PetLifeStage.puppy : PetLifeStage.adult;
    _isMiniBreed = isMiniBreed;
    _ageMonths = ageMonths.clamp(1, 12);
    notifyListeners();
    unawaited(_persist());
  }

  void stop() {
    _isActive = false;
    _foodName = '';
    _foodId = '';
    _bagKg = 0;
    _petName = null;
    _petSpecies = null;
    _lifeStage = PetLifeStage.adult;
    _isMiniBreed = false;
    _ageMonths = 4;
    notifyListeners();
    unawaited(_persist());
  }

  Future<void> persistNow() async {
    if (!_bound && !_isActive) return;
    await _persist();
  }

  Map<String, dynamic> toMap() {
    if (!_isActive || _bagKg <= 0) {
      return {FoodTrackingFields.active: false};
    }
    return {
      FoodTrackingFields.active: true,
      FoodTrackingFields.foodName: _foodName,
      FoodTrackingFields.foodId: _foodId,
      FoodTrackingFields.bagKg: _bagKg,
      FoodTrackingFields.purchaseDate: _ymd(_purchaseDate),
      FoodTrackingFields.petName: _petName,
      FoodTrackingFields.petSpecies: _petSpecies,
      FoodTrackingFields.lifeStage: _lifeStage,
      FoodTrackingFields.isMiniBreed: _isMiniBreed,
      FoodTrackingFields.ageMonths: _ageMonths,
    };
  }

  Future<void> _persist() async {
    if (_suppressPersist) return;
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .set({
            UserFields.foodTracking: toMap(),
            UserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
    } catch (_) {
      // Offline: local tracking remains until next save.
    }
  }

  static String _ymd(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static DateTime? _parseDate(dynamic raw) {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String && raw.length >= 10) {
      return DateTime.tryParse(raw.substring(0, 10));
    }
    return null;
  }
}
