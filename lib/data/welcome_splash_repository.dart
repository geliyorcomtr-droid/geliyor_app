import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/utils/local_image_cache.dart';
import 'package:shared_preferences/shared_preferences.dart';

class WelcomeSplashRepository extends ChangeNotifier {
  WelcomeSplashRepository._();
  static final instance = WelcomeSplashRepository._();

  static const canvasWidth = 393;
  static const canvasHeight = 852;
  static const _cacheKey = 'welcome_splash_image_url';

  String? _memoryUrl;

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection(FirestoreCollections.settings)
      .doc(SettingsDocs.welcomeSplash);

  String get imageUrl => (_memoryUrl ?? '').trim();

  Uint8List? get localBytes =>
      LocalImageCache.instance.peekNamed(LocalImageCache.splashName) ??
      LocalImageCache.instance.peek(imageUrl);

  Future<void> preloadLocal() async {
    await LocalImageCache.instance.hydrate();
    final prefs = await SharedPreferences.getInstance();
    _memoryUrl = (prefs.getString(_cacheKey) ?? '').trim();
  }

  Stream<String> watchImageUrl() {
    return _doc.snapshots().map((snap) {
      final url = _urlFrom(snap.data());
      unawaited(remember(url));
      return url;
    });
  }

  Future<String> cachedImageUrl() async {
    if (_memoryUrl != null) return _memoryUrl!;
    final prefs = await SharedPreferences.getInstance();
    final url = (prefs.getString(_cacheKey) ?? '').trim();
    _memoryUrl = url;
    return url;
  }

  Future<String> fetchImageUrl() async {
    final snap = await _doc.get();
    final url = _urlFrom(snap.data());
    await remember(url);
    return url;
  }

  Future<void> saveImageUrl(String url) {
    final cleaned = url.trim();
    unawaited(remember(cleaned));
    return _doc.set({
      WelcomeSplashFields.imageUrl: cleaned,
      WelcomeSplashFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Future<void> clearImage() => saveImageUrl('');

  Future<void> remember(String url) async {
    final cleaned = url.trim();
    final changed = cleaned != (_memoryUrl ?? '');
    _memoryUrl = cleaned;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cacheKey, cleaned);
    if (cleaned.isEmpty) {
      await LocalImageCache.instance.rememberNamed(
        LocalImageCache.splashName,
        '',
      );
    } else {
      await LocalImageCache.instance.rememberNamed(
        LocalImageCache.splashName,
        cleaned,
      );
    }
    if (changed) notifyListeners();
  }

  static String _urlFrom(Map<String, dynamic>? data) {
    return ((data?[WelcomeSplashFields.imageUrl] as String?) ?? '').trim();
  }
}
