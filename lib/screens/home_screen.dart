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
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/screens/smart_plan_screen.dart';
import 'package:geliyor_app/services/food_remaining_estimator.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/advantage_search.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/banner_image_preview.dart';

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

  static const double _serviceCardHeight = 118;
  static const double _serviceCardGap = 8;
  static const double _serviceCardRadius = 18;
  static const double _homeBrandBox = 84;
  static const _homeAdSlots =
      <({BannerPlacement placement, String brand, String fallbackAsset})>[
        (
          placement: BannerPlacement.homeAd1,
          brand: "Hill's",
          fallbackAsset: 'assets/images/brands/hills.png',
        ),
        (
          placement: BannerPlacement.homeAd2,
          brand: 'Royal Canin',
          fallbackAsset: 'assets/images/brands/royal_canin.png',
        ),
        (
          placement: BannerPlacement.homeAd3,
          brand: 'N&D',
          fallbackAsset: 'assets/images/brands/nd.png',
        ),
        (
          placement: BannerPlacement.homeAd4,
          brand: 'Pro Plan',
          fallbackAsset: 'assets/images/brands/proplan.png',
        ),
      ];

  final _searchController = TextEditingController();
  static const double _actionBarHeight = 48;

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
                  BrandRepository.instance,
                ]),
                builder: (context, _) => _buildSmartPlanCard(),
              ),
              const SizedBox(height: 12),
              _buildSpecialServices(),
              const SizedBox(height: 12),
              _buildPetMarket(),
              const SizedBox(height: 12),
              _buildDostEkle(),
              const SizedBox(height: 12),
              _buildHomeAdRow(),
              const SizedBox(height: 12),
              _buildAdoption(),
              const SizedBox(height: 12),
              _buildHomeHalfBanner(),
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
    final ratio = estimate?.remainingRatio ?? 0.0;
    final level = estimate?.stockLevel ?? FoodStockLevel.safe;
    final ringColor =
        remaining == null ? AppColors.primary : _stockRingColor(level);

    return GestureDetector(
      onTap: _openSmartPlan,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: double.infinity,
        height: 149,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                'assets/images/home_akilli_plan.jpg',
                fit: BoxFit.cover,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
              Positioned(
                left: 8,
                top: 18,
                width: 84,
                height: 84,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.background,
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 76,
                        height: 76,
                        child: CircularProgressIndicator(
                          value: remaining == null ? 0.72 : ratio,
                          strokeWidth: 6,
                          backgroundColor: ringColor.withValues(alpha: 0.16),
                          color: ringColor,
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.calendar_month_rounded,
                            color: ringColor,
                            size: 13,
                          ),
                          const SizedBox(height: 1),
                          SizedBox(
                            width: 48,
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                remaining == null ? '—' : '$remaining',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: ringColor,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                              ),
                            ),
                          ),
                          Text(
                            'Gün Kaldı',
                            style: TextStyle(
                              color: ringColor,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
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
          height: _serviceCardHeight,
          child: Row(
            children: [
              _serviceCard(
                title: 'Kolay\nSipariş',
                icon: Icons.delivery_dining_rounded,
                color: AppColors.success,
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
                color: AppColors.error,
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
                color: AppColors.warning,
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
                icon: Icons.restaurant_rounded,
                imagePath: 'assets/images/son_ikonlar/hangi_mama.png',
                color: AppColors.violet,
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
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(_serviceCardRadius),
            border: Border.all(color: color.withValues(alpha: 0.25)),
          ),
          child: Container(
            padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(16),
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
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
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
      ),
    );
  }


  Widget _buildDostEkle() {
    return AppBannerStrip(
      placement: BannerPlacement.homeDostEkle,
      fallbackAsset: 'assets/images/home_dost_ekle.jpg',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const MeetPetScreen()),
        );
      },
    );
  }

  Widget _buildPetMarket() {
    return AppBannerStrip(
      placement: BannerPlacement.homePetMarket,
      fallbackAsset: 'assets/images/home_pet_market.png',
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const PetMarketScreen()),
        );
      },
    );
  }

  Widget _buildHomeAdRow() {
    return StreamBuilder<List<AppBanner>>(
      stream: BannerRepository.instance.watchActive(),
      builder: (context, snapshot) {
        final banners = snapshot.data ?? const <AppBanner>[];
        return SizedBox(
          height: _homeBrandBox,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (final slot in _homeAdSlots)
                _homeAdCard(
                  slot: slot,
                  banner: _adBannerFor(slot.placement.id, banners),
                ),
            ],
          ),
        );
      },
    );
  }

  AppBanner? _adBannerFor(String placement, List<AppBanner> banners) {
    for (final item in banners) {
      if (item.placement == placement && item.displayImage.isNotEmpty) {
        return item;
      }
    }
    return null;
  }

  Future<void> _openHomeAd({
    required AppBanner? banner,
    required String brand,
  }) async {
    if (banner != null &&
        banner.linkType == BannerLinkType.product &&
        banner.linkId.trim().isNotEmpty) {
      final product = await ProductRepository.instance.getMarketProduct(
        banner.linkId,
      );
      if (!mounted) return;
      if (product != null) {
        await Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ProductDetailScreen(product: product),
          ),
        );
        return;
      }
    }
    if (banner != null &&
        banner.linkType == BannerLinkType.article &&
        banner.linkId.trim().isNotEmpty) {
      await BannerImagePreview.show(context, banner);
      return;
    }
    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(initialBrand: brand),
      ),
    );
  }

  Widget _homeAdCard({
    required ({BannerPlacement placement, String brand, String fallbackAsset})
        slot,
    required AppBanner? banner,
  }) {
    final path = slot.fallbackAsset;
    return GestureDetector(
      onTap: () => _openHomeAd(banner: banner, brand: slot.brand),
      child: Container(
        width: _homeBrandBox,
        height: _homeBrandBox,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(_serviceCardRadius),
          border: Border.all(color: AppColors.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: buildProductImage(
            path,
            fit: BoxFit.contain,
            width: double.infinity,
            height: double.infinity,
            alignment: Alignment.center,
            filterQuality: FilterQuality.medium,
            cacheWidth: 400,
          ),
        ),
      ),
    );
  }

  Widget _buildAdoption() {
    return AppBannerStrip(
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
