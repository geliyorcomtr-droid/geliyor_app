import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_factors.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/kitten_feeding_guide.dart';
import 'package:geliyor_app/data/mini_adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/mini_puppy_feeding_guide.dart';
import 'package:geliyor_app/data/puppy_feeding_guide.dart';
import 'package:geliyor_app/data/standard_puppy_feeding_guide.dart';

class SystemFeedingTables {
  const SystemFeedingTables({
    required this.catAdult,
    required this.catKitten,
    required this.dogAdult,
    required this.dogPuppy,
    required this.dogMiniAdult,
    required this.dogMiniPuppy,
    required this.factors,
    required this.miniAdultFactors,
    required this.miniPuppyFactors,
    required this.adultDogFactors,
    required this.puppyDogFactors,
  });

  final Map<String, int> catAdult;
  final Map<String, int> catKitten;
  final Map<String, int> dogAdult;
  final Map<String, int> dogPuppy;
  final Map<String, int> dogMiniAdult;
  final Map<String, int> dogMiniPuppy;
  final FeedingFactors factors;
  final MiniAdultDogFactors miniAdultFactors;
  final MiniPuppyFactors miniPuppyFactors;
  final MiniAdultDogFactors adultDogFactors;
  final StandardPuppyFactors puppyDogFactors;

  static SystemFeedingTables get defaults {
    return SystemFeedingTables(
      catAdult: {
        for (final row in CatFeedingGuide.rows) row.catKgLabel: row.baseGrams,
        '10+ kg': CatFeedingGuide.rows.last.baseGrams,
      },
      catKitten: KittenFeedingGuide.defaultGrams,
      dogAdult: AdultDogFeedingGuide.defaultGrams,
      dogPuppy: StandardPuppyFeedingGuide.defaultGrams,
      dogMiniAdult: MiniAdultDogFeedingGuide.defaultGrams,
      dogMiniPuppy: MiniPuppyFeedingGuide.defaultGrams,
      factors: FeedingFactors.defaults,
      miniAdultFactors: MiniAdultDogFactors.defaults,
      miniPuppyFactors: MiniPuppyFactors.defaults,
      adultDogFactors: MiniAdultDogFactors.defaults,
      puppyDogFactors: StandardPuppyFactors.defaults,
    );
  }

  factory SystemFeedingTables.fromMap(Map<String, dynamic>? data) {
    final base = defaults;
    if (data == null || data.isEmpty) return base;
    return SystemFeedingTables(
      catAdult: _merge(base.catAdult, data[FeedingGuideFields.catAdult]),
      catKitten: _mergeKitten(base.catKitten, data[FeedingGuideFields.catKitten]),
      dogAdult: _mergeKg(base.dogAdult, data[FeedingGuideFields.dogAdult]),
      dogPuppy: _mergeKitten(base.dogPuppy, data[FeedingGuideFields.dogPuppy]),
      dogMiniAdult:
          _merge(base.dogMiniAdult, data[FeedingGuideFields.dogMiniAdult]),
      dogMiniPuppy:
          _mergeKitten(base.dogMiniPuppy, data[FeedingGuideFields.dogMiniPuppy]),
      factors: FeedingFactors.fromMap(
        data[FeedingGuideFields.factors] is Map
            ? Map<String, dynamic>.from(
                data[FeedingGuideFields.factors] as Map,
              )
            : null,
      ),
      miniAdultFactors: MiniAdultDogFactors.fromMap(
        data[FeedingGuideFields.miniAdultDogFactors] is Map
            ? Map<String, dynamic>.from(
                data[FeedingGuideFields.miniAdultDogFactors] as Map,
              )
            : null,
      ),
      miniPuppyFactors: MiniPuppyFactors.fromMap(
        data[FeedingGuideFields.miniPuppyFactors] is Map
            ? Map<String, dynamic>.from(
                data[FeedingGuideFields.miniPuppyFactors] as Map,
              )
            : null,
      ),
      adultDogFactors: MiniAdultDogFactors.fromMap(
        data[FeedingGuideFields.adultDogFactors] is Map
            ? Map<String, dynamic>.from(
                data[FeedingGuideFields.adultDogFactors] as Map,
              )
            : null,
      ),
      puppyDogFactors: StandardPuppyFactors.fromMap(
        data[FeedingGuideFields.puppyDogFactors] is Map
            ? Map<String, dynamic>.from(
                data[FeedingGuideFields.puppyDogFactors] as Map,
              )
            : null,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        FeedingGuideFields.catAdult: catAdult,
        FeedingGuideFields.catKitten: catKitten,
        FeedingGuideFields.dogAdult: dogAdult,
        FeedingGuideFields.dogPuppy: dogPuppy,
        FeedingGuideFields.dogMiniAdult: dogMiniAdult,
        FeedingGuideFields.dogMiniPuppy: dogMiniPuppy,
        FeedingGuideFields.factors: factors.toMap(),
        FeedingGuideFields.miniAdultDogFactors: miniAdultFactors.toMap(),
        FeedingGuideFields.miniPuppyFactors: miniPuppyFactors.toMap(),
        FeedingGuideFields.adultDogFactors: adultDogFactors.toMap(),
        FeedingGuideFields.puppyDogFactors: puppyDogFactors.toMap(),
        FeedingGuideFields.updatedAt: FieldValue.serverTimestamp(),
      };

  static Map<String, int> _mergeKg(Map<String, int> fallback, dynamic raw) {
    final out = Map<String, int>.from(fallback);
    if (raw is! Map) return out;
    raw.forEach((key, value) {
      if (!RegExp(r'^\d+ kg$').hasMatch('$key')) return;
      final grams = switch (value) {
        num n => n.round(),
        String s => int.tryParse(s.trim()),
        _ => null,
      };
      if (grams != null && grams > 0) out['$key'] = grams;
    });
    return out;
  }

  static Map<String, int> _merge(Map<String, int> fallback, dynamic raw) {
    final out = Map<String, int>.from(fallback);
    if (raw is! Map) return out;
    raw.forEach((key, value) {
      final grams = switch (value) {
        num n => n.round(),
        String s => int.tryParse(s.trim()),
        _ => null,
      };
      if (grams != null && grams > 0) out['$key'] = grams;
    });
    return out;
  }

  static Map<String, int> _mergeKitten(Map<String, int> fallback, dynamic raw) {
    final out = Map<String, int>.from(fallback);
    if (raw is! Map) return out;
    raw.forEach((key, value) {
      if (!'$key'.contains('|')) return;
      final grams = switch (value) {
        num n => n.round(),
        String s => int.tryParse(s.trim()),
        _ => null,
      };
      if (grams != null && grams > 0) out['$key'] = grams;
    });
    return out;
  }
}

class SystemFeedingRepository extends ChangeNotifier {
  SystemFeedingRepository._();
  static final SystemFeedingRepository instance = SystemFeedingRepository._();

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection(FirestoreCollections.settings)
      .doc(SettingsDocs.feedingGuides);

  SystemFeedingTables _cached = SystemFeedingTables.defaults;
  bool _listening = false;

  SystemFeedingTables get cached => _cached;

  void startListening() {
    if (_listening) return;
    _listening = true;
    _apply(_cached);
    _doc.snapshots().listen((snap) {
      _cached = SystemFeedingTables.fromMap(snap.data());
      _apply(_cached);
      notifyListeners();
    });
  }

  Stream<SystemFeedingTables> watch() {
    startListening();
    return _doc.snapshots().map((snap) {
      final tables = SystemFeedingTables.fromMap(snap.data());
      _cached = tables;
      _apply(tables);
      return tables;
    });
  }

  Future<SystemFeedingTables> get() async {
    final snap = await _doc.get();
    final tables = SystemFeedingTables.fromMap(snap.data());
    _cached = tables;
    _apply(tables);
    return tables;
  }

  Future<void> save(SystemFeedingTables tables) {
    _cached = tables;
    _apply(tables);
    notifyListeners();
    return _doc.set(tables.toMap(), SetOptions(merge: true));
  }

  void _apply(SystemFeedingTables tables) {
    CatFeedingGuide.gramsOverride = tables.catAdult;
    CatFeedingGuide.factors = tables.factors;
    KittenFeedingGuide.gramsOverride = tables.catKitten;
    AdultDogFeedingGuide.gramsOverride = tables.dogAdult;
    AdultDogFeedingGuide.factors = tables.adultDogFactors;
    MiniAdultDogFeedingGuide.gramsOverride = tables.dogMiniAdult;
    MiniAdultDogFeedingGuide.factors = tables.miniAdultFactors;
    MiniPuppyFeedingGuide.gramsOverride = tables.dogMiniPuppy;
    MiniPuppyFeedingGuide.factors = tables.miniPuppyFactors;
    StandardPuppyFeedingGuide.gramsOverride = tables.dogPuppy;
    StandardPuppyFeedingGuide.factors = tables.puppyDogFactors;
    PuppyFeedingGuide.standardOverride = const {};
    PuppyFeedingGuide.miniOverride = const {};
  }
}
