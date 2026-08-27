import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdminAuth extends ChangeNotifier {
  AdminAuth._() {
    _auth.authStateChanges().listen((_) {
      // Giriş denemesi sürerken state değişimini elle yönetiyoruz.
      if (_busy) return;
      _refresh();
    });
  }

  static final AdminAuth instance = AdminAuth._();

  static const _rememberKey = 'admin_remember_me';
  static const _emailKey = 'admin_remembered_email';

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  SharedPreferences? _prefs;
  bool _ready = false;
  bool _busy = false;
  bool _isAdmin = false;
  bool _rememberMe = true;
  String? _email;
  String? _rememberedEmail;
  String? _error;
  String? _uid;

  bool get ready => _ready;
  bool get busy => _busy;
  bool get isAdmin => _isAdmin;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get rememberMe => _rememberMe;
  String? get email => _email;
  String? get rememberedEmail => _rememberedEmail;
  String? get error => _error;
  String? get uid => _uid;

  /// Oturumu geri yüklemeden önce kalıcılık tercihini uygular.
  Future<void> init() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      _rememberMe = _prefs?.getBool(_rememberKey) ?? true;
      _rememberedEmail = _prefs?.getString(_emailKey);
    } catch (_) {
      // Tercih okunamadıysa varsayılan davranış sürer.
    }

    if (kIsWeb) {
      try {
        await _auth.setPersistence(
          _rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      } catch (_) {
        // Kalıcılık ayarlanamazsa Firebase varsayılanı kullanılır.
      }
    }

    await _refresh();
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    notifyListeners();
    await _prefs?.setBool(_rememberKey, value);
  }

  Future<void> _refresh({bool clearError = true}) async {
    final user = _auth.currentUser;
    _email = user?.email;
    _uid = user?.uid;
    _isAdmin = false;
    if (clearError) _error = null;

    if (user == null) {
      _ready = true;
      notifyListeners();
      return;
    }

    try {
      final snap = await _db
          .collection(FirestoreCollections.users)
          .doc(user.uid)
          .get();
      final data = snap.data();
      final role =
          (data?[UserFields.userRole] as String?) ??
          (data?[UserFields.role] as String?);
      _isAdmin = role == 'admin';
      if (!_isAdmin) {
        _error = !snap.exists
            ? 'Giriş oldu ama Firestore users/${user.uid} dokümanı yok. '
                  'Console’da bu dokümanı oluşturup user_role: admin yazın.'
            : 'Bu hesap admin değil. users/${user.uid} içinde '
                  'user_role alanını "admin" yapın.';
        await _auth.signOut();
        _email = null;
        _uid = null;
      }
    } catch (e) {
      _error = 'Rol kontrolü başarısız: $e';
      _isAdmin = false;
      await _auth.signOut();
      _email = null;
      _uid = null;
    }

    _ready = true;
    notifyListeners();
  }

  Future<void> signIn({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      _error = 'E-posta ve şifre gerekli.';
      notifyListeners();
      return;
    }

    _busy = true;
    _rememberMe = rememberMe;
    _error = null;
    notifyListeners();
    try {
      if (kIsWeb) {
        await _auth.setPersistence(
          rememberMe ? Persistence.LOCAL : Persistence.SESSION,
        );
      }
      await _auth.signInWithEmailAndPassword(
        email: trimmedEmail,
        password: password,
      );
      await _refresh(clearError: false);
      if (!_isAdmin && _error == null) {
        _error = 'Admin yetkisi bulunamadı.';
      }
      if (_isAdmin) await _persistRemembered(trimmedEmail);
    } on FirebaseAuthException catch (e) {
      _error = switch (e.code) {
        'invalid-email' => 'Geçersiz e-posta adresi.',
        'user-not-found' =>
          'Bu e-posta Firebase Authentication’da yok. '
              'Console → Authentication → Add user ile ekleyin.',
        'wrong-password' => 'Şifre hatalı.',
        'invalid-credential' =>
          'E-posta veya şifre hatalı. Hesap yoksa Firebase Authentication’a '
              'Email/Password kullanıcısı eklemeniz gerekir.',
        'user-disabled' => 'Bu hesap devre dışı bırakılmış.',
        'too-many-requests' => 'Çok fazla deneme. Biraz sonra tekrar deneyin.',
        'operation-not-allowed' =>
          'Email/Password girişi kapalı. Firebase Console → Authentication → '
              'Sign-in method → Email/Password’ü açın.',
        _ => e.message ?? 'Giriş başarısız (${e.code}).',
      };
    } catch (e) {
      _error = '$e';
    } finally {
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> _persistRemembered(String email) async {
    final prefs = _prefs;
    if (prefs == null) return;
    await prefs.setBool(_rememberKey, _rememberMe);
    if (_rememberMe) {
      _rememberedEmail = email;
      await prefs.setString(_emailKey, email);
    } else {
      _rememberedEmail = null;
      await prefs.remove(_emailKey);
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    _isAdmin = false;
    _email = null;
    _uid = null;
    notifyListeners();
  }
}
