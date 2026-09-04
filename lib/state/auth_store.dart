import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';

class AuthStore extends ChangeNotifier {
  AuthStore._() {
    unawaited(_auth.setLanguageCode('tr'));
    _auth.authStateChanges().listen((user) async {
      await _onAuthChanged(user);
      if (!_authReady) {
        _authReady = true;
        notifyListeners();
      }
    });
  }

  static final AuthStore instance = AuthStore._();

  /// Çıkıştan hemen önce (kedi/mama kaydı için).
  static Future<void> Function()? beforeLogout;

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  bool _isLoggedIn = false;
  bool _isBusy = false;
  bool _authReady = false;
  String _fullName = '';
  String _phone = '';
  String _email = '';
  String _birthDate = '';
  String _gender = '';
  String? _uid;
  bool _otpReady = false;
  bool _emailVerified = false;

  bool get isLoggedIn => _isLoggedIn;
  bool get isBusy => _isBusy;
  bool get authReady => _authReady;
  String get fullName => _fullName;
  String get phone => _phone;
  String get email => _email;
  String get birthDate => _birthDate;
  String get gender => _gender;
  String? get uid => _uid;

  bool get isPhoneVerified {
    final phone = _auth.currentUser?.phoneNumber;
    return phone != null && phone.isNotEmpty;
  }

  bool get isEmailVerified =>
      _emailVerified || _auth.currentUser?.emailVerified == true;

  String get firstName {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  static bool _isPlaceholderName(String value) {
    final n = value.trim().toLowerCase();
    return n.isEmpty || n == 'üye' || n == 'uye' || n == 'member';
  }

  static String _realName(Iterable<String?> values) {
    for (final value in values) {
      final n = (value ?? '').trim();
      if (!_isPlaceholderName(n)) return n;
    }
    return '';
  }

  /// TR numarayı E.164 (+90...) formatına çevirir.
  static String normalizePhone(String raw) {
    var digits = raw.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('00')) {
      digits = digits.substring(2);
    }
    if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    if (digits.startsWith('90') && digits.length == 12) {
      return '+$digits';
    }
    if (digits.length == 10) {
      return '+90$digits';
    }
    if (raw.trim().startsWith('+') && digits.length >= 10) {
      return '+$digits';
    }
    throw const FormatException('Geçersiz telefon numarası');
  }

  Future<void> _onAuthChanged(User? user) async {
    if (user == null) {
      _isLoggedIn = false;
      _fullName = '';
      _phone = '';
      _email = '';
      _birthDate = '';
      _gender = '';
      _uid = null;
      _emailVerified = false;
      notifyListeners();
      return;
    }

    _uid = user.uid;
    _phone = user.phoneNumber ?? _phone;
    _isLoggedIn = true;

    try {
      DocumentSnapshot<Map<String, dynamic>> snap;
      try {
        snap = await _db
            .collection('users')
            .doc(user.uid)
            .get(const GetOptions(source: Source.server));
      } catch (_) {
        snap = await _db.collection('users').doc(user.uid).get();
      }
      applyProfileDoc(snap.data(), replaceMissing: true);
    } catch (_) {
      // Offline / rules: local state yeterli.
    }

    if (_isPlaceholderName(_fullName)) {
      _fullName = _realName([user.displayName]);
      if (_fullName.isEmpty) {
        _fullName = 'Üye';
      }
    }
    notifyListeners();
  }

  void applyProfileDoc(
    Map<String, dynamic>? data, {
    bool replaceMissing = false,
  }) {
    if (data == null) {
      if (replaceMissing) {
        _email = '';
        _birthDate = '';
        _gender = '';
        _emailVerified = false;
      }
      return;
    }
    final fromDoc = _realName([
      data['display_name'] as String?,
      data['fullName'] as String?,
    ]);
    if (fromDoc.isNotEmpty) {
      _fullName = fromDoc;
    }
    _phone =
        (data['phone_number'] as String?)?.trim() ??
        (data['phone'] as String?)?.trim() ??
        _phone;
    final email = (data['email'] as String?)?.trim() ?? '';
    if (replaceMissing || email.isNotEmpty) _email = email;
    if (data.containsKey('email_verified') || data.containsKey('emailVerified')) {
      _emailVerified =
          data['email_verified'] == true || data['emailVerified'] == true;
    }
    final birth = (data['birth_date'] as String?)?.trim() ?? '';
    if (replaceMissing || birth.isNotEmpty) _birthDate = birth;
    final gender = (data['gender'] as String?)?.trim() ?? '';
    if (replaceMissing || gender.isNotEmpty) _gender = gender;
  }

  void notifyProfileUpdated() => notifyListeners();

  Future<void> updateProfile({
    String? fullName,
    String? email,
    String? birthDate,
    String? gender,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final name = (fullName ?? _fullName).trim();
    final nextEmail = (email ?? _email).trim();
    final nextBirth = (birthDate ?? _birthDate).trim();
    final nextGender = (gender ?? _gender).trim();

    if (!_isPlaceholderName(name)) {
      _fullName = name;
      if (user.displayName != name) {
        await user.updateDisplayName(name);
      }
    }
    _email = nextEmail;
    _birthDate = nextBirth;
    _gender = nextGender;
    notifyListeners();

    try {
      await _db.collection('users').doc(user.uid).set({
        if (!_isPlaceholderName(_fullName)) 'display_name': _fullName,
        'email': _email,
        'email_verified': _emailVerified,
        'birth_date': _birthDate,
        'gender': _gender,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Firestore profile update failed: $e');
    }
    await UserDocPersist.waitForServer();
  }

  Future<void> sendCode(String phoneRaw) async {
    final e164 = normalizePhone(phoneRaw);
    _setBusy(true);
    try {
      await _functions.httpsCallable('sendLoginCode').call({'phone': e164});
      _otpReady = true;
      _phone = e164;
      notifyListeners();
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'SMS gönderilemedi.',
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> sendEmailCode(String rawEmail) async {
    final email = rawEmail.trim().toLowerCase();
    if (_auth.currentUser == null) {
      throw FirebaseAuthException(
        code: 'unauthenticated',
        message: 'Giriş yapın.',
      );
    }
    _setBusy(true);
    try {
      await _functions.httpsCallable('sendEmailCode').call({'email': email});
      _email = email;
      _emailVerified = false;
      notifyListeners();
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'Doğrulama kodu gönderilemedi.',
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> verifyEmailCode({
    required String email,
    required String code,
  }) async {
    _setBusy(true);
    try {
      await _functions.httpsCallable('verifyEmailCode').call({
        'email': email.trim().toLowerCase(),
        'code': code.trim(),
      });
      _email = email.trim();
      _emailVerified = true;
      notifyListeners();
      await updateProfile(email: _email);
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'E-posta doğrulanamadı.',
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> verifyCode({
    required String smsCode,
    String? fullName,
    bool requireExistingUser = false,
  }) async {
    if (!_otpReady) {
      throw FirebaseAuthException(
        code: 'missing-verification',
        message: 'Önce SMS kodu gönderin.',
      );
    }
    _setBusy(true);
    try {
      final result = await _functions.httpsCallable('verifyLoginCode').call({
        'phone': _phone,
        'code': smsCode.trim(),
        'fullName': (fullName ?? _fullName).trim(),
        'requireExistingUser': requireExistingUser,
      });
      final raw = result.data;
      if (raw is! Map) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Giriş başarısız.',
        );
      }
      final data = Map<String, dynamic>.from(raw);
      final token = data['token'] as String?;
      if (token == null || token.isEmpty) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Giriş başarısız.',
        );
      }
      final cred = await _auth.signInWithCustomToken(token);
      final user = cred.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Giriş başarısız.',
        );
      }

      await user.reload();
      final signedIn = _auth.currentUser ?? user;
      final doc = _db.collection('users').doc(signedIn.uid);
      final existing = await doc.get();

      final resolvedName = _realName([
        fullName,
        data['displayName'] as String?,
        existing.data()?['display_name'] as String?,
        existing.data()?['fullName'] as String?,
        signedIn.displayName,
        _fullName,
      ]);
      if (resolvedName.isNotEmpty) {
        if (signedIn.displayName != resolvedName) {
          await signedIn.updateDisplayName(resolvedName);
        }
        _fullName = resolvedName;
      } else {
        _fullName = 'Üye';
      }

      final resolvedPhone =
          signedIn.phoneNumber ??
          (data['phone'] as String?) ??
          _phone;

      try {
        final existingRole =
            (existing.data()?['user_role'] as String?) ??
            (existing.data()?['role'] as String?);
        final keepAdmin = existingRole == 'admin';
        await doc.set({
          'uid': signedIn.uid,
          if (!_isPlaceholderName(_fullName)) 'display_name': _fullName,
          'phone_number': resolvedPhone,
          'user_role': keepAdmin ? 'admin' : 'customer',
          'is_guest': false,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!existing.exists) 'created_time': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore user profile write failed: $e');
      }

      _uid = signedIn.uid;
      _phone = resolvedPhone;
      _isLoggedIn = true;
      _authReady = true;
      notifyListeners();
    } on FirebaseFunctionsException catch (e) {
      throw FirebaseAuthException(
        code: e.code,
        message: e.message ?? 'Doğrulama başarısız.',
      );
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    try {
      await beforeLogout?.call();
      await _auth.signOut();
      _otpReady = false;
      _isLoggedIn = false;
      _fullName = '';
      _phone = '';
      _email = '';
      _birthDate = '';
      _gender = '';
      _uid = null;
      _emailVerified = false;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  void _setBusy(bool value) {
    _isBusy = value;
    notifyListeners();
  }

  static String friendlyError(Object error) {
    final text = error.toString();
    if (text.contains('BILLING_NOT_ENABLED')) {
      return 'Gerçek SMS için Firebase’de Blaze (faturalandırma) gerekir. Test numarası + 123456 kullanın.';
    }

    if (text.contains('Error code:39') ||
        text.contains('Error code: 39') ||
        text.contains('error-code:-39')) {
      return 'Firebase SMS kotası doldu. Kod artık NetGSM ile gider; yeni uygulama sürümünü yükleyin veya 1 saat sonra deneyin.';
    }

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'Geçersiz telefon numarası.';
        case 'invalid-argument':
          final argMsg = error.message ?? '';
          return argMsg.isNotEmpty ? argMsg : 'Geçersiz bilgi girdiniz.';
        case 'too-many-requests':
        case 'resource-exhausted':
          return 'Çok fazla deneme. Bir süre sonra tekrar deneyin.';
        case 'invalid-verification-code':
        case 'invalid-verification-id':
        case 'permission-denied':
          return 'Doğrulama kodu hatalı veya süresi dolmuş. Kodu tekrar gönderin.';
        case 'session-expired':
        case 'deadline-exceeded':
          return 'Kodun süresi doldu. Kodu tekrar gönderin.';
        case 'unavailable':
          return error.message ?? 'Kod gönderilemedi. Biraz sonra tekrar deneyin.';
        case 'already-exists':
        case 'email-already-in-use':
        case 'email-already-exists':
          return 'Bu e-posta başka bir hesapta kayıtlı.';
        case 'invalid-email':
          return 'Geçerli bir e-posta girin.';
        case 'user-token-expired':
        case 'invalid-user-token':
        case 'user-disabled':
          return 'Oturumun yenilenmeli. Çıkış yapıp tekrar giriş yapın.';
        case 'user-not-found':
        case 'not-found':
          return 'Bu telefon numarası sistemde kayıtlı değil. Önce kayıt olun.';
        case 'missing-verification':
        case 'failed-precondition':
          return 'Önce “Kod Gönder”e basıp SMS kodunu alın.';
        case 'missing-client-identifier':
        case 'app-not-authorized':
          if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
            return 'iOS doğrulaması tamamlanamadı. Uygulamayı kapatıp tekrar deneyin.';
          }
          return 'Android SHA-1 eksik. Firebase Console’a SHA-1 ekleyin.';
        case 'timeout':
          return 'SMS gönderimi zaman aşımına uğradı.';
        case 'custom-token-mismatch':
        case 'invalid-custom-token':
          return 'Giriş oturumu oluşturulamadı. Kodu tekrar gönderip deneyin.';
        case 'internal':
          final internalMsg = error.message ?? '';
          return internalMsg.isNotEmpty && internalMsg != 'internal'
              ? internalMsg
              : 'Giriş tamamlanamadı. Kodu tekrar gönderip deneyin.';
        default:
          final msg = error.message ?? '';
          if (msg.contains('BILLING_NOT_ENABLED')) {
            return 'Gerçek SMS için Firebase’de Blaze (faturalandırma) gerekir. Test numarası + 123456 kullanın.';
          }
          return msg.isNotEmpty ? msg : 'Giriş hatası (${error.code}).';
      }
    }
    if (error is FormatException) {
      return error.message;
    }
    if (text.contains('BILLING_NOT_ENABLED')) {
      return 'Gerçek SMS için Firebase’de Blaze (faturalandırma) gerekir. Test numarası + 123456 kullanın.';
    }
    return 'Beklenmeyen bir hata oluştu. Önce Kod Gönder, sonra SMS kodunu girin (şifre değil).';
  }
}
