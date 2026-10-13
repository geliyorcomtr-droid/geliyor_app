import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geliyor_app/utils/local_image_disk_io.dart'
    if (dart.library.html) 'package:geliyor_app/utils/local_image_disk_stub.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Ağ görsellerini bellekte ve diskte tutar; sonraki açılışta anında gösterilir.
class LocalImageCache extends ChangeNotifier {
  LocalImageCache._();

  static final instance = LocalImageCache._();

  static const splashName = 'welcome_splash';
  static const _indexKey = 'local_image_urls';

  final Map<String, Uint8List> _mem = {};
  final Set<String> _inflight = {};
  var _hydrated = false;

  Uint8List? peek(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty) return null;
    return _mem[trimmed];
  }

  Uint8List? peekNamed(String name) => _mem[_namedKey(name)];

  Future<void> hydrate() async {
    if (_hydrated) return;
    _hydrated = true;
    try {
      final prefs = await SharedPreferences.getInstance();
      final urls = prefs.getStringList(_indexKey) ?? const <String>[];
      for (final url in urls) {
        if (url.trim().isEmpty) continue;
        final bytes = await readLocalImage(_fileKey(url));
        if (bytes == null || bytes.isEmpty) continue;
        _mem[url] = bytes;
      }
      final splash = await readLocalImage(_fileKey(_namedKey(splashName)));
      if (splash != null && splash.isNotEmpty) {
        _mem[_namedKey(splashName)] = splash;
      }
      if (_mem.isNotEmpty) notifyListeners();
    } catch (_) {}
  }

  Future<void> rememberNamed(String name, String url) async {
    final trimmed = url.trim();
    if (trimmed.isEmpty) {
      _mem.remove(_namedKey(name));
      notifyListeners();
      return;
    }
    await prefetch([trimmed]);
    final bytes = peek(trimmed);
    if (bytes == null) return;
    _mem[_namedKey(name)] = bytes;
    await writeLocalImage(_fileKey(_namedKey(name)), bytes);
    notifyListeners();
  }

  Future<void> prefetch(Iterable<String> urls) async {
    final pending = <Future<void>>[];
    for (final raw in urls) {
      final url = raw.trim();
      if (url.isEmpty) continue;
      if (_mem.containsKey(url)) continue;
      pending.add(_loadOne(url));
    }
    if (pending.isEmpty) return;
    await Future.wait(pending);
  }

  Future<void> _loadOne(String url) async {
    if (_mem.containsKey(url) || !_inflight.add(url)) return;
    try {
      final disk = await readLocalImage(_fileKey(url));
      if (disk != null && disk.isNotEmpty) {
        _mem[url] = disk;
        notifyListeners();
        unawaited(_rememberUrl(url));
        return;
      }
      if (kIsWeb) return;
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 12),
      );
      if (response.statusCode < 200 || response.statusCode >= 300) return;
      if (response.bodyBytes.isEmpty) return;
      _mem[url] = response.bodyBytes;
      notifyListeners();
      await writeLocalImage(_fileKey(url), response.bodyBytes);
      await _rememberUrl(url);
    } catch (_) {
    } finally {
      _inflight.remove(url);
    }
  }

  Future<void> _rememberUrl(String url) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getStringList(_indexKey) ?? <String>[];
      if (current.contains(url)) return;
      current.add(url);
      if (current.length > 80) {
        current.removeRange(0, current.length - 80);
      }
      await prefs.setStringList(_indexKey, current);
    } catch (_) {}
  }

  static String _namedKey(String name) => 'named:$name';

  static String _fileKey(String url) {
    var hash = 2166136261;
    for (final unit in url.codeUnits) {
      hash ^= unit;
      hash = (hash * 16777619) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16);
  }
}
