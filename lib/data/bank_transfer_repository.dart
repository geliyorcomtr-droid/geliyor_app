import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

class BankTransferInfo {
  const BankTransferInfo({
    this.holder = '',
    this.iban = '',
  });

  final String holder;
  final String iban;

  static const defaults = BankTransferInfo(
    holder: 'FATİH EROĞLU',
    iban: 'TR640006200012345678901234',
  );

  bool get isComplete => holder.trim().isNotEmpty && compactIban.length >= 16;

  String get compactIban =>
      iban.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();

  String get formattedIban => formatIban(iban);

  factory BankTransferInfo.fromMap(Map<String, dynamic> data) {
    return BankTransferInfo(
      holder: (data[BankTransferFields.holder] as String?)?.trim() ?? '',
      iban: (data[BankTransferFields.iban] as String?)?.trim() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    BankTransferFields.holder: holder.trim(),
    BankTransferFields.iban: compactIban,
    BankTransferFields.updatedAt: FieldValue.serverTimestamp(),
  };

  static String formatIban(String raw) {
    var compact = raw.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    if (compact.length > 26) compact = compact.substring(0, 26);
    if (compact.isEmpty) return '';
    final buffer = StringBuffer();
    for (var i = 0; i < compact.length; i++) {
      if (i > 0 && i % 4 == 0) buffer.write(' ');
      buffer.write(compact[i]);
    }
    return buffer.toString();
  }
}

class BankTransferRepository {
  BankTransferRepository._();
  static final BankTransferRepository instance = BankTransferRepository._();

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection(FirestoreCollections.settings)
      .doc(SettingsDocs.bankTransfer);

  Stream<BankTransferInfo> watch() {
    return _doc.snapshots().map((snap) {
      if (!snap.exists) return BankTransferInfo.defaults;
      final info = BankTransferInfo.fromMap(snap.data() ?? {});
      if (!info.isComplete) return BankTransferInfo.defaults;
      return info;
    });
  }

  Future<BankTransferInfo> get() async {
    final snap = await _doc.get();
    if (!snap.exists) return BankTransferInfo.defaults;
    final info = BankTransferInfo.fromMap(snap.data() ?? {});
    if (!info.isComplete) return BankTransferInfo.defaults;
    return info;
  }

  Future<void> save(BankTransferInfo info) {
    return _doc.set(info.toMap(), SetOptions(merge: true));
  }
}
