import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class RodentCategoryScreen extends StatelessWidget {
  const RodentCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FilterSubpageLayout(
      title: 'Kemirgen',
      accent: AppColors.success,
      items: [
        FilterSubpageItem(
          title: 'Kemirgen Ürünleri',
          subtitle: 'Mama, yem ve yaşam alanı ürünleri',
          imagePath: 'assets/images/urunler_kemirgen.png',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PetMarketProductsScreen(
                  initialMainCategory: 'rodent',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
