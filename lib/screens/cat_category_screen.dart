import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class CatCategoryScreen extends StatelessWidget {
  const CatCategoryScreen({super.key});

  static void _openProducts(BuildContext context, String subCategory) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: 'cat',
          initialSubCategory: subCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilterSubpageLayout(
      title: 'Kedi',
      items: [
        FilterSubpageItem(
          title: 'Mama',
          subtitle: 'Kuru mama, yaş mama ve özel diyet',
          imagePath: 'assets/images/petmarket_mama.png',
          onTap: () => _openProducts(context, 'Mama'),
        ),
        FilterSubpageItem(
          title: 'Yavru',
          subtitle: 'Yavru kedi mamaları ve ürünleri',
          imagePath: 'assets/images/petmarket_yavru.png',
          onTap: () => _openProducts(context, 'Yavru'),
        ),
        FilterSubpageItem(
          title: 'Kum',
          subtitle: 'Topaklanan ve kokusuz kumlar',
          imagePath: 'assets/images/petmarket_kum.png',
          onTap: () => _openProducts(context, 'Kum'),
        ),
        FilterSubpageItem(
          title: 'Ödül',
          subtitle: 'Eğitim ve ödül atıştırmalıkları',
          imagePath: 'assets/images/petmarket_odul.png',
          onTap: () => _openProducts(context, 'Ödül'),
        ),
        FilterSubpageItem(
          title: 'Bakım',
          subtitle: 'Şampuan, temizlik ve hijyen',
          imagePath: 'assets/images/petmarket_bakim.png',
          onTap: () => _openProducts(context, 'Bakım'),
        ),
        FilterSubpageItem(
          title: 'Oyuncak',
          subtitle: 'Tüy, top ve interaktif oyuncaklar',
          imagePath: 'assets/images/petmarket_oyun.png',
          onTap: () => _openProducts(context, 'Oyuncak'),
        ),
        FilterSubpageItem(
          title: 'Sağlık',
          subtitle: 'Vitamin ve sağlık destekleri',
          imagePath: 'assets/images/petmarket_saglik.png',
          onTap: () => _openProducts(context, 'Sağlık'),
        ),
        FilterSubpageItem(
          title: 'Taşıma',
          subtitle: 'Taşıma çantası ve ekipmanları',
          imagePath: 'assets/images/petmarket_tasima.png',
          onTap: () => _openProducts(context, 'Taşıma'),
        ),
      ],
    );
  }
}
