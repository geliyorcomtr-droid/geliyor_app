import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/best_sellers_screen.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/bird_category_screen.dart';
import 'package:geliyor_app/screens/brands_screen.dart';
import 'package:geliyor_app/screens/campaigns_screen.dart';
import 'package:geliyor_app/screens/cat_category_screen.dart';
import 'package:geliyor_app/screens/dog_category_screen.dart';
import 'package:geliyor_app/screens/health_screen.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/screens/rodent_category_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class FilterScreen extends StatefulWidget {
  const FilterScreen({super.key});

  @override
  State<FilterScreen> createState() => _FilterScreenState();
}

class _FilterScreenState extends State<FilterScreen> {
  final _searchController = TextEditingController();

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

  static const List<_FilterCategory> _categories = [
    _FilterCategory(
      imagePath: 'assets/images/urunler_kedi.png',
      title: 'Kedi',
      emoji: '🐾',
      subtitle: 'Mama, yavru, kum, ödül ve daha fazlası',
      route: _FilterRoute.cat,
    ),
    _FilterCategory(
      imagePath: 'assets/images/urunler_kopek.png',
      title: 'Köpek',
      emoji: '🐾',
      subtitle: 'Mama, yavru, mini ırk ve ödül',
      route: _FilterRoute.dog,
    ),
    _FilterCategory(
      imagePath: 'assets/images/urunler_kus.png',
      title: 'Kuş',
      emoji: '🐦',
      subtitle: 'Kuş yemleri ve bakım ürünleri',
      route: _FilterRoute.bird,
    ),
    _FilterCategory(
      imagePath: 'assets/images/urunler_kemirgen.png',
      title: 'Kemirgen',
      emoji: '🐾',
      subtitle: 'Kemirgen mamaları ve yaşam alanları',
      route: _FilterRoute.rodent,
    ),
    _FilterCategory(
      imagePath: 'assets/images/urunler_akilli.png',
      title: 'Akıllı Pet Ürünleri',
      emoji: '✨',
      subtitle: 'Akıllı mama kabı, takip ve daha fazlası',
      route: _FilterRoute.smart,
    ),
    _FilterCategory(
      imagePath: 'assets/images/cok_satan_urunler.png',
      title: 'Çok Satanlar',
      emoji: '⭐',
      subtitle: 'En çok tercih edilen ürünler',
      route: _FilterRoute.bestSellers,
    ),
    _FilterCategory(
      imagePath: 'assets/images/kampanya_urunleri.png',
      title: 'Kampanyalar',
      emoji: '🎁',
      subtitle: 'İndirimli ve avantajlı ürünler',
      route: _FilterRoute.campaigns,
    ),
    _FilterCategory(
      imagePath: 'assets/images/markaya_gore_urunleri.png',
      title: 'Markaya Göre Alışveriş',
      emoji: '🏷️',
      subtitle: 'Sevdiğin markaların ürünleri',
      route: _FilterRoute.brands,
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_FilterCategory> get _visibleCategories {
    final query = _searchController.text.trim().toLowerCase();
    if (query.isEmpty) return _categories;
    return _categories.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);
    }).toList();
  }

  void _submitSearch([String? value]) {
    final query = (value ?? _searchController.text).trim().toLowerCase();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();

    if (_healthKeywords.any(query.contains)) {
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const HealthScreen()),
      );
      return;
    }

    final matches = _categories.where((item) {
      return item.title.toLowerCase().contains(query) ||
          item.subtitle.toLowerCase().contains(query);
    }).toList();

    if (matches.length == 1) {
      _onCategoryTap(context, matches.first.route);
      return;
    }

    final exact = _categories.where(
      (item) => item.title.toLowerCase() == query,
    );
    if (exact.isNotEmpty) {
      _onCategoryTap(context, exact.first.route);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PetMarketProductsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final visible = _visibleCategories;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(context),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildSearchRow(),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: visible.isEmpty
                      ? const Center(
                          child: Text(
                            'Sonuç bulunamadı',
                            style: TextStyle(
                              color: AppColors.subText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: visible.length,
                          separatorBuilder: (context, index) => const Divider(
                            height: 1,
                            thickness: 1,
                            indent: 76,
                            endIndent: 16,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final item = visible[index];
                            return _buildCategoryRow(context, item);
                          },
                        ),
                ),
              ),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          AppBackButton(),
          Expanded(
            child: IgnorePointer(
              child: Text(
                'Filtrele',
                textAlign: TextAlign.center,
                style: AppTextStyles.pageHeader,
              ),
            ),
          ),
          AppNotificationButton(),
        ],
      ),
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
          onTap: _submitSearch,
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.search_rounded, color: AppColors.primary, size: 18),
                SizedBox(width: 4),
                Text(
                  'Ara',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(BuildContext context, _FilterCategory item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _onCategoryTap(context, item.route),
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              _buildIconCircle(item.imagePath),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          item.title,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.emoji,
                          style: const TextStyle(fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconCircle(String imagePath) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: Image.asset(
          imagePath,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.pets_rounded,
              color: AppColors.primary,
              size: 24,
            );
          },
        ),
      ),
    );
  }

  void _onCategoryTap(BuildContext context, _FilterRoute route) {
    switch (route) {
      case _FilterRoute.cat:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CatCategoryScreen()),
        );
      case _FilterRoute.dog:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const DogCategoryScreen()),
        );
      case _FilterRoute.bird:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BirdCategoryScreen()),
        );
      case _FilterRoute.rodent:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const RodentCategoryScreen()),
        );
      case _FilterRoute.smart:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FilterSubpageLayout(
              title: 'Akıllı Pet Ürünleri',
              items: [
                FilterSubpageItem(
                  title: 'Akıllı Pet',
                  subtitle: 'Akıllı mama kabı, takip ve kamera',
                  imagePath: 'assets/images/petmarket_akilli_ikon.png',
                  emoji: '✨',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const PetMarketProductsScreen(
                          initialMainCategory: 'smart',
                          initialSubCategory: 'Akıllı Pet',
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      case _FilterRoute.bestSellers:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BestSellersScreen()),
        );
      case _FilterRoute.campaigns:
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            settings: const RouteSettings(name: 'campaigns'),
            builder: (context) => const CampaignsScreen(),
          ),
        );
      case _FilterRoute.brands:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const BrandsScreen()),
        );
    }
  }
}

enum _FilterRoute {
  cat,
  dog,
  bird,
  rodent,
  smart,
  bestSellers,
  campaigns,
  brands,
}

class _FilterCategory {
  const _FilterCategory({
    required this.imagePath,
    required this.title,
    required this.emoji,
    required this.subtitle,
    required this.route,
  });

  final String imagePath;
  final String title;
  final String emoji;
  final String subtitle;
  final _FilterRoute route;
}
