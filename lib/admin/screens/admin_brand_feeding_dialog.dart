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
  late final Map<String, TextEditingController> _catKitten;
  late final Map<String, TextEditingController> _dogPuppy;
  late final Map<String, TextEditingController> _dogMiniPuppy;
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
    _catKitten = {
      for (final months in BrandFeedingGuide.monthRows)
        BrandFeedingGuide.monthKey(months): TextEditingController(
          text: _textOf(
            feeding.catKittenGrams[BrandFeedingGuide.monthKey(months)],
          ),
        ),
    };
    _dogPuppy = {
      for (final months in BrandFeedingGuide.monthRows)
        BrandFeedingGuide.monthKey(months): TextEditingController(
          text: _textOf(
            feeding.dogPuppyGrams[BrandFeedingGuide.monthKey(months)],
          ),
        ),
    };
    _dogMiniPuppy = {
      for (final months in BrandFeedingGuide.monthRows)
        BrandFeedingGuide.monthKey(months): TextEditingController(
          text: _textOf(
            feeding.dogMiniPuppyGrams[BrandFeedingGuide.monthKey(months)],
          ),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in [
      ..._cat.values,
      ..._dog.values,
      ..._catKitten.values,
      ..._dogPuppy.values,
      ..._dogMiniPuppy.values,
    ]) {
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

  Map<String, int> _collect(Map<String, TextEditingController> source) {
    final out = <String, int>{};
    source.forEach((key, controller) {
      final grams = _parse(controller);
      if (grams != null && grams > 0) out[key] = grams;
    });
    return out;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await BrandRepository.instance.saveFeeding(
      widget.brand.copyWith(
        feeding: BrandFeedingGuide(
          catGrams: _collect(_cat),
          dogGrams: _collect(_dog),
          catKittenGrams: _collect(_catKitten),
          dogPuppyGrams: _collect(_dogPuppy),
          dogMiniPuppyGrams: _collect(_dogMiniPuppy),
        ),
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
    final maxHeight = MediaQuery.sizeOf(context).height * 0.88;
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: 720, maxHeight: maxHeight),
        child: DefaultTabController(
          length: 4,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${widget.brand.name} — günlük tüketim (g)',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      tooltip: 'Kapat',
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ],
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: Text(
                  'Yetişkin kedi kilo, yavru kedi ay esas alır. Köpekte yetişkin '
                  'beden; yavru ay + standart/mini ırk ayrımı kullanılır. Boş '
                  'satırlar yok sayılır.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const TabBar(
                isScrollable: true,
                labelColor: AppColors.primary,
                tabs: [
                  Tab(text: 'Kedi yetişkin'),
                  Tab(text: 'Kedi yavru'),
                  Tab(text: 'Köpek yetişkin'),
                  Tab(text: 'Köpek yavru'),
                ],
              ),
              Expanded(
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
                        for (final months in BrandFeedingGuide.monthRows)
                          (
                            label: '$months ay',
                            controller:
                                _catKitten[BrandFeedingGuide.monthKey(months)]!,
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
                    _puppyDogTables(),
                  ],
                ),
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                child: Row(
                  children: [
                    TextButton(
                      onPressed: _saving ? null : () => Navigator.pop(context),
                      child: const Text('Vazgeç'),
                    ),
                    const Spacer(),
                    FilledButton(
                      onPressed: _saving ? null : _save,
                      child: Text(_saving ? 'Kaydediliyor...' : 'Kaydet'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _puppyDogTables() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      children: [
        const Text(
          'Standart ırk yavru',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...[
          for (final months in BrandFeedingGuide.monthRows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _gramRow(
                label: '$months ay',
                controller: _dogPuppy[BrandFeedingGuide.monthKey(months)]!,
              ),
            ),
        ],
        const SizedBox(height: 8),
        const Text(
          'Mini ırk yavru',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        ...[
          for (final months in BrandFeedingGuide.monthRows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _gramRow(
                label: '$months ay',
                controller: _dogMiniPuppy[BrandFeedingGuide.monthKey(months)]!,
              ),
            ),
        ],
      ],
    );
  }

  Widget _gramsTable({
    required List<({String label, TextEditingController controller})> rows,
  }) {
    return Scrollbar(
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
        itemCount: rows.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          final row = rows[index];
          return _gramRow(label: row.label, controller: row.controller);
        },
      ),
    );
  }

  Widget _gramRow({
    required String label,
    required TextEditingController controller,
  }) {
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
        ),
        SizedBox(
          width: 120,
          child: TextField(
            controller: controller,
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
  }
}
