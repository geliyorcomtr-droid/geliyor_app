import 'package:flutter/foundation.dart';

class AuthStore extends ChangeNotifier {
  AuthStore._();
  static final AuthStore instance = AuthStore._();

  bool _isLoggedIn = false;
  String _fullName = '';
  String _phone = '';

  bool get isLoggedIn => _isLoggedIn;
  String get fullName => _fullName;
  String get phone => _phone;

  String get firstName {
    final parts = _fullName.trim().split(RegExp(r'\s+'));
    return parts.isEmpty ? '' : parts.first;
  }

  void login({
    required String phone,
    String fullName = '',
  }) {
    _isLoggedIn = true;
    _phone = phone.trim();
    if (fullName.trim().isNotEmpty) {
      _fullName = fullName.trim();
    } else if (_fullName.isEmpty) {
      _fullName = 'Üye';
    }
    notifyListeners();
  }

  void register({
    required String fullName,
    required String phone,
  }) {
    _isLoggedIn = true;
    _fullName = fullName.trim();
    _phone = phone.trim();
    notifyListeners();
  }

  void logout() {
    _isLoggedIn = false;
    _fullName = '';
    _phone = '';
    notifyListeners();
  }
}
