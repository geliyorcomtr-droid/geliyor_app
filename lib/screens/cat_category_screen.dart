import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/category_repository.dart';
import 'package:geliyor_app/data/health_product_groups.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/category_icon.dart';
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
    final repo = CategoryRepository.instance;
    return StreamBuilder<List<AdminMainCategory>>(
      stream: repo.watchAll(),
      initialData: repo.ready ? repo.cached : null,
      builder: (context, categorySnap) {
        if (!categorySnap.hasData) {
          return FilterSubpageLayout(
            title: 'Kedi',
            accent: AppColors.success,
            content: const Center(child: CircularProgressIndicator()),
          );
        }
        return StreamBuilder<List<AppProductAdvantage>>(
          stream: ProductAdvantageRepository.instance.watchAll(activeOnly: true),
          builder: (context, snapshot) {
            final catalog = snapshot.data ?? const <AppProductAdvantage>[];
            final subs = _catSubs(categorySnap.data!);
            if (subs.isEmpty) {
              return _layout(context, (group) {
                return ProductAdvantageRepository.iconForHealthGroup(
                  group,
                  catalog: catalog,
                );
              });
            }
            return FilterSubpageLayout(
              title: 'Kedi',
              accent: AppColors.success,
              items: [
                for (final sub in subs)
                  FilterSubpageItem(
                    title: sub.title,
                    subtitle: sub.subtitle.trim().isEmpty
                        ? sub.title
                        : sub.subtitle,
                    imagePath: categoryIconPath(
                      mainId: 'cat',
                      title: sub.title,
                      imageUrl: sub.imageUrl,
                      catalog: catalog,
                    ),
                    onTap: () => _openProducts(context, sub.title),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  List<AdminSubCategory> _catSubs(List<AdminMainCategory>? mains) {
    if (mains == null) return const [];
    for (final main in mains) {
      if (main.id != 'cat') continue;
      return [
        for (final sub in main.subcategories)
          if (sub.title.trim().isNotEmpty) sub,
      ];
    }
    return const [];
  }

  Widget _layout(
    BuildContext context,
    String Function(HealthProductGroup group) icon,
  ) {
    return FilterSubpageLayout(
      title: 'Kedi',
      accent: AppColors.success,
      items: [
        FilterSubpageItem(
          title: 'Yetişkin',
          subtitle: 'Yetişkin kedi mamaları ve ürünleri',
          imagePath: 'assets/images/petmarket_mama.png',
          onTap: () => _openProducts(context, 'Yetişkin'),
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
          title: HealthProductGroup.vitamin.categoryTitle,
          subtitle: 'Bağışıklık ve enerji desteği',
          imagePath: icon(HealthProductGroup.vitamin),
          onTap: () => _openProducts(
            context,
            HealthProductGroup.vitamin.categoryTitle,
          ),
        ),
        FilterSubpageItem(
          title: HealthProductGroup.supplement.categoryTitle,
          subtitle: 'Ek besin ve destek ürünleri',
          imagePath: icon(HealthProductGroup.supplement),
          onTap: () => _openProducts(
            context,
            HealthProductGroup.supplement.categoryTitle,
          ),
        ),
        FilterSubpageItem(
          title: HealthProductGroup.malt.categoryTitle,
          subtitle: 'Tüy yumağı ve sindirim',
          imagePath: icon(HealthProductGroup.malt),
          onTap: () => _openProducts(
            context,
            HealthProductGroup.malt.categoryTitle,
          ),
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
