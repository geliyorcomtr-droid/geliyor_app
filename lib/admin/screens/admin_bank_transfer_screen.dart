import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/bank_transfer_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminBankTransferScreen extends StatefulWidget {
  const AdminBankTransferScreen({super.key});

  @override
  State<AdminBankTransferScreen> createState() =>
      _AdminBankTransferScreenState();
}

class _AdminBankTransferScreenState extends State<AdminBankTransferScreen> {
  final _holder = TextEditingController();
  final _iban = TextEditingController();
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
    _holder.dispose();
    _iban.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final info = await BankTransferRepository.instance.get();
      if (!mounted) return;
      _holder.text = info.holder;
      _iban.text = info.formattedIban;
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
    final holder = _holder.text.trim();
    final iban = BankTransferInfo.formatIban(_iban.text);
    if (holder.isEmpty || iban.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Alıcı adı ve IBAN gerekli.')),
      );
      return;
    }

    final compact = iban.replaceAll(' ', '');
    if (compact.length < 16) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Geçerli bir IBAN girin.')),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      await BankTransferRepository.instance.save(
        BankTransferInfo(holder: holder, iban: compact),
      );
      if (!mounted) return;
      _iban.text = BankTransferInfo.formatIban(compact);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Havale bilgileri kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilemedi: $error')),
      );
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
                'Havale bilgileri yüklenemedi: $_error',
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
          title: 'Havale / EFT',
          subtitle:
              'Müşteri havale ile ödemek istediğinde sipariş sonrası '
              'gösterilecek alıcı ve IBAN bilgileri.',
        ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: AdminPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _holder,
                  enabled: !_saving,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: 'Alıcı adı',
                    hintText: 'Örn. FATİH EROĞLU',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _iban,
                  enabled: !_saving,
                  autocorrect: false,
                  enableSuggestions: false,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: const [_IbanInputFormatter()],
                  decoration: const InputDecoration(
                    labelText: 'IBAN',
                    hintText: 'TR00 0000 0000 0000 0000 0000 00',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Bu bilgiler Havale / EFT seçen müşteriye sipariş alındı '
                  'ekranında gösterilir.',
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
}

class _IbanInputFormatter extends TextInputFormatter {
  const _IbanInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final formatted = BankTransferInfo.formatIban(newValue.text);
    final cursor = newValue.selection.end.clamp(0, newValue.text.length);
    var lettersBeforeCursor = 0;
    for (var i = 0; i < cursor; i++) {
      if (RegExp(r'[A-Za-z0-9]').hasMatch(newValue.text[i])) {
        lettersBeforeCursor++;
      }
    }
    var offset = formatted.length;
    var seen = 0;
    for (var i = 0; i < formatted.length; i++) {
      if (formatted[i] == ' ') continue;
      seen++;
      if (seen >= lettersBeforeCursor) {
        offset = i + 1;
        break;
      }
    }
    if (lettersBeforeCursor == 0) offset = 0;
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: offset.clamp(0, formatted.length),
      ),
    );
  }
}
