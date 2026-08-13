import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  static const int _gridColumns = 3;

  static const List<_BrandItem> _brands = [
    _BrandItem(name: 'Royal Canin', logoPath: 'assets/images/brands/royal_canin.png'),
    _BrandItem(name: "Hill's", logoPath: 'assets/images/brands/hills.png'),
    _BrandItem(name: 'N&D', logoPath: 'assets/images/brands/nd.png'),
    _BrandItem(name: 'Advance', logoPath: 'assets/images/brands/advance.png'),
    _BrandItem(name: 'Pro Plan', logoPath: 'assets/images/brands/proplan.png'),
    _BrandItem(name: 'Purina ONE', logoPath: 'assets/images/brands/purina_one.png'),
    _BrandItem(name: 'Acana', logoPath: 'assets/images/brands/acana.png'),
    _BrandItem(name: 'GimCat', logoPath: 'assets/images/brands/gimcat.png'),
    _BrandItem(name: 'Wanpy', logoPath: 'assets/images/brands/wanpy.png'),
    _BrandItem(name: 'Felix', logoPath: 'assets/images/brands/felix.png'),
    _BrandItem(name: 'Dreamies', logoPath: 'assets/images/brands/dreamies.png'),
    _BrandItem(name: 'Cat Chow', logoPath: 'assets/images/brands/catchow.png'),
    _BrandItem(name: 'Dog Chow', logoPath: 'assets/images/brands/dogchow.png'),
    _BrandItem(name: 'Reflex', logoPath: 'assets/images/brands/reflex.png'),
    _BrandItem(name: 'Proline', logoPath: 'assets/images/brands/proline.png'),
  ];

  static void _openProducts(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const PetMarketProductsScreen(initialMainCategory: 'cat'),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilterSubpageLayout(
      title: 'Markaya Göre Alışveriş',
      content: GridView.builder(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _gridColumns,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1,
        ),
        itemCount: _brands.length,
        itemBuilder: (context, index) {
          return _buildBrandTile(context, _brands[index]);
        },
      ),
    );
  }

  Widget _buildBrandTile(BuildContext context, _BrandItem brand) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProducts(context),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(8),
          child: Image.asset(
            brand.logoPath,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Center(
                child: Text(
                  brand.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _BrandItem {
  const _BrandItem({
    required this.name,
    required this.logoPath,
  });

  final String name;
  final String logoPath;
}
