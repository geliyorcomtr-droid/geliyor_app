import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/market_product_card.dart';

const petMarketCatFeatures = [
  MarketProductFeature(
    icon: Icons.health_and_safety_outlined,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.water_drop_outlined,
    iconColor: Color(0xFF8B5CF6),
    bgColor: Color(0xFFF3E8FF),
  ),
  MarketProductFeature(
    icon: Icons.fitness_center_rounded,
    iconColor: Color(0xFFF97316),
    bgColor: Color(0xFFFFF1E6),
  ),
  MarketProductFeature(
    icon: Icons.eco_rounded,
    iconColor: AppColors.success,
    bgColor: Color(0xFFE8F9EE),
  ),
  MarketProductFeature(
    icon: Icons.favorite_rounded,
    iconColor: AppColors.error,
    bgColor: Color(0xFFFEE2E2),
  ),
];

const petMarketDogFeatures = [
  MarketProductFeature(
    icon: Icons.pets_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.spa_outlined,
    iconColor: Color(0xFF8B5CF6),
    bgColor: Color(0xFFF3E8FF),
  ),
  MarketProductFeature(
    icon: Icons.fitness_center_rounded,
    iconColor: Color(0xFFF97316),
    bgColor: Color(0xFFFFF1E6),
  ),
  MarketProductFeature(
    icon: Icons.eco_rounded,
    iconColor: AppColors.success,
    bgColor: Color(0xFFE8F9EE),
  ),
  MarketProductFeature(
    icon: Icons.shield_outlined,
    iconColor: AppColors.warning,
    bgColor: Color(0xFFFFF8EC),
  ),
];

const petMarketSmartFeatures = [
  MarketProductFeature(
    icon: Icons.schedule_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.phone_android_rounded,
    iconColor: Color(0xFF8B5CF6),
    bgColor: Color(0xFFF3E8FF),
  ),
  MarketProductFeature(
    icon: Icons.wifi_rounded,
    iconColor: Color(0xFFF97316),
    bgColor: Color(0xFFFFF1E6),
  ),
  MarketProductFeature(
    icon: Icons.notifications_active_outlined,
    iconColor: AppColors.success,
    bgColor: Color(0xFFE8F9EE),
  ),
  MarketProductFeature(
    icon: Icons.battery_charging_full_rounded,
    iconColor: AppColors.warning,
    bgColor: Color(0xFFFFF8EC),
  ),
];

class PetMarketMainCategory {
  const PetMarketMainCategory({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;
}

class PetMarketSubCategory {
  const PetMarketSubCategory(this.title, this.icon);

  final String title;
  final IconData icon;
}

const petMarketMainCategories = [
  PetMarketMainCategory(id: 'cat', title: 'Kedi'),
  PetMarketMainCategory(id: 'dog', title: 'Köpek'),
  PetMarketMainCategory(id: 'smart', title: 'Akıllı Pet'),
];

const petMarketSubCategories = <String, List<PetMarketSubCategory>>{
  'cat': [
    PetMarketSubCategory('Mama', Icons.rice_bowl_rounded),
    PetMarketSubCategory('Ödül', Icons.cookie_outlined),
    PetMarketSubCategory('Bakım', Icons.spa_outlined),
    PetMarketSubCategory('Oyuncak', Icons.sports_baseball_outlined),
    PetMarketSubCategory('Sağlık', Icons.favorite_outline_rounded),
    PetMarketSubCategory('Taşıma', Icons.shopping_bag_outlined),
  ],
  'dog': [
    PetMarketSubCategory('Mama', Icons.rice_bowl_rounded),
    PetMarketSubCategory('Ödül', Icons.cookie_outlined),
    PetMarketSubCategory('Tasma', Icons.link_rounded),
    PetMarketSubCategory('Oyuncak', Icons.sports_baseball_outlined),
    PetMarketSubCategory('Bakım', Icons.spa_outlined),
    PetMarketSubCategory('Yatak', Icons.bed_outlined),
  ],
  'smart': [
    PetMarketSubCategory('Mama Kabı', Icons.rice_bowl_rounded),
    PetMarketSubCategory('Su Kabı', Icons.water_drop_outlined),
    PetMarketSubCategory('Takip', Icons.location_searching_rounded),
    PetMarketSubCategory('Kamera', Icons.videocam_outlined),
    PetMarketSubCategory('Tuvalet', Icons.auto_awesome_rounded),
    PetMarketSubCategory('Bakım', Icons.settings_remote_outlined),
  ],
};

List<MarketProductData> petMarketProductsFor({
  required String mainCategory,
  required String subCategory,
}) {
  return const [];
}

List<MarketProductData> petMarketSearchProducts({
  required String query,
  String? mainCategory,
}) {
  return const [];
}
