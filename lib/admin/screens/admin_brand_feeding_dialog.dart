import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/data/brand_feeding_guide.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_variant.dart';
import 'package:geliyor_app/data/pro_plan_mini_puppy_guide.dart';
import 'package:geliyor_app/theme/app_colors.dart';

Future<void> showAdminBrandFeedingDialog(
  BuildContext context,
  AppBrand brand, {
  FeedingVariant? initial,
}) {
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => _AdminBrandFeedingDialog(
      brand: brand,
      initial: initial,
    ),
  );
}

enum _WizardStep { species, breedType, life, table }

class _AdminBrandFeedingDialog extends StatefulWidget {
  const _AdminBrandFeedingDialog({required this.brand, this.initial});

  final AppBrand brand;
  final FeedingVariant? initial;

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
  _WizardStep _step = _WizardStep.species;
  bool? _isDog;
  bool? _isMini;
  bool? _isPuppy;
  FeedingVariant? _variant;

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
      for (final kg in ProPlanMiniPuppyGuide.kgRows)
        for (final band in ProPlanMiniPuppyGuide.ageBands)
          ProPlanMiniPuppyGuide.cellKey(kg, band): TextEditingController(
            text: feeding.dogMiniPuppyCells['$kg']?[band] ?? '',
          ),
    };
    final initial = widget.initial;
    if (initial != null) {
      _variant = initial;
      _isDog = initial.isDog;
      _isMini = initial.isMini;
      _isPuppy = initial.isPuppy;
      _step = _WizardStep.table;
    }
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

  String _textOf(int? grams) => grams != null && grams > 0 ? '$grams' : '';

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

  void _selectSpecies(bool isDog) {
    setState(() {
      _isDog = isDog;
      if (!isDog) _isMini = false;
      _isPuppy = null;
      _variant = null;
      _step = isDog ? _WizardStep.breedType : _WizardStep.life;
    });
  }

  void _selectBreedType(bool mini) {
    setState(() {
      _isMini = mini;
      _isPuppy = null;
      _variant = null;
      _step = _WizardStep.life;
    });
  }

  void _selectLife(bool puppy) {
    final variant = FeedingVariant.resolve(
      isDog: _isDog ?? false,
      isPuppy: puppy,
      isMiniBreed: _isDog == true && (_isMini ?? false),
    );
    setState(() {
      _isPuppy = puppy;
      _variant = variant;
      _step = _WizardStep.table;
    });
  }

  void _back() {
    if (_step == _WizardStep.species) {
      Navigator.pop(context);
      return;
    }
    setState(() {
      _step = switch (_step) {
        _WizardStep.species => _WizardStep.species,
        _WizardStep.breedType => _WizardStep.species,
        _WizardStep.life =>
          (_isDog ?? false) ? _WizardStep.breedType : _WizardStep.species,
        _WizardStep.table => _WizardStep.life,
      };
      if (_step != _WizardStep.table) _variant = null;
    });
  }

  Future<void> _save() async {
    final variant = _variant;
    if (variant == null) return;
    setState(() => _saving = true);
    final grams = switch (variant) {
      FeedingVariant.catAdult => _collect(_cat),
      FeedingVariant.catKitten => _collect(_catKitten),
      FeedingVariant.dogAdult || FeedingVariant.dogMiniAdult => _collect(_dog),
      FeedingVariant.dogPuppy => _collect(_dogPuppy),
      FeedingVariant.dogMiniPuppy => const <String, int>{},
    };
    await BrandRepository.instance.saveFeeding(
      widget.brand.copyWith(
        feeding: widget.brand.feeding.replacing(
          variant,
          grams: grams,
          cells: variant == FeedingVariant.dogMiniPuppy
              ? _collectMiniPuppyCells()
              : null,
        ),
      ),
    );
    if (!mounted) return;
    final messenger = ScaffoldMessenger.of(context);
    Navigator.pop(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          '${variant.displayName(widget.brand.name)} tablosu kaydedildi.',
        ),
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
        constraints: BoxConstraints(
          maxWidth: _variant == FeedingVariant.dogMiniPuppy ? 980 : 640,
          maxHeight: maxHeight,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 12, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _headerTitle,
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: Text(
                _headerHint,
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  height: 1.35,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Expanded(child: _stepBody()),
            const Divider(height: 1, color: AppColors.border),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
              child: Row(
                children: [
                  TextButton(
                    onPressed: _saving ? null : _back,
                    child: Text(
                      _step == _WizardStep.species ? 'Vazgeç' : 'Geri',
                    ),
                  ),
                  const Spacer(),
                  if (_step == _WizardStep.table)
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
    );
  }

  String get _headerTitle {
    final variant = _variant;
    if (variant == FeedingVariant.dogMiniPuppy) {
      return '${widget.brand.name} Small & Mini Puppy — günlük tüketim';
    }
    if (variant != null) {
      return '${widget.brand.name} — ${variant.shortLabel}';
    }
    return '${widget.brand.name} — tüketim tablosu';
  }

  String get _headerHint => switch (_step) {
        _WizardStep.species =>
          'Önce türü seçin. Mama takibi hesabı dost profilinden yapılır; '
              'bu tablo yavru kedi / köpek yüklemesi içindir.',
        _WizardStep.breedType =>
          'Köpek, Köpek Yavru, Mini Irk veya Mini Irk Yavru.',
        _WizardStep.life => _isDog == true && (_isMini ?? false)
            ? 'Mini Irk veya Mini Irk Yavru tablosunu seçin.'
            : 'Yavru veya Yetişkin. Genç / yaşlı yok.',
        _WizardStep.table => _variant == FeedingVariant.dogMiniPuppy
            ? 'Satır beklenen yetişkin kilosu, sütun yaş aralığıdır. '
                '30-45 gibi aralık yazılabilir; hesapta orta değer kullanılır.'
            : 'Bu değerler standart günlük gramdır. Boş satırlar yok sayılır.',
      };

  Widget _stepBody() {
    return switch (_step) {
      _WizardStep.species => _choiceStep(
          title: 'Tür',
          options: const [
            (false, 'Kedi'),
            (true, 'Köpek'),
          ],
          selected: _isDog,
          onSelect: _selectSpecies,
        ),
      _WizardStep.breedType => _choiceStep(
          title: 'Köpek tipi',
          options: const [
            (false, 'Köpek'),
            (true, 'Mini Irk'),
          ],
          selected: _isMini,
          onSelect: _selectBreedType,
        ),
      _WizardStep.life => _choiceStep(
          title: 'Yaş aralığı',
          options: _isDog == true && (_isMini ?? false)
              ? const [
                  (false, 'Mini Irk'),
                  (true, 'Mini Irk Yavru'),
                ]
              : _isDog == true
                  ? const [
                      (false, 'Köpek'),
                      (true, 'Köpek Yavru'),
                    ]
                  : const [
                      (false, 'Yetişkin'),
                      (true, 'Yavru'),
                    ],
          selected: _isPuppy,
          onSelect: _selectLife,
        ),
      _WizardStep.table => _tableFor(_variant),
    };
  }

  Widget _choiceStep({
    required String title,
    required List<(bool, String)> options,
    required bool? selected,
    required ValueChanged<bool> onSelect,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final option in options)
                ChoiceChip(
                  label: Text(option.$2),
                  selected: selected == option.$1,
                  selectedColor: AppColors.selected,
                  onSelected: (_) => onSelect(option.$1),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tableFor(FeedingVariant? variant) {
    if (variant == null) {
      return const Center(child: Text('Tablo seçilmedi.'));
    }
    return switch (variant) {
      FeedingVariant.catAdult => _gramsTable(
          rows: [
            for (final kg in BrandFeedingGuide.catKgRows)
              (
                label: '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg',
                controller: _cat[BrandFeedingGuide.catKey(kg)]!,
              ),
          ],
        ),
      FeedingVariant.catKitten => _gramsTable(
          rows: [
            for (final months in BrandFeedingGuide.monthRows)
              (
                label: '$months ay',
                controller: _catKitten[BrandFeedingGuide.monthKey(months)]!,
              ),
          ],
        ),
      FeedingVariant.dogAdult => _gramsTable(
          rows: [
            for (final size in BrandFeedingGuide.dogAdultSizes)
              (
                label:
                    '$size · ${DogFeedingGuide.rows.firstWhere((row) => row.size == size).weightLabel}',
                controller: _dog[size]!,
              ),
          ],
        ),
      FeedingVariant.dogMiniAdult => _gramsTable(
          rows: [
            for (final size in BrandFeedingGuide.dogMiniAdultSizes)
              (
                label:
                    '$size · ${DogFeedingGuide.rows.firstWhere((row) => row.size == size).weightLabel}',
                controller: _dog[size]!,
              ),
          ],
        ),
      FeedingVariant.dogPuppy => _gramsTable(
          rows: [
            for (final months in BrandFeedingGuide.monthRows)
              (
                label: '$months ay',
                controller: _dogPuppy[BrandFeedingGuide.monthKey(months)]!,
              ),
          ],
        ),
      FeedingVariant.dogMiniPuppy => _miniPuppyTable(),
    };
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

  Map<String, Map<String, String>> _collectMiniPuppyCells() {
    final out = <String, Map<String, String>>{};
    for (final kg in ProPlanMiniPuppyGuide.kgRows) {
      final row = <String, String>{};
      for (final band in ProPlanMiniPuppyGuide.ageBands) {
        final text = _dogMiniPuppy[ProPlanMiniPuppyGuide.cellKey(kg, band)]
                ?.text
                .trim() ??
            '';
        if (text.isNotEmpty && ProPlanMiniPuppyGuide.parseCell(text) > 0) {
          row[band] = text;
        }
      }
      if (row.isNotEmpty) out['$kg'] = row;
    }
    return out;
  }

  Widget _miniPuppyTable() {
    return Scrollbar(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            headingRowColor: const WidgetStatePropertyAll(AppColors.selected),
            headingRowHeight: 44,
            dataRowMinHeight: 44,
            dataRowMaxHeight: 48,
            columnSpacing: 10,
            horizontalMargin: 8,
            columns: [
              const DataColumn(
                label: Text(
                  'Beklenen yetişkin kg',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
              for (final label in ProPlanMiniPuppyGuide.ageBandLabels)
                DataColumn(
                  label: Text(
                    label,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
            ],
            rows: [
              for (final kg in ProPlanMiniPuppyGuide.kgRows)
                DataRow(
                  cells: [
                    DataCell(
                      Text(
                        '$kg kg',
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    for (final band in ProPlanMiniPuppyGuide.ageBands)
                      DataCell(
                        SizedBox(
                          width: 88,
                          child: TextField(
                            controller: _dogMiniPuppy[
                                ProPlanMiniPuppyGuide.cellKey(kg, band)]!,
                            keyboardType: TextInputType.text,
                            inputFormatters: [
                              FilteringTextInputFormatter.allow(
                                RegExp(r'[0-9\-–]'),
                              ),
                            ],
                            decoration: const InputDecoration(
                              isDense: true,
                              suffixText: 'g',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 8,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
