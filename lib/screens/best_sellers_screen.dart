import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class BestSellersScreen extends StatelessWidget {
  const BestSellersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FilterSubpageLayout(
      title: 'Çok Satanlar',
      items: [
        FilterSubpageItem(
          title: 'En Çok Satan Kedi Ürünleri',
          subtitle: 'Kediler için en popüler seçimler',
          imagePath: 'assets/images/urunler_kedi.png',
          badgeIcon: Icons.star_rounded,
          badgeIconColor: AppColors.warning,
          onTap: () => _openProducts(context, 'cat'),
        ),
        FilterSubpageItem(
          title: 'En Çok Satan Köpek Ürünleri',
          subtitle: 'Köpekler için en popüler seçimler',
          imagePath: 'assets/images/urunler_kopek.png',
          badgeIcon: Icons.star_rounded,
          badgeIconColor: AppColors.warning,
          onTap: () => _openProducts(context, 'dog'),
        ),
        FilterSubpageItem(
          title: 'Popüler Mamalar',
          subtitle: 'En çok tercih edilen mama markaları',
          imagePath: 'assets/images/petmarket_mama.png',
          badgeIcon: Icons.star_rounded,
          badgeIconColor: AppColors.warning,
          onTap: () => _openProducts(context, 'cat', subCategory: 'Mama'),
        ),
        FilterSubpageItem(
          title: 'Popüler Kum ve Bakım',
          subtitle: 'Kum, şampuan ve bakım ürünleri',
          imagePath: 'assets/images/petmarket_kum.png',
          badgeIcon: Icons.star_rounded,
          badgeIconColor: AppColors.warning,
          onTap: () => _openProducts(context, 'cat', subCategory: 'Kum'),
        ),
        FilterSubpageItem(
          title: 'Haftanın Yıldızları',
          subtitle: 'Bu hafta en çok satan ürünler',
          imagePath: 'assets/images/cok_satan_urunler.png',
          badgeIcon: Icons.star_rounded,
          badgeIconColor: AppColors.warning,
          onTap: () => _openProducts(context, 'cat'),
        ),
        FilterSubpageItem(
          title: 'Yeni Favoriler',
          subtitle: 'Yeni eklenen popüler ürünler',
          icon: Icons.favorite_rounded,
          iconColor: AppColors.error,
          badgeIcon: Icons.star_rounded,
          badgeIconColor: AppColors.warning,
          onTap: () => _openProducts(context, 'cat'),
        ),
      ],
    );
  }

  static void _openProducts(
    BuildContext context,
    String mainCategory, {
    String? subCategory,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: mainCategory,
          initialSubCategory: subCategory,
        ),
      ),
    );
  }
}
