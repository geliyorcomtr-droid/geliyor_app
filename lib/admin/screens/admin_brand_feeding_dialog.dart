import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/data/brand_feeding_guide.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/theme/app_colors.dart';

Future<void> showAdminBrandFeedingDialog(
  BuildContext context,
  AppBrand brand,
) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AdminBrandFeedingDialog(brand: brand),
  );
}

class _AdminBrandFeedingDialog extends StatefulWidget {
  const _AdminBrandFeedingDialog({required this.brand});

  final AppBrand brand;

  @override
  State<_AdminBrandFeedingDialog> createState() =>
      _AdminBrandFeedingDialogState();
}

class _AdminBrandFeedingDialogState extends State<_AdminBrandFeedingDialog> {
  late final Map<String, TextEditingController> _cat;
  late final Map<String, TextEditingController> _dog;
  var _saving = false;

  @override
  void initState() {
    super.initState();
    final feeding = widget.brand.feeding;
    _cat = {
      for (final kg in BrandFeedingGuide.catKgRows)
        BrandFeedingGuide.catKey(kg): TextEditingController(
          text: _textOf(feeding.catGrams[BrandFeedingGuide.catKey(kg)]),
        ),
    };
    _dog = {
      for (final size in BrandFeedingGuide.dogSizeRows)
        size: TextEditingController(
          text: _textOf(feeding.dogGrams[size]),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _cat.values) {
      c.dispose();
    }
    for (final c in _dog.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _textOf(int? grams) =>
      grams != null && grams > 0 ? '$grams' : '';

  int? _parse(TextEditingController controller) {
    final raw = controller.text.trim().replaceAll(',', '.');
    if (raw.isEmpty) return null;
    return int.tryParse(raw) ?? double.tryParse(raw)?.round();
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final cat = <String, int>{};
    _cat.forEach((key, controller) {
      final grams = _parse(controller);
      if (grams != null && grams > 0) cat[key] = grams;
    });
    final dog = <String, int>{};
    _dog.forEach((key, controller) {
      final grams = _parse(controller);
      if (grams != null && grams > 0) dog[key] = grams;
    });
    await BrandRepository.instance.saveFeeding(
      widget.brand.copyWith(
        feeding: BrandFeedingGuide(catGrams: cat, dogGrams: dog),
      ),
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text('${widget.brand.name} tüketim tablosu kaydedildi.'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('${widget.brand.name} — günlük tüketim (g)'),
      content: SizedBox(
        width: 640,
        child: DefaultTabController(
          length: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Boş satırlar hesaplamada yok sayılır. Hiç değer yoksa '
                'müşteri standart mama tablosuna düşer.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 12),
              const TabBar(
                labelColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Kedi'),
                  Tab(text: 'Köpek'),
                ],
              ),
              SizedBox(
                height: 420,
                child: TabBarView(
                  children: [
                    _gramsTable(
                      rows: [
                        for (final kg in BrandFeedingGuide.catKgRows)
                          (
                            label:
                                '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg',
                            controller: _cat[BrandFeedingGuide.catKey(kg)]!,
                          ),
                      ],
                    ),
                    _gramsTable(
                      rows: [
                        for (final size in BrandFeedingGuide.dogSizeRows)
                          (
                            label:
                                '$size · ${DogFeedingGuide.rows.firstWhere((row) => row.size == size).weightLabel}',
                            controller: _dog[size]!,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Vazgeç'),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
        ),
      ],
    );
  }

  Widget _gramsTable({
    required List<({String label, TextEditingController controller})> rows,
  }) {
    return Scrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.only(top: 12, right: 8),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final row = rows[index];
          return Row(
            children: [
              Expanded(
                child: Text(
                  row.label,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              SizedBox(
                width: 120,
                child: TextField(
                  controller: row.controller,
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9]')),
                  ],
                  decoration: const InputDecoration(
                    suffixText: 'g',
                    isDense: true,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
