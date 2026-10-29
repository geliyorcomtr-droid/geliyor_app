import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/courier_fee_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/courier_fee.dart';

class AdminCourierSettingScreen extends StatefulWidget {
  const AdminCourierSettingScreen({super.key});

  @override
  State<AdminCourierSettingScreen> createState() =>
      _AdminCourierSettingScreenState();
}

class _AdminCourierSettingScreenState extends State<AdminCourierSettingScreen> {
  final _amount = TextEditingController();
  final _fee = TextEditingController();
  bool _loading = true;
  bool _saving = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _amount.dispose();
    _fee.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await CourierFeeRepository.instance.get();
      if (!mounted) return;
      _amount.text = CourierFee.formatTl(CourierFee.freeThreshold);
      _fee.text = CourierFee.formatTl(CourierFee.amount);
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    final value = _parseMoney(_amount.text);
    final fee = _parseMoney(_fee.text);
    if (value == null || fee == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Geçerli bir tutar girin.')));
      return;
    }

    setState(() => _saving = true);
    try {
      await CourierFeeRepository.instance.saveBoth(
        freeThreshold: value,
        amount: fee,
      );
      if (!mounted) return;
      _amount.text = CourierFee.formatTl(value);
      _fee.text = CourierFee.formatTl(fee);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sepet limiti ve getirme ücreti kaydedildi.'),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
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
              Text(
                'Ayar yüklenemedi: $_error',
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
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
          title: 'Sepet limiti',
          subtitle:
              'Üstteki tutar ücretsiz kurye sınırıdır. Alttaki tutar, sepet bu '
              'sınırın altındayken alınan getirme ücretidir.',
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AdminPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _moneyField(
                  controller: _amount,
                  label: 'Sepet limit tutarı (TL)',
                  hint: 'Örn. 599 — 0 yazılırsa tüm siparişler ücretsiz kurye olur',
                ),
                const SizedBox(height: 14),
                _moneyField(
                  controller: _fee,
                  label: 'Limit altı getirme ücreti (TL)',
                  hint: 'Örn. 99 — 0 yazılırsa getirme ücreti alınmaz',
                ),
                const SizedBox(height: 10),
                const Text(
                  'Kayıt, uygulamadaki sepet, kolay sipariş ve sipariş özeti '
                  'tutarlarına hemen yansır. Daha önce verilmiş siparişlerin '
                  'ücreti değişmez.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _saving ? null : _save,
                    icon: _saving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_rounded, size: 18),
                    label: Text(_saving ? 'Kaydediliyor…' : 'Kaydet'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _moneyField({
    required TextEditingController controller,
    required String label,
    required String hint,
  }) {
    return TextField(
      controller: controller,
      enabled: !_saving,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
      ],
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        suffixText: 'TL',
      ),
    );
  }
}

double? _parseMoney(String raw) {
  var text = raw.trim().replaceAll(' ', '').replaceAll('₺', '');
  text = text.replaceAll(RegExp(r'tl', caseSensitive: false), '');
  if (text.isEmpty) return null;
  if (text.contains(',')) {
    text = text.replaceAll('.', '').replaceAll(',', '.');
  } else {
    final dots = '.'.allMatches(text).length;
    if (dots > 1) {
      text = text.replaceAll('.', '');
    } else if (dots == 1) {
      final fraction = text.split('.').last;
      if (fraction.length == 3) text = text.replaceAll('.', '');
    }
  }
  final value = double.tryParse(text);
  if (value == null || !value.isFinite || value < 0) return null;
  return value;
}
