import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/cat_feeding_table.dart';

class FoodTrackingScreen extends StatefulWidget {
  const FoodTrackingScreen({super.key});

  @override
  State<FoodTrackingScreen> createState() => _FoodTrackingScreenState();
}

class _FoodTrackingScreenState extends State<FoodTrackingScreen> {
  int _weightKg = 10;
  DateTime _purchaseDate = DateTime.now();
  final TextEditingController _foodController = TextEditingController();
  final TextEditingController _customKgController = TextEditingController();

  static const List<int> _weights = [1, 2, 3, 5, 10, 15];

  @override
  void initState() {
    super.initState();
    final tracking = FoodTrackingStore.instance;
    if (!tracking.isActive) return;
    _foodController.text = tracking.foodName;
    _purchaseDate = tracking.purchaseDate;
    final kg = tracking.bagKg;
    if (kg == kg.roundToDouble() && _weights.contains(kg.round())) {
      _weightKg = kg.round();
    } else {
      _weightKg = -1;
      _customKgController.text = kg == kg.roundToDouble()
          ? kg.toStringAsFixed(0)
          : kg.toStringAsFixed(1).replaceAll('.', ',');
    }
  }

  @override
  void dispose() {
    _foodController.dispose();
    _customKgController.dispose();
    super.dispose();
  }

  PetData? get _guidePet {
    final pets = PetStore.instance.pets;
    for (final pet in pets) {
      if (pet.species.toLowerCase().contains('kedi')) return pet;
    }
    return pets.isEmpty ? null : pets.first;
  }

  CatFeedingRow? get _feedingRow {
    final pet = _guidePet;
    if (pet == null || !pet.species.toLowerCase().contains('kedi')) {
      return null;
    }
    return CatFeedingGuide.fromWeightLabel(pet.weight);
  }

  double get _bagKg {
    if (_weightKg > 0) return _weightKg.toDouble();
    final typed = _customKgController.text.trim().replaceAll(',', '.');
    return double.tryParse(typed) ?? 0;
  }

  int get _profileDailyGrams {
    final pet = _guidePet;
    final row = _feedingRow;
    if (pet == null || row == null) return 0;
    return row.gramsFor(
      bodyType: pet.bodyType,
      activityLevel: pet.activityLevel,
    );
  }

  int get _estimatedDays {
    if (_bagKg <= 0) return 0;
    final row = _feedingRow;
    if (row != null) {
      return row.daysForBagKg(_bagKg, daily: _profileDailyGrams);
    }
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
              primary: AppColors.primary,
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
              _buildFoodSection(),
              const SizedBox(height: 14),
              _buildWeightSection(),
              const SizedBox(height: 14),
              _buildDateSection(),
              const SizedBox(height: 14),
              _buildEstimateCard(),
              const SizedBox(height: 12),
              CatFeedingTableCard(
                highlighted: _feedingRow,
                bodyType: _guidePet?.bodyType,
                activityLevel: _guidePet?.activityLevel,
              ),
              const SizedBox(height: 12),
              AppPressableButton.primary(
                onTap: () {
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
                  FoodTrackingStore.instance.start(
                    foodName: _foodController.text,
                    bagKg: bagKg,
                    purchaseDate: _purchaseDate,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Mama takibi başlatıldı. Manuel kg esas alındı.'),
                      backgroundColor: AppColors.primary,
                    ),
                  );
                  Navigator.of(context).maybePop();
                },
                width: double.infinity,
                height: 48,
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
          const Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Mama Takibini Başlat',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.pageHeader,
                  ),
                ),
                SizedBox(width: 4),
                Icon(Icons.pets_rounded, color: AppColors.primary, size: 16),
              ],
            ),
          ),
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Image.asset(
          'assets/images/mama_takibi_banner.png',
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Container(
              height: 140,
              color: AppColors.selected,
              alignment: Alignment.center,
              child: const Icon(
                Icons.pets_rounded,
                color: AppColors.primary,
                size: 40,
              ),
            );
          },
        ),
      ),
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
            color: AppColors.primary,
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
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
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
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _foodController,
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
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        AppPressableButton.soft(
          onTap: () {},
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 12),
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
      ],
    );
  }

  Widget _buildWeightSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(2, 'Ne kadar mama aldınız?'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (var i = 0; i < _weights.length; i++) ...[
              if (i > 0) const SizedBox(width: 5),
              Expanded(child: _weightChip(_weights[i])),
            ],
            const SizedBox(width: 5),
            Expanded(child: _weightChip(-1, label: 'Diğer')),
          ],
        ),
        if (_weightKg < 0) ...[
          const SizedBox(height: 8),
          Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _customKgController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Kaç kg? (ör. 4,5)',
                hintStyle: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
                suffixText: 'kg',
                suffixStyle: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _weightChip(int kg, {String? label}) {
    final selected = _weightKg == kg;
    return GestureDetector(
      onTap: () => setState(() => _weightKg = kg),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            label ?? '$kg kg',
            style: TextStyle(
              color: selected ? AppColors.surface : AppColors.text,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ),
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
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
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
                  color: AppColors.subText,
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
    final pet = _guidePet;
    final remaining = (_remainingRatio * 100).round();
    final daily = _profileDailyGrams;
    final hint = row != null && pet != null && daily > 0
        ? '${pet.name} (${pet.weight}, ${CatFeedingGuide.profileLabel(bodyType: pet.bodyType, activityLevel: pet.activityLevel)}) '
            'için günde $daily g, 30 günde ${row.monthlyFor(daily)}. '
            '${_bagKg.toStringAsFixed(0)} kg mama yaklaşık $_estimatedDays gün yeter.'
        : 'Tahmin kilo, vücut tipi ve aktiviteye göre hesaplanır.';

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
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
                          color: AppColors.primary,
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
                        color: AppColors.primary,
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
                        backgroundColor: AppColors.border,
                        color: AppColors.primary,
                        strokeCap: StrokeCap.round,
                      ),
                    ),
                    Text(
                      '%$remaining',
                      style: const TextStyle(
                        color: AppColors.primary,
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
                color: AppColors.primary,
                size: 14,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  hint,
                  style: const TextStyle(
                    color: AppColors.primary,
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
