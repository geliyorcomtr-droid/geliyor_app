import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/widgets.dart';
import 'package:geliyor_app/services/user_profile_sync.dart';

/// Wi‑Fi / mobil veri düşünce Firestore’u bekletmez; geri gelince hemen açar.
class NetworkReconnect with WidgetsBindingObserver {
  NetworkReconnect._();

  static final NetworkReconnect instance = NetworkReconnect._();

  StreamSubscription<List<ConnectivityResult>>? _sub;
  var _started = false;
  var _offline = false;
  var _reconnecting = false;

  void start() {
    if (_started) return;
    _started = true;
    WidgetsBinding.instance.addObserver(this);
    _sub = Connectivity().onConnectivityChanged.listen(_onChange);
    unawaited(_prime());
  }

  Future<void> _prime() async {
    final results = await Connectivity().checkConnectivity();
    _offline = !_isOnline(results);
    if (!_offline) await _softReconnect();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_onResume());
    }
  }

  Future<void> _onResume() async {
    final results = await Connectivity().checkConnectivity();
    final online = _isOnline(results);
    if (!online) {
      _offline = true;
      return;
    }
    if (_offline) {
      _offline = false;
      await _hardReconnect();
      return;
    }
    await _softReconnect();
  }

  void _onChange(List<ConnectivityResult> results) {
    final online = _isOnline(results);
    if (!online) {
      _offline = true;
      return;
    }
    if (_offline) {
      _offline = false;
      unawaited(_hardReconnect());
      return;
    }
    unawaited(_softReconnect());
  }

  bool _isOnline(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }

  Future<void> _softReconnect() async {
    try {
      await FirebaseFirestore.instance.enableNetwork();
    } catch (_) {}
  }

  Future<void> _hardReconnect() async {
    if (_reconnecting) return;
    _reconnecting = true;
    final db = FirebaseFirestore.instance;
    try {
      try {
        await db.disableNetwork();
      } catch (_) {}
      await db.enableNetwork();
      await UserProfileSync.sync(force: true);
    } catch (_) {
      try {
        await db.enableNetwork();
      } catch (_) {}
    } finally {
      _reconnecting = false;
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(_sub?.cancel());
    _sub = null;
    _started = false;
  }
}
