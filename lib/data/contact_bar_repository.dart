import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

class ContactBarRepository extends ChangeNotifier {
  ContactBarRepository._();
  static final ContactBarRepository instance = ContactBarRepository._();

  /// Kaynak görsel oranı. İki kutu satırı bu oranda bölünür.
  static const artWidth = 1024.0;
  static const artHeight = 201.0;

  /// Yüklenen dosya, WhatsApp kartıyla aynı ölçü.
  static const uploadWidth = 1024;
  static const uploadHeight = 201;

  static const defaultPhone = '05402990000';
  static const assetPath = 'assets/images/iletisim_no.png';
  static const whatsappAssetPath = 'assets/images/whatsapp_iletisim.png';

  bool _started = false;
  String _imageUrl = '';
  String _phone = defaultPhone;
  String _whatsappImageUrl = '';
  String _whatsappPhone = defaultPhone;

  String get imageUrl => _imageUrl;
  String get phone => _phone;
  String get whatsappImageUrl => _whatsappImageUrl;
  String get whatsappPhone => _whatsappPhone;

  /// 0540... numarasını WhatsApp ülke koduna çevirir.
  static String whatsappDigits(String phone) {
    var digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) digits = digits.substring(2);
    if (digits.startsWith('0')) digits = '90${digits.substring(1)}';
    if (digits.length == 10) digits = '90$digits';
    return digits;
  }

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection(FirestoreCollections.settings)
      .doc(SettingsDocs.contactBar);

  void startListening() {
    if (_started) return;
    _started = true;
    _doc.snapshots().listen(
      (snap) {
        final data = snap.data();
        _imageUrl = ((data?[ContactBarFields.imageUrl] as String?) ?? '')
            .trim();
        final phone = ((data?[ContactBarFields.phone] as String?) ?? '')
            .trim();
        _phone = phone.isEmpty ? defaultPhone : phone;
        _whatsappImageUrl =
            ((data?[ContactBarFields.whatsappImageUrl] as String?) ?? '')
                .trim();
        final whatsapp =
            ((data?[ContactBarFields.whatsappPhone] as String?) ?? '').trim();
        _whatsappPhone = whatsapp.isEmpty ? defaultPhone : whatsapp;
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('İletişim şeridi okunamadı: $error\n$stack');
      },
    );
  }

  Future<void> save({required String imageUrl, required String phone}) {
    final cleanedPhone = phone.trim().isEmpty ? defaultPhone : phone.trim();
    return _doc.set({
      ContactBarFields.imageUrl: imageUrl.trim(),
      ContactBarFields.phone: cleanedPhone,
      ContactBarFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> saveWhatsapp({
    required String imageUrl,
    required String phone,
  }) {
    final cleanedPhone = phone.trim().isEmpty ? defaultPhone : phone.trim();
    return _doc.set({
      ContactBarFields.whatsappImageUrl: imageUrl.trim(),
      ContactBarFields.whatsappPhone: cleanedPhone,
      ContactBarFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
