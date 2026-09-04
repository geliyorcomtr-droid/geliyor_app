import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/data/dog_feeding_guide.dart';
import 'package:geliyor_app/services/food_remaining_estimator.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/cat_feeding_table.dart';
import 'package:geliyor_app/widgets/dog_feeding_table.dart';

class FoodTrackingScreen extends StatefulWidget {
  const FoodTrackingScreen({super.key});

  @override
  State<FoodTrackingScreen> createState() => _FoodTrackingScreenState();
}

class _FoodTrackingScreenState extends State<FoodTrackingScreen> {
  int _weightKg = 10;
  DateTime _purchaseDate = DateTime.now();
  final TextEditingController _foodController = TextEditingController();
  String? _selectedPetName;

  static const int _minKg = 1;
  static const int _maxKg = 19;

  /// Akıllı Plan → Mama Takibi / Hangi Mama rengi.
  static const Color _accent = Color(0xFF8B5CF6);

  Color get _soft => _accent.withValues(alpha: 0.12);
  Color get _line => _accent.withValues(alpha: 0.45);
  Color get _lineSoft => _accent.withValues(alpha: 0.28);
  Color get _buttonFill =>
      Color.lerp(_accent, Colors.white, 0.28) ?? _accent;

  TextStyle get _titleStyle => AppTextStyles.pageHeaderWith(
        color: _accent,
      );

  TextStyle get _sectionTitleStyle => AppTextStyles.sectionHeaderWith(
        color: _accent,
      );

  @override
  void initState() {
    super.initState();
    final tracking = FoodTrackingStore.instance;
    final pets = PetStore.instance.pets;
    _selectedPetName =
        tracking.petName ??
        PetStore.instance.activePet?.name ??
        (pets.isNotEmpty ? pets.first.name : null);
    if (!tracking.isActive) return;
    _foodController.text = tracking.foodName;
    _purchaseDate = tracking.purchaseDate;
    final kg = tracking.bagKg.round().clamp(_minKg, _maxKg);
    _weightKg = kg;
  }

  @override
  void dispose() {
    _foodController.dispose();
    super.dispose();
  }

  Future<void> _startTracking() async {
    final bagKg = _bagKg;
    if (bagKg <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lütfen mama kilosunu girin.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    final ok = await LoginGate.require(
      context: context,
      message: 'Mama takibini kaydetmek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;
    FoodTrackingStore.instance.start(
      foodName: _foodController.text,
      bagKg: bagKg,
      purchaseDate: _purchaseDate,
      petName: _guidePet?.name,
      petSpecies: _guidePet?.species,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Mama takibi başlatıldı. Manuel kg esas alındı.'),
        backgroundColor: _accent,
      ),
    );
    Navigator.of(context).maybePop();
  }

  PetData? get _guidePet {
    final pets = PetStore.instance.pets;
    final selectedName = _selectedPetName;
    if (selectedName != null) {
      for (final pet in pets) {
        if (pet.name == selectedName) return pet;
      }
    }
    return pets.isEmpty ? null : pets.first;
  }

  bool get _isDog =>
      _guidePet?.species.toLowerCase().contains('köpek') == true ||
      _guidePet?.species.toLowerCase().contains('kopek') == true;

  CatFeedingRow? get _feedingRow {
    final pet = _guidePet;
    if (pet == null || !pet.species.toLowerCase().contains('kedi')) {
      return null;
    }
    return CatFeedingGuide.fromWeightLabel(pet.weight);
  }

  DogFeedingRow? get _dogFeedingRow {
    if (!_isDog) return null;
    return DogFeedingGuide.fromSizeLabel(_guidePet?.ageRange);
  }

  double get _bagKg => _weightKg.toDouble();

  int get _profileDailyGrams {
    final pet = _guidePet;
    if (pet == null) return 0;
    return FoodRemainingEstimator.sharedDailyGrams(
      FoodRemainingEstimator.sharingPetsFor(pet),
    );
  }

  int get _estimatedDays {
    if (_bagKg <= 0) return 0;
    final daily = _profileDailyGrams;
    if (daily > 0) return ((_bagKg * 1000) / daily).round();
    return (_bagKg * 2.4).round().clamp(7, 120);
  }

  DateTime get _estimatedEnd =>
      _purchaseDate.add(Duration(days: _estimatedDays));

  double get _remainingRatio {
    final total = _estimatedDays;
    if (total <= 0) return 0;
    final elapsed = DateTime.now().difference(_purchaseDate).inDays;
    return (1 - (elapsed / total)).clamp(0.0, 1.0);
  }

  String _formatDate(DateTime d) {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now().add(const Duration(days: 1)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: _accent,
              onPrimary: AppColors.surface,
              surface: AppColors.surface,
              onSurface: AppColors.text,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(),
        content: ListenableBuilder(
          listenable: PetStore.instance,
          builder: (context, _) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Mamanız bitmeden sizi haberdar edelim.',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildBanner(),
                  const SizedBox(height: 14),
                  _buildPetSection(),
                  const SizedBox(height: 14),
                  _buildFoodSection(),
                  const SizedBox(height: 14),
                  _buildWeightSection(),
                  const SizedBox(height: 14),
                  _buildDateSection(),
                  const SizedBox(height: 14),
                  _buildEstimateCard(),
                  const SizedBox(height: 12),
                  CatFeedingTableCard(
                    highlighted: _isDog ? null : _feedingRow,
                    bodyType: _isDog ? null : _guidePet?.bodyType,
                    activityLevel: _isDog ? null : _guidePet?.activityLevel,
                  ),
                  const SizedBox(height: 10),
                  DogFeedingTableCard(
                    highlighted: _isDog ? _dogFeedingRow : null,
                    activityLevel: _isDog ? _guidePet?.activityLevel : null,
                  ),
                  const SizedBox(height: 12),
                  AppPressableButton(
                    onTap: () {
                      _startTracking();
                    },
                    width: double.infinity,
                    height: 48,
                    backgroundColor: _buttonFill,
                    pressedBackgroundColor: _accent,
                    foregroundColor: AppColors.surface,
                    pressedForegroundColor: AppColors.surface,
                    borderColor: _buttonFill,
                    pressedBorderColor: _accent,
                    builder: (pressed) => DefaultTextStyle.merge(
                      style: const TextStyle(
                        color: AppColors.surface,
                        fontWeight: FontWeight.w900,
                      ),
                      child: IconTheme.merge(
                        data: const IconThemeData(color: AppColors.surface),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.pets_rounded, size: 18),
                            SizedBox(width: 8),
                            Text(
                              'Takibi Başlat',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        navbar: const AppBottomNavbar(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Mama Takibini Başlat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _titleStyle,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.pets_rounded, color: _accent, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return const AppBannerSlot(
      placement: BannerPlacement.foodTracking,
      fallbackAssets: ['assets/images/mama_takibi_banner.png'],
    );
  }

  Widget _sectionTitle(int number, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: _accent,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$number',
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: _sectionTitleStyle)),
      ],
    );
  }

  Widget _buildPetSection() {
    final pets = PetStore.instance.pets;
    if (pets.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: _soft,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _lineSoft),
        ),
        child: const Text(
          'Önce Dost Ekle sayfasından dostunuzu kaydedin.',
          style: TextStyle(
            color: AppColors.subText,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mama türü',
          style: TextStyle(
            color: _accent,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Aynı türdeki tüm dostlar bu paketi paylaşır. Günlük tüketimler toplanır.',
          style: TextStyle(
            color: AppColors.subText,
            fontSize: 11.5,
            fontWeight: FontWeight.w600,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final pet in pets)
              GestureDetector(
                onTap: () => setState(() => _selectedPetName = pet.name),
                child: Container(
                  height: 34,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: _selectedPetName == pet.name
                        ? _accent
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _selectedPetName == pet.name ? _accent : _lineSoft,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.pets_rounded,
                        size: 14,
                        color: _selectedPetName == pet.name
                            ? AppColors.surface
                            : _accent,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${pet.name} · ${pet.species}',
                        style: TextStyle(
                          color: _selectedPetName == pet.name
                              ? AppColors.surface
                              : AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFoodSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(1, 'Kullandığınız mama hangisi?'),
        const SizedBox(height: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _lineSoft),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.search_rounded,
                color: _accent,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _foodController,
                  cursorColor: _accent,
                  decoration: const InputDecoration(
                    hintText: 'Mama markası veya adı yazın',
                    hintStyle: TextStyle(
                      color: AppColors.subText,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w500,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                  ),
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const Icon(
                Icons.qr_code_scanner_rounded,
                color: _accent,
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppPressableButton(
          onTap: () {},
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
          backgroundColor: _soft,
          pressedBackgroundColor: _accent,
          foregroundColor: _accent,
          pressedForegroundColor: AppColors.surface,
          borderColor: _lineSoft,
          pressedBorderColor: _accent,
          builder: (pressed) => DefaultTextStyle.merge(
            style: TextStyle(
              color: pressed ? AppColors.surface : _accent,
              fontWeight: FontWeight.w800,
            ),
            child: IconTheme.merge(
              data: IconThemeData(
                color: pressed ? AppColors.surface : _accent,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.photo_camera_outlined, size: 18),
                  SizedBox(width: 8),
                  Text(
                    'Mama paketini fotoğraflayın',
                    style: TextStyle(fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(2, 'Ne kadar mama aldınız?'),
        const SizedBox(height: 8),
        _buildWeightDropdown(
          value: '$_weightKg kg',
          placeholder: 'Kilo seç',
          onTap: () => _openSelectSheet(
            title: 'Mama kilosu',
            options: [
              for (var kg = _minKg; kg <= _maxKg; kg++) '$kg kg',
            ],
            selected: '$_weightKg kg',
            onSelect: (value) {
              final parsed = int.tryParse(value.replaceAll(' kg', ''));
              if (parsed != null) {
                setState(() => _weightKg = parsed.clamp(_minKg, _maxKg));
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildWeightDropdown({
    required String? value,
    required String placeholder,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Ink(
          height: 36,
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: _lineSoft),
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
                color: _accent,
                size: 22,
              ),
            ],
          ),
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
                side: BorderSide(color: _lineSoft),
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
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            thickness: 1,
                            color: _lineSoft,
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
                                                ? _accent
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
                                            ? _accent
                                            : _lineSoft,
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

  Widget _buildDateSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(3, 'Ne zaman aldınız?'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: _pickDate,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: _lineSoft),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: _accent,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _formatDate(_purchaseDate),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _accent,
                  size: 22,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEstimateCard() {
    final row = _feedingRow;
    final dogRow = _dogFeedingRow;
    final pet = _guidePet;
    final remaining = (_remainingRatio * 100).round();
    final daily = _profileDailyGrams;
    final monthlyKg = (daily * 30 / 1000)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    final sharing = pet == null
        ? const <PetData>[]
        : FoodRemainingEstimator.sharingPetsFor(pet);
    final shareLabel = FoodRemainingEstimator.shareLabelFor(sharing);
    final hint = pet != null && daily > 0
        ? sharing.length > 1
              ? '$shareLabel bu paketi paylaşıyor. Günlük toplam $daily g, '
                    '30 günde $monthlyKg kg. '
                    '${_bagKg.toStringAsFixed(0)} kg mama yaklaşık $_estimatedDays gün yeter.'
              : _isDog && dogRow != null
              ? '${pet.name} (${dogRow.size}, ${DogFeedingGuide.normalizeActivity(pet.activityLevel)} aktivite) '
                    'için tablo aralığı ${dogRow.rangeFor(pet.activityLevel)}, tahmini günlük $daily g ve 30 günde $monthlyKg kg. '
                    '${_bagKg.toStringAsFixed(0)} kg mama yaklaşık $_estimatedDays gün yeter.'
              : row != null
              ? '${pet.name} (${pet.weight}, ${CatFeedingGuide.profileLabel(bodyType: pet.bodyType, activityLevel: pet.activityLevel)}) '
                    'için günde $daily g, 30 günde ${row.monthlyFor(daily)}. '
                    '${_bagKg.toStringAsFixed(0)} kg mama yaklaşık $_estimatedDays gün yeter.'
              : 'Dostun bilgileriyle günlük tüketim hesaplanamadı.'
        : 'Tahmin dostun boyutu, kilosu ve aktivitesine göre hesaplanır.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _soft,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.eco_rounded,
                          color: _accent,
                          size: 16,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Tahmini bitiş tarihi',
                          style: TextStyle(
                            color: AppColors.subText,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatDate(_estimatedEnd),
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 56,
                height: 56,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 56,
                      height: 56,
                      child: CircularProgressIndicator(
                        value: _remainingRatio,
                        strokeWidth: 5,
                        backgroundColor: _lineSoft,
                        color: _accent,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '%$remaining',
                      style: const TextStyle(
                        color: _accent,
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: _accent,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(
                    color: _accent,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
