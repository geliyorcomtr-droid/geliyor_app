import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/state/pet_store.dart';

class FoodRemainingEstimate {
  const FoodRemainingEstimate({
    required this.remainingDays,
    required this.totalDays,
    required this.bagKg,
    required this.dailyGrams,
    required this.pet,
    this.food,
    required this.foodTitle,
    this.imagePath,
    this.fromManual = false,
  });

  final int remainingDays;
  final int totalDays;
  final double bagKg;
  final int dailyGrams;
  final PetData pet;
  final LastOrderItem? food;
  final String foodTitle;
  final String? imagePath;
  final bool fromManual;

  double get remainingRatio {
    if (totalDays <= 0) return 0;
    return (remainingDays / totalDays).clamp(0.0, 1.0);
  }

  /// Mama stok durumu: kalan gün ve paket oranına göre.
  FoodStockLevel get stockLevel {
    if (remainingDays <= 3 || remainingRatio <= 0.08) {
      return FoodStockLevel.critical;
    }
    if (remainingDays <= 7 || remainingRatio <= 0.15) {
      return FoodStockLevel.low;
    }
    if (remainingDays <= 14 || remainingRatio <= 0.30) {
      return FoodStockLevel.watch;
    }
    return FoodStockLevel.safe;
  }
}

enum FoodStockLevel { safe, watch, low, critical }

/// Mama takibi açıksa manuel kg; değilse son siparişteki mama kg.
abstract final class FoodRemainingEstimator {
  static FoodRemainingEstimate? compute() {
    final pet = _guidePet();
    if (pet == null) return null;

    final dailyGrams = _dailyGramsFor(pet);
    if (dailyGrams <= 0) return null;

    final tracking = FoodTrackingStore.instance;
    if (tracking.isActive && tracking.bagKg > 0) {
      return _build(
        pet: pet,
        bagKg: tracking.bagKg,
        startedAt: tracking.purchaseDate,
        dailyGrams: dailyGrams,
        foodTitle: tracking.foodName.isEmpty
            ? 'Manuel mama takibi'
            : tracking.foodName,
        fromManual: true,
      );
    }

    final food = _lastDryFood();
    if (food == null) return null;

    final bagKg = kgFromLabel(food.weight) * food.quantity;
    if (bagKg <= 0) return null;

    return _build(
      pet: pet,
      bagKg: bagKg,
      startedAt: OrderStore.instance.lastOrderAt,
      dailyGrams: dailyGrams,
      food: food,
      foodTitle: food.title,
      imagePath: food.imagePath,
    );
  }

  static FoodRemainingEstimate? _build({
    required PetData pet,
    required double bagKg,
    required DateTime startedAt,
    required int dailyGrams,
    LastOrderItem? food,
    required String foodTitle,
    String? imagePath,
    bool fromManual = false,
  }) {
    if (bagKg <= 0 || dailyGrams <= 0) return null;
    final totalDays = ((bagKg * 1000) / dailyGrams).round();
    final elapsed = DateTime.now()
        .difference(_dateOnly(startedAt))
        .inDays
        .clamp(0, 10000);
    final remaining = (totalDays - elapsed).clamp(0, totalDays);

    return FoodRemainingEstimate(
      remainingDays: remaining,
      totalDays: totalDays,
      bagKg: bagKg,
      dailyGrams: dailyGrams,
      pet: pet,
      food: food,
      foodTitle: foodTitle,
      imagePath: imagePath,
      fromManual: fromManual,
    );
  }

  static double kgFromLabel(String? text) {
    if (text == null || text.trim().isEmpty) return 0;
    final matches = RegExp(
      r'(\d+(?:[.,]\d+)?)\s*kg',
      caseSensitive: false,
    ).allMatches(text);
    var sum = 0.0;
    for (final match in matches) {
      sum += double.tryParse(match.group(1)!.replaceAll(',', '.')) ?? 0;
    }
    return sum;
  }

  static PetData? _guidePet() {
    final pets = PetStore.instance.pets;
    if (pets.isEmpty) return null;
    for (final pet in pets) {
      if (pet.species.toLowerCase().contains('kedi')) return pet;
    }
    return null;
  }

  static LastOrderItem? _lastDryFood() {
    final items = OrderStore.instance.lastOrderItems;
    for (final item in items) {
      final blob = '${item.title} ${item.subtitle} ${item.weight}'.toLowerCase();
      final hasKg = RegExp(r'\d+(?:[.,]\d+)?\s*kg').hasMatch(blob);
      if (!hasKg) continue;
      if (blob.contains('mama') || blob.contains('food') || hasKg) {
        return item;
      }
    }
    return null;
  }

  static int _dailyGramsFor(PetData pet) {
    return CatFeedingGuide.dailyGramsFor(
          weightLabel: pet.weight,
          bodyType: pet.bodyType,
          activityLevel: pet.activityLevel,
        ) ??
        0;
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }
}
