/// Kedi / köpek yaş grubu ve mini ırk eşlemesi.
///
/// Yetişkin: kilo (kedi) veya beden (köpek).
/// Yavru: ay.
abstract final class PetLifeStage {
  static const adult = 'adult';
  static const puppy = 'puppy';

  static const catAdult = 'Mama';
  static const catKitten = 'Yavru';
  static const dogAdult = 'Mama';
  static const dogPuppy = 'Yavru';
  static const dogMiniAdult = 'Mini Irk';
  static const dogMiniPuppy = 'Mini Irk Yavru';

  static const monthOptions = [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12];

  static String normalizeTitle(String raw) {
    return raw
        .trim()
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('İ', 'i')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  static bool isMiniTitle(String raw) {
    final title = normalizeTitle(raw);
    return title.contains('mini');
  }

  static bool isPuppyTitle(String raw) {
    final title = normalizeTitle(raw);
    return title.contains('yavru') ||
        title.contains('puppy') ||
        title.contains('kitten');
  }

  static bool inferIsPuppyFromFood({
    String? brandName,
    String? title,
    String? subtitle,
    String? category,
  }) {
    return isPuppyTitle('$brandName $title $subtitle $category');
  }

  static String ageGroupOf(String? raw) {
    final title = normalizeTitle(raw ?? '');
    if (title.contains('senior') || title.contains('yasli') || title.contains('yaşlı')) {
      return 'Senior';
    }
    if (title.contains('yetiskin') || title.contains('yetişkin')) {
      return 'Yetişkin';
    }
    if (title.contains('genc') || title.contains('genç')) {
      return 'Genç';
    }
    if (title.contains('yavru') ||
        title.contains('puppy') ||
        title.contains('kitten')) {
      return 'Yavru';
    }
    return (raw ?? '').trim();
  }

  static String persistAgeRange({
    required String ageGroup,
    int? months,
  }) {
    if (ageGroupOf(ageGroup) != 'Yavru' || months == null) return ageGroup;
    return 'Yavru · $months ay';
  }

  static bool isAdultFoodTitle(String raw) {
    final title = normalizeTitle(raw);
    return title == 'mama' || title.isEmpty;
  }

  static bool isLifeStageTitle(String raw) {
    final title = normalizeTitle(raw);
    return title == 'mama' ||
        title == 'yavru' ||
        title == 'mini irk' ||
        title == 'mini irk yavru';
  }

  static bool isSameLifeStageCategory(String a, String b) {
    return normalizeTitle(a) == normalizeTitle(b);
  }

  /// Mini Irk Yavru, formda Mini Irk + Yavru ile yönetilir.
  static bool hideAsFormChip(String title) {
    return normalizeTitle(title) == 'mini irk yavru';
  }

  static String categoryTitle({
    required String mainCategory,
    required bool isMini,
    required bool isPuppy,
  }) {
    if (mainCategory == 'dog') {
      if (isMini) return isPuppy ? dogMiniPuppy : dogMiniAdult;
      return isPuppy ? dogPuppy : dogAdult;
    }
    if (mainCategory == 'cat') {
      return isPuppy ? catKitten : catAdult;
    }
    return catAdult;
  }

  /// Yavru seçilmemiş ürün yetişkin kedi/köpek (Mama) olarak kaydedilir.
  static String savedCategory({
    required String mainCategory,
    required String selected,
  }) {
    final current = selected.trim();
    if (mainCategory != 'cat' && mainCategory != 'dog') {
      return current;
    }
    if (current.isEmpty) {
      return categoryTitle(
        mainCategory: mainCategory,
        isMini: false,
        isPuppy: false,
      );
    }
    return current;
  }

  static bool inferIsPuppy({
    String? ageRange,
    String? category,
  }) {
    if (isPuppyTitle(category ?? '')) return true;
    final range = (ageRange ?? '').toLowerCase();
    if (range.contains('yetişkin') ||
        range.contains('yetiskin') ||
        range.contains('senior') ||
        range.contains('genç') ||
        range.contains('genc')) {
      return false;
    }
    if (range.contains('yavru') ||
        range.contains('puppy') ||
        range.contains('kitten')) {
      return true;
    }
    final months = monthsFromLabel(ageRange);
    if (months != null && months <= 12) return true;
    return false;
  }

  static bool inferIsMini({String? ageRange, String? category}) {
    if (isMiniTitle(category ?? '')) return true;
    final range = (ageRange ?? '').toLowerCase();
    return range.contains('mini') ||
        range.contains('x-small') ||
        range.contains('xsmall') ||
        range.contains('0-4');
  }

  static int? monthsFromLabel(String? label) {
    if (label == null || label.trim().isEmpty) return null;
    final lower = label.toLowerCase();
    final monthMatch = RegExp(
      r'(\d+)\s*(ay|aylık|aylik)',
    ).firstMatch(lower);
    if (monthMatch != null) {
      final months = int.tryParse(monthMatch.group(1)!);
      if (months == null) return null;
      return months.clamp(1, 12);
    }
    return null;
  }

  static String monthLabel(int months) => '$months ay';
}

class PetLifeStageProfile {
  const PetLifeStageProfile({
    required this.isPuppy,
    this.isMiniBreed = false,
    this.ageMonths = 4,
  });

  final bool isPuppy;
  final bool isMiniBreed;
  final int ageMonths;

  String get id => isPuppy ? PetLifeStage.puppy : PetLifeStage.adult;

  String get ageLabel =>
      isPuppy ? PetLifeStage.monthLabel(ageMonths) : 'Yetişkin';

  String get breedLabel => isMiniBreed ? 'Mini Irk' : 'Standart ırk';
}
