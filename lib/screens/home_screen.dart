import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/easy_order_screen.dart';
import 'package:geliyor_app/screens/filter_screen.dart';
import 'package:geliyor_app/screens/hangi_mama_screen.dart';
import 'package:geliyor_app/screens/health_screen.dart';
import 'package:geliyor_app/screens/knowledge_base_screen.dart';
import 'package:geliyor_app/screens/meet_pet_screen.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/screens/pet_market_screen.dart';
import 'package:geliyor_app/screens/smart_plan_screen.dart';
import 'package:geliyor_app/services/food_remaining_estimator.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  static const _healthKeywords = [
    'sağlık',
    'saglik',
    'aşı',
    'asi',
    'ilaç',
    'ilac',
    'tedavi',
    'vitamin',
    'e-nabız',
    'enabız',
    'enabiz',
    'hatırlat',
    'hatirlat',
    'parazit',
    'veteriner',
    'takvim',
    'muayene',
  ];

  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch([String? value]) {
    final query = (value ?? _searchController.text).trim().toLowerCase();
    if (query.isEmpty) return;

    final isHealth = _healthKeywords.any(query.contains);
    FocusScope.of(context).unfocus();

    if (isHealth) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HealthScreen()));
      return;
    }

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const PetMarketProductsScreen()));
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 12),
              _buildBannerSlider(),
              const SizedBox(height: 12),
              _buildSearchRow(),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: Listenable.merge([
                  PetStore.instance,
                  OrderStore.instance,
                  FoodTrackingStore.instance,
                ]),
                builder: (context, _) => _buildSmartPlanCard(),
              ),
              const SizedBox(height: 12),
              _buildSpecialServices(),
              const SizedBox(height: 12),
              _buildPetProfileBar(),
              const SizedBox(height: 12),
              _buildPetMarket(),
              const SizedBox(height: 12),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const FilterScreen()));
            },
            icon: const Icon(
              Icons.menu_rounded,
              color: AppColors.primary,
              size: 28,
            ),
          ),
          Expanded(
            child: IgnorePointer(
              child: Transform.translate(
                offset: const Offset(0, 6),
                child: Image.asset(
                  'assets/images/ana_logo.png',
                  height: 46,
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return const Text(
                      'geliyor.tr',
                      textAlign: TextAlign.center,
                      style: AppTextStyles.pageHeader,
                    );
                  },
                ),
              ),
            ),
          ),
          const AppNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildBannerSlider() {
    return const AppBannerSlot(
      placement: BannerPlacement.home,
      fallbackAssets: [
        'assets/images/banner_mutlu_patiler.png',
        'assets/images/banner_geliyor.png',
        'assets/images/banner1.png',
      ],
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
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
                GestureDetector(
                  onTap: _submitSearch,
                  child: const Icon(
                    Icons.search_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submitSearch,
                    onChanged: (_) => setState(() {}),
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Ürün, marka veya kategori ara...',
                      hintStyle: TextStyle(
                        color: AppColors.subText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
                ValueListenableBuilder<TextEditingValue>(
                  valueListenable: _searchController,
                  builder: (context, value, _) {
                    if (value.text.isEmpty) return const SizedBox.shrink();
                    return GestureDetector(
                      onTap: () {
                        _searchController.clear();
                        setState(() {});
                      },
                      child: const Icon(
                        Icons.close_rounded,
                        color: AppColors.subText,
                        size: 18,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const FilterScreen()));
          },
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 22,
            ),
          ),
        ),
      ],
    );
  }

  Color _stockRingColor(FoodStockLevel level) {
    return switch (level) {
      FoodStockLevel.safe => AppColors.primary,
      FoodStockLevel.watch => AppColors.warning,
      FoodStockLevel.low => Color.lerp(
        AppColors.warning,
        AppColors.error,
        0.45,
      )!,
      FoodStockLevel.critical => AppColors.error,
    };
  }

  Color _stockInnerColor(FoodStockLevel level) {
    return switch (level) {
      FoodStockLevel.safe => AppColors.primary.withValues(alpha: 0.14),
      FoodStockLevel.watch => AppColors.warning.withValues(alpha: 0.18),
      FoodStockLevel.low => Color.lerp(
        AppColors.warning,
        AppColors.error,
        0.45,
      )!.withValues(alpha: 0.16),
      FoodStockLevel.critical => AppColors.error.withValues(alpha: 0.16),
    };
  }

  Widget _buildSmartPlanCard() {
    final estimate = FoodRemainingEstimator.compute();
    final remaining = estimate?.remainingDays;
    final ratio = estimate?.remainingRatio ?? 0.0;
    final level = estimate?.stockLevel ?? FoodStockLevel.safe;
    final ringColor = _stockRingColor(level);
    final innerColor = _stockInnerColor(level);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 78,
              height: 78,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 280),
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: remaining == null
                          ? AppColors.selected
                          : innerColor,
                    ),
                  ),
                  SizedBox(
                    width: 78,
                    height: 78,
                    child: CircularProgressIndicator(
                      value: remaining == null ? 0 : ratio,
                      strokeWidth: 6,
                      backgroundColor: remaining == null
                          ? AppColors.selected
                          : ringColor.withValues(alpha: 0.18),
                      color: remaining == null ? AppColors.primary : ringColor,
                      strokeCap: StrokeCap.round,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.calendar_month_rounded,
                        color: remaining == null
                            ? AppColors.primary
                            : ringColor,
                        size: 14,
                      ),
                      const SizedBox(height: 2),
                      SizedBox(
                        width: 52,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            remaining == null ? '—' : '$remaining',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: remaining == null
                                  ? AppColors.primary
                                  : ringColor,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              height: 1,
                            ),
                          ),
                        ),
                      ),
                      Text(
                        'Gün Kaldı',
                        style: TextStyle(
                          color: remaining == null ? AppColors.text : ringColor,
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Flexible(
                        child: Text(
                          'Akıllı Planla',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: AppTextStyles.sectionHeader,
                        ),
                      ),
                      const SizedBox(width: 4),
                      const Icon(
                        Icons.pets_rounded,
                        size: 16,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Minik dostunun düzenli bakımını seninle planlar',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppPressableButton.soft(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const SmartPlanScreen(),
                        ),
                      );
                    },
                    width: 104,
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: const Text(
                      'Plan Oluştur',
                      style: TextStyle(fontSize: 11.5),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 88,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                child: Image.asset(
                  'assets/images/akilli_plan_mama.png',
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.rice_bowl_rounded,
                      color: AppColors.primary,
                      size: 48,
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpecialServices() {
    return Column(
      children: [
        const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Size Özel Hizmetler', style: AppTextStyles.sectionHeader),
            SizedBox(width: 4),
            Icon(Icons.pets_rounded, size: 15, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 118,
          child: Row(
            children: [
              _serviceCard(
                title: 'Kolay\nSipariş',
                icon: Icons.local_shipping_rounded,
                color: const Color(0xFF22C55E),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EasyOrderScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              _serviceCard(
                title: 'Pet\nE-nabız',
                icon: Icons.health_and_safety_rounded,
                color: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HealthScreen()),
                  );
                },
              ),
              const SizedBox(width: 8),
              _serviceCard(
                title: 'Bilgi\nBankası',
                icon: Icons.menu_book_rounded,
                color: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const KnowledgeBaseScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              _serviceCard(
                title: 'Hangi\nMama',
                icon: Icons.restaurant_rounded,
                imagePath: 'assets/images/son_ikonlar/hangi_mama.png',
                color: const Color(0xFF8B5CF6),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HangiMamaScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _serviceCard({
    required String title,
    required IconData icon,
    required Color color,
    String? imagePath,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (imagePath != null)
                Image.asset(
                  imagePath,
                  width: 34,
                  height: 34,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) =>
                      Icon(icon, color: color, size: 34),
                )
              else
                Icon(icon, color: color, size: 34),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.surface,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPetProfileBar() {
    return ListenableBuilder(
      listenable: PetStore.instance,
      builder: (context, _) {
        final pets = PetStore.instance.pets;
        final pet = pets.isEmpty ? null : pets.first;

        return Container(
          height: 48,
          padding: const EdgeInsets.fromLTRB(8, 0, 8, 0),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: pet == null
                    ? const Icon(
                        Icons.pets_rounded,
                        color: AppColors.primary,
                        size: 16,
                      )
                    : Image.asset(
                        pet.imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.pets_rounded,
                            color: AppColors.primary,
                            size: 16,
                          );
                        },
                      ),
              ),
              const SizedBox(width: 6),
              Text(
                pet?.name ?? 'Dostun yok',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 6),
              Container(width: 1, height: 20, color: AppColors.border),
              const SizedBox(width: 6),
              Expanded(
                child: pet == null
                    ? const SizedBox.shrink()
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _PetMeta(
                            icon: Icons.calendar_month_rounded,
                            label: pet.shortAge,
                          ),
                          _PetMeta(
                            icon: Icons.pets_rounded,
                            label: pet.species,
                          ),
                          _PetMeta(
                            icon: Icons.monitor_weight_outlined,
                            label: pet.weight ?? '-',
                          ),
                        ],
                      ),
              ),
              const SizedBox(width: 6),
              AppPressableButton.soft(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const MeetPetScreen()),
                  );
                },
                width: 92,
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: const Text('Dost Ekle', style: TextStyle(fontSize: 11)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPetMarket() {
    return GestureDetector(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const PetMarketScreen()));
      },
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: AppColors.selected,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.shopping_cart_outlined,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pet Market',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.sectionHeader,
                      ),
                      SizedBox(width: 4),
                      Icon(
                        Icons.pets_rounded,
                        size: 17,
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  Text(
                    'Binlerce ürün seni bekliyor',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 28,
              height: 28,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.surface,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PetMeta extends StatelessWidget {
  const _PetMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.primary, size: 12),
        const SizedBox(width: 2),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.subText,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
