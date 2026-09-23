import 'package:geliyor_app/data/pet_life_stage.dart';

/// Marka tüketim tablosu: ürün girişindeki kedi/köpek + yaş grubu ile aynı.
enum FeedingVariant {
  catAdult,
  catKitten,
  dogAdult,
  dogPuppy,
  dogMiniAdult,
  dogMiniPuppy;

  bool get isDog =>
      this == dogAdult ||
      this == dogPuppy ||
      this == dogMiniAdult ||
      this == dogMiniPuppy;

  bool get isPuppy =>
      this == catKitten || this == dogPuppy || this == dogMiniPuppy;

  bool get isMini => this == dogMiniAdult || this == dogMiniPuppy;

  String get speciesLabel => isDog ? 'Köpek' : 'Kedi';

  String get petFormLabel => switch (this) {
        catAdult => PetLifeStage.petCatAdult,
        catKitten => PetLifeStage.petCatKitten,
        dogAdult => PetLifeStage.petDogAdult,
        dogPuppy => PetLifeStage.petDogPuppy,
        dogMiniAdult => PetLifeStage.petDogMini,
        dogMiniPuppy => PetLifeStage.petDogMiniPuppy,
      };

  /// Yeni Dost Ekle’deki 6 profil etiketi.
  String get shortLabel => switch (this) {
        catAdult => 'Yetişkin',
        catKitten => 'Yavru',
        dogAdult => 'Köpek',
        dogPuppy => 'Köpek Yavru',
        dogMiniAdult => 'Mini Irk Yetişkin',
        dogMiniPuppy => 'Mini Irk Yavru',
      };

  String displayName(String brandName) {
    final brand = brandName.trim();
    if (this == dogMiniPuppy && isProPlanName(brand)) {
      return 'Pro Plan Small & Mini Puppy';
    }
    final raw = brand.isEmpty ? shortLabel : '$brand $shortLabel';
    return titleCaseWords(raw);
  }

  static bool isProPlanName(String name) {
    final title = PetLifeStage.normalizeTitle(name);
    return title.contains('pro plan') ||
        title.replaceAll(' ', '').contains('proplan');
  }

  static String titleCaseWords(String value) {
    return value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
        .join(' ');
  }

  /// Ürün girişindeki alt kategori.
  String get productCategory => switch (this) {
        catAdult || dogAdult => PetLifeStage.catAdult,
        catKitten || dogPuppy => PetLifeStage.catKitten,
        dogMiniAdult => PetLifeStage.dogMiniAdult,
        dogMiniPuppy => PetLifeStage.dogMiniPuppy,
      };

  static FeedingVariant? tryParse(String? raw) {
    final value = (raw ?? '').trim();
    if (value.isEmpty) return null;
    for (final variant in values) {
      if (variant.name == value) return variant;
    }
    return null;
  }

  static FeedingVariant resolve({
    required bool isDog,
    bool isPuppy = false,
    bool isMiniBreed = false,
  }) {
    if (!isDog) return isPuppy ? catKitten : catAdult;
    if (isMiniBreed) return isPuppy ? dogMiniPuppy : dogMiniAdult;
    return isPuppy ? dogPuppy : dogAdult;
  }

  /// Ürün ana/alt kategorisi ve başlıktan tablo seçer.
  static FeedingVariant fromProduct({
    String? mainCategory,
    String? category,
    String? brandName,
    String? title,
    String? subtitle,
  }) {
    final main = (mainCategory ?? '').trim().toLowerCase();
    final blob = PetLifeStage.normalizeTitle(
      '$mainCategory $category $brandName $title $subtitle',
    );
    final isMini = PetLifeStage.isMiniTitle(category ?? '') ||
        PetLifeStage.isMiniTitle('$title $subtitle');
    final isPuppy = PetLifeStage.isPuppyTitle(category ?? '') ||
        PetLifeStage.inferIsPuppyFromFood(
          brandName: brandName,
          title: title,
          subtitle: subtitle,
          category: category,
        );
    final isDog = main == 'dog' ||
        isMini ||
        blob.contains('kopek') ||
        blob.contains('dog');
    final isCat = main == 'cat' || blob.contains('kedi') || blob.contains('cat');
    if (isDog && !isCat) {
      return resolve(isDog: true, isPuppy: isPuppy, isMiniBreed: isMini);
    }
    if (isCat) {
      return resolve(isDog: false, isPuppy: isPuppy);
    }
    if (isDog) {
      return resolve(isDog: true, isPuppy: isPuppy, isMiniBreed: isMini);
    }
    return resolve(isDog: false, isPuppy: isPuppy);
  }
}
