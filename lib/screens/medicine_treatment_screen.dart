import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/health_product_groups.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/market_product_helpers.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';

enum _MedCategory { vitamins, supplements, malts }

class MedicineTreatmentScreen extends StatefulWidget {
  const MedicineTreatmentScreen({super.key});

  @override
  State<MedicineTreatmentScreen> createState() =>
      _MedicineTreatmentScreenState();
}

class _MedicineTreatmentScreenState extends State<MedicineTreatmentScreen> {
  _MedCategory _selected = _MedCategory.vitamins;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _categories = <_CategoryData>[
    _CategoryData(
      id: _MedCategory.vitamins,
      title: 'Vitaminler',
      subtitle: 'Bağışıklık ve enerji desteği',
      accent: AppColors.primary,
    ),
    _CategoryData(
      id: _MedCategory.supplements,
      title: 'Takviye Gıdalar',
      subtitle: 'Ek besin ve destek ürünleri',
      accent: AppColors.success,
    ),
    _CategoryData(
      id: _MedCategory.malts,
      title: 'Maltlar',
      subtitle: 'Tüy yumağı ve sindirim',
      accent: AppColors.primary,
    ),
  ];

  String get _sectionTitle {
    switch (_selected) {
      case _MedCategory.vitamins:
        return 'Vitaminler';
      case _MedCategory.supplements:
        return 'Takviye Gıdalar';
      case _MedCategory.malts:
        return 'Maltlar';
    }
  }

  HealthProductGroup get _selectedGroup {
    switch (_selected) {
      case _MedCategory.vitamins:
        return HealthProductGroup.vitamin;
      case _MedCategory.supplements:
        return HealthProductGroup.supplement;
      case _MedCategory.malts:
        return HealthProductGroup.malt;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MarketProductData> _productsForSelection(
    List<MarketProductData> catalog,
  ) {
    final group = _selectedGroup;
    final query = _searchQuery;

    return [
      for (final item in catalog)
        if (_matchesCategory(item, group) && _matchesSearch(item, query))
          item,
    ];
  }

  bool _matchesCategory(MarketProductData item, HealthProductGroup group) {
    if (item.petTag != 'Kedi') return false;
    return group.matches(
      advantageIds: item.productAdvantageIds,
      categoryTitles: [item.dietTag, ...item.categoryTitles],
    );
  }

  bool _matchesSearch(MarketProductData item, String query) {
    if (query.isEmpty) return true;
    final hay = ProductAdvantageRepository.foldSearch(
      '${item.title} ${item.subtitle} ${item.brand} ${item.dietTag}',
    );
    return hay.contains(query);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketProductData>>(
      stream: ProductRepository.instance.watchMarketProducts(),
      initialData: ProductRepository.instance.cachedMarketProducts(),
      builder: (context, snapshot) {
        final products = _productsForSelection(snapshot.data ?? const []);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: AppPageFrame.standard(
            backgroundColor: AppColors.background,
            header: _buildHeader(context),
            content: CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppPageFrame.contentHorizontalPadding,
                      0,
                      AppPageFrame.contentHorizontalPadding,
                      8,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildBanner(),
                        const SizedBox(height: 10),
                        _buildSearchBar(),
                        const SizedBox(height: 10),
                        _buildCategoryCards(),
                        const SizedBox(height: 12),
                        _buildSectionHeader(),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppPageFrame.contentHorizontalPadding,
                    0,
                    AppPageFrame.contentHorizontalPadding,
                    10,
                  ),
                  sliver: products.isEmpty
                      ? SliverToBoxAdapter(
                          child: marketProductsPlaceholder(isEmpty: true),
                        )
                      : SliverGrid(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: MarketCompactProductCard.cardGap,
                            crossAxisSpacing: MarketCompactProductCard.cardGap,
                            mainAxisExtent: MarketCompactProductCard.cardHeight,
                          ),
                          delegate: SliverChildBuilderDelegate((context, index) {
                            final product = products[index];
                            final price = product.prices.isNotEmpty
                                ? product.prices.first
                                : 0.0;
                            final oldPrice = product.oldPrices.isNotEmpty
                                ? product.oldPrices.first
                                : price;
                            final weight = product.weights.isNotEmpty
                                ? product.weights.first
                                : '';
                            return MarketCompactProductCard(
                              product: product,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) =>
                                        ProductDetailScreen(product: product),
                                  ),
                                );
                              },
                              onAddToCart: () => _addToCart(
                                product,
                                weight,
                                price,
                                oldPrice,
                              ),
                            );
                          }, childCount: products.length),
                        ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppPageFrame.contentHorizontalPadding,
                      0,
                      AppPageFrame.contentHorizontalPadding,
                      16,
                    ),
                    child: _buildTipsBanner(),
                  ),
                ),
              ],
            ),
            navbar: const AppBottomNavbar(),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          const Expanded(
            child: Text(
              'İlaç ve Tedavi',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageHeader,
            ),
          ),
          ListenableBuilder(
            listenable: CartStore.instance,
            builder: (context, _) {
              final qty = CartStore.instance.totalQuantity;
              return Stack(
                clipBehavior: Clip.none,
                children: [
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          settings: const RouteSettings(name: 'cart'),
                          builder: (_) => const CartScreen(),
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.shopping_cart_outlined,
                      color: AppColors.primary,
                      size: 26,
                    ),
                  ),
                  if (qty > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 16,
                        height: 16,
                        alignment: Alignment.center,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$qty',
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    const fallback = 'assets/images/ilac_tedavi_banner.jpg';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.banners)
          .snapshots(),
      builder: (context, snapshot) {
        var path = fallback;
        var hidden = false;
        final docs = snapshot.data?.docs;
        if (docs != null) {
          final deleted = <String>{};
          for (final doc in docs) {
            if (doc.id != BannerRepository.seededDocId) continue;
            final raw = doc.data()['deletedIds'];
            if (raw is Iterable) {
              deleted.addAll(raw.map((item) => item.toString()));
            }
          }
          final live = [
            for (final doc in docs)
              if (!doc.id.startsWith('_')) AppBanner.fromDoc(doc),
          ].where((banner) {
            return banner.active &&
                banner.placement == BannerPlacement.medicine.id &&
                banner.imageUrl.trim().isNotEmpty;
          }).toList();
          final picked = AppBanner.latestLive(live);
          if (picked != null) {
            path = picked.imageUrl;
          } else if (deleted.contains('medicine')) {
            hidden = true;
          }
        }
        if (hidden) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            const framePad = 3.0;
            final width = constraints.maxWidth - framePad * 2;
            final height = width * 140 / 361;
            return Container(
              padding: const EdgeInsets.all(framePad),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: buildProductImage(
                    path,
                    fit: BoxFit.fill,
                    width: width,
                    height: height,
                    cacheWidth: 1024,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.subText, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              onChanged: (value) {
                setState(() {
                  _searchQuery = ProductAdvantageRepository.foldSearch(value);
                });
              },
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Ürün, marka veya kategori ara...',
                hintStyle: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (_searchQuery.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _searchQuery = '');
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.subText,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  HealthProductGroup _groupFor(_MedCategory id) {
    switch (id) {
      case _MedCategory.vitamins:
        return HealthProductGroup.vitamin;
      case _MedCategory.supplements:
        return HealthProductGroup.supplement;
      case _MedCategory.malts:
        return HealthProductGroup.malt;
    }
  }

  Widget _buildCategoryCards() {
    return StreamBuilder<List<AppProductAdvantage>>(
      stream: ProductAdvantageRepository.instance.watchAll(activeOnly: true),
      builder: (context, snapshot) {
        final catalog = snapshot.data ?? const <AppProductAdvantage>[];
        return SizedBox(
          height: 108,
          child: Row(
            children: [
              for (int i = 0; i < _categories.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                Expanded(child: _buildCategoryCard(_categories[i], catalog)),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategoryCard(
    _CategoryData cat,
    List<AppProductAdvantage> catalog,
  ) {
    final selected = _selected == cat.id;
    return GestureDetector(
      onTap: () => setState(() => _selected = cat.id),
      child: Container(
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? cat.accent : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: buildProductImage(
                      ProductAdvantageRepository.iconForHealthGroup(
                        _groupFor(cat.id),
                        catalog: catalog,
                      ),
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorWidget: Icon(
                        Icons.medical_services_outlined,
                        color: cat.accent,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cat.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? cat.accent : AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cat.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected
                        ? cat.accent.withValues(alpha: 0.8)
                        : AppColors.subText,
                    fontSize: 8.5,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: cat.accent,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 11,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_sectionTitle, style: AppTextStyles.sectionHeader),
        const SizedBox(height: 2),
        Container(
          width: 28,
          height: 2.5,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ],
    );
  }

  Widget _buildTipsBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: AppColors.surface,
              size: 18,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Sağlık ipuçları ve bakım önerileri',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Veteriner önerileriyle doğru ürünleri seçin.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Keşfet',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 14,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addToCart(
    MarketProductData product,
    String weight,
    double price,
    double oldPrice,
  ) {
    CartStore.instance.addItem(
      id: '${product.id}-$weight',
      imagePath: product.imagePath,
      title: product.title,
      unitPrice: price,
      oldPrice: oldPrice,
      weight: weight,
      brand: product.brand,
      skt: product.skt,
      barcode: product.barcode,
    );
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

class _CategoryData {
  const _CategoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.accent,
  });

  final _MedCategory id;
  final String title;
  final String subtitle;
  final Color accent;
}
