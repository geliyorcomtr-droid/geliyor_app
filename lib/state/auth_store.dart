import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class AuthStore extends ChangeNotifier {
  AuthStore._() {
    _auth.authStateChanges().listen(_onAuthChanged);
  }

  static final AuthStore instance = AuthStore._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  bool _isLoggedIn = false;
  bool _isBusy = false;
  String _fullName = '';
  String _phone = '';
  String? _uid;
  String? _verificationId;
  int? _resendToken;

  bool get isLoggedIn => _isLoggedIn;
  bool get isBusy => _isBusy;
  String get fullName => _fullName;
  String get phone => _phone;
  String? get uid => _uid;

  String get firstName {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
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
      _uid = null;
      notifyListeners();
      return;
    }

    _uid = user.uid;
    _phone = user.phoneNumber ?? _phone;
    _isLoggedIn = true;

    try {
      final snap = await _db.collection('users').doc(user.uid).get();
      final data = snap.data();
      if (data != null) {
        _fullName =
            (data['display_name'] as String?)?.trim() ??
            (data['fullName'] as String?)?.trim() ??
            _fullName;
        _phone =
            (data['phone_number'] as String?)?.trim() ??
            (data['phone'] as String?)?.trim() ??
            _phone;
      }
    } catch (_) {
      // Offline / rules: local state yeterli.
    }

    if (_fullName.isEmpty) {
      _fullName = user.displayName?.trim().isNotEmpty == true
          ? user.displayName!.trim()
          : 'Üye';
    }
    notifyListeners();
  }

  Future<void> sendCode(String phoneRaw) async {
    final e164 = normalizePhone(phoneRaw);
    _setBusy(true);
    final completer = Completer<void>();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: e164,
        forceResendingToken: _resendToken,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (credential) async {
          try {
            await _auth.signInWithCredential(credential);
            if (!completer.isCompleted) completer.complete();
          } catch (e) {
            if (!completer.isCompleted) completer.completeError(e);
          }
        },
        verificationFailed: (e) {
          if (!completer.isCompleted) completer.completeError(e);
        },
        codeSent: (verificationId, resendToken) {
          _verificationId = verificationId;
          _resendToken = resendToken;
          _phone = e164;
          notifyListeners();
          if (!completer.isCompleted) completer.complete();
        },
        codeAutoRetrievalTimeout: (verificationId) {
          _verificationId = verificationId;
        },
      );

      await completer.future.timeout(
        const Duration(seconds: 70),
        onTimeout: () {
          throw FirebaseAuthException(
            code: 'timeout',
            message: 'SMS gönderimi zaman aşımına uğradı.',
          );
        },
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
    final id = _verificationId;
    if (id == null) {
      throw FirebaseAuthException(
        code: 'missing-verification',
        message: 'Önce SMS kodu gönderin.',
      );
    }
    _setBusy(true);
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: id,
        smsCode: smsCode.trim(),
      );
      final result = await _auth.signInWithCredential(credential);
      final user = result.user;
      if (user == null) {
        throw FirebaseAuthException(
          code: 'null-user',
          message: 'Giriş başarısız.',
        );
      }

      final doc = _db.collection('users').doc(user.uid);
      final existing = await doc.get();
      if (requireExistingUser && !existing.exists) {
        await _auth.signOut();
        throw FirebaseAuthException(
          code: 'user-not-found',
          message: 'Bu telefon numarası sistemde kayıtlı değil.',
        );
      }

      final name = (fullName ?? _fullName).trim();
      if (name.isNotEmpty) {
        await user.updateDisplayName(name);
        _fullName = name;
      }

      final resolvedName = _fullName.isEmpty ? 'Üye' : _fullName;
      final resolvedPhone = user.phoneNumber ?? _phone;

      try {
        final existingRole =
            (existing.data()?['user_role'] as String?) ??
            (existing.data()?['role'] as String?);
        final keepAdmin = existingRole == 'admin';
        await doc.set({
          'uid': user.uid,
          'display_name': resolvedName,
          'phone_number': resolvedPhone,
          'user_role': keepAdmin ? 'admin' : 'customer',
          'is_guest': false,
          'updatedAt': FieldValue.serverTimestamp(),
          if (!existing.exists) 'created_time': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Firestore user profile write failed: $e');
      }

      _uid = user.uid;
      _phone = resolvedPhone;
      _fullName = resolvedName;
      _isLoggedIn = true;
      notifyListeners();
    } finally {
      _setBusy(false);
    }
  }

  Future<void> logout() async {
    _setBusy(true);
    try {
      await _auth.signOut();
      _verificationId = null;
      _resendToken = null;
      _isLoggedIn = false;
      _fullName = '';
      _phone = '';
      _uid = null;
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

    if (error is FirebaseAuthException) {
      switch (error.code) {
        case 'invalid-phone-number':
          return 'Geçersiz telefon numarası.';
        case 'too-many-requests':
          return 'Çok fazla deneme. Bir süre sonra tekrar deneyin.';
        case 'invalid-verification-code':
        case 'invalid-verification-id':
          return 'SMS kodu hatalı veya süresi dolmuş. Kodu tekrar gönderin.';
        case 'session-expired':
          return 'Oturum süresi doldu. Kodu tekrar gönderin.';
        case 'user-not-found':
          return 'Bu telefon numarası sistemde kayıtlı değil. Önce kayıt olun.';
        case 'missing-verification':
          return 'Önce “Kod Gönder”e basıp SMS kodunu alın.';
        case 'missing-client-identifier':
        case 'app-not-authorized':
          return 'Android SHA-1 eksik. Firebase Console’a SHA-1 ekleyin.';
        case 'timeout':
          return 'SMS gönderimi zaman aşımına uğradı.';
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
