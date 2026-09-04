import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/advantage_search.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';

class PetMarketScreen extends StatefulWidget {
  const PetMarketScreen({
    super.key,
    this.initialMainCategory = 'cat',
    this.initialSubCategory,
  });

  final String initialMainCategory;
  final String? initialSubCategory;

  @override
  State<PetMarketScreen> createState() => _PetMarketScreenState();
}

class _PetMarketScreenState extends State<PetMarketScreen> {
  late String selectedMainCategory;
  late String selectedSubCategory;
  final _searchController = TextEditingController();

  static const _mainMenus = [
    _MainMenu(
      id: 'cat',
      title: 'Kedi',
      imagePath: 'assets/images/petmarket_kedi.png',
      badgeColor: Color(0xFFF97316),
    ),
    _MainMenu(
      id: 'dog',
      title: 'Köpek',
      imagePath: 'assets/images/petmarket_kopek.png',
      badgeColor: AppColors.success,
    ),
    _MainMenu(
      id: 'smart',
      title: 'Akıllı Pet\nÜrünleri',
      imagePath: 'assets/images/petmarket_akilli.png',
      badgeColor: Color(0xFF8B5CF6),
    ),
  ];

  static const _catCategoryIcons = [
    _CategoryIcon('Mama', 'assets/images/petmarket_mama.png'),
    _CategoryIcon('Yavru', 'assets/images/petmarket_yavru.png'),
    _CategoryIcon('Kum', 'assets/images/petmarket_kum.png'),
    _CategoryIcon('Ödül', 'assets/images/petmarket_odul.png'),
    _CategoryIcon('Bakım', 'assets/images/petmarket_bakim.png'),
    _CategoryIcon('Oyuncak', 'assets/images/petmarket_oyun.png'),
    _CategoryIcon('Sağlık', 'assets/images/petmarket_saglik.png'),
    _CategoryIcon('Taşıma', 'assets/images/petmarket_tasima.png'),
  ];

  static const _dogCategoryIcons = [
    _CategoryIcon('Mama', 'assets/images/petmarket_mama.png'),
    _CategoryIcon('Yavru', 'assets/images/petmarket_kopek_yavru.png'),
    _CategoryIcon('Mini Irk', 'assets/images/petmarket_mini_irk.png'),
    _CategoryIcon('Ödül', 'assets/images/petmarket_odul.png'),
  ];

  static const _smartCategoryIcons = [
    _CategoryIcon('Akıllı Pet', 'assets/images/petmarket_akilli_ikon.png'),
  ];

  List<_CategoryIcon> get _categoryIcons {
    if (selectedMainCategory == 'dog') return _dogCategoryIcons;
    if (selectedMainCategory == 'smart') return _smartCategoryIcons;
    return _catCategoryIcons;
  }

  String _defaultSubCategoryFor(String mainCategory) {
    if (mainCategory == 'smart') return 'Akıllı Pet';
    return 'Mama';
  }

  @override
  void initState() {
    super.initState();
    selectedMainCategory = widget.initialMainCategory;
    selectedSubCategory =
        widget.initialSubCategory ??
        _defaultSubCategoryFor(selectedMainCategory);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String? _subCategoryFromQuery(String query) {
    final q = query.toLowerCase();
    if (q.contains('ödül') || q.contains('odul') || q.contains('treat')) {
      return 'Ödül';
    }
    if (q.contains('kum') || q.contains('litter')) return 'Kum';
    if (q.contains('yavru') || q.contains('puppy') || q.contains('kitten')) {
      return 'Yavru';
    }
    if (q.contains('oyuncak') || q.contains('oyun')) return 'Oyuncak';
    if (q.contains('bakım') || q.contains('bakim')) return 'Bakım';
    if (q.contains('sağlık') || q.contains('saglik') || q.contains('vitamin')) {
      return 'Sağlık';
    }
    if (q.contains('taşıma') || q.contains('tasima') || q.contains('kafes')) {
      return 'Taşıma';
    }
    if (q.contains('mini')) return 'Mini Irk';
    if (q.contains('mama') || q.contains('yem')) return 'Mama';
    return null;
  }

  void _submitSearch([String? value]) {
    final query = (value ?? _searchController.text).trim();
    if (query.isEmpty) return;

    FocusScope.of(context).unfocus();
    if (AdvantageSearch.openProductsIfMatched(
      context,
      query,
      mainCategory: selectedMainCategory,
    )) {
      return;
    }
    final matchedSub = _subCategoryFromQuery(query);

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: selectedMainCategory,
          initialSubCategory: matchedSub ?? selectedSubCategory,
          initialSearchQuery: query,
        ),
      ),
    );
  }

  List<MarketProductData> _mergedProducts(List<MarketProductData> remote) {
    return remote.take(6).toList();
  }

  String get _sectionTitle {
    if (selectedMainCategory == 'dog') return 'Köpek Ürünleri';
    if (selectedMainCategory == 'smart') return 'Akıllı Pet Ürünleri';
    return 'Kedi Ürünleri';
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketProductData>>(
      stream: ProductRepository.instance.watchMarketProducts(
        mainCategory: selectedMainCategory,
        subCategory: selectedSubCategory,
      ),
      builder: (context, snapshot) {
        final products = _mergedProducts(snapshot.data ?? const []);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: AppPageFrame.standard(
            backgroundColor: AppColors.background,
            header: _buildHeader(),
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppPageFrame.contentHorizontalPadding,
                0,
                AppPageFrame.contentHorizontalPadding,
                8,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSearchBar(),
                  const SizedBox(height: 10),
                  _buildMainMenus(),
                  const SizedBox(height: 12),
                  const Text(
                    'Kategoriler',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildCategories(),
                  const SizedBox(height: 12),
                  _buildProductSectionHeader(),
                  const SizedBox(height: 8),
                  if (snapshot.hasError)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        'Ürünler yüklenemedi: ${snapshot.error}',
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  _buildProductGrid(products),
                ],
              ),
            ),
            navbar: const AppBottomNavbar(),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.pets_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    const Text('Pet Market', style: AppTextStyles.pageHeader),
                  ],
                ),
                const SizedBox(height: 1),
                const Text(
                  'Dostun için en iyi ürünler, tek yerde.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 9,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 36,
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
                    size: 18,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    textInputAction: TextInputAction.search,
                    onSubmitted: _submitSearch,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Mama, ödül, oyuncak ara...',
                      hintStyle: TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
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
                        size: 16,
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
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PetMarketProductsScreen(
                  initialMainCategory: selectedMainCategory,
                  initialSubCategory: selectedSubCategory,
                  openFeatureSheet: true,
                ),
              ),
            );
          },
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.tune_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMainMenus() {
    return SizedBox(
      height: 108,
      child: Row(
        children: [
          for (int i = 0; i < _mainMenus.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _buildMainMenuCard(_mainMenus[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildMainMenuCard(_MainMenu menu) {
    final selected = selectedMainCategory == menu.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedMainCategory = menu.id;
          selectedSubCategory = _defaultSubCategoryFor(menu.id);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(6, 6, 6, 4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 0.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        menu.imagePath,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(
                              Icons.pets_rounded,
                              color: AppColors.primary,
                              size: 28,
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 2,
                    left: 2,
                    child: Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        color: menu.badgeColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.pets_rounded,
                        size: 11,
                        color: menu.badgeColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              menu.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategories() {
    const gap = 6.0;
    const visibleCount = 6;
    final icons = _categoryIcons;
    final contentWidth =
        AppPageFrame.width - (AppPageFrame.contentHorizontalPadding * 2);
    final itemWidth = (contentWidth - gap * (visibleCount - 1)) / visibleCount;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: icons.length > visibleCount
          ? const BouncingScrollPhysics()
          : const NeverScrollableScrollPhysics(),
      child: Row(
        children: [
          for (int i = 0; i < icons.length; i++) ...[
            if (i > 0) const SizedBox(width: gap),
            SizedBox(width: itemWidth, child: _buildCategoryItem(icons[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryItem(_CategoryIcon category) {
    final selected = selectedSubCategory == category.title;

    return GestureDetector(
      onTap: () => setState(() => selectedSubCategory = category.title),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 160),
            height: 48,
            width: double.infinity,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? AppColors.primaryLight : AppColors.border,
                width: selected ? 0.8 : 1,
              ),
            ),
            child: Image.asset(
              category.imagePath,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.category_outlined,
                color: AppColors.primary,
                size: 20,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            category.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: selected ? AppColors.primary : AppColors.text,
              fontSize: 9,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductSectionHeader() {
    return Row(
      children: [
        Icon(
          selectedMainCategory == 'dog'
              ? Icons.pets_rounded
              : selectedMainCategory == 'smart'
              ? Icons.auto_awesome_rounded
              : Icons.pets_rounded,
          color: AppColors.primary,
          size: 15,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            _sectionTitle,
            style: AppTextStyles.sectionHeader,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => PetMarketProductsScreen(
                  initialMainCategory: selectedMainCategory,
                ),
              ),
            );
          },
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Tümünü Gör',
                style: AppTextStyles.seeAllAction,
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductGrid(List<MarketProductData> products) {
    if (products.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'Bu kategoride ürün bulunamadı.',
            style: TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    const columns = 3;
    const gap = MarketCompactProductCard.cardGap;
    final rows = <Widget>[];

    for (int start = 0; start < products.length; start += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      rows.add(
        SizedBox(
          height: MarketCompactProductCard.cardHeight,
          child: Row(
            children: [
              for (int i = 0; i < columns; i++) ...[
                if (i > 0) const SizedBox(width: gap),
                Expanded(
                  child: start + i < products.length
                      ? MarketCompactProductCard(
                          product: products[start + i],
                          onTap: () => _openDetail(products[start + i]),
                          onAddToCart: () {
                            final product = products[start + i];
                            final price = product.prices.isNotEmpty
                                ? product.prices.first
                                : 0.0;
                            final oldPrice = product.oldPrices.isNotEmpty
                                ? product.oldPrices.first
                                : price;
                            final weight = product.weights.isNotEmpty
                                ? product.weights.first
                                : '';
                            _addToCart(product, weight, price, oldPrice, 1);
                          },
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Column(children: rows);
  }

  void _openDetail(MarketProductData product) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ProductDetailScreen(product: product)),
    );
  }

  void _addToCart(
    MarketProductData product,
    String weight,
    double price,
    double oldPrice,
    int quantity,
  ) {
    for (int q = 0; q < quantity; q++) {
      CartStore.instance.addItem(
        id: '${product.id}-$weight',
        imagePath: product.imagePath,
        title: product.title,
        unitPrice: price,
        oldPrice: oldPrice,
        weight: weight,
        brand: product.brand,
        skt: product.skt,
      );
    }
    _showAddedToCartDialog(product.title);
  }

  void _showAddedToCartDialog(String productTitle) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: AppPageFrame.width - 48,
              constraints: const BoxConstraints(maxHeight: 280),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ürün sepete eklenmiştir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppPressableButton.primary(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    width: double.infinity,
                    height: 40,
                    child: const Text(
                      'Sepete Git',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppPressableButton.outline(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    width: double.infinity,
                    height: 40,
                    child: const Text(
                      'Alışverişe Devam Et',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MainMenu {
  const _MainMenu({
    required this.id,
    required this.title,
    required this.imagePath,
    required this.badgeColor,
  });

  final String id;
  final String title;
  final String imagePath;
  final Color badgeColor;
}

class _CategoryIcon {
  const _CategoryIcon(this.title, this.imagePath);

  final String title;
  final String imagePath;
}
