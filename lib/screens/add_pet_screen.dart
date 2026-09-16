import 'dart:typed_data';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/pet_photo.dart';
import 'package:image_picker/image_picker.dart';

class AddPetScreen extends StatefulWidget {
  const AddPetScreen({super.key, this.editIndex, this.pet});

  final int? editIndex;
  final PetData? pet;

  bool get isEditing => editIndex != null && pet != null;

  @override
  State<AddPetScreen> createState() => _AddPetScreenState();
}

class _AddPetScreenState extends State<AddPetScreen> {
  final TextEditingController _nameController = TextEditingController();
  String? _species = 'Kedi';
  String? _ageRange = 'Yavru';
  String? _weight = '1-2 kg';
  String? _neutered;
  String? _bodyType = 'İdeal';
  String? _activityLevel = 'Orta';
  String? _extraFood;
  Uint8List? _photoBytes;
  String? _photoUrl;
  bool _saving = false;

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

  PetData get _previewPet => PetData(
    name: _nameController.text.trim().isEmpty
        ? (widget.pet?.name ?? 'Dost')
        : _nameController.text.trim(),
    species: _species ?? 'Kedi',
    photoUrl: _photoUrl,
  );

  @override
  void initState() {
    super.initState();
    final pet = widget.pet;
    if (pet != null) {
      _nameController.text = pet.name;
      _species = pet.species;
      _ageRange = pet.ageRange;
      _weight = pet.weight;
      _neutered = pet.neutered;
      _bodyType = pet.bodyType ?? 'İdeal';
      _activityLevel = pet.activityLevel;
      _extraFood = pet.extraFood;
      _photoUrl = pet.photoUrl;
    }
  }

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

  Future<void> _openPhotoSourceSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppPageFrame.width),
            child: Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Dost görseli ekle',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Galeriden seç veya fotoğraf çek.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _buildImageSourceButton(
                      icon: Icons.photo_camera_outlined,
                      label: 'Fotoğraf çek',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _pickPhoto(ImageSource.camera);
                      },
                    ),
                    const SizedBox(height: 8),
                    _buildImageSourceButton(
                      icon: Icons.photo_library_outlined,
                      label: 'Galeriden seç',
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _pickPhoto(ImageSource.gallery);
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildImageSourceButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return AppPressableButton(
      onTap: onTap,
      width: double.infinity,
      height: 42,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      backgroundColor: AppColors.background,
      pressedBackgroundColor: AppColors.selected,
      borderColor: AppColors.border,
      pressedBorderColor: AppColors.primaryLight,
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Icon(
            Icons.chevron_right_rounded,
            color: AppColors.subText,
            size: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _pickPhoto(ImageSource source) async {
    try {
      final file = await ImagePicker().pickImage(
        source: source,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null || !mounted) return;
      final bytes = await file.readAsBytes();
      if (!mounted || bytes.isEmpty) return;
      setState(() => _photoBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Kamera açılamadı. İzinleri kontrol edin.'
                : 'Galeri açılamadı.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String?> _uploadPhoto(Uint8List bytes) async {
    final uid = AuthStore.instance.uid ?? '';
    if (uid.isEmpty) return null;
    final ref = FirebaseStorage.instance.ref(
      'pet_photos/$uid/${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await ref.putData(bytes, SettableMetadata(contentType: 'image/jpeg'));
    return ref.getDownloadURL();
  }

  Future<void> _savePet() async {
    if (_saving) return;
    final ok = await LoginGate.require(
      context: context,
      message: 'Dost kaydetmek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;

    setState(() => _saving = true);
    try {
      var photoUrl = _photoUrl;
      final bytes = _photoBytes;
      var photoFailed = false;
      if (bytes != null && bytes.isNotEmpty) {
        try {
          photoUrl = await _uploadPhoto(bytes) ?? photoUrl;
        } catch (_) {
          photoFailed = true;
        }
      }

      final species = _species ?? 'Kedi';
      final typedName = _nameController.text.trim();
      final dailyFoodGrams = species == 'Köpek'
          ? DogFeedingGuide.dailyGramsFor(
              sizeLabel: _ageRange,
              activityLevel: _activityLevel,
            )
          : CatFeedingGuide.dailyGramsFor(
              weightLabel: _weight,
              bodyType: _bodyType ?? 'İdeal',
              activityLevel: _activityLevel,
            );

      if (widget.isEditing) {
        final existing = widget.pet!;
        PetStore.instance.updatePet(
          widget.editIndex!,
          PetData(
            name: typedName.isEmpty ? existing.name : typedName,
            species: species,
            ageRange: _ageRange,
            weight: _weight,
            bodyType: _bodyType ?? 'İdeal',
            neutered: _neutered,
            activityLevel: _activityLevel,
            extraFood: _extraFood,
            dailyFoodGrams: dailyFoodGrams,
            allergies: existing.allergies,
            photoUrl: photoUrl ?? existing.photoUrl,
          ),
        );
      } else {
        final count =
            PetStore.instance.pets.where((p) => p.species == species).length + 1;
        PetStore.instance.addPet(
          PetData(
            name: typedName.isEmpty ? '$species $count' : typedName,
            species: species,
            ageRange: _ageRange,
            weight: _weight,
            bodyType: _bodyType ?? 'İdeal',
            neutered: _neutered,
            activityLevel: _activityLevel,
            extraFood: _extraFood,
            dailyFoodGrams: dailyFoodGrams,
            photoUrl: photoUrl,
          ),
        );
      }
      if (!mounted) return;
      if (photoFailed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Dost kaydedildi. Görsel yüklenemedi.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: AppPageHeader(
          title: widget.isEditing ? 'Dostu Düzenle' : 'Yeni Dost Ekle',
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPhotoPicker(),
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
              AppPressableButton.primary(
                onTap: _saving ? null : _savePet,
                enabled: !_saving,
                width: double.infinity,
                height: 42,
                child: _saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.2,
                          color: AppColors.surface,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_rounded, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Kaydet',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.home),
      ),
    );
  }

  Widget _buildPhotoPicker() {
    return Center(
      child: Column(
        children: [
          GestureDetector(
            onTap: _openPhotoSourceSheet,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    color: AppColors.selected,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: PetPhoto(
                    pet: _previewPet,
                    photoBytes: _photoBytes,
                    iconSize: 36,
                  ),
                ),
                Positioned(
                  right: -4,
                  bottom: -4,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.surface, width: 2),
                    ),
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: AppColors.surface,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Galeriden seç veya fotoğraf çek',
            style: TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
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
