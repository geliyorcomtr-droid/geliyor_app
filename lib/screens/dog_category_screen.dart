import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/category_repository.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/category_icon.dart';
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
    final repo = CategoryRepository.instance;
    return StreamBuilder<List<AdminMainCategory>>(
      stream: repo.watchAll(),
      initialData: repo.ready ? repo.cached : null,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return FilterSubpageLayout(
            title: 'Köpek',
            accent: AppColors.success,
            content: const Center(child: CircularProgressIndicator()),
          );
        }
        final subs = _dogSubs(snapshot.data!);
        if (subs.isNotEmpty) {
          return FilterSubpageLayout(
            title: 'Köpek',
            accent: AppColors.success,
            items: [
              for (final sub in subs)
                FilterSubpageItem(
                  title: sub.title,
                  subtitle: sub.subtitle.trim().isEmpty
                      ? sub.title
                      : sub.subtitle,
                  imagePath: categoryIconPath(
                    mainId: 'dog',
                    title: sub.title,
                    imageUrl: sub.imageUrl,
                  ),
                  onTap: () => _openProducts(context, sub.title),
                ),
            ],
          );
        }
        return _fallback(context);
      },
    );
  }

  List<AdminSubCategory> _dogSubs(List<AdminMainCategory>? mains) {
    if (mains == null) return const [];
    for (final main in mains) {
      if (main.id != 'dog') continue;
      return [
        for (final sub in main.subcategories)
          if (sub.title.trim().isNotEmpty) sub,
      ];
    }
    return const [];
  }

  Widget _fallback(BuildContext context) {
    return FilterSubpageLayout(
      title: 'Köpek',
      accent: AppColors.success,
      items: [
        FilterSubpageItem(
          title: 'Yetişkin',
          subtitle: 'Yetişkin köpek mamaları ve ürünleri',
          imagePath: 'assets/images/petmarket_mama.png',
          onTap: () => _openProducts(context, 'Yetişkin'),
        ),
        FilterSubpageItem(
          title: 'Yavru',
          subtitle: 'Yavru köpek mamaları ve ürünleri',
          imagePath: 'assets/images/petmarket_kopek_yavru.png',
          onTap: () => _openProducts(context, 'Yavru'),
        ),
        FilterSubpageItem(
          title: 'Mini Irk',
          subtitle: 'Mini ırk yetişkin köpek ürünleri',
          imagePath: 'assets/images/petmarket_mini_irk.png',
          onTap: () => _openProducts(context, 'Mini Irk'),
        ),
        FilterSubpageItem(
          title: 'Mini Irk Yavru',
          subtitle: 'Mini ırk yavru köpek mamaları ve ürünleri',
          imagePath: 'assets/images/petmarket_kopek_yavru.png',
          onTap: () => _openProducts(context, 'Mini Irk Yavru'),
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
