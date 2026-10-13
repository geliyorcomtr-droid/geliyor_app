import 'package:flutter/material.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/data/product_bag_days.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/data/trust_badge_repository.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/screens/favorites_screen.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/favorite_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/utils/product_ingredients.dart';
import 'package:geliyor_app/utils/product_price.dart';
import 'package:geliyor_app/utils/product_skt.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/info_guide_sheet.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';
import 'package:geliyor_app/widgets/product_advantage_guide_sheet.dart';
import 'package:geliyor_app/widgets/preferred_rank_medal.dart';
import 'package:geliyor_app/widgets/product_favorite_corner.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({
    super.key,
    this.product,
    this.listenLive = true,
  });

  final MarketProductData? product;
  final bool listenLive;

  static const _fallbackId = '';
  static const _fallbackTitle = '';
  static const _fallbackBrand = '';
  static const _fallbackWeight = '';
  static const _fallbackImagePath = '';
  static const _fallbackUnitPrice = 0.0;
  static const _fallbackOldPrice = 0.0;
  static const _fallbackDiscountPercent = 0;
  static const _fallbackDescription = '';

  String get _productId => product?.id ?? _fallbackId;
  String get _productTitle => product?.title ?? _fallbackTitle;
  String get _productBrand => product?.brand ?? _fallbackBrand;
  String get _productWeight => product != null && product!.weights.isNotEmpty
      ? product!.weights.first
      : _fallbackWeight;
  String get _productImagePath => product?.imagePath ?? _fallbackImagePath;

  List<String> get _galleryImages {
    final images = product?.displayImages ?? const <String>[];
    if (images.isNotEmpty) return images;
    final fallback = _productImagePath.trim();
    return fallback.isEmpty ? const <String>[] : [fallback];
  }

  double get _productUnitPrice => product != null && product!.prices.isNotEmpty
      ? product!.prices.first
      : _fallbackUnitPrice;
  double get _productOldPrice =>
      product != null && product!.oldPrices.isNotEmpty
      ? product!.oldPrices.first
      : _fallbackOldPrice;
  int get _productDiscountPercent =>
      product?.discount ?? _fallbackDiscountPercent;
  String get _productDescription {
    final subtitle = product?.subtitle.trim() ?? '';
    if (subtitle.isEmpty) return _fallbackDescription;
    if (ProductIngredients.looksLike(subtitle) &&
        (product?.ingredients.trim().isEmpty ?? true)) {
      return '';
    }
    return subtitle;
  }

  String get _productIngredients {
    final dedicated = product?.ingredients.trim() ?? '';
    if (dedicated.isNotEmpty) return dedicated;
    final subtitle = product?.subtitle.trim() ?? '';
    if (ProductIngredients.looksLike(subtitle)) return subtitle;
    return '';
  }

  String? _advantageStatValue(AppProductAdvantage item) {
    if (ProductAdvantageRepository.isAnimalProteinAdvantage(item)) {
      final value = product?.animalProteinValue.trim() ?? '';
      if (value.isNotEmpty) {
        return ProductAdvantageRepository.formatProteinDisplay(value);
      }
      final override = product?.productAdvantageValues[item.id]?.trim();
      if (override != null && override.isNotEmpty) {
        return ProductAdvantageRepository.formatProteinDisplay(override);
      }
      return null;
    }
    if (ProductAdvantageRepository.isProteinStat(item)) {
      final protein = product?.proteinValue.trim() ?? '';
      if (protein.isNotEmpty) {
        return ProductAdvantageRepository.formatProteinDisplay(protein);
      }
    }
    final override = product?.productAdvantageValues[item.id]?.trim();
    if (override != null && override.isNotEmpty) return override;
    final template = item.value.trim();
    if (template.isNotEmpty) return template;
    if (ProductAdvantageRepository.displaysAsStat(item)) return '%42';
    return null;
  }

  bool _showsAsStat(AppProductAdvantage item) {
    return ProductAdvantageRepository.displaysAsStat(item);
  }

  String get _productRatingLabel {
    final value = product?.rating ?? 4.8;
    return value.toStringAsFixed(1);
  }

  String get _expiryLabel => ProductSkt.label(product?.skt);

  bool _isPreferredBadge(AppTrustBadge badge) {
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return id == 'en-cok-tercih' ||
        name.contains('tercih') ||
        name.contains('çok satan') ||
        name.contains('cok satan') ||
        name.contains('en çok') ||
        name.contains('en cok');
  }

  String get _preferredRankLabel {
    final rank = product?.preferredRank.trim() ?? '';
    return TrustBadgeRepository.formatPreferredRank(rank);
  }

  bool _isProteinTrustBadge(AppTrustBadge badge) {
    return TrustBadgeRepository.isProteinBadge(badge);
  }

  String get _proteinDisplayValue {
    final protein = product?.proteinValue.trim() ?? '';
    if (protein.isNotEmpty) {
      return ProductAdvantageRepository.formatProteinDisplay(protein);
    }
    return '%42';
  }

  bool _isRepurchaseBadge(AppTrustBadge badge) {
    return TrustBadgeRepository.isRepurchaseBadge(badge);
  }

  bool _isAffordableBadge(AppTrustBadge badge) {
    return TrustBadgeRepository.isAffordableBadge(badge);
  }

  String get _repurchaseDisplayValue {
    final value = ProductBagDays.digits(product?.repurchaseRate);
    return value.isEmpty ? '—' : value;
  }

  bool _isRatingBadge(AppTrustBadge badge) {
    final id = badge.id.toLowerCase();
    final name = badge.name.toLowerCase();
    return id == 'degerlendirme' ||
        id.contains('puan') ||
        name.contains('puan') ||
        name.contains('yıldız') ||
        name.contains('yildiz') ||
        name.contains('değerlendirme') ||
        name.contains('degerlendirme');
  }

  _RelatedProduct _relatedFrom(MarketProductData item) {
    final price = item.prices.isNotEmpty ? item.prices.first : 0.0;
    final oldPrice =
        item.oldPrices.isNotEmpty ? item.oldPrices.first : price;
    return _RelatedProduct(
      title: item.title,
      brand: item.brand,
      weight: item.weights.isNotEmpty ? item.weights.first : '',
      price: formatProductPrice(price),
      oldPrice: formatProductPrice(oldPrice),
      imagePath: item.imagePath,
      source: item,
    );
  }

  Widget _buildExampleRelated({
    required Widget Function(List<_RelatedProduct> items) builder,
  }) {
    return StreamBuilder<List<MarketProductData>>(
      stream: ProductRepository.instance.watchMarketProducts(),
      initialData: ProductRepository.instance.cachedMarketProducts(),
      builder: (context, snapshot) {
        final catalog = snapshot.data ?? const <MarketProductData>[];
        final example = product ?? (catalog.isNotEmpty ? catalog.first : null);
        if (example == null) return const SizedBox.shrink();
        return builder([_relatedFrom(example)]);
      },
    );
  }

  static const double _sideColumnWidth = 54;
  static const int _sideSlotCount = 6;
  static const double _sideCardGap = 8;
  static const double _cardGap = 8;
  static const double _heroHeight = 488;
  static const double _cardPaddingTop = 10;
  static const double _cardPaddingBottom = 12;
  static const double _afterGalleryGap = 6;
  static const double _afterTitleGap = 8;
  static const double _afterMetaGap = 10;
  static const double _dividerHeight = 1;
  static const double _afterDividerGap = 10;
  static const double _titleBlockHeight = 62;
  static const double _metaRowHeight = 28;
  static const double _priceBlockHeight = 62;
  static const double _sectionGap = 12;
  static const Color _accent = AppColors.primary;

  static BoxDecoration get _boxDecoration => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(24),
    border: Border.all(color: _accent, width: 1),
    boxShadow: const [
      BoxShadow(color: Color(0x0D000000), blurRadius: 8, offset: Offset(0, 2)),
    ],
  );

  FavoriteItem get _favoriteItem => FavoriteItem(
    id: _productId,
    imagePath: _productImagePath,
    title: _productTitle,
    unitPrice: _productUnitPrice,
    oldPrice: _productOldPrice,
    discountPercent: _productDiscountPercent,
    weight: _productWeight,
    brand: _productBrand,
    category: 'Kuru Mama',
  );

  void _toggleFavorite(BuildContext context) {
    final store = FavoriteStore.instance;
    final wasFavorite = store.isFavorite(_productId);
    store.toggle(_favoriteItem);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.text,
        content: Text(
          wasFavorite
              ? '$_productTitle favorilerden çıkarıldı.'
              : '$_productTitle favorilere eklendi.',
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
        ),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  String get _marketMainCategory {
    final tag = (product?.petTag ?? '').trim().toLowerCase();
    if (tag.contains('köpek') || tag.contains('kopek')) return 'dog';
    if (tag.contains('kuş') || tag.contains('kus')) return 'bird';
    if (tag.contains('kemirgen')) return 'rodent';
    if (tag.contains('akıllı') || tag.contains('akilli')) return 'smart';
    return 'cat';
  }

  void _openFullscreenImage(BuildContext context, {int initialIndex = 0}) {
    final images = _galleryImages;
    if (images.isEmpty) return;
    final start = initialIndex.clamp(0, images.length - 1);
    InfoGuideSheet.showCentered(
      context,
      builder: (sheetContext) {
        return _FullscreenProductGallery(
          images: images,
          initialIndex: start,
          onClose: () => Navigator.of(sheetContext).pop(),
        );
      },
    );
  }

  void _openBrandProducts(BuildContext context) {
    final brand = _productBrand.trim();
    if (brand.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: _marketMainCategory,
          initialBrand: brand,
        ),
      ),
    );
  }

  void _openAdvantageGuide(BuildContext context, AppProductAdvantage item) {
    ProductAdvantageGuideSheet.show(
      context,
      item: item,
      mainCategory: _marketMainCategory,
    );
  }

  void _openTrustGuide(BuildContext context, _SideBadge badge) {
    InfoGuideSheet.showImageOverlay(
      context,
      imagePath: (badge.detailImageUrl ?? '').trim(),
      fallbackIcon: badge.isRating
          ? Icons.star_rounded
          : Icons.workspace_premium_rounded,
      fallbackIconColor: badge.isRating ? AppColors.warning : AppColors.primary,
      onSeeProducts: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PetMarketProductsScreen(
              initialMainCategory: _marketMainCategory,
              initialCatalogFilter: badge.catalogFilter,
              initialFeature: badge.feature,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!listenLive) return _buildPage(context);

    final seed = product;
    final seedId = seed?.id.trim() ?? '';

    return StreamBuilder<List<MarketProductData>>(
      stream: ProductRepository.instance.watchMarketProducts(),
      initialData: ProductRepository.instance.cachedMarketProducts(),
      builder: (context, snapshot) {
        final items = snapshot.data ?? const <MarketProductData>[];
        MarketProductData? live;
        if (seedId.isNotEmpty) {
          for (final item in items) {
            if (item.id == seedId) {
              live = item;
              break;
            }
          }
        } else if (items.isNotEmpty) {
          live = items.first;
        }

        if (ProductRepository.instance.catalogReady &&
            seedId.isNotEmpty &&
            live == null) {
          return Scaffold(
            backgroundColor: AppColors.surface,
            body: AppPageFrame.standard(
              backgroundColor: AppColors.surface,
              header: const AppPageHeader(title: 'Ürün Detay'),
              content: const Center(
                child: Text(
                  'Bu ürün şu an stokta yok.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          );
        }

        return ProductDetailScreen(
          product: live ?? seed,
          listenLive: false,
        );
      },
    );
  }

  Widget _buildPage(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.surface,
        header: const AppPageHeader(title: 'Ürün Detay'),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppPageFrame.contentHorizontalPadding,
            0,
            AppPageFrame.contentHorizontalPadding,
            12,
          ),
          child: Column(
            children: [
              SizedBox(
                height: _heroHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildTrustBadgeColumn(context),
                    const SizedBox(width: _cardGap),
                    Expanded(child: _buildMainCard(context)),
                    const SizedBox(width: _cardGap),
                    _buildAdvantageColumn(context),
                  ],
                ),
              ),
              _buildTogetherBox(context),
              const SizedBox(height: _sectionGap),
              _buildDescriptionBox(),
              const SizedBox(height: _sectionGap),
              _buildIngredientsBox(),
              const SizedBox(height: _sectionGap),
              const _ProductReviewsSection(),
              const SizedBox(height: _sectionGap),
              _buildSimilarBox(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTrustBadgeColumn(BuildContext context) {
    final cached = TrustBadgeRepository.instance.cached;
    return StreamBuilder<List<AppTrustBadge>>(
      initialData: cached.isEmpty ? null : cached,
      stream: TrustBadgeRepository.instance.watchAll(activeOnly: true),
      builder: (context, snapshot) {
        final allBadges = snapshot.data ?? cached;
        if (allBadges.isEmpty) {
          return _buildSideColumn(context, const []);
        }
        final selectedIds = product?.trustBadgeIds ?? const <String>[];
        final badges = [
                    for (final id in selectedIds)
                      ...allBadges.where((badge) => badge.id == id),
                  ]
            .where((badge) => !TrustBadgeRepository.isSmartSuggestionBadge(badge))
            .where((badge) => !TrustBadgeRepository.isProteinBadge(badge))
            .toList();
        if (!badges.any(_isAffordableBadge)) {
          final insertAt = badges.length >= 4 ? 4 : badges.length;
          badges.insert(
            insertAt,
            TrustBadgeRepository.defaultAffordableBadge,
          );
        }
        if (badges.isEmpty) {
          return const SizedBox(width: _sideColumnWidth);
        }

        return _buildSideColumn(context, [
          for (final badge in badges)
            _SideBadge(
              id: badge.id,
              label: _isRatingBadge(badge)
                  ? 'Puan'
                  : _shortSideLabel(
                      TrustBadgeRepository.displayName(badge),
                    ),
              iconPath: TrustBadgeRepository.displayAssetPath(badge),
              imageUrl: TrustBadgeRepository.displayImageUrl(badge),
              detailImageUrl: TrustBadgeRepository.displayDetailImageUrl(badge),
              isFavoriteAction:
                  !_isPreferredBadge(badge) &&
                  !_isRepurchaseBadge(badge) &&
                  !_isAffordableBadge(badge) &&
                  (badge.id == 'favorilere-ekle' ||
                      badge.name.toLowerCase().contains('favori')),
              isRating: _isRatingBadge(badge),
              isPreferred: _isPreferredBadge(badge),
              isStat:
                  _isProteinTrustBadge(badge) || _isRepurchaseBadge(badge),
              ratingValue: _isRatingBadge(badge) ? _productRatingLabel : null,
              preferredRank: _isPreferredBadge(badge)
                  ? _preferredRankLabel
                  : null,
              catalogFilter: _isPreferredBadge(badge)
                  ? 'bestSellers'
                  : _isRatingBadge(badge)
                  ? 'topRated'
                  : _isAffordableBadge(badge)
                  ? 'affordable'
                  : _isRepurchaseBadge(badge)
                  ? 'repurchase'
                  : null,
              statValue: _isRepurchaseBadge(badge)
                  ? _repurchaseDisplayValue
                  : _isProteinTrustBadge(badge)
                  ? _proteinDisplayValue
                  : null,
            ),
        ]);
      },
    );
  }

  Widget _buildAdvantageColumn(BuildContext context) {
    final cached = ProductAdvantageRepository.instance.cached;
    return StreamBuilder<List<AppProductAdvantage>>(
      initialData: cached.isEmpty ? null : cached,
      stream: ProductAdvantageRepository.instance.watchAll(activeOnly: true),
      builder: (context, snapshot) {
        final catalog = snapshot.data ?? cached;
        if (catalog.isEmpty) {
          return _buildSideColumn(context, const []);
        }
        final selectedIds = product?.productAdvantageIds ?? const <String>[];
        final items = ProductAdvantageRepository.forProductDetail(
          selectedIds: selectedIds,
          catalog: catalog,
          animalProteinValue: product?.animalProteinValue ?? '',
        ).take(_sideSlotCount).toList();
        if (items.isEmpty) {
          return const SizedBox(width: _sideColumnWidth);
        }
        return _buildSideColumn(context, [
          for (final item in items)
            _SideBadge(
              id: item.id,
              label: _shortSideLabel(item.name),
              iconPath: ProductAdvantageRepository.displayAssetPath(item),
              imageUrl: ProductAdvantageRepository.sharedDisplayImageUrl(
                item,
                catalog: catalog,
              ),
              feature: item.name,
              advantage: item,
              isStat: _showsAsStat(item),
              statValue: _advantageStatValue(item),
            ),
        ]);
      },
    );
  }

  Widget _buildSideColumn(BuildContext context, List<_SideBadge> badges) {
    final visible = badges.take(_sideSlotCount).toList();
    return SizedBox(
      width: _sideColumnWidth,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < _sideSlotCount; i++) ...[
            if (i > 0) const SizedBox(height: _sideCardGap),
            Expanded(
              child: i < visible.length
                  ? KeyedSubtree(
                      key: ValueKey(visible[i].id),
                      child: _buildSideCard(context, visible[i]),
                    )
                  : const SizedBox.expand(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSideCard(BuildContext context, _SideBadge badge) {
    if (badge.isFavoriteAction) {
      return _buildFavoriteSideCard(context);
    }

    final card = Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _accent, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: _sideCardBody(badge),
    );

    if (badge.advantage != null) {
      return GestureDetector(
        onTap: () => _openAdvantageGuide(context, badge.advantage!),
        behavior: HitTestBehavior.opaque,
        child: card,
      );
    }

    return GestureDetector(
      onTap: () => _openTrustGuide(context, badge),
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }

  Widget _sideCardBody(_SideBadge badge) {
    if (badge.isPreferred) {
      return Column(
        children: [
          Expanded(
            flex: 7,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 2, 0),
              child: PreferredRankMedal(
                rank: badge.preferredRank ?? '2.',
                imagePath: (badge.imageUrl?.trim().isNotEmpty ?? false)
                    ? badge.imageUrl
                    : badge.iconPath,
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: _fitSideLabel(badge.label),
          ),
        ],
      );
    }
    if (badge.id == 'uygun-fiyat') {
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          SizedBox(
            height: 32,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: _sideBadgeImage(badge),
            ),
          ),
          _fitSideLabel(badge.label),
        ],
      );
    }
    if (badge.isRating) {
      return _iconNumberLabelCard(
        icon: _sideBadgeImage(badge),
        value: badge.ratingValue ?? '—',
        label: badge.label,
        valueColor: _sideValueColor(badge),
        compactTexts: true,
      );
    }
    if (badge.isStat) {
      final isBagDays = badge.id == 'tekrar-alim';
      return _iconNumberLabelCard(
        icon: _sideBadgeImage(badge),
        value: badge.statValue ?? '—',
        label: badge.label,
        valueColor: _sideValueColor(badge),
        valueFontSize: isBagDays ? 13 : 12,
      );
    }
    return Column(
      children: _sideCardSlots(
        icon: _sideBadgeImage(badge),
        label: badge.label,
      ),
    );
  }

  Color _sideValueColor(_SideBadge badge) {
    if (badge.id == 'tekrar-alim') return AppColors.statNumber;
    if (badge.id == 'protein' ||
        ProductAdvantageRepository.isAnimalProteinId(badge.id) ||
        badge.isStat) {
      return AppColors.statNumber;
    }
    if (badge.isRating || badge.id == 'degerlendirme') return AppColors.statNumber;
    return AppColors.primary;
  }

  /// İkon önde; protein / gün yeter / puan rakamı küçük kalır.
  Widget _iconNumberLabelCard({
    required Widget icon,
    required String value,
    required String label,
    required Color valueColor,
    bool compactTexts = false,
    double valueFontSize = 12,
  }) {
    final valueText = FittedBox(
      fit: BoxFit.scaleDown,
      child: Text(
        value,
        textAlign: TextAlign.center,
        maxLines: 1,
        style: TextStyle(
          color: valueColor,
          fontSize: compactTexts ? 11 : valueFontSize,
          fontWeight: FontWeight.w800,
          height: 1,
          letterSpacing: -0.2,
        ),
      ),
    );
    final labelText = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: AppColors.text,
            fontSize: compactTexts ? 9 : 10,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ),
    );

    return Column(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(1, 1, 1, 0),
            child: icon,
          ),
        ),
        Expanded(flex: 2, child: Center(child: valueText)),
        Expanded(flex: 2, child: Center(child: labelText)),
      ],
    );
  }

  /// Tek satır kısa etiket: yetişkin kedi → yetişkin, tavuklu formül → tavuklu.
  String _shortSideLabel(String name) {
    var text = name
        .trim()
        .replaceAll(RegExp(r'[\n\r]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ');
    if (text.isEmpty) return text;
    text = text.replaceAll(
      RegExp(r'\s+(sağlığı|sagligi|sağlık|saglik)$', caseSensitive: false),
      '',
    );
    text = text.replaceAll(
      RegExp(
        r'\s+(formülü|formulü|formül|formul|formula)$',
        caseSensitive: false,
      ),
      '',
    );
    text = text.replaceAll(
      RegExp(r'\s+(kedi|köpek|kopek)$', caseSensitive: false),
      '',
    );
    return text.trim();
  }

  Widget _fitSideLabel(String label) {
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 1),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _shortSideLabel(label),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _sideCardSlots({
    required Widget icon,
    String? value,
    required String label,
  }) {
    return [
      Expanded(
        flex: 7,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(1, 1, 1, 0),
          child: icon,
        ),
      ),
      if (value != null)
        Expanded(
          flex: 4,
          child: Center(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                textAlign: TextAlign.center,
                maxLines: 1,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1,
                  letterSpacing: -0.3,
                ),
              ),
            ),
          ),
        ),
      Expanded(
        flex: 3,
        child: _fitSideLabel(label),
      ),
    ];
  }

  Widget _sideBadgeImage(_SideBadge badge) {
    final isRating = badge.isRating || badge.id == 'degerlendirme';
    final uploadedUrl = badge.imageUrl?.trim() ?? '';
    final assetPath = badge.iconPath.trim();
    final hasCustomIcon =
        uploadedUrl.isNotEmpty ||
        (assetPath.isNotEmpty && !assetPath.endsWith('/favori.png'));
    if (isRating && !hasCustomIcon) {
      return const FittedBox(
        fit: BoxFit.contain,
        child: Icon(
          Icons.star_rounded,
          color: AppColors.warning,
        ),
      );
    }

    final fallback = Icon(
      switch (badge.id) {
        'en-cok-tercih' => Icons.workspace_premium_rounded,
        'akilli-oneri' => Icons.auto_awesome_rounded,
        'protein' => Icons.set_meal_rounded,
        'tekrar-alim' => Icons.replay_rounded,
        'uygun-fiyat' => Icons.check_rounded,
        _ => Icons.verified_outlined,
      },
      size: 32,
      color: switch (badge.id) {
        'tekrar-alim' => AppColors.error,
        'protein' => AppColors.warning,
        'uygun-fiyat' => AppColors.success,
        _ => AppColors.primary,
      },
    );
    const decodePx = 96;

    final wrongDefaultFavorite = assetPath.endsWith('/favori.png');

    Widget image;
    if (uploadedUrl.isNotEmpty) {
      image = buildProductImage(
        uploadedUrl,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
        cacheWidth: decodePx,
        errorWidget: assetPath.isEmpty || wrongDefaultFavorite
            ? fallback
            : buildProductImage(
                assetPath,
                fit: BoxFit.contain,
                width: double.infinity,
                height: double.infinity,
                filterQuality: FilterQuality.medium,
                cacheWidth: decodePx,
                errorWidget: fallback,
              ),
      );
    } else if (assetPath.isNotEmpty && !wrongDefaultFavorite) {
      image = buildProductImage(
        assetPath,
        fit: BoxFit.contain,
        width: double.infinity,
        height: double.infinity,
        filterQuality: FilterQuality.medium,
        cacheWidth: decodePx,
        errorWidget: fallback,
      );
    } else {
      return fallback;
    }
    return ColorFiltered(
      colorFilter: _knockOutWhite,
      child: image,
    );
  }

  static const _knockOutWhite = ColorFilter.matrix(<double>[
    1, 0, 0, 0, 0,
    0, 1, 0, 0, 0,
    0, 0, 1, 0, 0,
    -1, -1, -1, 3, 0,
  ]);

  Widget _buildFavoriteSideCard(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoriteStore.instance,
      builder: (context, _) {
        final isFavorite = FavoriteStore.instance.isFavorite(_productId);

        return GestureDetector(
          onTap: () => _toggleFavorite(context),
          onLongPress: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FavoritesScreen()),
            );
          },
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: double.infinity,
            padding: const EdgeInsets.fromLTRB(2, 2, 2, 2),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _accent, width: 1),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              children: [
                Expanded(
                  child: Center(
                    child: Container(
                      width: 26,
                      height: 26,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: AppColors.statNumber.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.statNumber,
                          width: 1.2,
                        ),
                      ),
                      child: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 16,
                        color: AppColors.statNumber,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Center(
                    child: Text(
                      'Favori',
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMainCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(
        12,
        _cardPaddingTop,
        12,
        _cardPaddingBottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ClipRect(child: _buildGallery(context)),
          ),
          const SizedBox(height: _afterGalleryGap),
          SizedBox(
            height: _titleBlockHeight,
            child: ClipRect(child: _buildTitleBlock(context)),
          ),
          const SizedBox(height: _afterTitleGap),
          SizedBox(
            height: _metaRowHeight,
            child: ClipRect(child: _buildMetaRow()),
          ),
          const SizedBox(height: _afterMetaGap),
          const SizedBox(height: _dividerHeight, child: _DashedDivider()),
          const SizedBox(height: _afterDividerGap),
          SizedBox(
            height: _priceBlockHeight,
            child: ClipRect(child: _buildPriceRow(context)),
          ),
        ],
      ),
    );
  }

  Widget _buildGallery(BuildContext context) {
    return _ProductHeroGallery(
      images: _galleryImages,
      onOpenFullscreen: (index) =>
          _openFullscreenImage(context, initialIndex: index),
    );
  }

  Widget _buildTitleBlock(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _productTitle,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 16,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        GestureDetector(
          onTap: () => _openBrandProducts(context),
          behavior: HitTestBehavior.opaque,
          child: Text(
            _productBrand,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        const Icon(
          Icons.monitor_weight_outlined,
          size: 22,
          color: AppColors.primary,
        ),
        const SizedBox(width: 6),
        Text(
          _productWeight,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 18,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
        Container(
          width: 1.5,
          height: 16,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: _accent,
        ),
        const Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: AppColors.primary,
        ),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            _expiryLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }

  static const double _priceLineGap = 6;

  Widget _buildPriceRow(BuildContext context) {
    final showOldPrice = _productOldPrice > _productUnitPrice;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showOldPrice) ...[
          Text(
            '${formatProductPrice(_productOldPrice, withDecimals: false).replaceAll('₺', '').trim()} ₺',
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              decoration: TextDecoration.lineThrough,
              decorationColor: AppColors.subText,
              height: 1.1,
            ),
          ),
          const SizedBox(height: _priceLineGap),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              '${formatProductPrice(_productUnitPrice, withDecimals: false).replaceAll('₺', '').trim()} ₺',
              style: const TextStyle(
                color: AppColors.statNumber,
                fontSize: 21,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () {
                CartStore.instance.addItem(
                  id: '$_productId-$_productWeight',
                  imagePath: _productImagePath,
                  title: _productTitle,
                  unitPrice: _productUnitPrice,
                  oldPrice: _productOldPrice,
                  discountPercent: _productDiscountPercent,
                  weight: _productWeight,
                  brand: _productBrand,
                  skt: product?.skt ?? '',
                  barcode: product?.barcode ?? '',
                );
                _showAddedToCartDialog(context, _productTitle);
              },
              behavior: HitTestBehavior.opaque,
              child: const SizedBox(
                width: 40,
                height: 21,
                child: OverflowBox(
                  alignment: Alignment.center,
                  minWidth: 40,
                  minHeight: 40,
                  maxWidth: 40,
                  maxHeight: 40,
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    size: 40,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: _priceLineGap),
        const Row(
          children: [
            Icon(Icons.circle, size: 7, color: AppColors.success),
            SizedBox(width: 5),
            Text(
              'Stokta',
              style: TextStyle(
                color: AppColors.success,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDescriptionBox() {
    final text = _productDescription.trim();
    if (text.isEmpty || ProductIngredients.looksLike(text)) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: _boxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ürün Açıklaması',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsBox() {
    final sections = ProductIngredients.parse(_productIngredients);
    if (sections.isEmpty) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: _boxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'İçindekiler',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          for (final section in sections) ...[
            const SizedBox(height: 10),
            Text(
              section.title,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              section.body,
              style: const TextStyle(
                color: AppColors.subText,
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTogetherBox(BuildContext context) {
    final ids = [
      for (final id in product?.boughtTogetherIds ?? const <String>[])
        if (id.trim().isNotEmpty && id.trim() != product?.id) id.trim(),
    ];
    if (ids.isEmpty) return const SizedBox.shrink();
    return StreamBuilder<List<MarketProductData>>(
      stream: ProductRepository.instance.watchActiveProducts(),
      initialData: ProductRepository.instance.cachedActiveProducts(),
      builder: (context, snapshot) {
        final catalog = snapshot.data ?? const <MarketProductData>[];
        final byId = {for (final item in catalog) item.id: item};
        final items = <_RelatedProduct>[
          for (final id in ids)
            if (byId[id] != null) _relatedFrom(byId[id]!),
        ];
        if (items.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: _sectionGap),
          child: Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          decoration: _boxDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Birlikte Alınan Ürünler',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: 148,
                child: Row(
                  children: [
                    for (int i = 0; i < 3; i++) ...[
                      if (i > 0) const SizedBox(width: _cardGap),
                      Expanded(
                        child: i < items.length
                            ? _buildCompactProductCard(context, items[i])
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        );
      },
    );
  }

  Widget _buildSimilarBox(BuildContext context) {
    return _buildExampleRelated(
      builder: (items) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
          decoration: _boxDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Benzer Ürünler',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 10),
              for (int i = 0; i < items.length; i++) ...[
                if (i > 0) const SizedBox(height: _sectionGap),
                _buildSimilarProductRow(context, items[i]),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildCompactProductCard(
    BuildContext context,
    _RelatedProduct product,
  ) {
    return GestureDetector(
      onTap: () => _openRelatedDetail(context, product),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Center(
                      child: buildProductImage(
                        product.imagePath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorWidget: const Icon(
                              Icons.image_outlined,
                              color: AppColors.subText,
                              size: 36,
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: ProductFavoriteCorner(
                      productId: product.id,
                      onToggle: () => _toggleRelatedFavorite(product),
                      size: 22,
                      iconSize: 12,
                    ),
                  ),
                  if (product.animalProteinLabel.isNotEmpty)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: AnimalProteinBadge(
                        label: product.animalProteinLabel,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Text(
              product.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              product.weight,
              style: const TextStyle(
                color: AppColors.subText,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    product.price,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.discount,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _addRelatedToCart(context, product),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _accent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.shopping_cart_rounded,
                      size: 12,
                      color: AppColors.surface,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSimilarProductRow(
    BuildContext context,
    _RelatedProduct product,
  ) {
    return GestureDetector(
      onTap: () => _openRelatedDetail(context, product),
      child: Container(
        height: 78,
        padding: const EdgeInsets.fromLTRB(8, 8, 10, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _accent),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 58,
              height: 58,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: buildProductImage(
                        product.imagePath,
                        fit: BoxFit.contain,
                        filterQuality: FilterQuality.high,
                        errorWidget: const Icon(
                              Icons.image_outlined,
                              color: AppColors.subText,
                              size: 28,
                            ),
                      ),
                    ),
                  ),
                  Positioned(
                    top: 0,
                    left: 0,
                    child: ProductFavoriteCorner(
                      productId: product.id,
                      onToggle: () => _toggleRelatedFavorite(product),
                      size: 20,
                      iconSize: 11,
                    ),
                  ),
                  if (product.animalProteinLabel.isNotEmpty)
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: AnimalProteinBadge(
                        label: product.animalProteinLabel,
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.brand}  ·  ${product.weight}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        product.price,
                        style: const TextStyle(
                          color: AppColors.discount,
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        product.oldPrice,
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.subText,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _addRelatedToCart(context, product),
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(
                  Icons.shopping_cart_rounded,
                  size: 14,
                  color: AppColors.surface,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openRelatedDetail(BuildContext context, _RelatedProduct product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(product: product.source),
      ),
    );
  }

  void _addRelatedToCart(BuildContext context, _RelatedProduct product) {
    final price = parseTurkishPrice(product.price) ?? 0;
    final oldPrice = parseTurkishPrice(product.oldPrice) ?? price;

    CartStore.instance.addItem(
      id: product.id,
      imagePath: product.imagePath,
      title: product.title,
      unitPrice: price,
      oldPrice: oldPrice,
      weight: product.weight,
      brand: product.brand,
      skt: product.source?.skt ?? '',
      barcode: product.source?.barcode ?? '',
    );
    _showAddedToCartDialog(context, product.title);
  }

  void _toggleRelatedFavorite(_RelatedProduct product) {
    final price = parseTurkishPrice(product.price) ?? 0;
    final oldPrice = parseTurkishPrice(product.oldPrice) ?? price;
    FavoriteStore.instance.toggle(
      FavoriteItem(
        id: product.id,
        imagePath: product.imagePath,
        title: '${product.title} ${product.weight}',
        unitPrice: price,
        oldPrice: oldPrice,
        discountPercent: discountPercentFromPrices(price, oldPrice) ?? 15,
        weight: product.weight,
        brand: product.brand,
      ),
    );
  }

  void _showAddedToCartDialog(BuildContext context, String productTitle) {
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

class _ProductReviewsSection extends StatefulWidget {
  const _ProductReviewsSection();

  @override
  State<_ProductReviewsSection> createState() => _ProductReviewsSectionState();
}

class _ProductReviewsSectionState extends State<_ProductReviewsSection> {
  bool _showAll = false;

  static const _reviews = <_ProductReview>[
    _ProductReview(
      name: 'Ayşe K.',
      date: '12 Ağustos 2026',
      rating: 5,
      comment:
          'Kedim ilk günden severek yemeye başladı. Taneleri uygun boyutta ve paketleme çok özenliydi.',
    ),
    _ProductReview(
      name: 'Mehmet T.',
      date: '8 Ağustos 2026',
      rating: 5,
      comment:
          'Uzun süredir kullandığımız bir mama. Tüy dökülmesinde azalma fark ettik, hızlı teslimat için teşekkürler.',
    ),
    _ProductReview(
      name: 'Selin A.',
      date: '2 Ağustos 2026',
      rating: 4,
      comment:
          'İçeriği güzel ve kedim severek tüketiyor. Kilitli paket olması mamanın tazeliğini koruyor.',
    ),
    _ProductReview(
      name: 'Burak D.',
      date: '28 Temmuz 2026',
      rating: 5,
      comment:
          'Kısır kedim için veterinerimizin önerisiyle aldım. Sindirim sorunu yaşamadık ve oldukça memnunuz.',
    ),
    _ProductReview(
      name: 'Zeynep Y.',
      date: '21 Temmuz 2026',
      rating: 4,
      comment:
          'Ürün sağlam ulaştı. Kedim mamaya kısa sürede alıştı, tekrar sipariş vermeyi düşünüyorum.',
    ),
    _ProductReview(
      name: 'Emre Ç.',
      date: '15 Temmuz 2026',
      rating: 5,
      comment:
          'Tazeliği ve kokusu gayet iyi. Porsiyon kontrolüne dikkat edildiğinde uzun süre yeterli oluyor.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final visibleReviews = _showAll ? _reviews : _reviews.take(2);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: ProductDetailScreen._boxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Ürün Değerlendirmeleri',
                  style: AppTextStyles.sectionHeader,
                ),
              ),
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => setState(() => _showAll = !_showAll),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    _showAll ? 'Daha Az' : 'Tümünü Gör',
                    style: AppTextStyles.seeAllAction.copyWith(fontSize: 12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          AnimatedSize(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            alignment: Alignment.topCenter,
            child: Column(
              children: [
                for (final review in visibleReviews) ...[
                  _buildReviewCard(review),
                  if (review != visibleReviews.last) const SizedBox(height: 10),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReviewCard(_ProductReview review) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppColors.selected,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  review.name.characters.first,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.verified_rounded,
                          color: AppColors.success,
                          size: 12,
                        ),
                        const SizedBox(width: 3),
                        const Text(
                          'Doğrulanmış alışveriş',
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Text(
                review.date,
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildStars(review.rating, size: 14),
          const SizedBox(height: 7),
          Text(
            review.comment,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStars(int rating, {required double size}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: AppColors.warning,
          size: size,
        ),
      ),
    );
  }
}

class _ProductReview {
  const _ProductReview({
    required this.name,
    required this.date,
    required this.rating,
    required this.comment,
  });

  final String name;
  final String date;
  final int rating;
  final String comment;
}

class _SideBadge {
  const _SideBadge({
    required this.id,
    required this.label,
    required this.iconPath,
    this.imageUrl,
    this.detailImageUrl,
    this.feature,
    this.advantage,
    this.isFavoriteAction = false,
    this.isStat = false,
    this.isRating = false,
    this.isPreferred = false,
    this.statValue,
    this.ratingValue,
    this.preferredRank,
    this.catalogFilter,
  });

  final String id;
  final String label;
  final String iconPath;
  final String? imageUrl;
  final String? detailImageUrl;
  final String? feature;
  final AppProductAdvantage? advantage;
  final bool isFavoriteAction;
  final bool isStat;
  final bool isRating;
  final bool isPreferred;
  final String? statValue;
  final String? ratingValue;
  final String? preferredRank;
  final String? catalogFilter;
}

class _RelatedProduct {
  const _RelatedProduct({
    required this.title,
    required this.brand,
    required this.weight,
    required this.price,
    required this.oldPrice,
    required this.imagePath,
    this.source,
  });

  final String title;
  final String brand;
  final String weight;
  final String price;
  final String oldPrice;
  final String imagePath;
  final MarketProductData? source;

  String get id => source?.id ?? 'related-$title-$weight';

  String get animalProteinLabel => source?.animalProteinLabel ?? '';
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashGap = 4.0;
        final count = (constraints.maxWidth / (dashWidth + dashGap))
            .floor()
            .clamp(1, 200);

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => const SizedBox(
              width: dashWidth,
              height: 1,
              child: DecoratedBox(
                decoration: BoxDecoration(color: ProductDetailScreen._accent),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ProductHeroGallery extends StatefulWidget {
  const _ProductHeroGallery({
    required this.images,
    required this.onOpenFullscreen,
  });

  final List<String> images;
  final ValueChanged<int> onOpenFullscreen;

  @override
  State<_ProductHeroGallery> createState() => _ProductHeroGalleryState();
}

class _ProductHeroGalleryState extends State<_ProductHeroGallery> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    return SizedBox.expand(
      child: ClipRect(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
                child: images.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 72,
                          color: AppColors.subText,
                        ),
                      )
                    : PageView.builder(
                        itemCount: images.length,
                        onPageChanged: (index) {
                          setState(() => _index = index);
                        },
                        itemBuilder: (context, index) {
                          return GestureDetector(
                            onTap: () => widget.onOpenFullscreen(index),
                            behavior: HitTestBehavior.opaque,
                            child: SizedBox.expand(
                              child: buildProductImage(
                                images[index],
                                fit: BoxFit.contain,
                                width: double.infinity,
                                height: double.infinity,
                                alignment: Alignment.center,
                                filterQuality: FilterQuality.medium,
                                useHtmlElement: false,
                                cacheWidth: productPhotoCachePx,
                                errorWidget: const Center(
                                  child: Icon(
                                    Icons.image_outlined,
                                    size: 72,
                                    color: AppColors.subText,
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 46,
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: AppColors.statNumber,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '%15',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    Text(
                      'İNDİRİM',
                      style: TextStyle(
                        color: AppColors.surface,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (images.length > 1)
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 0; i < images.length; i++) ...[
                      if (i > 0) const SizedBox(width: 6),
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: i == _index
                              ? ProductDetailScreen._accent
                              : AppColors.subText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _FullscreenProductGallery extends StatefulWidget {
  const _FullscreenProductGallery({
    required this.images,
    required this.initialIndex,
    required this.onClose,
  });

  final List<String> images;
  final int initialIndex;
  final VoidCallback onClose;

  @override
  State<_FullscreenProductGallery> createState() =>
      _FullscreenProductGalleryState();
}

class _FullscreenProductGalleryState extends State<_FullscreenProductGallery> {
  late final PageController _controller;
  late int _index;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex;
    _controller = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          SizedBox(
            height: 32,
            child: Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: widget.onClose,
                behavior: HitTestBehavior.opaque,
                child: const SizedBox(
                  width: 32,
                  height: 32,
                  child: Icon(
                    Icons.close_rounded,
                    color: AppColors.text,
                    size: 22,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: PageView.builder(
              controller: _controller,
              itemCount: widget.images.length,
              onPageChanged: (index) => setState(() => _index = index),
              itemBuilder: (context, index) {
                return buildProductImage(
                  widget.images[index],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  useHtmlElement: false,
                  cacheWidth: productPhotoCachePx,
                  errorWidget: const Center(
                    child: Icon(
                      Icons.image_outlined,
                      size: 72,
                      color: AppColors.subText,
                    ),
                  ),
                );
              },
            ),
          ),
          if (widget.images.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (int i = 0; i < widget.images.length; i++) ...[
                  if (i > 0) const SizedBox(width: 6),
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i == _index
                          ? ProductDetailScreen._accent
                          : AppColors.subText,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
