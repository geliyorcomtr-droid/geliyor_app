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
  }) async {
    var template = '';
    try {
      template =
          await ProductAdvantageRepository.instance.fetchOverlayTemplateUrl();
    } catch (_) {}
    if (!context.mounted) return;

    return InfoGuideSheet.showAdvantageOverlay(
      context,
      templatePath: template,
      title: item.overlayTitle,
      description: ProductAdvantageRepository.explanationFor(item),
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
