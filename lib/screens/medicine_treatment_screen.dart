import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/cart_product_card.dart';

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
  final Map<String, int> _quantities = {};

  static const _categories = <_CategoryData>[
    _CategoryData(
      id: _MedCategory.vitamins,
      title: 'Vitaminler',
      subtitle: 'Bağışıklık ve enerji desteği',
      imagePath: 'assets/images/ilac_icon_vitamin.png',
      accent: AppColors.primary,
    ),
    _CategoryData(
      id: _MedCategory.supplements,
      title: 'Takviye Gıdalar',
      subtitle: 'Ek besin ve destek ürünleri',
      imagePath: 'assets/images/ilac_icon_takviye.png',
      accent: AppColors.success,
    ),
    _CategoryData(
      id: _MedCategory.malts,
      title: 'Maltlar',
      subtitle: 'Tüy yumağı ve sindirim',
      imagePath: 'assets/images/ilac_icon_malt.png',
      accent: Color(0xFF1E90FF),
    ),
  ];

  static const _vitamins = <_MedProduct>[
    _MedProduct(
      id: 'petyvital-multivitamin',
      brand: 'PetyVital',
      name: 'Multivitamin Şurup',
      weight: '100 ml',
      oldPrice: 359,
      price: 299,
      imagePath: 'assets/images/ilac_icon_vitamin.png',
    ),
    _MedProduct(
      id: 'petyvital-omega',
      brand: 'PetyVital',
      name: 'Omega Softgel',
      weight: '60 kapsül',
      oldPrice: 419,
      price: 349,
      imagePath: 'assets/images/ilac_icon_vitamin.png',
    ),
  ];

  static const _supplements = <_MedProduct>[
    _MedProduct(
      id: 'petybio-probiotik',
      brand: 'PetyBio',
      name: 'Probiyotik Destek',
      weight: '30 tablet',
      oldPrice: 309,
      price: 259,
      imagePath: 'assets/images/ilac_icon_takviye.png',
    ),
    _MedProduct(
      id: 'petyjoint-care',
      brand: 'PetyJoint',
      name: 'Care Tablet',
      weight: '45 tablet',
      oldPrice: 329,
      price: 279,
      imagePath: 'assets/images/ilac_icon_takviye.png',
    ),
  ];

  static const _malts = <_MedProduct>[
    _MedProduct(
      id: 'petymalt-classic',
      brand: 'PetyMalt',
      name: 'Classic Pasta',
      weight: '100 g',
      oldPrice: 229,
      price: 189,
      imagePath: 'assets/images/ilac_icon_malt.png',
    ),
    _MedProduct(
      id: 'petymalt-plus',
      brand: 'PetyMalt',
      name: 'Plus Malt Pasta',
      weight: '120 g',
      oldPrice: 259,
      price: 219,
      imagePath: 'assets/images/ilac_icon_malt.png',
    ),
  ];

  List<_MedProduct> get _products {
    switch (_selected) {
      case _MedCategory.vitamins:
        return _vitamins;
      case _MedCategory.supplements:
        return _supplements;
      case _MedCategory.malts:
        return _malts;
    }
  }

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

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(context),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Misket’in sağlığını desteklemek için ihtiyacınız olan ürünler ve bilgiler burada.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              _buildBanner(),
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildCategoryCards(),
              const SizedBox(height: 12),
              _buildSectionHeader(),
              const SizedBox(height: 8),
              _buildProductRow(),
              const SizedBox(height: 10),
              _buildTipsBanner(),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(),
      ),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/ilac_tedavi_banner.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            color: AppColors.selected,
            alignment: Alignment.center,
            child: const Icon(
              Icons.medical_services_outlined,
              color: AppColors.primary,
              size: 36,
            ),
          );
        },
      ),
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
        ],
      ),
    );
  }

  Widget _buildCategoryCards() {
    return SizedBox(
      height: 108,
      child: Row(
        children: [
          for (int i = 0; i < _categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _buildCategoryCard(_categories[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_CategoryData cat) {
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
                    child: Image.asset(
                      cat.imagePath,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.medical_services_outlined,
                          color: cat.accent,
                          size: 32,
                        );
                      },
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
    return Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _sectionTitle,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
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
        ),
        const Spacer(),
        const Text(
          'Tümünü Gör',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Icon(
          Icons.chevron_right_rounded,
          color: AppColors.primary,
          size: 16,
        ),
      ],
    );
  }

  Widget _buildProductRow() {
    final products = _products;
    return Column(
      children: [
        _buildProductCard(products[0]),
        const SizedBox(height: 10),
        _buildProductCard(products[1]),
      ],
    );
  }

  Widget _buildProductCard(_MedProduct product) {
    final qty = _quantities[product.id] ?? 1;
    final discount = product.oldPrice <= 0
        ? 0
        : (((product.oldPrice - product.price) / product.oldPrice) * 100)
            .round();

    return CartProductCard(
      item: CartItem(
        id: product.id,
        imagePath: product.imagePath,
        title: product.name,
        brand: product.brand,
        unitPrice: product.price,
        oldPrice: product.oldPrice,
        discountPercent: discount,
        weight: product.weight,
        quantity: qty,
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
        );
      },
      onQuantityChanged: (next) {
        setState(() => _quantities[product.id] = next);
      },
      onAddToCart: () {
        final count = _quantities[product.id] ?? 1;
        for (var i = 0; i < count; i++) {
          CartStore.instance.addItem(
            id: product.id,
            imagePath: product.imagePath,
            title: '${product.brand} ${product.name} ${product.weight}',
            unitPrice: product.price,
            oldPrice: product.oldPrice,
            weight: product.weight,
          );
        }
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const CartScreen()),
        );
      },
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
}

class _CategoryData {
  const _CategoryData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.imagePath,
    required this.accent,
  });

  final _MedCategory id;
  final String title;
  final String subtitle;
  final String imagePath;
  final Color accent;
}

class _MedProduct {
  const _MedProduct({
    required this.id,
    required this.brand,
    required this.name,
    required this.weight,
    required this.oldPrice,
    required this.price,
    required this.imagePath,
  });

  final String id;
  final String brand;
  final String name;
  final String weight;
  final double oldPrice;
  final double price;
  final String imagePath;

  String get priceLabel => '₺${price.toStringAsFixed(0)},00';
  String get oldPriceLabel => '₺${oldPrice.toStringAsFixed(0)},00';
}
