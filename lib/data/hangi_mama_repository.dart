import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';

class HangiMamaRepository {
  HangiMamaRepository._();
  static final instance = HangiMamaRepository._();

  static const defaultAdvantageIds = <String>[
    'sindirim',
    'bobrek',
    'tuy_deri',
    'kilo_kontrol',
    'bagisiklik',
    'dogal_icerik',
    'kalp',
    'dis',
    'kisir_kedi',
    'tahilsiz',
    'idrar',
    'eklem',
  ];

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection(FirestoreCollections.productAdvantages)
      .doc(ProductAdvantageRepository.hangiMamaConfigId);

  Stream<List<String>> watchAdvantageIds() {
    return _doc.snapshots().map((snap) => _idsFrom(snap.data()));
  }

  Future<List<String>> fetchAdvantageIds() async {
    final snap = await _doc.get();
    return _idsFrom(snap.data());
  }

  Future<void> saveAdvantageIds(List<String> ids) {
    final cleaned = [
      for (final id in ids)
        if (id.trim().isNotEmpty &&
            !ProductAdvantageRepository.isSystemDocId(id.trim()))
          id.trim(),
    ];
    return _doc.set({
      ProductAdvantageFields.name: 'Hangi Mama',
      ProductAdvantageFields.active: false,
      ProductAdvantageFields.order: -2,
      HangiMamaFields.advantageIds: cleaned,
      HangiMamaFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> ensureDefaults() async {
    try {
      final snap = await _doc.get();
      final existing = _idsFrom(snap.data(), allowDefault: false);
      if (existing.isNotEmpty) return;
      await saveAdvantageIds(defaultAdvantageIds);
    } on FirebaseException catch (error) {
      if (error.code == 'permission-denied') return;
      rethrow;
    }
  }

  static List<String> _idsFrom(
    Map<String, dynamic>? data, {
    bool allowDefault = true,
  }) {
    final raw = data?[HangiMamaFields.advantageIds];
    if (raw is! List) {
      return allowDefault ? defaultAdvantageIds : const [];
    }
    final ids = [
      for (final value in raw)
        if ('$value'.trim().isNotEmpty &&
            !ProductAdvantageRepository.isSystemDocId('$value'.trim()))
          '$value'.trim(),
    ];
    if (ids.isEmpty) return allowDefault ? defaultAdvantageIds : const [];
    return ids;
  }
}
