import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminSofttrStockScreen extends StatefulWidget {
  const AdminSofttrStockScreen({super.key});

  @override
  State<AdminSofttrStockScreen> createState() => _AdminSofttrStockScreenState();
}

class _AdminSofttrStockScreenState extends State<AdminSofttrStockScreen> {
  final _baseUrl = TextEditingController(
    text: 'https://www.geliyor.com.tr/api',
  );
  final _username = TextEditingController();
  final _password = TextEditingController();
  bool _enabled = false;
  bool _passwordSet = false;
  bool _loading = true;
  bool _saving = false;
  bool _syncing = false;
  Object? _error;
  String _lastError = '';
  String _lastSampleKeys = '';
  int _lastPulled = 0;
  int _lastMatched = 0;
  int _lastUpdated = 0;
  int _lastPushed = 0;
  int _lastStockFound = 0;
  int _lastPriceFound = 0;
  DateTime? _lastSyncAt;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _baseUrl.dispose();
    _username.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final result = await _functions.httpsCallable('getSofttrSettings').call();
      final data = Map<String, dynamic>.from(result.data as Map? ?? const {});
      if (!mounted) return;
      _apply(data);
      setState(() => _loading = false);
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.message ?? error.code;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _apply(Map<String, dynamic> data) {
    _enabled = data['enabled'] == true;
    _passwordSet = data['passwordSet'] == true;
    final baseUrl = '${data['baseUrl'] ?? ''}'.trim();
    if (baseUrl.isNotEmpty) _baseUrl.text = baseUrl;
    _username.text = '${data['username'] ?? ''}';
    _password.clear();
    _lastError = '${data['lastError'] ?? ''}';
    _lastSampleKeys = '${data['lastSampleKeys'] ?? ''}';
    _lastPulled = (data['lastPulled'] as num?)?.toInt() ?? 0;
    _lastMatched = (data['lastMatched'] as num?)?.toInt() ?? 0;
    _lastUpdated = (data['lastUpdated'] as num?)?.toInt() ?? 0;
    _lastPushed = (data['lastPushed'] as num?)?.toInt() ?? 0;
    _lastStockFound = (data['lastStockFound'] as num?)?.toInt() ?? 0;
    _lastPriceFound = (data['lastPriceFound'] as num?)?.toInt() ?? 0;
    _lastSyncAt = _dateOf(data['lastSyncAt']);
  }

  DateTime? _dateOf(dynamic raw) {
    if (raw is DateTime) return raw;
    if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
    if (raw is Map) {
      final seconds = raw['_seconds'] ?? raw['seconds'];
      if (seconds is num) {
        return DateTime.fromMillisecondsSinceEpoch(seconds.round() * 1000);
      }
    }
    return null;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final result = await _functions.httpsCallable('saveSofttrSettings').call({
        'enabled': _enabled,
        'baseUrl': _baseUrl.text.trim(),
        'username': _username.text.trim(),
        if (_password.text.trim().isNotEmpty) 'password': _password.text.trim(),
      });
      final data = Map<String, dynamic>.from(result.data as Map? ?? const {});
      if (!mounted) return;
      _apply(data);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Softtr ayarları kaydedildi.')),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Ayar kaydedilemedi.')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _syncNow() async {
    setState(() => _syncing = true);
    try {
      await _functions.httpsCallable('saveSofttrSettings').call({
        'enabled': true,
        'baseUrl': _baseUrl.text.trim(),
        'username': _username.text.trim(),
        if (_password.text.trim().isNotEmpty) 'password': _password.text.trim(),
      });
      final result = await _functions.httpsCallable('syncSofttrStockNow').call();
      final data = Map<String, dynamic>.from(result.data as Map? ?? const {});
      if (!mounted) return;
      await _load();
      if (!mounted) return;
      final pulled = data['pulled'] ?? 0;
      final matched = data['matched'] ?? 0;
      final updated = data['updated'] ?? 0;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            pulled == 0
                ? 'Softtr’den ürün gelmedi. API bilgilerini ve barkodları kontrol edin.'
                : matched == 0
                ? 'Softtr $pulled ürün getirdi ama barkod eşleşmedi.'
                : 'Eşitlendi: Softtr $pulled ürün, eşleşen $matched, stok/fiyat yazılan $updated.',
          ),
        ),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Eşitleme başarısız.')),
      );
    } finally {
      if (mounted) setState(() => _syncing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Ayarlar yüklenemedi: $_error'),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Yeniden dene')),
            ],
          ),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const AdminPageHeader(
          title: 'Softtr stok / fiyat',
          subtitle:
              'geliyor.com.tr (Softtr) ana kaynaktır. Barkod eşleşince alış '
              'fiyatı, satış fiyatı, indirimli fiyat ve stok uygulamaya yazılır. '
              'İndirimli fiyat müşteriye satılan fiyattır; satış fiyatı üzeri '
              'çizili listedir.',
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 720),
          child: AdminPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text(
                    'Stok ve fiyat eşitlemeyi aç',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                  subtitle: const Text(
                    'Açıkken her 5 dakikada Softtr stok ve fiyatları uygulamaya '
                    'yazılır. Uygulama satışı Softtr stokunu da düşer. '
                    'Şimdi eşitle hem açar hem Softtr’den çeker.',
                  ),
                  value: _enabled,
                  onChanged: _saving
                      ? null
                      : (value) => setState(() => _enabled = value),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _baseUrl,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'API adresi',
                    hintText: 'https://www.geliyor.com.tr/api',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _username,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'API kullanıcı adı',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _password,
                  enabled: !_saving,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: _passwordSet
                        ? 'API şifre (kayıtlı, değiştirmek için yazın)'
                        : 'API şifre',
                    border: const OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Kullanıcı adı ve şifreyi Softtr panelinden Yardım → Destek '
                  'ile alın. Aynı barkod her iki üründe de girilmiş olmalı.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminStatusChip(
                      label: _enabled ? 'Eşitleme açık' : 'Eşitleme kapalı',
                      color: _enabled ? AppColors.success : AppColors.subText,
                    ),
                    AdminStatusChip(
                      label: 'Softtr $_lastPulled',
                      color: AppColors.primary,
                    ),
                    AdminStatusChip(
                      label: 'Eşleşen $_lastMatched',
                      color: AppColors.success,
                    ),
                    AdminStatusChip(
                      label: 'Güncellenen $_lastUpdated',
                      color: AppColors.warning,
                    ),
                    AdminStatusChip(
                      label: 'Stok alanı $_lastStockFound',
                      color: _lastStockFound > 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    AdminStatusChip(
                      label: 'Fiyat alanı $_lastPriceFound',
                      color: _lastPriceFound > 0
                          ? AppColors.success
                          : AppColors.error,
                    ),
                    AdminStatusChip(
                      label: 'Gönderilen $_lastPushed',
                      color: AppColors.primary,
                    ),
                    if (_lastSyncAt != null)
                      AdminStatusChip(
                        label: 'Son ${AdminUi.dateTime(_lastSyncAt)}',
                        color: AppColors.primary,
                      ),
                  ],
                ),
                if (_lastError.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text(
                    _lastError,
                    style: const TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
                if (_lastSampleKeys.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Softtr alanları: $_lastSampleKeys',
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                    ),
                    const SizedBox(width: 12),
                    OutlinedButton(
                      onPressed: _syncing || _saving ? null : _syncNow,
                      child: Text(_syncing ? 'Eşitleniyor…' : 'Şimdi eşitle'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
