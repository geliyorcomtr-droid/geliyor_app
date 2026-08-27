import 'package:flutter/foundation.dart';

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

  String get imagePath => species == 'Köpek'
      ? 'assets/images/luna_kopek.png'
      : 'assets/images/milo_kedi.png';

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
}

/// Uygulama genelinde paylaşılan evcil dost listesi.
/// Dost Ekle sayfası yazar; Akıllı Planım ve ana sayfa okur.
class PetStore extends ChangeNotifier {
  PetStore._();

  static final PetStore instance = PetStore._();

  final List<PetData> _pets = [
    const PetData(
      name: 'Misket',
      species: 'Kedi',
      ageRange: 'Genç',
      weight: '2-3 kg',
      neutered: 'Evet',
      activityLevel: 'Orta',
      dailyFoodGrams: 40,
      allergies: ['Besin'],
    ),
    const PetData(
      name: 'Luna',
      species: 'Köpek',
      ageRange: 'Medium (11-25 kg)',
      weight: '20-30 kg',
      neutered: 'Hayır',
      activityLevel: 'Yüksek',
      dailyFoodGrams: 260,
      allergies: ['Çevre'],
    ),
  ];
  int _activePetIndex = 0;

  List<PetData> get pets => List.unmodifiable(_pets);
  PetData? get activePet =>
      _pets.isEmpty ? null : _pets[_activePetIndex.clamp(0, _pets.length - 1)];

  void addPet(PetData pet) {
    _pets.add(pet);
    _activePetIndex = _pets.length - 1;
    notifyListeners();
  }

  void updatePet(int index, PetData pet) {
    if (index < 0 || index >= _pets.length) return;
    _pets[index] = pet;
    _activePetIndex = index;
    notifyListeners();
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
  }
}
