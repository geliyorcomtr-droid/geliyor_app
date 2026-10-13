import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/easy_order_screen.dart';
import 'package:geliyor_app/screens/filter_screen.dart';
import 'package:geliyor_app/screens/hangi_mama_screen.dart';
import 'package:geliyor_app/screens/health_screen.dart';
import 'package:geliyor_app/screens/knowledge_base_screen.dart';
import 'package:geliyor_app/screens/meet_pet_screen.dart';
import 'package:geliyor_app/screens/adoption_screen.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/screens/pet_market_screen.dart';
import 'package:geliyor_app/screens/smart_plan_screen.dart';
import 'package:geliyor_app/services/food_remaining_estimator.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_icons.dart';
import 'package:geliyor_app/utils/advantage_search.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/brand_tile_image.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

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

  static const double _serviceCardHeight = 132;
  static const double _serviceCardGap = 8;
  static const double _serviceCardRadius = 18;

  final _searchController = TextEditingController();
  static const double _actionBarHeight = 48;

  @override
  void initState() {
    super.initState();
    unawaited(BannerRepository.instance.restoreHomeDostEkleIfMeetPetLeaked());
    ProductRepository.instance.ensureWarm();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _submitSearch([String? value]) {
    final query = (value ?? _searchController.text).trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    if (AdvantageSearch.openProductsIfMatched(context, query)) return;

    final folded = query.toLowerCase();
    if (_healthKeywords.any(folded.contains)) {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const HealthScreen()));
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(initialSearchQuery: query),
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              const SizedBox(height: 2),
              _buildBannerSlider(),
              const SizedBox(height: 12),
              _buildSearchRow(),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: Listenable.merge([
                  PetStore.instance,
                  OrderStore.instance,
                  FoodTrackingStore.instance,
                  BrandRepository.instance,
                  NotificationSettingsStore.instance,
                ]),
                builder: (context, _) => _ovalFramedStrip(
                  color: AppColors.primary,
                  child: _buildSmartPlanCard(),
                ),
              ),
              const SizedBox(height: 7),
              _buildSpecialServices(),
              const SizedBox(height: 12),
              _ovalFramedStrip(
                color: AppColors.success,
                child: _buildPetMarket(),
              ),
              const SizedBox(height: _serviceCardGap),
              _ovalFramedStrip(
                color: AppColors.error,
                child: _buildDostEkle(),
              ),
              const SizedBox(height: 12),
              _buildHomeAdRow(),
              const SizedBox(height: 12),
              _ovalFramedStrip(
                color: AppColors.warning,
                child: _buildAdoption(),
              ),
              const SizedBox(height: 12),
              _ovalFramedStrip(
                color: AppColors.violet,
                child: _buildHomeHalfBanner(),
              ),
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
                child: Center(
                  child: ClipRect(
                    child: Align(
                      alignment: Alignment.centerRight,
                      widthFactor: 0.74,
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
      autoPlay: true,
      openOnTap: false,
    );
  }

  Widget _buildHomeHalfBanner() {
    return const AppBannerSlot(
      placement: BannerPlacement.homeBottom,
      openOnTap: false,
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: _actionBarHeight,
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
            width: _actionBarHeight,
            height: _actionBarHeight,
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

  void _openSmartPlan() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const SmartPlanScreen()),
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

  Widget _buildSmartPlanCard() {
    final estimate = FoodRemainingEstimator.compute();
    final remaining = estimate?.remainingDays;
    final ratio = remaining == null
        ? 0.0
        : (estimate?.remainingRatio ?? 0.0);
    final level = estimate?.stockLevel ?? FoodStockLevel.safe;
    final textColor =
        remaining == null ? AppColors.primary : _stockRingColor(level);

    return SizedBox(
      width: double.infinity,
      height: BannerPlacement.homeSmartPlan.height,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const imgW = 1024.0;
          const imgH = 409.0;
          const circleCx = 151.0;
          const circleCy = 199.0;
          const circleD = 213.0;
          final boxW = constraints.maxWidth;
          final boxH = constraints.maxHeight;
          final scale = math.max(boxW / imgW, boxH / imgH);
          final cx = circleCx * scale - (imgW * scale - boxW) / 2;
          final cy = circleCy * scale - (imgH * scale - boxH) / 2;
          final overlayD = math.max(0.0, circleD * scale - 1);
          final ringD = overlayD * 0.88;
          return Stack(
            fit: StackFit.expand,
            children: [
              AppBannerStrip(
                key: const ValueKey('home-smart-plan'),
                placement: BannerPlacement.homeSmartPlan,
                fallbackAsset: 'assets/images/home_akilli_plan.jpg',
                onTap: _openSmartPlan,
              ),
              Positioned(
                left: cx - overlayD / 2,
                top: cy - overlayD / 2,
                width: overlayD,
                height: overlayD,
                child: IgnorePointer(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.surface,
                        ),
                        child: SizedBox.expand(),
                      ),
                      SizedBox(
                        width: ringD,
                        height: ringD,
                        child: CircularProgressIndicator(
                          value: ratio,
                          strokeWidth: (overlayD * 0.07).clamp(3.5, 5.0),
                          backgroundColor: AppColors.selected,
                          color: AppColors.primary,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: textColor,
                            size: overlayD * 0.16,
                          ),
                          SizedBox(
                            width: overlayD * 0.55,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                remaining == null ? '—' : '$remaining',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: overlayD * 0.24,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'Gün Kaldı',
                            style: TextStyle(
                              color: textColor,
                              fontSize: overlayD * 0.105,
                              fontWeight: FontWeight.w700,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSpecialServices() {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Size Özel Hizmetler',
              style: AppTextStyles.sectionHeader.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                height: 1.1,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.pets_rounded, size: 22, color: AppColors.primary),
          ],
        ),
        const SizedBox(height: 7),
        SizedBox(
          height: _serviceCardHeight,
          child: Row(
            children: [
              _serviceCard(
                title: 'Kolay\nSipariş',
                icon: Icons.delivery_dining_rounded,
                color: AppColors.primary,
                iconColor: const Color(0xFF22C55E),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EasyOrderScreen()),
                  );
                },
              ),
              const SizedBox(width: _serviceCardGap),
              _serviceCard(
                title: 'Pet\nE-nabız',
                icon: Icons.health_and_safety_rounded,
                color: AppColors.primary,
                iconColor: const Color(0xFFEF4444),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const HealthScreen()),
                  );
                },
              ),
              const SizedBox(width: _serviceCardGap),
              _serviceCard(
                title: 'Bilgi\nBankası',
                icon: Icons.menu_book_rounded,
                color: AppColors.primary,
                iconColor: const Color(0xFFF59E0B),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const KnowledgeBaseScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(width: _serviceCardGap),
              _serviceCard(
                title: 'Hangi\nMama',
                icon: Icons.question_mark_rounded,
                color: AppColors.primary,
                iconColor: const Color(0xFF8B5CF6),
                imagePath: AppIcons.mamaKabi,
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
    Color? iconColor,
    String? imagePath,
    VoidCallback? onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_serviceCardRadius),
            border: Border.all(color: color),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              fit: StackFit.expand,
              children: [
                ColoredBox(color: color.withValues(alpha: 0.10)),
                _serviceCardPaws(color),
                _serviceSparkles(color),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Column(
                    children: [
                      const Spacer(),
                      _serviceLogo(
                        icon: icon,
                        color: color,
                        iconColor: iconColor ?? color,
                        imagePath: imagePath,
                      ),
                      const Spacer(),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const Spacer(),
                      Icon(
                        Icons.arrow_forward_rounded,
                        color: color,
                        size: 22,
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _serviceSparkles(Color color) {
    final line = color.withValues(alpha: 0.55);
    Widget dash(double width, double angle) {
      return Transform.rotate(
        angle: angle,
        child: Container(
          width: width,
          height: 1.7,
          decoration: BoxDecoration(
            color: line,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      );
    }

    return Positioned(
      top: 8,
      left: 7,
      child: SizedBox(
        width: 18,
        height: 16,
        child: Stack(
          children: [
            Positioned(left: 0, top: 8, child: dash(9, -0.75)),
            Positioned(left: 5, top: 1, child: dash(7, -0.15)),
            Positioned(left: 11, top: 6, child: dash(6, 0.55)),
          ],
        ),
      ),
    );
  }

  Widget _serviceLogo({
    required IconData icon,
    required Color color,
    required Color iconColor,
    String? imagePath,
  }) {
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: color),
      ),
      child: imagePath != null
          ? Image.asset(
              imagePath,
              width: 36,
              height: 36,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) =>
                  Icon(icon, color: iconColor, size: 36),
            )
          : Icon(icon, color: iconColor, size: 36),
    );
  }

  Widget _serviceCardPaws(Color color) {
    const paws = <(double x, double y, double size, double rotation)>[
      (0.16, 0.58, 22, -0.35),
      (0.84, 0.62, 20, 0.45),
    ];
    final tint = color.withValues(alpha: 0.16);
    return IgnorePointer(
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              for (final paw in paws)
                Positioned(
                  left: paw.$1 * constraints.maxWidth - paw.$3 / 2,
                  top: paw.$2 * constraints.maxHeight - paw.$3 / 2,
                  width: paw.$3,
                  height: paw.$3,
                  child: Transform.rotate(
                    angle: paw.$4,
                    child: Icon(
                      Icons.pets_rounded,
                      size: paw.$3,
                      color: tint,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _ovalFramedStrip({
    required Color color,
    required Widget child,
    double radius = 999,
    double innerRadius = 999,
  }) {
    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(innerRadius),
        child: child,
      ),
    );
  }

  Widget _buildDostEkle() {
    return AppBannerStrip(
      key: const ValueKey('home-dost-ekle'),
      placement: BannerPlacement.homeDostEkle,
      fallbackAsset: '',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MeetPetScreen()),
        );
      },
    );
  }

  Widget _buildPetMarket() {
    return AppBannerStrip(
      key: const ValueKey('home-pet-market'),
      placement: BannerPlacement.homePetMarket,
      fallbackAsset: '',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PetMarketScreen()),
        );
      },
    );
  }

  Widget _buildHomeAdRow() {
    return ListenableBuilder(
      listenable: BrandRepository.instance,
      builder: (context, _) {
        final brands = BrandRepository.instance.cached
            .where((brand) => brand.active && brand.hasImage)
            .toList();
        if (brands.isEmpty) return const SizedBox.shrink();
        ImageWarmup.precache(
          context,
          brands.map((brand) => brand.displayImage),
          cacheWidth: brandLogoCachePx,
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            const gap = _serviceCardGap;
            final box = (constraints.maxWidth - gap * 3) / 4;
            return SizedBox(
              height: box,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                itemCount: brands.length,
                separatorBuilder: (context, index) => const SizedBox(width: gap),
                itemBuilder: (context, index) {
                  return SizedBox(
                    width: box,
                    height: box,
                    child: _homeBrandCard(brands[index]),
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  void _openBrand(AppBrand brand) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: '',
          initialBrand: brand.name,
        ),
      ),
    );
  }

  Widget _homeBrandCard(AppBrand brand) {
    return GestureDetector(
      onTap: () => _openBrand(brand),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_serviceCardRadius),
          border: Border.all(color: AppColors.border),
        ),
        padding: const EdgeInsets.all(8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Transform.scale(
            scale: 1.08,
            child: BrandTileImage(brand: brand),
          ),
        ),
      ),
    );
  }

  Widget _buildAdoption() {
    return AppBannerStrip(
      key: const ValueKey('home-sahiplendirme'),
      placement: BannerPlacement.homeSahiplendirme,
      fallbackAsset: 'assets/images/home_sahiplendirme.png',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const AdoptionScreen()),
        );
      },
    );
  }
}
