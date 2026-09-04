import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class MeetPetScreen extends StatefulWidget {
  const MeetPetScreen({super.key});

  @override
  State<MeetPetScreen> createState() => _MeetPetScreenState();
}

class _MeetPetScreenState extends State<MeetPetScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _species = 'Kedi';
  String? _ageRange = 'Yavru';
  String? _weight = '1-2 kg';
  String? _neutered;
  String? _bodyType;
  String? _activityLevel = 'Orta';
  String? _extraFood;

  static const _ageOptions = ['Yavru', 'Genç', 'Yetişkin', 'Senior'];

  static const _dogSizeOptions = [
    'X-Small (0-4 kg)',
    'Mini (5-10 kg)',
    'Medium (11-25 kg)',
    'Maxi (26-44 kg)',
    'Giant (45 kg+)',
  ];

  static const _activityOptions = ['Düşük', 'Orta', 'Yüksek'];
  static const _catWeightOptions = [
    '1-2 kg',
    '2-3 kg',
    '3-4 kg',
    '4-5 kg',
    '5-6 kg',
    '6-7 kg',
    '7-8 kg',
    '8-9 kg',
    '9-10 kg',
  ];
  static const _dogWeightOptions = [
    '0-5 kg',
    '5-10 kg',
    '10-20 kg',
    '20-30 kg',
    '30-40 kg',
    '40-50 kg',
    '50+ kg',
  ];
  static const _bodyTypeOptions = ['Zayıf', 'İdeal', 'Kilolu'];
  static const _extraFoodOptions = [
    'Hayır',
    'Yaş mama',
    'Ödül maması',
    'Her ikisi',
  ];

  List<String> get _weightOptions =>
      _species == 'Köpek' ? _dogWeightOptions : _catWeightOptions;

  bool get _isDog => _species == 'Köpek';

  void _selectSpecies(String species) {
    setState(() {
      _species = species;
      final weightOpts = species == 'Köpek'
          ? _dogWeightOptions
          : _catWeightOptions;
      if (_weight == null || !weightOpts.contains(_weight)) {
        _weight = weightOpts.first;
      }
      final rangeOpts = species == 'Köpek' ? _dogSizeOptions : _ageOptions;
      if (_ageRange == null || !rangeOpts.contains(_ageRange)) {
        _ageRange = rangeOpts.first;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  List<PetData> get _savedPets => PetStore.instance.pets;
  int? _selectedPetIndex;

  static String _imageForSpecies(String species) {
    return species == 'Köpek'
        ? 'assets/images/luna_kopek.png'
        : 'assets/images/milo_kedi.png';
  }

  void _clearSelections() {
    _nameController.clear();
    _species = null;
    _ageRange = null;
    _weight = null;
    _neutered = null;
    _bodyType = null;
    _activityLevel = null;
    _extraFood = null;
  }

  void _loadPetIntoForm(PetData pet) {
    _nameController.text = pet.name;
    _species = pet.species;
    _ageRange = pet.ageRange;
    _weight = pet.weight;
    _neutered = pet.neutered;
    _bodyType = pet.bodyType;
    _activityLevel = pet.activityLevel;
    _extraFood = pet.extraFood;
  }

  Future<void> _savePet() async {
    final editingAsMember = LoginGate.isLoggedIn && _selectedPetIndex != null;
    final ok = await LoginGate.require(
      context: context,
      message: 'Dost kaydetmek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;

    final species = _species ?? 'Kedi';
    final typedName = _nameController.text.trim();
    final dailyFoodGrams = species == 'Köpek'
        ? DogFeedingGuide.dailyGramsFor(
            sizeLabel: _ageRange,
            activityLevel: _activityLevel,
          )
        : CatFeedingGuide.dailyGramsFor(
            weightLabel: _weight,
            bodyType: _bodyType,
            activityLevel: _activityLevel,
          );
    setState(() {
      if (editingAsMember) {
        final existing = _savedPets[_selectedPetIndex!];
        PetStore.instance.updatePet(
          _selectedPetIndex!,
          PetData(
            name: typedName.isEmpty ? existing.name : typedName,
            species: species,
            ageRange: _ageRange,
            weight: _weight,
            bodyType: _bodyType,
            neutered: _neutered,
            activityLevel: _activityLevel,
            extraFood: _extraFood,
            dailyFoodGrams: dailyFoodGrams,
            allergies: existing.allergies,
          ),
        );
      } else {
        final count = _savedPets.where((p) => p.species == species).length + 1;
        PetStore.instance.addPet(
          PetData(
            name: typedName.isEmpty ? '$species $count' : typedName,
            species: species,
            ageRange: _ageRange,
            weight: _weight,
            bodyType: _bodyType,
            neutered: _neutered,
            activityLevel: _activityLevel,
            extraFood: _extraFood,
            dailyFoodGrams: dailyFoodGrams,
          ),
        );
      }
      _selectedPetIndex = null;
      _clearSelections();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dost bilgileri kaydedildi.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTopBanner(),
              const SizedBox(height: 10),
              _buildPetSummaryCard(),
              const SizedBox(height: 10),
              _buildQuestion(title: 'Dostunun adı?', child: _buildNameField()),
              const SizedBox(height: 10),
              _buildQuestion(
                number: '1',
                title: 'Türü nedir?',
                child: _buildSpeciesRow(),
              ),
              const SizedBox(height: 10),
              _buildQuestion(
                number: '2',
                title: 'Kısır mı?',
                child: _buildNeuteredRow(),
              ),
              const SizedBox(height: 10),
              if (_isDog)
                _buildQuestion(
                  number: '3',
                  title: 'Boyuta Göre',
                  child: _buildSelectDropdown(
                    value: _ageRange,
                    placeholder: 'Boyut seç',
                    onTap: () => _openSelectSheet(
                      title: 'Boyuta Göre',
                      options: _dogSizeOptions,
                      selected: _ageRange,
                      onSelect: (v) => setState(() => _ageRange = v),
                    ),
                  ),
                )
              else ...[
                _buildQuestion(
                  number: '3',
                  title: 'Yaş aralığı nedir?',
                  child: _buildSelectDropdown(
                    value: _ageRange,
                    placeholder: 'Yaş seç',
                    onTap: () => _openSelectSheet(
                      title: 'Yaş Aralığı',
                      options: _ageOptions,
                      selected: _ageRange,
                      onSelect: (v) => setState(() => _ageRange = v),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                _buildQuestion(
                  number: '4',
                  title: 'Kilosu nedir?',
                  child: _buildSelectDropdown(
                    value: _weight,
                    placeholder: 'Kilo seç',
                    onTap: () => _openSelectSheet(
                      title: 'Kilo',
                      options: _weightOptions,
                      selected: _weight,
                      onSelect: (v) => setState(() => _weight = v),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 10),
              _buildQuestion(
                number: _isDog ? '4' : '5',
                title: 'Vücut yapısı?',
                child: _buildOptionRow(
                  options: _bodyTypeOptions,
                  selected: _bodyType,
                  onSelect: (v) => setState(() => _bodyType = v),
                ),
              ),
              const SizedBox(height: 10),
              _buildQuestion(
                number: _isDog ? '5' : '6',
                title: 'Aktivite seviyesi nedir?',
                child: _buildOptionRow(
                  options: _activityOptions,
                  selected: _activityLevel,
                  onSelect: (v) => setState(() => _activityLevel = v),
                ),
              ),
              const SizedBox(height: 10),
              _buildQuestion(
                number: _isDog ? '6' : '7',
                title: 'Kuru mama dışında düzenli besin tüketiyor mu?',
                child: _buildOptionRow(
                  options: _extraFoodOptions,
                  selected: _extraFood,
                  onSelect: (v) => setState(() => _extraFood = v),
                ),
              ),
              const SizedBox(height: 14),
              _buildBottomActions(),
              const SizedBox(height: 8),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.home),
      ),
    );
  }

  Widget _buildHeader() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          AppBackButton(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.pets_rounded, color: AppColors.primary, size: 20),
                SizedBox(width: 6),
                Text(
                  'Dost Ekle',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageHeader,
                ),
              ],
            ),
          ),
          SizedBox(width: 42),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return const AppBannerSlot(
      placement: BannerPlacement.meetPet,
      fallbackAssets: ['assets/images/dostunu_taniyalim_banner.png'],
    );
  }

  Widget _buildPetSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SizedBox(
        height: 68,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          itemCount: _savedPets.length + 1,
          separatorBuilder: (context, index) => const SizedBox(width: 10),
          itemBuilder: (context, index) => index == _savedPets.length
              ? _buildAddPetAvatar()
              : _buildPetAvatar(index),
        ),
      ),
    );
  }

  Widget _buildAddPetAvatar() {
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPetIndex = null;
          _clearSelections();
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.selected,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 1.5),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Icon(
              Icons.add_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
          const SizedBox(height: 3),
          const Text(
            'Dost Ekle',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetAvatar(int index) {
    final pet = _savedPets[index];
    final selected = _selectedPetIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _selectedPetIndex = null;
            _clearSelections();
          } else {
            _selectedPetIndex = index;
            _loadPetIntoForm(pet);
          }
        });
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 140),
            width: 44,
            height: 44,
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? AppColors.primaryLight : AppColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                _imageForSpecies(pet.species),
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.pets_rounded,
                    color: AppColors.primary,
                    size: 22,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            pet.name,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.text,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion({
    String? number,
    required String title,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            if (number != null) ...[
              Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  number,
                  style: const TextStyle(
                    color: AppColors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Expanded(child: Text(title, style: AppTextStyles.questionHeader)),
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _buildSpeciesRow() {
    return Row(
      children: [
        _OptionChip(
          label: 'Köpek',
          selected: _species == 'Köpek',
          compact: true,
          onTap: () => _selectSpecies('Köpek'),
        ),
        const SizedBox(width: 6),
        _OptionChip(
          label: 'Kedi',
          selected: _species == 'Kedi',
          compact: true,
          onTap: () => _selectSpecies('Kedi'),
        ),
      ],
    );
  }

  Widget _buildNeuteredRow() {
    return Row(
      children: [
        _OptionChip(
          label: 'Evet',
          selected: _neutered == 'Evet',
          compact: true,
          onTap: () => setState(() => _neutered = 'Evet'),
        ),
        const SizedBox(width: 6),
        _OptionChip(
          label: 'Hayır',
          selected: _neutered == 'Hayır',
          compact: true,
          onTap: () => setState(() => _neutered = 'Hayır'),
        ),
      ],
    );
  }

  Widget _buildSelectDropdown({
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                value ?? placeholder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: value == null ? AppColors.subText : AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSelectSheet({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (sheetContext) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36),
            child: Material(
              color: AppColors.surface,
              elevation: 8,
              shadowColor: Colors.black.withValues(alpha: 0.18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: const BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  maxWidth: AppPageFrame.width - 72,
                  maxHeight: 280,
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          GestureDetector(
                            onTap: () => Navigator.of(sheetContext).pop(),
                            child: const Icon(
                              Icons.close_rounded,
                              color: AppColors.subText,
                              size: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Flexible(
                        child: ListView.separated(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            thickness: 1,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final option = options[index];
                            final isSelected = selected == option;
                            return Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () {
                                  onSelect(option);
                                  Navigator.of(sheetContext).pop();
                                },
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 10,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          option,
                                          style: TextStyle(
                                            color: isSelected
                                                ? AppColors.primary
                                                : AppColors.text,
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: isSelected
                                            ? AppColors.primary
                                            : AppColors.border,
                                        size: 18,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionRow({
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Row(
      children: [
        for (int i = 0; i < options.length; i++) ...[
          Expanded(
            child: _OptionChip(
              label: options[i],
              selected: selected == options[i],
              onTap: () => onSelect(options[i]),
            ),
          ),
          if (i != options.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }

  Widget _buildNameField() {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      alignment: Alignment.center,
      child: TextField(
        controller: _nameController,
        textCapitalization: TextCapitalization.words,
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
        decoration: const InputDecoration(
          isDense: true,
          border: InputBorder.none,
          hintText: 'Örn. Misket',
          hintStyle: TextStyle(
            color: AppColors.subText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Future<void> _deletePet() async {
    if (_selectedPetIndex == null) return;
    final ok = await LoginGate.require(
      context: context,
      message: 'Dost silmek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;
    setState(() {
      PetStore.instance.removePet(_selectedPetIndex!);
      _selectedPetIndex = null;
      _clearSelections();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dost silindi.'),
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Widget _buildBottomActions() {
    return Row(
      children: [
        Expanded(
          child: AppPressableButton(
            onTap: _deletePet,
            enabled: _selectedPetIndex != null,
            height: 42,
            backgroundColor: AppColors.primaryLight,
            pressedBackgroundColor: AppColors.primary,
            borderColor: AppColors.primaryLight,
            pressedBorderColor: AppColors.primary,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.delete_outline_rounded,
                  size: 18,
                  color: AppColors.surface,
                ),
                SizedBox(width: 4),
                Text(
                  'Sil',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: AppPressableButton(
            onTap: () {
              _savePet();
            },
            height: 42,
            backgroundColor: AppColors.primaryLight,
            pressedBackgroundColor: AppColors.primary,
            borderColor: AppColors.primaryLight,
            pressedBorderColor: AppColors.primary,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.check_rounded, size: 18, color: AppColors.surface),
                SizedBox(width: 4),
                Text(
                  'Kaydet',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
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

class _OptionChip extends StatelessWidget {
  const _OptionChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        height: compact ? 28 : 32,
        width: compact ? 64 : double.infinity,
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 6),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withValues(alpha: 0.04)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: 0.8,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: selected ? AppColors.primaryLight : AppColors.text,
            fontSize: compact ? 11 : 11.5,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}
