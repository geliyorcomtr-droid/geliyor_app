import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class DogCategoryScreen extends StatelessWidget {
  const DogCategoryScreen({super.key});

  static void _openProducts(BuildContext context, String subCategory) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: 'dog',
          initialSubCategory: subCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilterSubpageLayout(
      title: 'Köpek',
      items: [
        FilterSubpageItem(
          title: 'Mama',
          subtitle: 'Kuru mama, yaş mama ve özel diyet',
          imagePath: 'assets/images/petmarket_mama.png',
          onTap: () => _openProducts(context, 'Mama'),
        ),
        FilterSubpageItem(
          title: 'Yavru',
          subtitle: 'Yavru köpek mamaları ve ürünleri',
          imagePath: 'assets/images/petmarket_kopek_yavru.png',
          onTap: () => _openProducts(context, 'Yavru'),
        ),
        FilterSubpageItem(
          title: 'Mini Irk',
          subtitle: 'Küçük ırk köpek ürünleri',
          imagePath: 'assets/images/petmarket_mini_irk.png',
          onTap: () => _openProducts(context, 'Mini Irk'),
        ),
        FilterSubpageItem(
          title: 'Ödül',
          subtitle: 'Eğitim ve ödül atıştırmalıkları',
          imagePath: 'assets/images/petmarket_odul.png',
          onTap: () => _openProducts(context, 'Ödül'),
        ),
      ],
    );
  }
}
