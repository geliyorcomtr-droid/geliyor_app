import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/filter_screen.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_price.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

enum _PetType { cat, dog }

class SpecialFoodsScreen extends StatefulWidget {
  const SpecialFoodsScreen({super.key});

  @override
  State<SpecialFoodsScreen> createState() => _SpecialFoodsScreenState();
}

class _SpecialFoodsScreenState extends State<SpecialFoodsScreen> {
  _PetType _petType = _PetType.dog;
  String _selectedProblemId = 'diyabet';
  final _searchController = TextEditingController();

  static const _problems = <_HealthProblem>[
    _HealthProblem(
      id: 'diyabet',
      title: 'Diyabet',
      iconPath: 'assets/images/app_ikonlar/diyabet.png',
    ),
    _HealthProblem(
      id: 'bobrek',
      title: 'Böbrek',
      iconPath: 'assets/images/app_ikonlar/bobrek.png',
    ),
    _HealthProblem(
      id: 'tuy',
      title: 'Tüy',
      iconPath: 'assets/images/app_ikonlar/tuy_deri.png',
    ),
    _HealthProblem(
      id: 'eklem',
      title: 'Eklem',
      iconPath: 'assets/images/app_ikonlar/eklem.png',
    ),
    _HealthProblem(
      id: 'sindirim',
      title: 'Sindirim',
      iconPath: 'assets/images/app_ikonlar/sindirim.png',
    ),
    _HealthProblem(
      id: 'bagisiklik',
      title: 'Bağışıklık',
      iconPath: 'assets/images/app_ikonlar/bagisiklik.png',
    ),
    _HealthProblem(
      id: 'idrar',
      title: 'İdrar',
      iconPath: 'assets/images/app_ikonlar/idrar.png',
    ),
    _HealthProblem(
      id: 'kalp',
      title: 'Kalp',
      iconPath: 'assets/images/app_ikonlar/kalp.png',
    ),
    _HealthProblem(
      id: 'dis',
      title: 'Diş',
      iconPath: 'assets/images/app_ikonlar/dis.png',
    ),
    _HealthProblem(
      id: 'karaciger',
      title: 'Karaciğer',
      iconPath: 'assets/images/app_ikonlar/karaciger.png',
    ),
    _HealthProblem(
      id: 'hipo',
      title: 'Hipo',
      iconPath: 'assets/images/app_ikonlar/dogal_icerik.png',
    ),
    _HealthProblem(
      id: 'kilo',
      title: 'Kilo',
      iconPath: 'assets/images/app_ikonlar/kilo_kontrol.png',
    ),
  ];

  _HealthProblem get _selectedProblem =>
      _problems.firstWhere((e) => e.id == _selectedProblemId);

  List<_SpecialProduct> get _products {
    final isCat = _petType == _PetType.cat;
    final petLabel = isCat ? 'Kedi' : 'Köpek';
    final tag = _selectedProblem.title;

    return [
      _SpecialProduct(
        id: 'rc-$_selectedProblemId-$petLabel',
        brand: 'Royal Canin',
        name: '$tag Support $petLabel',
        tag: tag,
        weight: isCat ? '2 kg' : '2.5 kg',
        price: isCat ? 999 : 1149,
        imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      ),
      _SpecialProduct(
        id: 'hills-$_selectedProblemId-$petLabel',
        brand: "Hill's Prescription",
        name: '$tag Care',
        tag: 'Veteriner Önerisi',
        weight: isCat ? '1.5 kg' : '1.5 kg',
        price: isCat ? 889 : 1020,
        imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      ),
      _SpecialProduct(
        id: 'proplan-$_selectedProblemId-$petLabel',
        brand: 'Pro Plan Veterinary',
        name: '$tag Formula',
        tag: tag,
        weight: isCat ? '1.5 kg' : '2 kg',
        price: isCat ? 849 : 965,
        imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      ),
    ];
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final products = _products;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.surface,
        header: _buildHeader(context),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Veteriner gözetiminde sağlık desteği için formüle edilmiş mamalar.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              _buildPetTypeSelector(),
              const SizedBox(height: 10),
              _buildSearchRow(),
              const SizedBox(height: 12),
              const Text(
                'Sağlık Problemi Seç',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              _buildProblemGrid(),
              const SizedBox(height: 12),
              _buildProductsHeader(),
              const SizedBox(height: 8),
              _buildProductGrid(products),
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
          IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints.tightFor(width: 42, height: 42),
            icon: Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: AppColors.primary,
                size: 16,
              ),
            ),
          ),
          Expanded(
            child: IgnorePointer(
              child: Text(
                'Özel Sağlık Mamaları',
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

  Widget _buildPetTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _petTypeChip(
            type: _PetType.cat,
            label: 'Kedi',
            icon: Icons.pets_rounded,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _petTypeChip(
            type: _PetType.dog,
            label: 'Köpek',
            icon: Icons.pets_rounded,
          ),
        ),
      ],
    );
  }

  Widget _petTypeChip({
    required _PetType type,
    required String label,
    required IconData icon,
  }) {
    final selected = _petType == type;
    return GestureDetector(
      onTap: () => setState(() => _petType = type),
      child: Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 0.8 : 1,
          ),
        ),
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    icon,
                    color: selected ? AppColors.primary : AppColors.subText,
                    size: 16,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
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
                      hintText: 'Sağlık problemi veya mama ara...',
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
          ),
        ),
        const SizedBox(width: 8),
        AppPressableButton(
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const FilterScreen()),
            );
          },
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          borderRadius: 999,
          backgroundColor: AppColors.primary,
          pressedBackgroundColor: AppColors.primary,
          foregroundColor: AppColors.surface,
          pressedForegroundColor: AppColors.surface,
          borderColor: AppColors.primary,
          pressedBorderColor: AppColors.primary,
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 15),
              SizedBox(width: 4),
              Text('Filtrele', style: TextStyle(fontSize: 11)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProblemGrid() {
    const columns = 6;
    const gap = 4.0;
    final rows = <Widget>[];

    for (int start = 0; start < _problems.length; start += columns) {
      if (rows.isNotEmpty) rows.add(const SizedBox(height: gap));
      final end = (start + columns).clamp(0, _problems.length);
      rows.add(
        Row(
          children: [
            for (int i = 0; i < columns; i++) ...[
              if (i > 0) const SizedBox(width: gap),
              Expanded(
                child: start + i < end
                    ? _buildProblemCard(_problems[start + i])
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
    }

    return Column(children: rows);
  }

  Widget _buildProblemCard(_HealthProblem problem) {
    final selected = _selectedProblemId == problem.id;
    return GestureDetector(
      onTap: () => setState(() => _selectedProblemId = problem.id),
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(2, 3, 2, 3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 0.8 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(1, 1, 1, 1),
                    child: Image.asset(
                      problem.iconPath,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.health_and_safety_outlined,
                          color: AppColors.primary,
                          size: 22,
                        );
                      },
                    ),
                  ),
                ),
                Text(
                  problem.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ],
            ),
            if (selected)
              Positioned(
                right: 0,
                top: 0,
                child: Container(
                  width: 11,
                  height: 11,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 8,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductsHeader() {
    final title = _selectedProblem.title.replaceAll('\n', ' ');
    return Row(
      children: [
        const Icon(
          Icons.verified_rounded,
          color: AppColors.success,
          size: 16,
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            '$title İçin Önerilen Mamalar',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const Text(
          'Tümü',
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

  Widget _buildProductGrid(List<_SpecialProduct> products) {
    return SizedBox(
      height: 148,
      child: Row(
        children: [
          for (int i = 0; i < products.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _buildProductCard(products[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildProductCard(_SpecialProduct product) {
    final oldPrice = product.price * 1.15;

    return GestureDetector(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
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
              product.name,
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
                    formatProductPrice(product.price),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _addToCart(product, oldPrice),
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
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

  void _addToCart(_SpecialProduct product, double oldPrice) {
    CartStore.instance.addItem(
      id: product.id,
      imagePath: product.imagePath,
      title: '${product.brand} ${product.name} ${product.weight}',
      unitPrice: product.price,
      oldPrice: oldPrice,
    );
    _showAddedToCartDialog(product.name);
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

class _HealthProblem {
  const _HealthProblem({
    required this.id,
    required this.title,
    required this.iconPath,
  });

  final String id;
  final String title;
  final String iconPath;
}

class _SpecialProduct {
  const _SpecialProduct({
    required this.id,
    required this.brand,
    required this.name,
    required this.tag,
    required this.weight,
    required this.price,
    required this.imagePath,
  });

  final String id;
  final String brand;
  final String name;
  final String tag;
  final String weight;
  final double price;
  final String imagePath;
}
