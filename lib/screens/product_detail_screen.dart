import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/favorite_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_price.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class ProductDetailScreen extends StatelessWidget {
  const ProductDetailScreen({super.key});

  static const _productId = 'detail-royal-canin-indoor-27';
  static const _productTitle = 'Royal Canin Indoor 27';
  static const _productBrand = 'Royal Canin';
  static const _productWeight = '2 Kg';
  static const _productImagePath = 'assets/images/nd_kuzu_kisir.jpg';
  static const _productUnitPrice = 1249.0;
  static const _productOldPrice = 1470.0;
  static const _productDiscountPercent = 15;

  static const _leftBadges = <_SideBadge>[
    _SideBadge(
      label: 'Favorilere\nEkle',
      iconPath: 'assets/images/app_ikonlar/kalp.png',
      isFavoriteAction: true,
    ),
    _SideBadge(
      label: '4.8\n(256)',
      iconPath: 'assets/images/app_ikonlar/favori.png',
    ),
    _SideBadge(
      label: 'En Çok\nTercih Edilen',
      iconPath: '',
      rankNumber: '1.',
    ),
    _SideBadge(
      label: 'Akıllı\nÖneri',
      iconPath: 'assets/images/app_ikonlar/akilli_oneri.png',
    ),
  ];

  static const _rightBadges = <_FeatureBadge>[
    _FeatureBadge(
      label: 'Kısır Kediler\niçin',
      iconPath: 'assets/images/app_ikonlar/kisir_kedi.png',
      feature: 'Kısır',
      description:
          'Kısırlaştırılmış kedilerin kilo kontrolü ve idrar sağlığı için özel formüle edilmiştir.',
    ),
    _FeatureBadge(
      label: 'Böbrek Sağlığını\nDestekler',
      iconPath: 'assets/images/app_ikonlar/bobrek.png',
      feature: 'Böbrek',
      description:
          'Dengeli mineral seviyesiyle böbrek fonksiyonlarını desteklemeye yardımcı olur.',
    ),
    _FeatureBadge(
      label: 'Sindirim Sağlığını\nDestekler',
      iconPath: 'assets/images/app_ikonlar/sindirim.png',
      feature: 'Sindirim',
      description:
          'Yüksek sindirilebilir proteinlerle hassas mide ve bağırsak florasını korur.',
    ),
    _FeatureBadge(
      label: 'Somonlu\nFormül',
      iconPath: 'assets/images/app_ikonlar/somon.png',
      feature: 'Somon',
      description:
          'Somon içeriğiyle lezzetli bir protein kaynağı ve Omega-3 desteği sunar.',
    ),
    _FeatureBadge(
      label: 'Protein\nOranı',
      iconPath: '',
      feature: 'Protein',
      description:
          'Kas kütlesini korumaya yardımcı yüksek kaliteli protein oranı içerir.',
      valueText: '%32',
    ),
  ];

  static const _togetherProducts = <_RelatedProduct>[
    _RelatedProduct(
      title: 'Pro Plan Sterilised',
      brand: 'Pro Plan',
      weight: '1.5 Kg',
      price: '989 ₺',
      oldPrice: '1.150 ₺',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
    ),
    _RelatedProduct(
      title: 'Hill\'s Urinary Care',
      brand: 'Hill\'s',
      weight: '1.5 Kg',
      price: '1.120 ₺',
      oldPrice: '1.290 ₺',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
    ),
    _RelatedProduct(
      title: 'Royal Canin Digestive',
      brand: 'Royal Canin',
      weight: '2 Kg',
      price: '1.189 ₺',
      oldPrice: '1.380 ₺',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
    ),
  ];

  static const _similarProducts = <_RelatedProduct>[
    _RelatedProduct(
      title: 'Royal Canin Fit 32',
      brand: 'Royal Canin',
      weight: '2 Kg',
      price: '1.179 ₺',
      oldPrice: '1.360 ₺',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
    ),
    _RelatedProduct(
      title: 'Pro Plan Indoor',
      brand: 'Pro Plan',
      weight: '1.5 Kg',
      price: '945 ₺',
      oldPrice: '1.090 ₺',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
    ),
    _RelatedProduct(
      title: 'N&D Kuzu Kısır',
      brand: 'N&D',
      weight: '1.5 Kg',
      price: '1.049 ₺',
      oldPrice: '1.220 ₺',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
    ),
    _RelatedProduct(
      title: 'Hill\'s Adult Indoor',
      brand: 'Hill\'s',
      weight: '1.5 Kg',
      price: '1.099 ₺',
      oldPrice: '1.280 ₺',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
    ),
  ];

  static const double _sideColumnWidth = 50;
  static const double _sideCardHeight = 88;
  static const double _sideCardGap = 12;
  static const double _cardGap = 12;
  static const double _heroHeight = 488;
  static const double _sectionGap = 12;
  static const Color _accent = Color(0xFF6CB6FF);

  static BoxDecoration get _boxDecoration => BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: _accent, width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      );

  static FavoriteItem get _favoriteItem => FavoriteItem(
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

  static void _toggleFavorite(BuildContext context) {
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

  static void _openFeatureProducts(
    BuildContext context, {
    String? feature,
    bool openFeatureSheet = false,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: 'cat',
          initialFeature: feature,
          openFeatureSheet: openFeatureSheet,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.surface,
        header: const AppPageHeader(
          title: 'Ürün Detay',
        ),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          child: Column(
            children: [
              SizedBox(
                height: _heroHeight,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildSideColumn(context, _leftBadges),
                    const SizedBox(width: _cardGap),
                    Expanded(child: _buildMainCard(context)),
                    const SizedBox(width: _cardGap),
                    _buildSideColumn(
                      context,
                      [
                        for (final b in _rightBadges)
                          _SideBadge(
                            label: b.label,
                            iconPath: b.iconPath,
                            feature: b.feature,
                            rankNumber: b.valueText,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: _sectionGap),
              _buildFeatureExplanations(context),
              const SizedBox(height: _sectionGap),
              _buildDescriptionBox(),
              const SizedBox(height: _sectionGap),
              _buildTogetherBox(context),
              const SizedBox(height: _sectionGap),
              _buildSimilarBox(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideColumn(BuildContext context, List<_SideBadge> badges) {
    return SizedBox(
      width: _sideColumnWidth,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (int i = 0; i < badges.length; i++) ...[
            if (i > 0) const SizedBox(height: _sideCardGap),
            _buildSideCard(context, badges[i]),
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
      height: _sideCardHeight,
      padding: const EdgeInsets.fromLTRB(3, 12, 3, 10),
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
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: badge.rankNumber != null
                ? Center(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        badge.rankNumber!,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: badge.rankNumber!.startsWith('%') ? 16 : 22,
                          fontWeight: FontWeight.w900,
                          height: 1,
                        ),
                      ),
                    ),
                  )
                : Image.asset(
                    badge.iconPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.pets_rounded,
                      size: 24,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 28,
            child: Text(
              badge.label,
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 7,
                fontWeight: FontWeight.w700,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );

    if (badge.feature == null) return card;

    return GestureDetector(
      onTap: () => _openFeatureProducts(context, feature: badge.feature),
      behavior: HitTestBehavior.opaque,
      child: card,
    );
  }

  Widget _buildFavoriteSideCard(BuildContext context) {
    return ListenableBuilder(
      listenable: FavoriteStore.instance,
      builder: (context, _) {
        final isFavorite =
            FavoriteStore.instance.isFavorite(_productId);

        return GestureDetector(
          onTap: () => _toggleFavorite(context),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: double.infinity,
            height: _sideCardHeight,
            padding: const EdgeInsets.fromLTRB(3, 12, 3, 10),
            decoration: BoxDecoration(
              color: isFavorite
                  ? AppColors.error.withValues(alpha: 0.08)
                  : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isFavorite ? AppColors.error : _accent,
                width: isFavorite ? 1.4 : 1,
              ),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x0D000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: isFavorite
                        ? AppColors.error.withValues(alpha: 0.12)
                        : AppColors.selected,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isFavorite ? AppColors.error : AppColors.primary,
                      width: 1.2,
                    ),
                  ),
                  child: Icon(
                    isFavorite
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: 16,
                    color: isFavorite ? AppColors.error : AppColors.primary,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  height: 28,
                  child: Text(
                    isFavorite ? 'Favorilerde' : 'Favorilere\nEkle',
                    textAlign: TextAlign.center,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: isFavorite ? AppColors.error : AppColors.text,
                      fontSize: 7,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
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
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildGallery()),
          const SizedBox(height: 10),
          _buildTitleBlock(context),
          const SizedBox(height: 8),
          _buildMetaRow(),
          const SizedBox(height: 10),
          const _DashedDivider(),
          const SizedBox(height: 10),
          _buildPriceRow(context),
        ],
      ),
    );
  }

  Widget _buildGallery() {
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 6, 16),
            child: Image.asset(
              'assets/images/nd_kuzu_kisir.jpg',
              fit: BoxFit.contain,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.image_outlined,
                size: 72,
                color: AppColors.subText,
              ),
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
              color: AppColors.warning,
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
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildDot(true),
              const SizedBox(width: 6),
              _buildDot(false),
              const SizedBox(width: 6),
              _buildDot(false),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTitleBlock(BuildContext context) {
    return GestureDetector(
      onTap: () => _openFeatureProducts(context, openFeatureSheet: true),
      behavior: HitTestBehavior.opaque,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Royal Canin Indoor 27',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 17,
              fontWeight: FontWeight.w800,
              height: 1.2,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Royal Canin',
            style: TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetaRow() {
    return Row(
      children: [
        const Icon(
          Icons.monitor_weight_outlined,
          size: 17,
          color: AppColors.primary,
        ),
        const SizedBox(width: 5),
        const Text(
          '2 Kg',
          style: TextStyle(
            color: AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
        Container(
          width: 1,
          height: 14,
          margin: const EdgeInsets.symmetric(horizontal: 10),
          color: _accent,
        ),
        const Icon(
          Icons.calendar_today_outlined,
          size: 14,
          color: AppColors.primary,
        ),
        const SizedBox(width: 5),
        const Flexible(
          child: Text(
            'SKT: 12.08.2026',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '1.249 ₺',
                      style: TextStyle(
                        color: _accent,
                        fontSize: 21,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                    SizedBox(width: 5),
                    Padding(
                      padding: EdgeInsets.only(bottom: 2),
                      child: Text(
                        '1.470 ₺',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.lineThrough,
                          decorationColor: AppColors.subText,
                          height: 1,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
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
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const CartScreen()),
            );
          },
          child: Container(
            height: 30,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              color: _accent,
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.shopping_cart_rounded,
                  size: 12,
                  color: AppColors.surface,
                ),
                SizedBox(width: 4),
                Text(
                  'Sepete Ekle',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFeatureExplanations(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: _boxDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ürün Özellikleri',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 10),
          for (int i = 0; i < _rightBadges.length; i++) ...[
            if (i > 0) const SizedBox(height: _sectionGap),
            _buildFeatureRow(context, _rightBadges[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildFeatureRow(BuildContext context, _FeatureBadge badge) {
    return GestureDetector(
      onTap: () => _openFeatureProducts(context, feature: badge.feature),
      behavior: HitTestBehavior.opaque,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: _accent),
            ),
            child: badge.valueText != null
                ? Center(
                    child: Text(
                      badge.valueText!,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  )
                : Image.asset(
                    badge.iconPath,
                    fit: BoxFit.contain,
                    filterQuality: FilterQuality.high,
                    errorBuilder: (context, error, stackTrace) => const Icon(
                      Icons.pets_rounded,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              badge.description,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDescriptionBox() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: _boxDecoration,
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ürün Açıklaması',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Royal Canin Indoor 27, evde yaşayan kısırlaştırılmış kedilerin '
            'enerji ihtiyacına göre dengelenmiş bir mamadır. Yüksek sindirilebilir '
            'proteinler, tüy yumağı kontrolü ve kilo yönetimine yardımcı formülüyle '
            'günlük beslenmede dengeli bir tercih sunar. Somon içerikli lezzetli '
            'tarif, kedinizin damak tadına uygun şekilde hazırlanmıştır.',
            style: TextStyle(
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

  Widget _buildTogetherBox(BuildContext context) {
    return Container(
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
                for (int i = 0; i < _togetherProducts.length; i++) ...[
                  if (i > 0) const SizedBox(width: _cardGap),
                  Expanded(
                    child: _buildCompactProductCard(
                      context,
                      _togetherProducts[i],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimilarBox(BuildContext context) {
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
          for (int i = 0; i < _similarProducts.length; i++) ...[
            if (i > 0) const SizedBox(height: _sectionGap),
            _buildSimilarProductRow(context, _similarProducts[i]),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactProductCard(
    BuildContext context,
    _RelatedProduct product,
  ) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
        );
      },
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
              child: Center(
                child: Image.asset(
                  product.imagePath,
                  fit: BoxFit.contain,
                  filterQuality: FilterQuality.high,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_outlined,
                    color: AppColors.subText,
                    size: 36,
                  ),
                ),
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
                      color: _accent,
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
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
        );
      },
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
            Container(
              width: 58,
              height: 58,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                product.imagePath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.image_outlined,
                  color: AppColors.subText,
                  size: 28,
                ),
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
                          color: _accent,
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

  Widget _buildDot(bool isActive) {
    return Container(
      width: 7,
      height: 7,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isActive ? AppColors.subText : _accent,
      ),
    );
  }

  void _addRelatedToCart(BuildContext context, _RelatedProduct product) {
    final price = parseTurkishPrice(product.price) ?? 0;
    final oldPrice = parseTurkishPrice(product.oldPrice) ?? price;

    CartStore.instance.addItem(
      id: 'related-${product.title}-${product.weight}',
      imagePath: product.imagePath,
      title: '${product.title} ${product.weight}',
      unitPrice: price,
      oldPrice: oldPrice,
    );
    _showAddedToCartDialog(context, product.title);
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

class _SideBadge {
  const _SideBadge({
    required this.label,
    required this.iconPath,
    this.feature,
    this.isFavoriteAction = false,
    this.rankNumber,
  });

  final String label;
  final String iconPath;
  final String? feature;
  final bool isFavoriteAction;
  final String? rankNumber;
}

class _FeatureBadge {
  const _FeatureBadge({
    required this.label,
    required this.iconPath,
    required this.feature,
    required this.description,
    this.valueText,
  });

  final String label;
  final String iconPath;
  final String feature;
  final String description;
  final String? valueText;
}

class _RelatedProduct {
  const _RelatedProduct({
    required this.title,
    required this.brand,
    required this.weight,
    required this.price,
    required this.oldPrice,
    required this.imagePath,
  });

  final String title;
  final String brand;
  final String weight;
  final String price;
  final String oldPrice;
  final String imagePath;
}

class _DashedDivider extends StatelessWidget {
  const _DashedDivider();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashGap = 4.0;
        final count =
            (constraints.maxWidth / (dashWidth + dashGap)).floor().clamp(1, 200);

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
