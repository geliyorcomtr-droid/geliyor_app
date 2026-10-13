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
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.fitness_center_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.eco_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.favorite_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
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
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.fitness_center_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.eco_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.shield_outlined,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
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
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.wifi_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.notifications_active_outlined,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
  ),
  MarketProductFeature(
    icon: Icons.battery_charging_full_rounded,
    iconColor: AppColors.primary,
    bgColor: AppColors.selected,
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
    PetMarketSubCategory('Yetişkin', Icons.rice_bowl_rounded),
    PetMarketSubCategory('Yavru', Icons.child_care_outlined),
    PetMarketSubCategory('Ödül', Icons.cookie_outlined),
    PetMarketSubCategory('Bakım', Icons.spa_outlined),
    PetMarketSubCategory('Oyuncak', Icons.sports_baseball_outlined),
    PetMarketSubCategory('Vitamin', Icons.medication_outlined),
    PetMarketSubCategory('Takviye Gıdalar', Icons.health_and_safety_outlined),
    PetMarketSubCategory('Maltlar', Icons.spa_outlined),
    PetMarketSubCategory('Taşıma', Icons.shopping_bag_outlined),
  ],
  'dog': [
    PetMarketSubCategory('Yetişkin', Icons.rice_bowl_rounded),
    PetMarketSubCategory('Yavru', Icons.child_care_outlined),
    PetMarketSubCategory('Mini Irk', Icons.pets_outlined),
    PetMarketSubCategory('Mini Irk Yavru', Icons.pets_rounded),
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
