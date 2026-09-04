import 'package:flutter/material.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';

/// Arama metni bir ürün özelliğine denk geliyorsa etiketli ürün listesini açar.
class AdvantageSearch {
  AdvantageSearch._();

  static bool openProductsIfMatched(
    BuildContext context,
    String query, {
    String mainCategory = 'cat',
  }) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return false;
    if (ProductAdvantageRepository.matchingIds(trimmed).isEmpty) {
      return false;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: mainCategory,
          initialFeature: trimmed,
        ),
      ),
    );
    return true;
  }
}
