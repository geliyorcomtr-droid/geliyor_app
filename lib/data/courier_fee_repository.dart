import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/utils/courier_fee.dart';

class CourierFeeRepository extends ChangeNotifier {
  CourierFeeRepository._();
  static final CourierFeeRepository instance = CourierFeeRepository._();

  bool _started = false;

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection(FirestoreCollections.settings)
      .doc(SettingsDocs.courierFee);

  void startListening() {
    if (_started) return;
    _started = true;
    _doc.snapshots().listen(
      (snap) {
        _apply(snap.data());
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Getirme ücreti ayarı okunamadı: $error\n$stack');
      },
    );
  }

  Future<void> get() async {
    final snap = await _doc.get();
    _apply(snap.data());
    notifyListeners();
  }

  Future<void> saveBoth({
    required double freeThreshold,
    required double amount,
  }) {
    return _save(freeThreshold: freeThreshold, amount: amount);
  }

  Future<void> _save({double? freeThreshold, double? amount}) {
    return _doc.set({
      if (freeThreshold != null) CourierFeeFields.freeThreshold: freeThreshold,
      if (amount != null) CourierFeeFields.amount: amount,
      CourierFeeFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  void _apply(Map<String, dynamic>? data) {
    final threshold = _nonNegative(data?[CourierFeeFields.freeThreshold]);
    final fee = _nonNegative(data?[CourierFeeFields.amount]);
    CourierFee.apply(
      freeThreshold: threshold ?? CourierFee.defaultFreeThreshold,
      amount: fee ?? CourierFee.defaultAmount,
    );
  }

  double? _nonNegative(dynamic raw) {
    final value = (raw as num?)?.toDouble();
    if (value == null || !value.isFinite || value < 0) return null;
    return value;
  }
}
