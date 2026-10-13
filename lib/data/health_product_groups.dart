import 'package:geliyor_app/data/pet_life_stage.dart';

/// İlaç ve tedavi sekmeleri, ürün faydaları ve pet market kedi alt
/// kategorileri aynı ürün kümesini kullanır.
class HealthProductGroup {
  const HealthProductGroup({
    required this.advantageId,
    required this.categoryTitle,
    required this.iconPath,
    required this.aliases,
  });

  final String advantageId;
  final String categoryTitle;
  final String iconPath;
  final List<String> aliases;

  static const vitaminTitle = 'Vitamin';
  static const supplementTitle = 'Takviye Gıdalar';
  static const maltTitle = 'Maltlar';
  static const vitaminIcon = 'assets/images/ilac_icon_vitamin.png';
  static const supplementIcon = 'assets/images/ilac_icon_takviye.png';
  static const maltIcon = 'assets/images/ilac_icon_malt.png';

  static const vitamin = HealthProductGroup(
    advantageId: 'vitamin',
    categoryTitle: vitaminTitle,
    iconPath: vitaminIcon,
    aliases: ['vitamin', 'vitaminler', 'multivitamin'],
  );

  static const supplement = HealthProductGroup(
    advantageId: 'takviye',
    categoryTitle: supplementTitle,
    iconPath: supplementIcon,
    aliases: [
      'takviye',
      'takviye gida',
      'takviye gidalar',
      'supplement',
    ],
  );

  static const malt = HealthProductGroup(
    advantageId: 'malt',
    categoryTitle: maltTitle,
    iconPath: maltIcon,
    aliases: ['malt', 'maltlar', 'maltler'],
  );

  static const values = <HealthProductGroup>[vitamin, supplement, malt];

  static HealthProductGroup? forAdvantageId(String id) {
    final key = id.trim();
    for (final group in values) {
      if (group.advantageId == key) return group;
    }
    return null;
  }

  static HealthProductGroup? forCategoryTitle(String raw) {
    for (final group in values) {
      if (group.matchesTitle(raw)) return group;
    }
    return null;
  }

  static HealthProductGroup? forAdvantage(String id, String name) {
    final byId = forAdvantageId(id);
    if (byId != null) return byId;
    return forCategoryTitle(name) ??
        forCategoryTitle(id.replaceAll('_', ' '));
  }

  bool matchesAdvantage(String id, String name) {
    if (id.trim() == advantageId) return true;
    if (matchesTitle(name) || matchesTitle(id.replaceAll('_', ' '))) {
      return true;
    }
    final folded = PetLifeStage.normalizeTitle(name);
    return aliases.any(
      (alias) => folded == alias || folded.startsWith('$alias '),
    );
  }

  bool matchesTitle(String raw) {
    final title = PetLifeStage.normalizeTitle(raw);
    if (title.isEmpty) return false;
    return aliases.contains(title);
  }

  bool matches({
    required Iterable<String> advantageIds,
    required Iterable<String> categoryTitles,
  }) {
    if (advantageIds.any((id) => id.trim() == advantageId)) return true;
    return categoryTitles.any(matchesTitle);
  }

  /// Vitamin / takviye / malt seçimi hem ürün faydasına hem kedi alt
  /// kategorisine yazılsın.
  static void applyToProductSelection({
    required List<String> advantageIds,
    required String mainCategory,
    required String primaryCategory,
    required Set<String> extraCategories,
    required int maxAdvantages,
  }) {
    final main = mainCategory.trim().toLowerCase();
    final onCat = main.isEmpty || main == 'cat';
    for (final group in values) {
      final hasAdvantage = advantageIds.contains(group.advantageId);
      final hasCategory = group.matchesTitle(primaryCategory) ||
          extraCategories.any(group.matchesTitle);
      if (onCat && hasAdvantage && !hasCategory) {
        extraCategories.add(group.categoryTitle);
      }
      if (hasCategory &&
          !hasAdvantage &&
          advantageIds.length < maxAdvantages) {
        advantageIds.add(group.advantageId);
      }
    }
  }
}
