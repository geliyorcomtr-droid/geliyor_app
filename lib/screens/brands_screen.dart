import 'package:flutter/material.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class BrandsScreen extends StatelessWidget {
  const BrandsScreen({super.key});

  static const int _gridColumns = 3;

  static void _openProducts(BuildContext context, AppBrand brand) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: 'cat',
          initialBrand: brand.name,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilterSubpageLayout(
      title: 'Markaya Göre Alışveriş',
      content: StreamBuilder<List<AppBrand>>(
        stream: BrandRepository.instance.watchAll(activeOnly: true),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Text(
                'Markalar yüklenemedi.',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final brands = snapshot.data!;
          if (brands.isEmpty) {
            return const Center(
              child: Text(
                'Henüz marka eklenmedi.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            );
          }

          return GridView.builder(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.all(12),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _gridColumns,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1,
            ),
            itemCount: brands.length,
            itemBuilder: (context, index) {
              return _buildBrandTile(context, brands[index]);
            },
          );
        },
      ),
    );
  }

  Widget _buildBrandTile(BuildContext context, AppBrand brand) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProducts(context, brand),
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          padding: const EdgeInsets.all(8),
          child: _brandImage(brand),
        ),
      ),
    );
  }

  Widget _brandImage(AppBrand brand) {
    final fallback = Center(
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
    if (brand.imageUrl.isNotEmpty) {
      return Image.network(
        brand.imageUrl,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    if (brand.assetPath.isNotEmpty) {
      return Image.asset(
        brand.assetPath,
        fit: BoxFit.contain,
        errorBuilder: (_, _, _) => fallback,
      );
    }
    return fallback;
  }
}
