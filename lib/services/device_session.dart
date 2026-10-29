import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

/// Bu cihazın kimliği ve “hesabı açık tut” tercihi.
class DeviceSession {
  DeviceSession._();

  static const _deviceKey = 'auth_device_id';
  static const _keepKey = 'auth_keep_account_open';

  /// Bu açılışta kullanıcı az önce giriş yaptıysa oturumu düşürme.
  static bool claimedThisLaunch = false;

  static Future<String> deviceId() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_deviceKey)?.trim() ?? '';
    if (existing.length >= 12) return existing;
    final created = _newId();
    await prefs.setString(_deviceKey, created);
    return created;
  }

  static Future<bool> keepAccountOpen() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keepKey) ?? true;
  }

  static Future<void> setKeepAccountOpen(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keepKey, value);
  }

  static String _newId() {
    final random = Random.secure();
    final time = DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final extra = List.generate(
      4,
      (_) => random.nextInt(0x10000).toRadixString(16).padLeft(4, '0'),
    ).join();
    return '$time$extra';
  }
}
