import 'package:flutter/material.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/data/trust_badge_repository.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';

class _MarketCategory {
  const _MarketCategory({
    required this.id,
    required this.label,
    required this.imagePath,
  });

  final String id;
  final String label;
  final String imagePath;
}

/// Pet Market "Tümünü Gör" — 393×852, ilk ekranda 3 ürün kartı.
class PetMarketProductsScreen extends StatefulWidget {
  const PetMarketProductsScreen({
    super.key,
    this.initialMainCategory = 'cat',
    this.initialSubCategory,
    this.initialFeature,
    this.initialAdvantageId,
    this.initialBrand,
    this.initialSearchQuery,
    this.initialSortBy,
    this.initialCatalogFilter,
    this.openFeatureSheet = false,
  });

  final String initialMainCategory;
  final String? initialSubCategory;
  final String? initialFeature;
  final String? initialAdvantageId;
  final String? initialBrand;
  final String? initialSearchQuery;
  final String? initialSortBy;
  /// `bestSellers` | `topRated` | `affordable` | `repurchase`
  final String? initialCatalogFilter;
  final bool openFeatureSheet;

  static const double productCardGap = MarketCompactProductCard.cardGap;

  @override
  State<PetMarketProductsScreen> createState() =>
      _PetMarketProductsScreenState();
}

class _PetMarketProductsScreenState extends State<PetMarketProductsScreen> {
  late String _mainCategory;
  late String _subCategory;
  String _sortBy = 'Önerilen';
  String? _selectedBrand;
  String? _selectedWeight;
  String? _selectedAgeGroup;
  String? _selectedFeature;
  String? _selectedAdvantageId;
  String? _catalogFilter;
  final _searchController = TextEditingController();
  String _searchQuery = '';

  static const _sortOptions = [
    'Önerilen',
    'Fiyat: Düşükten Yükseğe',
    'Fiyat: Yüksekten Düşüğe',
    'En Çok Değerlendirilen',
    'En Yüksek İndirim',
    'En Çok Satan Kedi Ürünleri',
    'En Çok Satan Köpek Ürünleri',
    'Popüler Mamalar',
    'Popüler Kum ve Bakım',
    'Haftanın Yıldızları',
    'Yeni Favoriler',
  ];

  static const _bestSellerSortOptions = {
    'En Çok Satan Kedi Ürünleri',
    'En Çok Satan Köpek Ürünleri',
    'Popüler Mamalar',
    'Popüler Kum ve Bakım',
    'Haftanın Yıldızları',
    'Yeni Favoriler',
  };

  List<String> _brandOptions = const [];

  List<String> get _brandFilterOptions {
    final selected = _selectedBrand;
    if (selected == null || _brandOptions.contains(selected)) {
      return _brandOptions;
    }
    return [selected, ..._brandOptions];
  }

  static const _healthFilters = <_HealthFilter>[
    _HealthFilter(id: 'sindirim', title: 'Sindirim', iconPath: ''),
    _HealthFilter(id: 'bobrek', title: 'Böbrek', iconPath: ''),
    _HealthFilter(id: 'tuy', title: 'Tüy', iconPath: ''),
    _HealthFilter(id: 'kilo', title: 'Kilo', iconPath: ''),
    _HealthFilter(id: 'bagisiklik', title: 'Bağışıklık', iconPath: ''),
    _HealthFilter(id: 'mide', title: 'Mide', iconPath: ''),
    _HealthFilter(id: 'idrar', title: 'İdrar', iconPath: ''),
    _HealthFilter(id: 'kalp', title: 'Kalp', iconPath: ''),
    _HealthFilter(id: 'dis', title: 'Diş', iconPath: ''),
    _HealthFilter(id: 'eklem', title: 'Eklem', iconPath: ''),
    _HealthFilter(id: 'diyabet', title: 'Diyabet', iconPath: ''),
    _HealthFilter(id: 'karaciger', title: 'Karaciğer', iconPath: ''),
    _HealthFilter(id: 'hipo', title: 'Hipo', iconPath: ''),
    _HealthFilter(id: 'kisir', title: 'Kısır', iconPath: ''),
    _HealthFilter(id: 'tahilsiz', title: 'Tahılsız', iconPath: ''),
  ];

  static const _categories = [
    _MarketCategory(
      id: 'cat',
      label: 'Kedi',
      imagePath: 'assets/images/urunler_kedi.png',
    ),
    _MarketCategory(
      id: 'dog',
      label: 'Köpek',
      imagePath: 'assets/images/urunler_kopek.png',
    ),
    _MarketCategory(
      id: 'bird',
      label: 'Kuş',
      imagePath: 'assets/images/urunler_kus.png',
    ),
    _MarketCategory(
      id: 'rodent',
      label: 'Kemirgen',
      imagePath: 'assets/images/urunler_kemirgen.png',
    ),
    _MarketCategory(
      id: 'smart',
      label: 'Pet Ürünleri',
      imagePath: 'assets/images/urunler_akilli.png',
    ),
  ];

  String _defaultSubCategoryFor(String mainCategory) {
    if (mainCategory == 'smart') return 'Akıllı Pet';
    return 'Mama';
  }

  void _applySortSelection(String value) {
    _sortBy = value;
    switch (value) {
      case 'En Çok Satan Kedi Ürünleri':
        _mainCategory = 'cat';
        _subCategory = _defaultSubCategoryFor('cat');
      case 'En Çok Satan Köpek Ürünleri':
        _mainCategory = 'dog';
        _subCategory = _defaultSubCategoryFor('dog');
      case 'Popüler Mamalar':
        _subCategory = 'Mama';
      case 'Popüler Kum ve Bakım':
        _mainCategory = 'cat';
        _subCategory = 'Kum';
      case 'Haftanın Yıldızları':
      case 'Yeni Favoriler':
        break;
    }
  }

  String get _sortChipLabel {
    if (_sortBy == 'Önerilen') return 'Sıralama';
    if (_bestSellerSortOptions.contains(_sortBy)) {
      return switch (_sortBy) {
        'En Çok Satan Kedi Ürünleri' => 'Kedi',
        'En Çok Satan Köpek Ürünleri' => 'Köpek',
        'Popüler Mamalar' => 'Mama',
        'Popüler Kum ve Bakım' => 'Kum',
        'Haftanın Yıldızları' => 'Yıldız',
        'Yeni Favoriler' => 'Yeni',
        _ => 'Sıra',
      };
    }
    return 'Sıra';
  }

  List<String> get _visibleSortOptions {
    const main = [
      'Önerilen',
      'Fiyat: Düşükten Yükseğe',
      'Fiyat: Yüksekten Düşüğe',
      'En Çok Değerlendirilen',
      'En Yüksek İndirim',
    ];
    if (main.contains(_sortBy)) return main;
    return [_sortBy, ...main];
  }

  String get _filterChipLabel {
    final id = _selectedAdvantageId?.trim() ?? '';
    if (id.isNotEmpty) {
      for (final item in _healthFilters) {
        if (item.id == id) return item.title;
      }
    }
    if (_selectedFeature != null && _selectedFeature!.trim().isNotEmpty) {
      return _selectedFeature!;
    }
    return 'Filtre';
  }

  bool get _filterActive =>
      _selectedFeature != null ||
      (_selectedAdvantageId != null && _selectedAdvantageId!.trim().isNotEmpty);

  @override
  void initState() {
    super.initState();
    _mainCategory = widget.initialMainCategory;
    _subCategory =
        widget.initialSubCategory ?? _defaultSubCategoryFor(_mainCategory);
    _selectedFeature = widget.initialFeature;
    _selectedAdvantageId = widget.initialAdvantageId;
    _catalogFilter = widget.initialCatalogFilter;
    final initialSort = widget.initialSortBy?.trim() ?? '';
    if (initialSort.isNotEmpty) {
      _sortBy = initialSort;
    }
    _selectedBrand = widget.initialBrand;
    _loadBrandOptions();
    final initialQuery = widget.initialSearchQuery?.trim() ?? '';
    if (initialQuery.isNotEmpty) {
      _searchController.text = initialQuery;
      _searchQuery = initialQuery.toLowerCase();
    }
    if (widget.openFeatureSheet) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _openFilterSheet();
      });
    }
  }

  Future<void> _loadBrandOptions() async {
    try {
      final brands = await BrandRepository.instance.fetchAll(activeOnly: true);
      if (!mounted) return;
      setState(() {
        _brandOptions = [for (final brand in brands) brand.name];
      });
    } catch (_) {
      // Filtre boş kalır; seçili marka yine de ürünleri süzebilir.
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _applySearch([String? value]) {
    final query = (value ?? _searchController.text).trim();
    setState(() => _searchQuery = query.toLowerCase());
  }

  void _setFeature(String? value, {String? advantageId}) {
    setState(() {
      _selectedFeature = value;
      _selectedAdvantageId = advantageId;
    });
  }

  List<MarketProductData> _filteredProducts(List<MarketProductData> remote) {
    var items = List<MarketProductData>.from(remote);

    if (_selectedBrand != null) {
      items = items
          .where(
            (p) =>
                p.brand.toLowerCase().contains(_selectedBrand!.toLowerCase()) ||
                p.title.toLowerCase().contains(_selectedBrand!.toLowerCase()),
          )
          .toList();
    }

    if (_selectedWeight != null) {
      items = items.where((p) => p.weights.contains(_selectedWeight)).toList();
    }

    if (_selectedAgeGroup != null) {
      final key = switch (_selectedAgeGroup) {
        'Yavru (0-1)' => 'yavru',
        'Genç (1-3)' => 'genç',
        'Yetişkin (3-7)' => 'yetişkin',
        'Yaşlı (7-+)' => 'yaşlı',
        _ => '',
      };
      if (key.isNotEmpty) {
        items = items
            .where(
              (p) =>
                  p.subtitle.toLowerCase().contains(key) ||
                  p.title.toLowerCase().contains(key) ||
                  p.dietTag.toLowerCase().contains(key) ||
                  p.petTag.toLowerCase().contains(key),
            )
            .toList();
      }
    }

    if (_selectedAdvantageId != null &&
        _selectedAdvantageId!.trim().isNotEmpty) {
      items = items
          .where(
            (p) => ProductAdvantageRepository.productMatchesTags(
              productAdvantageIds: p.productAdvantageIds,
              tags: [_selectedAdvantageId!],
            ),
          )
          .toList();
    } else if (_selectedFeature != null) {
      items = items
          .where(
            (p) => ProductAdvantageRepository.productMatchesTags(
              productAdvantageIds: p.productAdvantageIds,
              tags: [_selectedFeature!],
            ),
          )
          .toList();
    }

    if (_catalogFilter != null) {
      items = _applyCatalogFilter(items);
      return items;
    }

    switch (_sortBy) {
      case 'Fiyat: Düşükten Yükseğe':
        items.sort((a, b) => a.prices.first.compareTo(b.prices.first));
      case 'Fiyat: Yüksekten Düşüğe':
        items.sort((a, b) => b.prices.first.compareTo(a.prices.first));
      case 'En Çok Değerlendirilen':
        items.sort((a, b) {
          final rating = b.rating.compareTo(a.rating);
          if (rating != 0) return rating;
          return b.reviewCount.compareTo(a.reviewCount);
        });
      case 'En Çok Satan Kedi Ürünleri':
      case 'En Çok Satan Köpek Ürünleri':
      case 'Popüler Mamalar':
      case 'Popüler Kum ve Bakım':
      case 'Haftanın Yıldızları':
      case 'Yeni Favoriler':
        items.sort((a, b) => b.reviewCount.compareTo(a.reviewCount));
      case 'En Yüksek İndirim':
        items.sort((a, b) => b.discount.compareTo(a.discount));
      default:
        break;
    }

    return items;
  }

  List<MarketProductData> _applyCatalogFilter(List<MarketProductData> items) {
    switch (_catalogFilter) {
      case 'affordable':
        final tagged = items
            .where(
              (p) =>
                  p.trustBadgeIds.contains(
                    TrustBadgeRepository.affordableBadgeId,
                  ) ||
                  p.discount >= 8,
            )
            .toList();
        if (tagged.isNotEmpty) items = tagged;
        items.sort((a, b) {
          final disc = b.discount.compareTo(a.discount);
          if (disc != 0) return disc;
          return a.prices.first.compareTo(b.prices.first);
        });
      case 'bestSellers':
        items.sort((a, b) {
          final aRanked = a.preferredRank.trim().isEmpty ? 1 : 0;
          final bRanked = b.preferredRank.trim().isEmpty ? 1 : 0;
          if (aRanked != bRanked) return aRanked.compareTo(bRanked);
          return b.reviewCount.compareTo(a.reviewCount);
        });
      case 'topRated':
        items.sort((a, b) {
          final rating = b.rating.compareTo(a.rating);
          if (rating != 0) return rating;
          return b.reviewCount.compareTo(a.reviewCount);
        });
      case 'repurchase':
        items.sort((a, b) {
          final rates = _repurchaseValue(b).compareTo(_repurchaseValue(a));
          if (rates != 0) return rates;
          return b.reviewCount.compareTo(a.reviewCount);
        });
      default:
        break;
    }
    return items;
  }

  int _repurchaseValue(MarketProductData product) {
    final raw = product.repurchaseRate.replaceAll('%', '').trim();
    return int.tryParse(raw) ?? 0;
  }

  bool get _relaxCategoryFilter {
    return _searchQuery.isNotEmpty ||
        _selectedFeature != null ||
        (_selectedAdvantageId != null &&
            _selectedAdvantageId!.trim().isNotEmpty) ||
        _catalogFilter != null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<MarketProductData>>(
      stream: ProductRepository.instance.watchMarketProducts(
        mainCategory: _relaxCategoryFilter ? null : _mainCategory,
        subCategory: _relaxCategoryFilter ? null : _subCategory,
        searchQuery: _searchQuery.isEmpty ? null : _searchQuery,
      ),
      builder: (context, snapshot) {
        final products = _filteredProducts(snapshot.data ?? const []);
        return Scaffold(
          backgroundColor: AppColors.background,
          body: AppPageFrame.standard(
            backgroundColor: AppColors.background,
            header: _buildHeader(),
            content: _buildScrollBody(products),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            padding: EdgeInsets.zero,
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          Expanded(
            child: IgnorePointer(
              child: Text(
                'Ürünler',
                textAlign: TextAlign.center,
                style: AppTextStyles.pageHeader,
              ),
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildScrollBody(List<MarketProductData> products) {
    return CustomScrollView(
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
                _buildSearchBar(),
                const SizedBox(height: 10),
                _buildCategoryRow(),
                const SizedBox(height: 10),
                _buildFilterRow(),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(
            AppPageFrame.contentHorizontalPadding,
            0,
            AppPageFrame.contentHorizontalPadding,
            12,
          ),
          sliver: products.isEmpty
              ? const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
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
                  ),
                )
              : SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                      onAddToCart: () =>
                          _addToCart(product, weight, price, oldPrice, 1),
                    );
                  }, childCount: products.length),
                ),
        ),
      ],
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
                  onTap: _applySearch,
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
                    onSubmitted: _applySearch,
                    onChanged: (value) {
                      if (value.trim().isEmpty && _searchQuery.isNotEmpty) {
                        setState(() => _searchQuery = '');
                      }
                    },
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
                        setState(() => _searchQuery = '');
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
            _openFilterSheet();
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

  Widget _buildCategoryRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        for (final category in _categories) _buildCategoryCircle(category),
      ],
    );
  }

  Widget _buildCategoryCircle(_MarketCategory category) {
    final selected = _mainCategory == category.id;

    return GestureDetector(
      onTap: () {
        setState(() {
          _mainCategory = category.id;
          _subCategory = _defaultSubCategoryFor(category.id);
          _selectedBrand = null;
          _selectedWeight = null;
          _selectedAgeGroup = null;
          _selectedFeature = null;
          _selectedAdvantageId = null;
          _catalogFilter = null;
          _sortBy = 'Önerilen';
        });
      },
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 48,
              height: 48,
              padding: const EdgeInsets.all(5),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected ? AppColors.primaryLight : AppColors.border,
                  width: selected ? 0.8 : 1,
                ),
              ),
              child: ClipOval(
                child: Image.asset(
                  category.imagePath,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    category.id == 'smart'
                        ? Icons.auto_awesome_rounded
                        : category.id == 'bird'
                        ? Icons.flutter_dash_rounded
                        : Icons.pets_rounded,
                    color: AppColors.primary,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterRow() {
    final sortActive = _sortBy != 'Önerilen';
    final brandActive = _selectedBrand != null;

    return Row(
      children: [
        Expanded(
          child: _filterChip(
            label: _sortChipLabel,
            selected: sortActive,
            showArrow: true,
            onTap: () => _openOptionSheet(
              title: 'Sıralama',
              options: _visibleSortOptions,
              selected: _sortBy,
              maxHeight: 320,
              onSelect: (value) => setState(() => _applySortSelection(value)),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterChip(
            label: brandActive ? _selectedBrand! : 'Marka',
            selected: brandActive,
            showArrow: true,
            onTap: () => _openOptionSheet(
              title: 'Marka',
              options: _brandFilterOptions,
              selected: _selectedBrand,
              allowClear: true,
              onSelect: (value) => setState(() => _selectedBrand = value),
              onClear: () => setState(() => _selectedBrand = null),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _filterChip(
            label: _filterChipLabel,
            selected: _filterActive,
            showArrow: true,
            onTap: _openFilterSheet,
          ),
        ),
      ],
    );
  }

  Widget _filterChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
    bool showArrow = false,
    Color accent = AppColors.primary,
  }) {
    final bg = selected
        ? accent.withValues(alpha: accent == AppColors.error ? 0.14 : 0.12)
        : AppColors.surface;
    final border = selected
        ? accent.withValues(alpha: accent == AppColors.error ? 0.35 : 0.45)
        : AppColors.border;
    final fg = selected ? accent : AppColors.text;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: selected ? 1.1 : 0.8),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: fg,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (showArrow) ...[
              const SizedBox(width: 1),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: selected ? accent : AppColors.subText,
                size: 12,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openFilterSheet() async {
    await _openOptionSheet(
      title: 'Filtre',
      options: [for (final item in _healthFilters) item.title],
      selected: _filterActive ? _filterChipLabel : null,
      allowClear: true,
      maxHeight: 360,
      onSelect: (value) {
        final item = _healthFilters.firstWhere((e) => e.title == value);
        _setFeature(item.title, advantageId: item.id);
      },
      onClear: () => _setFeature(null),
    );
  }

  Future<void> _openOptionSheet({
    required String title,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
    VoidCallback? onClear,
    bool allowClear = false,
    double maxHeight = 260,
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.28),
      builder: (sheetContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: AppPageFrame.width - 72,
              constraints: BoxConstraints(maxHeight: maxHeight),
              margin: const EdgeInsets.symmetric(horizontal: 36),
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 14,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
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
                      if (allowClear && selected != null)
                        GestureDetector(
                          onTap: () {
                            onClear?.call();
                            Navigator.of(sheetContext).pop();
                          },
                          child: const Text(
                            'Temizle',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      const SizedBox(width: 6),
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
                        return InkWell(
                          onTap: () {
                            onSelect(option);
                            Navigator.of(sheetContext).pop();
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    option,
                                    style: TextStyle(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.text,
                                      fontSize: 12,
                                      fontWeight: isSelected
                                          ? FontWeight.w900
                                          : FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  const Icon(
                                    Icons.check_rounded,
                                    color: AppColors.primary,
                                    size: 16,
                                  ),
                              ],
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
        );
      },
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
        barcode: product.barcode,
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

class _HealthFilter {
  const _HealthFilter({
    required this.id,
    required this.title,
    required this.iconPath,
  });

  final String id;
  final String title;
  final String iconPath;
}
