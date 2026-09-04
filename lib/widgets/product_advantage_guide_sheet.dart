import 'package:flutter/material.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/widgets/info_guide_sheet.dart';

class ProductAdvantageGuideSheet {
  ProductAdvantageGuideSheet._();

  static Future<void> show(
    BuildContext context, {
    required AppProductAdvantage item,
    String mainCategory = 'cat',
  }) {
    final iconPath = ProductAdvantageRepository.displaysAsStat(item)
        ? ProductAdvantageRepository.proteinIconPath
        : item.assetPath;
    return InfoGuideSheet.show(
      context,
      title: item.name,
      guide: ProductAdvantageRepository.guideFor(item),
      iconPath: iconPath,
      imageUrl: ProductAdvantageRepository.displaysAsStat(item)
          ? ''
          : item.imageUrl,
      onSeeProducts: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => PetMarketProductsScreen(
              initialMainCategory: mainCategory,
              initialFeature: item.name,
              initialAdvantageId: item.id,
            ),
          ),
        );
      },
    );
  }
}
