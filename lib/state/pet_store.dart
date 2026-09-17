import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/state/auth_store.dart';

class PetData {
  const PetData({
    required this.name,
    required this.species,
    this.ageRange,
    this.weight,
    this.bodyType,
    this.neutered,
    this.activityLevel,
    this.extraFood,
    this.dailyFoodGrams,
    this.allergies = const [],
    this.photoUrl,
    this.gender,
  });

  final String name;
  final String species;
  final String? ageRange;
  final String? weight;
  final String? bodyType;
  final String? neutered;
  final String? activityLevel;
  final String? extraFood;
  final int? dailyFoodGrams;
  final List<String> allergies;
  final String? photoUrl;
  final String? gender;

  String get fallbackAsset => species == 'Köpek'
      ? 'assets/images/luna_kopek.png'
      : 'assets/images/milo_kedi.png';

  String get imagePath => fallbackAsset;

  bool get hasCustomPhoto {
    final url = photoUrl?.trim() ?? '';
    return url.isNotEmpty;
  }

  /// Kısa yaş etiketi (ör. "Genç").
  String get shortAge {
    final range = ageRange;
    if (range == null || range.isEmpty) return '-';
    final start = range.indexOf('(');
    if (start > 0) {
      return range.substring(0, start).trim();
    }
    return range;
  }

  /// Vücut yapısı: Zayıf, İdeal veya Kilolu.
  String get shortBodyType {
    final v = (bodyType ?? '').toLowerCase();
    if (v.contains('zayıf') || v.contains('zayif')) return 'Zayıf';
    if (v.contains('kilolu') || v.contains('obez')) return 'Kilolu';
    return 'İdeal';
  }

  Map<String, dynamic> toMap() {
    return {
      PetFields.name: name,
      PetFields.species: species,
      PetFields.ageRange: ageRange,
      PetFields.weight: weight,
      PetFields.bodyType: bodyType,
      PetFields.neutered: neutered,
      PetFields.activityLevel: activityLevel,
      PetFields.extraFood: extraFood,
      PetFields.dailyFoodGrams: dailyFoodGrams,
      PetFields.allergies: allergies,
      PetFields.photoUrl: photoUrl,
      PetFields.gender: gender,
    };
  }

  factory PetData.fromMap(Map<String, dynamic> data) {
    final rawAllergies = data[PetFields.allergies];
    return PetData(
      name: (data[PetFields.name] as String?)?.trim() ?? '',
      species: (data[PetFields.species] as String?)?.trim() ?? 'Kedi',
      ageRange: data[PetFields.ageRange] as String?,
      weight: data[PetFields.weight] as String?,
      bodyType: data[PetFields.bodyType] as String?,
      neutered: data[PetFields.neutered] as String?,
      activityLevel: data[PetFields.activityLevel] as String?,
      extraFood: data[PetFields.extraFood] as String?,
      dailyFoodGrams: (data[PetFields.dailyFoodGrams] as num?)?.toInt(),
      allergies: rawAllergies is List
          ? rawAllergies.map((item) => item.toString()).toList()
          : const [],
      photoUrl: (data[PetFields.photoUrl] as String?)?.trim(),
      gender: (data[PetFields.gender] as String?)?.trim(),
    );
  }
}

/// Uygulama genelinde paylaşılan evcil dost listesi.
/// Girişli hesapta Firestore’a yazılır; çıkışta örnek dostlara dönülmez.
class PetStore extends ChangeNotifier {
  PetStore._();

  static final PetStore instance = PetStore._();

  static const _guestPets = [
    PetData(
      name: 'Misket',
      species: 'Kedi',
      ageRange: '2 yaş',
      weight: '2-3 kg',
      bodyType: 'İdeal',
      neutered: 'Evet',
      activityLevel: 'Orta',
      dailyFoodGrams: 40,
      allergies: ['Besin'],
      gender: 'Dişi',
    ),
    PetData(
      name: 'Luna',
      species: 'Köpek',
      ageRange: '1,5 yaş',
      weight: '20-30 kg',
      bodyType: 'İdeal',
      neutered: 'Hayır',
      activityLevel: 'Yüksek',
      dailyFoodGrams: 260,
      allergies: ['Çevre'],
      gender: 'Dişi',
    ),
    PetData(
      name: 'Pamuk',
      species: 'Kedi',
      ageRange: '4 yaş',
      weight: '4-5 kg',
      bodyType: 'İdeal',
      neutered: 'Evet',
      activityLevel: 'Düşük',
      dailyFoodGrams: 45,
      allergies: const [],
      gender: 'Erkek',
    ),
  ];

  List<PetData> _pets = List<PetData>.from(_guestPets);
  int _activePetIndex = 0;
  String? _boundUid;
  bool _suppressPersist = false;
  Timer? _persistTimer;

  String? get boundUid => _boundUid;

  List<PetData> get pets => List.unmodifiable(_pets);
  int get activePetIndex => _activePetIndex;
  PetData? get activePet =>
      _pets.isEmpty ? null : _pets[_activePetIndex.clamp(0, _pets.length - 1)];

  void selectPet(int index) {
    if (index < 0 || index >= _pets.length) return;
    if (_activePetIndex == index) return;
    _activePetIndex = index;
    notifyListeners();
    _schedulePersist();
  }

  bool isBoundTo(String? uid) => _boundUid == uid;

  bool get hasOnlyGuestPets {
    if (_pets.length != _guestPets.length) return false;
    for (var i = 0; i < _pets.length; i++) {
      if (!_samePet(_pets[i], _guestPets[i])) return false;
    }
    return true;
  }

  static bool _samePet(PetData a, PetData b) {
    if (a.name != b.name || a.species != b.species) return false;
    if (a.ageRange != b.ageRange || a.weight != b.weight) return false;
    if (a.bodyType != b.bodyType || a.neutered != b.neutered) return false;
    if (a.activityLevel != b.activityLevel || a.extraFood != b.extraFood) {
      return false;
    }
    if (a.dailyFoodGrams != b.dailyFoodGrams) return false;
    if ((a.photoUrl ?? '') != (b.photoUrl ?? '')) return false;
    if ((a.gender ?? '') != (b.gender ?? '')) return false;
    if (a.allergies.length != b.allergies.length) return false;
    for (var i = 0; i < a.allergies.length; i++) {
      if (a.allergies[i] != b.allergies[i]) return false;
    }
    return true;
  }

  void showGuestPets() {
    _persistTimer?.cancel();
    _boundUid = null;
    _suppressPersist = true;
    _pets = List<PetData>.from(_guestPets);
    _activePetIndex = 0;
    _suppressPersist = false;
    notifyListeners();
  }

  void applyRemote({
    required String uid,
    required List<PetData> pets,
    int activeIndex = 0,
  }) {
    _persistTimer?.cancel();
    _boundUid = uid;
    _suppressPersist = true;
    _pets = List<PetData>.from(pets);
    _activePetIndex = pets.isEmpty ? 0 : activeIndex.clamp(0, pets.length - 1);
    _suppressPersist = false;
    notifyListeners();
  }

  Future<void> persistNow() async {
    _persistTimer?.cancel();
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return;
    if (hasOnlyGuestPets) return;
    await _persist(uid);
  }

  void addPet(PetData pet) {
    _pets.add(pet);
    _activePetIndex = _pets.length - 1;
    notifyListeners();
    _schedulePersist();
  }

  void updatePet(int index, PetData pet) {
    if (index < 0 || index >= _pets.length) return;
    _pets[index] = pet;
    _activePetIndex = index;
    notifyListeners();
    _schedulePersist();
  }

  void removePet(int index) {
    if (index < 0 || index >= _pets.length) return;
    _pets.removeAt(index);
    if (_pets.isEmpty) {
      _activePetIndex = 0;
    } else if (_activePetIndex >= _pets.length) {
      _activePetIndex = _pets.length - 1;
    } else if (index < _activePetIndex) {
      _activePetIndex--;
    }
    notifyListeners();
    _schedulePersist();
  }

  void _schedulePersist() {
    if (_suppressPersist) return;
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return;
    _persistTimer?.cancel();
    unawaited(_persist(uid));
  }

  Future<void> _persist(String uid) async {
    if (hasOnlyGuestPets) return;
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.users)
          .doc(uid)
          .set({
            UserFields.pets: _pets.map((pet) => pet.toMap()).toList(),
            UserFields.activePetIndex: _activePetIndex,
            UserFields.updatedAt: FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
      _boundUid = uid;
    } catch (_) {
      // Offline: local list remains until next save.
    }
  }
}
