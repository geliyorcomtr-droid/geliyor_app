import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/feeding_factors.dart';
import 'package:geliyor_app/data/kitten_feeding_guide.dart';
import 'package:geliyor_app/data/mini_adult_dog_feeding_guide.dart';
import 'package:geliyor_app/data/mini_puppy_feeding_guide.dart';
import 'package:geliyor_app/data/standard_puppy_feeding_guide.dart';
import 'package:geliyor_app/data/system_feeding_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminFoodTrackingScreen extends StatefulWidget {
  const AdminFoodTrackingScreen({super.key});

  @override
  State<AdminFoodTrackingScreen> createState() =>
      _AdminFoodTrackingScreenState();
}

class _AdminFoodTrackingScreenState extends State<AdminFoodTrackingScreen> {
  static const _profiles = [
    'Yetişkin kedi',
    'Yavru kedi',
    'Köpek',
    'Köpek Yavru',
    'Mini Irk Yetişkin',
    'Mini Irk Yavru',
  ];

  final _grams = <String, TextEditingController>{};
  final _factors = <String, TextEditingController>{};
  int _profile = 0;
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
    for (final controller in _grams.values) {
      controller.dispose();
    }
    for (final controller in _factors.values) {
      controller.dispose();
    }
    super.dispose();
  }

  TextEditingController _gramField(String table, String label, int value) {
    final key = '$table|$label';
    return _grams.putIfAbsent(
      key,
      () => TextEditingController(text: value > 0 ? '$value' : ''),
    );
  }

  TextEditingController _factorField(String key, double value) {
    return _factors.putIfAbsent(
      key,
      () => TextEditingController(text: _formatFactor(value)),
    );
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final tables = await SystemFeedingRepository.instance.get();
      if (!mounted) return;
      _fill(tables);
      setState(() => _loading = false);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _loading = false;
      });
    }
  }

  void _fill(SystemFeedingTables tables) {
    void fillMap(String table, Map<String, int> values) {
      values.forEach((label, grams) {
        _gramField(table, label, grams).text = '$grams';
      });
    }

    fillMap('catAdult', tables.catAdult);
    fillMap('catKitten', tables.catKitten);
    fillMap('dogAdult', tables.dogAdult);
    fillMap('dogPuppy', tables.dogPuppy);
    fillMap('dogMiniAdult', tables.dogMiniAdult);
    fillMap('dogMiniPuppy', tables.dogMiniPuppy);

    final f = tables.factors;
    _factorField('neuteredYes', f.neuteredYes);
    _factorField('neuteredNo', f.neuteredNo);
    _factorField('bodyThin', f.bodyThin);
    _factorField('bodyIdeal', f.bodyIdeal);
    _factorField('bodyHeavy', f.bodyHeavy);
    _factorField('activityLow', f.activityLow);
    _factorField('activityMid', f.activityMid);
    _factorField('activityHigh', f.activityHigh);
    _factorField('extraNone', f.extraNone);
    _factorField('extraTreat', f.extraTreat);
    _factorField('extraWet', f.extraWet);
    _factorField('extraBoth', f.extraBoth);
    _factorField('clampLow', f.clampLow);
    _factorField('clampHigh', f.clampHigh);

    final m = tables.miniAdultFactors;
    _factorField('mini_neuteredYes', m.neuteredYes);
    _factorField('mini_neuteredNo', m.neuteredNo);
    _factorField('mini_bodyThin', m.bodyThin);
    _factorField('mini_bodyIdeal', m.bodyIdeal);
    _factorField('mini_bodyHeavy', m.bodyHeavy);
    _factorField('mini_activityLow', m.activityLow);
    _factorField('mini_activityMid', m.activityMid);
    _factorField('mini_activityHigh', m.activityHigh);
    _factorField('mini_activityVeryHigh', m.activityVeryHigh);
    _factorField('mini_extraNone', m.extraNone);
    _factorField('mini_extraTreat', m.extraTreat);
    _factorField('mini_extraWet', m.extraWet);
    _factorField('mini_extraBoth', m.extraBoth);

    final p = tables.miniPuppyFactors;
    _factorField('pup_bodyThin', p.bodyThin);
    _factorField('pup_bodyIdeal', p.bodyIdeal);
    _factorField('pup_bodyHeavy', p.bodyHeavy);
    _factorField('pup_activityLow', p.activityLow);
    _factorField('pup_activityMid', p.activityMid);
    _factorField('pup_activityHigh', p.activityHigh);
    _factorField('pup_activityVeryHigh', p.activityVeryHigh);
    _factorField('pup_extraNone', p.extraNone);
    _factorField('pup_extraTreat', p.extraTreat);
    _factorField('pup_extraWet', p.extraWet);
    _factorField('pup_extraBoth', p.extraBoth);

    final a = tables.adultDogFactors;
    _factorField('dog_neuteredYes', a.neuteredYes);
    _factorField('dog_neuteredNo', a.neuteredNo);
    _factorField('dog_bodyThin', a.bodyThin);
    _factorField('dog_bodyIdeal', a.bodyIdeal);
    _factorField('dog_bodyHeavy', a.bodyHeavy);
    _factorField('dog_activityLow', a.activityLow);
    _factorField('dog_activityMid', a.activityMid);
    _factorField('dog_activityHigh', a.activityHigh);
    _factorField('dog_activityVeryHigh', a.activityVeryHigh);
    _factorField('dog_extraNone', a.extraNone);
    _factorField('dog_extraTreat', a.extraTreat);
    _factorField('dog_extraWet', a.extraWet);
    _factorField('dog_extraBoth', a.extraBoth);

    final s = tables.puppyDogFactors;
    _factorField('stdp_neuteredYes', s.neuteredYes);
    _factorField('stdp_neuteredNo', s.neuteredNo);
    _factorField('stdp_bodyThin', s.bodyThin);
    _factorField('stdp_bodyIdeal', s.bodyIdeal);
    _factorField('stdp_bodyHeavy', s.bodyHeavy);
    _factorField('stdp_activityLow', s.activityLow);
    _factorField('stdp_activityMid', s.activityMid);
    _factorField('stdp_activityHigh', s.activityHigh);
    _factorField('stdp_activityVeryHigh', s.activityVeryHigh);
    _factorField('stdp_extraNone', s.extraNone);
    _factorField('stdp_extraTreat', s.extraTreat);
    _factorField('stdp_extraWet', s.extraWet);
    _factorField('stdp_extraBoth', s.extraBoth);
  }

  Map<String, int> _readGrams(String table, Iterable<String> labels) {
    final out = <String, int>{};
    for (final label in labels) {
      final raw = _grams['$table|$label']?.text.trim() ?? '';
      final value = int.tryParse(raw);
      if (value != null && value > 0) out[label] = value;
    }
    return out;
  }

  double _readFactor(String key, double fallback) {
    final raw = _factors[key]?.text.trim().replaceAll(',', '.') ?? '';
    return double.tryParse(raw) ?? fallback;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      final d = FeedingFactors.defaults;
      final md = MiniAdultDogFactors.defaults;
      final pd = MiniPuppyFactors.defaults;
      final sd = StandardPuppyFactors.defaults;
      await SystemFeedingRepository.instance.save(
        SystemFeedingTables(
          catAdult: _readGrams('catAdult', [
            for (final row in CatFeedingGuide.rows) row.catKgLabel,
            '10+ kg',
          ]),
          catKitten: _readGrams('catKitten', KittenFeedingGuide.cellKeys),
          dogAdult: _readGrams(
            'dogAdult',
            AdultDogFeedingGuide.weightLabels,
          ),
          dogPuppy: _readGrams(
            'dogPuppy',
            StandardPuppyFeedingGuide.cellKeys,
          ),
          dogMiniAdult: _readGrams('dogMiniAdult', [
            for (final row in MiniAdultDogFeedingGuide.rows) row.kgLabel,
          ]),
          dogMiniPuppy: _readGrams('dogMiniPuppy', MiniPuppyFeedingGuide.cellKeys),
          factors: FeedingFactors(
            neuteredYes: _readFactor('neuteredYes', d.neuteredYes),
            neuteredNo: _readFactor('neuteredNo', d.neuteredNo),
            bodyThin: _readFactor('bodyThin', d.bodyThin),
            bodyIdeal: _readFactor('bodyIdeal', d.bodyIdeal),
            bodyHeavy: _readFactor('bodyHeavy', d.bodyHeavy),
            activityLow: _readFactor('activityLow', d.activityLow),
            activityMid: _readFactor('activityMid', d.activityMid),
            activityHigh: _readFactor('activityHigh', d.activityHigh),
            extraNone: _readFactor('extraNone', d.extraNone),
            extraTreat: _readFactor('extraTreat', d.extraTreat),
            extraWet: _readFactor('extraWet', d.extraWet),
            extraBoth: _readFactor('extraBoth', d.extraBoth),
            clampLow: _readFactor('clampLow', d.clampLow),
            clampHigh: _readFactor('clampHigh', d.clampHigh),
          ),
          miniAdultFactors: MiniAdultDogFactors(
            neuteredYes: _readFactor('mini_neuteredYes', md.neuteredYes),
            neuteredNo: _readFactor('mini_neuteredNo', md.neuteredNo),
            bodyThin: _readFactor('mini_bodyThin', md.bodyThin),
            bodyIdeal: _readFactor('mini_bodyIdeal', md.bodyIdeal),
            bodyHeavy: _readFactor('mini_bodyHeavy', md.bodyHeavy),
            activityLow: _readFactor('mini_activityLow', md.activityLow),
            activityMid: _readFactor('mini_activityMid', md.activityMid),
            activityHigh: _readFactor('mini_activityHigh', md.activityHigh),
            activityVeryHigh:
                _readFactor('mini_activityVeryHigh', md.activityVeryHigh),
            extraNone: _readFactor('mini_extraNone', md.extraNone),
            extraTreat: _readFactor('mini_extraTreat', md.extraTreat),
            extraWet: _readFactor('mini_extraWet', md.extraWet),
            extraBoth: _readFactor('mini_extraBoth', md.extraBoth),
          ),
          miniPuppyFactors: MiniPuppyFactors(
            bodyThin: _readFactor('pup_bodyThin', pd.bodyThin),
            bodyIdeal: _readFactor('pup_bodyIdeal', pd.bodyIdeal),
            bodyHeavy: _readFactor('pup_bodyHeavy', pd.bodyHeavy),
            activityLow: _readFactor('pup_activityLow', pd.activityLow),
            activityMid: _readFactor('pup_activityMid', pd.activityMid),
            activityHigh: _readFactor('pup_activityHigh', pd.activityHigh),
            activityVeryHigh:
                _readFactor('pup_activityVeryHigh', pd.activityVeryHigh),
            extraNone: _readFactor('pup_extraNone', pd.extraNone),
            extraTreat: _readFactor('pup_extraTreat', pd.extraTreat),
            extraWet: _readFactor('pup_extraWet', pd.extraWet),
            extraBoth: _readFactor('pup_extraBoth', pd.extraBoth),
          ),
          puppyDogFactors: StandardPuppyFactors(
            neuteredYes: _readFactor('stdp_neuteredYes', sd.neuteredYes),
            neuteredNo: _readFactor('stdp_neuteredNo', sd.neuteredNo),
            bodyThin: _readFactor('stdp_bodyThin', sd.bodyThin),
            bodyIdeal: _readFactor('stdp_bodyIdeal', sd.bodyIdeal),
            bodyHeavy: _readFactor('stdp_bodyHeavy', sd.bodyHeavy),
            activityLow: _readFactor('stdp_activityLow', sd.activityLow),
            activityMid: _readFactor('stdp_activityMid', sd.activityMid),
            activityHigh: _readFactor('stdp_activityHigh', sd.activityHigh),
            activityVeryHigh:
                _readFactor('stdp_activityVeryHigh', sd.activityVeryHigh),
            extraNone: _readFactor('stdp_extraNone', sd.extraNone),
            extraTreat: _readFactor('stdp_extraTreat', sd.extraTreat),
            extraWet: _readFactor('stdp_extraWet', sd.extraWet),
            extraBoth: _readFactor('stdp_extraBoth', sd.extraBoth),
          ),
          adultDogFactors: MiniAdultDogFactors(
            neuteredYes: _readFactor('dog_neuteredYes', md.neuteredYes),
            neuteredNo: _readFactor('dog_neuteredNo', md.neuteredNo),
            bodyThin: _readFactor('dog_bodyThin', md.bodyThin),
            bodyIdeal: _readFactor('dog_bodyIdeal', md.bodyIdeal),
            bodyHeavy: _readFactor('dog_bodyHeavy', md.bodyHeavy),
            activityLow: _readFactor('dog_activityLow', md.activityLow),
            activityMid: _readFactor('dog_activityMid', md.activityMid),
            activityHigh: _readFactor('dog_activityHigh', md.activityHigh),
            activityVeryHigh:
                _readFactor('dog_activityVeryHigh', md.activityVeryHigh),
            extraNone: _readFactor('dog_extraNone', md.extraNone),
            extraTreat: _readFactor('dog_extraTreat', md.extraTreat),
            extraWet: _readFactor('dog_extraWet', md.extraWet),
            extraBoth: _readFactor('dog_extraBoth', md.extraBoth),
          ),
        ),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tüketim tabloları kaydedildi.')),
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
                'Tüketim tabloları yüklenemedi: $_error',
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
        AdminPageHeader(
          title: 'Mama Tüketim Takibi',
          subtitle:
              'Marka tablosu yok. Gram değerlerini buradan girin; uygulama Yeni Dost Ekle’deki 6 profile göre hesaplar.',
          actions: [
            FilledButton.icon(
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
          ],
        ),
        _FormulaCard(profile: _profile),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            for (var i = 0; i < _profiles.length; i++)
              _ProfileChip(
                title: _profiles[i],
                selected: _profile == i,
                onTap: () => setState(() => _profile = i),
              ),
          ],
        ),
        const SizedBox(height: 18),
        _tableCard(),
        if (_profile == 0 ||
            _profile == 2 ||
            _profile == 3 ||
            _profile == 4 ||
            _profile == 5) ...[
          const SizedBox(height: 18),
          _FactorsCard(
            kind: switch (_profile) {
              2 => _FactorKind.adultDog,
              3 => _FactorKind.standardPuppy,
              4 => _FactorKind.miniAdult,
              5 => _FactorKind.miniPuppy,
              _ => _FactorKind.cat,
            },
            enabled: !_saving,
            field: _factorField,
          ),
        ],
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.save_rounded, size: 18),
            label: const Text('Kaydet'),
          ),
        ),
      ],
    );
  }

  Widget _tableCard() {
    return switch (_profile) {
      0 => _GramsCard(
          title: 'Yetişkin kedi · temel tüketim',
          hint:
              'Dost Ekle kilo aralıkları ile aynıdır. 10+ kg ayrı satırdır. Değerleri g/gün olarak girin.',
          rows: [
            for (final row in CatFeedingGuide.rows)
              (row.catKgLabel, _gramField('catAdult', row.catKgLabel, row.baseGrams)),
            (
              '10+ kg',
              _gramField(
                'catAdult',
                '10+ kg',
                CatFeedingGuide.rows.last.baseGrams,
              ),
            ),
          ],
          enabled: !_saving,
        ),
      1 => _KittenGramsGrid(
          enabled: !_saving,
          field: (kgLabel, ageLabel, value) => _gramField(
            'catKitten',
            KittenFeedingGuide.cellKey(kgLabel, ageLabel),
            value,
          ),
        ),
      2 => _GramsCard(
          title: 'Yetişkin köpek · kilo',
          hint:
              'Dost Ekle’de Köpek seçilince çıkan 1–60 kg baz gramlarıdır. Günlük tüketim çarpanlarla çarpılır.',
          rows: [
            for (final row in AdultDogFeedingGuide.rows)
              (
                row.kgLabel,
                _gramField('dogAdult', row.kgLabel, row.dailyGrams),
              ),
          ],
          enabled: !_saving,
        ),
      3 => _StandardPuppyGramsGrid(
          enabled: !_saving,
          field: (kgLabel, ageLabel, value) => _gramField(
            'dogPuppy',
            StandardPuppyFeedingGuide.cellKey(kgLabel, ageLabel),
            value,
          ),
        ),
      4 => _GramsCard(
          title: 'Mini Irk Yetişkin · kilo',
          hint:
              'Dost Ekle’de Mini Irk Yetişkin seçilince çıkan 1–10 kg baz gramlarıdır. Günlük tüketim çarpanlarla çarpılır.',
          rows: [
            for (final row in MiniAdultDogFeedingGuide.rows)
              (
                row.kgLabel,
                _gramField('dogMiniAdult', row.kgLabel, row.dailyGrams),
              ),
          ],
          enabled: !_saving,
        ),
      _ => _MiniPuppyGramsGrid(
          enabled: !_saving,
          field: (kgLabel, ageLabel, value) => _gramField(
            'dogMiniPuppy',
            MiniPuppyFeedingGuide.cellKey(kgLabel, ageLabel),
            value,
          ),
        ),
    };
  }
}

class _FormulaCard extends StatelessWidget {
  const _FormulaCard({required this.profile});

  final int profile;

  @override
  Widget build(BuildContext context) {
    final adultDog = profile == 2;
    final standardPuppy = profile == 3;
    final miniAdult = profile == 4;
    final miniPuppy = profile == 5;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            miniPuppy
                ? 'Mini Irk Yavru formülü'
                : standardPuppy
                    ? 'Yavru köpek formülü'
                    : adultDog
                        ? 'Yetişkin köpek formülü'
                        : miniAdult
                            ? 'Mini Irk Yetişkin formülü'
                            : 'Yetişkin kedi formülü',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            miniPuppy
                ? 'Hedef yetişkin kilo × yaş dönemi baz gram × aktivite × vücut × ek gıda\n'
                    'Yaş aralıkları: 2-3, 4-5, 6-8, 9-12 ay. Sonuç tam grama yuvarlanır.'
                : standardPuppy
                    ? 'Hedef yetişkin kilo × yaş dönemi baz gram × kısır × aktivite × vücut × ek gıda\n'
                        'Yaş aralıkları: 2-3, 4-5, 6-8, 9-12, 13-15, 16-18 ay. Sonuç tam grama yuvarlanır.'
                    : adultDog || miniAdult
                    ? 'Baz gram × kısır × aktivite × vücut × ek gıda\n'
                        'Sonuç tam grama yuvarlanır. Paket günü = alınan mama gramı / günlük gram.'
                    : 'Temel gram × kısır × vücut × aktivite × ek besin\n'
                        'Sonuç temel tüketimin %75–%125 aralığında, tam grama yuvarlanır.\n'
                        'Paket günü = alınan mama gramı / günlük gram.',
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w600,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProfileChip extends StatelessWidget {
  const _ProfileChip({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.selected : AppColors.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Ink(
          width: 210,
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
            ),
          ),
          child: Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 14,
              color: selected ? AppColors.primary : AppColors.text,
            ),
          ),
        ),
      ),
    );
  }
}

class _KittenGramsGrid extends StatelessWidget {
  const _KittenGramsGrid({
    required this.enabled,
    required this.field,
  });

  final bool enabled;
  final TextEditingController Function(String kgLabel, String ageLabel, int value)
      field;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Yavru kedi · kilo × ay',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Excel referansı: satır kilo (0,5–5 kg), sütun yaş. Boş hücre o kombinasyon için referans yok; doldurursanız kaydedilir. Değerler g/gün.',
            style: TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 72,
                      child: Text(
                        'Kilo',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.subText,
                        ),
                      ),
                    ),
                    for (final col in KittenFeedingGuide.ageColumns)
                      SizedBox(
                        width: 72,
                        child: Text(
                          col.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: AppColors.subText,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var r = 0; r < KittenFeedingGuide.kgRows.length; r++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(
                            KittenFeedingGuide.kgLabel(
                              KittenFeedingGuide.kgRows[r],
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        for (var c = 0;
                            c < KittenFeedingGuide.ageColumns.length;
                            c++)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SizedBox(
                              width: 68,
                              child: TextField(
                                controller: field(
                                  KittenFeedingGuide.kgLabel(
                                    KittenFeedingGuide.kgRows[r],
                                  ),
                                  KittenFeedingGuide.ageColumns[c].label,
                                  KittenFeedingGuide.table[r][c] ?? 0,
                                ),
                                enabled: enabled,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: '—',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

enum _FactorKind { cat, adultDog, standardPuppy, miniAdult, miniPuppy }

class _MiniPuppyGramsGrid extends StatelessWidget {
  const _MiniPuppyGramsGrid({
    required this.enabled,
    required this.field,
  });

  final bool enabled;
  final TextEditingController Function(String kgLabel, String ageLabel, int value)
      field;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Mini Irk Yavru · hedef kilo × ay',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Excel referansı: satır beklenen yetişkin kilo (1–10 kg), sütun yaş dönemi. Değerler baz g/gün.',
            style: TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(
                      width: 72,
                      child: Text(
                        'Kilo',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: AppColors.subText,
                        ),
                      ),
                    ),
                    for (final col in MiniPuppyFeedingGuide.ageColumns)
                      SizedBox(
                        width: 88,
                        child: Text(
                          col.label,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 11,
                            color: AppColors.subText,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                for (var r = 0; r < MiniPuppyFeedingGuide.kgRows.length; r++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 72,
                          child: Text(
                            MiniPuppyFeedingGuide.kgLabel(
                              MiniPuppyFeedingGuide.kgRows[r],
                            ),
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        for (var c = 0;
                            c < MiniPuppyFeedingGuide.ageColumns.length;
                            c++)
                          Padding(
                            padding: const EdgeInsets.only(right: 4),
                            child: SizedBox(
                              width: 84,
                              child: TextField(
                                controller: field(
                                  MiniPuppyFeedingGuide.kgLabel(
                                    MiniPuppyFeedingGuide.kgRows[r],
                                  ),
                                  MiniPuppyFeedingGuide.ageColumns[c].label,
                                  MiniPuppyFeedingGuide.table[r][c],
                                ),
                                enabled: enabled,
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                decoration: const InputDecoration(
                                  isDense: true,
                                  border: OutlineInputBorder(),
                                  hintText: '—',
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StandardPuppyGramsGrid extends StatefulWidget {
  const _StandardPuppyGramsGrid({
    required this.enabled,
    required this.field,
  });

  final bool enabled;
  final TextEditingController Function(String kgLabel, String ageLabel, int value)
      field;

  @override
  State<_StandardPuppyGramsGrid> createState() =>
      _StandardPuppyGramsGridState();
}

class _StandardPuppyGramsGridState extends State<_StandardPuppyGramsGrid> {
  int _ageIndex = 1;

  @override
  Widget build(BuildContext context) {
    final ages = StandardPuppyFeedingGuide.ageColumns;
    final age = ages[_ageIndex];
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Köpek Yavru · hedef kilo × ay',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Excel referansı: satır beklenen yetişkin kilo (1–60 kg), sütun yaş dönemi. Yaş seçip o sütunu düzenleyin. Değerler baz g/gün.',
            style: TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (var i = 0; i < ages.length; i++)
                Material(
                  color: i == _ageIndex ? AppColors.selected : AppColors.surface,
                  borderRadius: BorderRadius.circular(999),
                  child: InkWell(
                    onTap: () => setState(() => _ageIndex = i),
                    borderRadius: BorderRadius.circular(999),
                    child: Ink(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: i == _ageIndex
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Text(
                        ages[i].label,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                          color: i == _ageIndex
                              ? AppColors.primary
                              : AppColors.text,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (var r = 0; r < StandardPuppyFeedingGuide.kgRows.length; r++)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      StandardPuppyFeedingGuide.kgLabel(
                        StandardPuppyFeedingGuide.kgRows[r],
                      ),
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: widget.field(
                        StandardPuppyFeedingGuide.kgLabel(
                          StandardPuppyFeedingGuide.kgRows[r],
                        ),
                        age.label,
                        StandardPuppyFeedingGuide.table[r][_ageIndex],
                      ),
                      enabled: widget.enabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        suffixText: 'g / gün',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _GramsCard extends StatelessWidget {
  const _GramsCard({
    required this.title,
    required this.hint,
    required this.rows,
    required this.enabled,
  });

  final String title;
  final String hint;
  final List<(String, TextEditingController)> rows;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            hint,
            style: const TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          for (final row in rows)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 160,
                    child: Text(
                      row.$1,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 140,
                    child: TextField(
                      controller: row.$2,
                      enabled: enabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                      ],
                      decoration: const InputDecoration(
                        suffixText: 'g / gün',
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _FactorsCard extends StatelessWidget {
  const _FactorsCard({
    required this.kind,
    required this.enabled,
    required this.field,
  });

  final _FactorKind kind;
  final bool enabled;
  final TextEditingController Function(String key, double value) field;

  @override
  Widget build(BuildContext context) {
    final d = FeedingFactors.defaults;
    final m = MiniAdultDogFactors.defaults;
    final p = MiniPuppyFactors.defaults;
    final s = StandardPuppyFactors.defaults;
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            switch (kind) {
              _FactorKind.adultDog => 'Çarpanlar (yetişkin köpek)',
              _FactorKind.standardPuppy => 'Çarpanlar (Köpek Yavru)',
              _FactorKind.miniAdult => 'Çarpanlar (Mini Irk Yetişkin)',
              _FactorKind.miniPuppy => 'Çarpanlar (Mini Irk Yavru)',
              _FactorKind.cat => 'Çarpanlar (yetişkin kedi)',
            },
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 12),
          if (kind == _FactorKind.adultDog) ...[
            _factorRow('Kısır evet', field('dog_neuteredYes', m.neuteredYes)),
            _factorRow('Kısır değil', field('dog_neuteredNo', m.neuteredNo)),
            _factorRow('Vücut zayıf', field('dog_bodyThin', m.bodyThin)),
            _factorRow('Vücut ideal', field('dog_bodyIdeal', m.bodyIdeal)),
            _factorRow('Vücut kilolu', field('dog_bodyHeavy', m.bodyHeavy)),
            _factorRow(
              'Aktivite düşük',
              field('dog_activityLow', m.activityLow),
            ),
            _factorRow(
              'Aktivite normal',
              field('dog_activityMid', m.activityMid),
            ),
            _factorRow(
              'Aktivite yüksek',
              field('dog_activityHigh', m.activityHigh),
            ),
            _factorRow(
              'Aktivite çok yüksek',
              field('dog_activityVeryHigh', m.activityVeryHigh),
            ),
            _factorRow('Ek gıda yok', field('dog_extraNone', m.extraNone)),
            _factorRow('Ödül', field('dog_extraTreat', m.extraTreat)),
            _factorRow('Yaş mama', field('dog_extraWet', m.extraWet)),
            _factorRow('Her ikisi', field('dog_extraBoth', m.extraBoth)),
          ] else if (kind == _FactorKind.standardPuppy) ...[
            _factorRow('Kısır evet', field('stdp_neuteredYes', s.neuteredYes)),
            _factorRow('Kısır değil', field('stdp_neuteredNo', s.neuteredNo)),
            _factorRow('Vücut zayıf', field('stdp_bodyThin', s.bodyThin)),
            _factorRow('Vücut ideal', field('stdp_bodyIdeal', s.bodyIdeal)),
            _factorRow('Vücut kilolu', field('stdp_bodyHeavy', s.bodyHeavy)),
            _factorRow(
              'Aktivite düşük',
              field('stdp_activityLow', s.activityLow),
            ),
            _factorRow(
              'Aktivite normal',
              field('stdp_activityMid', s.activityMid),
            ),
            _factorRow(
              'Aktivite yüksek',
              field('stdp_activityHigh', s.activityHigh),
            ),
            _factorRow(
              'Aktivite çok yüksek',
              field('stdp_activityVeryHigh', s.activityVeryHigh),
            ),
            _factorRow('Ek gıda yok', field('stdp_extraNone', s.extraNone)),
            _factorRow('Ödül', field('stdp_extraTreat', s.extraTreat)),
            _factorRow('Yaş mama', field('stdp_extraWet', s.extraWet)),
            _factorRow('Her ikisi', field('stdp_extraBoth', s.extraBoth)),
          ] else if (kind == _FactorKind.miniAdult) ...[
            _factorRow('Kısır evet', field('mini_neuteredYes', m.neuteredYes)),
            _factorRow('Kısır değil', field('mini_neuteredNo', m.neuteredNo)),
            _factorRow('Vücut zayıf', field('mini_bodyThin', m.bodyThin)),
            _factorRow('Vücut ideal', field('mini_bodyIdeal', m.bodyIdeal)),
            _factorRow('Vücut kilolu', field('mini_bodyHeavy', m.bodyHeavy)),
            _factorRow(
              'Aktivite düşük',
              field('mini_activityLow', m.activityLow),
            ),
            _factorRow(
              'Aktivite normal',
              field('mini_activityMid', m.activityMid),
            ),
            _factorRow(
              'Aktivite yüksek',
              field('mini_activityHigh', m.activityHigh),
            ),
            _factorRow(
              'Aktivite çok yüksek',
              field('mini_activityVeryHigh', m.activityVeryHigh),
            ),
            _factorRow('Ek gıda yok', field('mini_extraNone', m.extraNone)),
            _factorRow('Ödül', field('mini_extraTreat', m.extraTreat)),
            _factorRow('Yaş mama', field('mini_extraWet', m.extraWet)),
            _factorRow('Her ikisi', field('mini_extraBoth', m.extraBoth)),
          ] else if (kind == _FactorKind.miniPuppy) ...[
            _factorRow('Vücut zayıf', field('pup_bodyThin', p.bodyThin)),
            _factorRow('Vücut ideal', field('pup_bodyIdeal', p.bodyIdeal)),
            _factorRow('Vücut kilolu', field('pup_bodyHeavy', p.bodyHeavy)),
            _factorRow(
              'Aktivite düşük',
              field('pup_activityLow', p.activityLow),
            ),
            _factorRow(
              'Aktivite normal',
              field('pup_activityMid', p.activityMid),
            ),
            _factorRow(
              'Aktivite yüksek',
              field('pup_activityHigh', p.activityHigh),
            ),
            _factorRow(
              'Aktivite çok yüksek',
              field('pup_activityVeryHigh', p.activityVeryHigh),
            ),
            _factorRow('Ek gıda yok', field('pup_extraNone', p.extraNone)),
            _factorRow('Ödül', field('pup_extraTreat', p.extraTreat)),
            _factorRow('Yaş mama', field('pup_extraWet', p.extraWet)),
            _factorRow('Her ikisi', field('pup_extraBoth', p.extraBoth)),
          ] else ...[
            _factorRow('Kısır evet', field('neuteredYes', d.neuteredYes)),
            _factorRow('Kısır hayır', field('neuteredNo', d.neuteredNo)),
            _factorRow('Vücut zayıf', field('bodyThin', d.bodyThin)),
            _factorRow('Vücut ideal', field('bodyIdeal', d.bodyIdeal)),
            _factorRow('Vücut kilolu', field('bodyHeavy', d.bodyHeavy)),
            _factorRow('Aktivite düşük', field('activityLow', d.activityLow)),
            _factorRow('Aktivite orta', field('activityMid', d.activityMid)),
            _factorRow('Aktivite yüksek', field('activityHigh', d.activityHigh)),
            _factorRow('Ek besin yok', field('extraNone', d.extraNone)),
            _factorRow('Ödül', field('extraTreat', d.extraTreat)),
            _factorRow('Yaş mama', field('extraWet', d.extraWet)),
            _factorRow('Her ikisi', field('extraBoth', d.extraBoth)),
            _factorRow('Alt sınır', field('clampLow', d.clampLow)),
            _factorRow('Üst sınır', field('clampHigh', d.clampHigh)),
          ],
        ],
      ),
    );
  }

  Widget _factorRow(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.text,
                fontSize: 13,
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: TextField(
              controller: controller,
              enabled: enabled,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                isDense: true,
                border: OutlineInputBorder(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _formatFactor(double value) {
  if (value == value.roundToDouble()) return '${value.toInt()}';
  return value.toString();
}
