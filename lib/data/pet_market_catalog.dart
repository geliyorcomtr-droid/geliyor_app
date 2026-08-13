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
  if (mainCategory == 'smart') {
    return _smartProductsFor(subCategory);
  }
  if (mainCategory == 'cat') {
    return _catProductsFor(subCategory);
  }
  if (mainCategory == 'bird') {
    return _birdProductsFor(subCategory);
  }
  if (mainCategory == 'rodent') {
    return _rodentProductsFor(subCategory);
  }
  return _dogProductsFor(subCategory);
}

/// Pet Market arama — ana kategori (veya tümü) içinde ürün tara.
List<MarketProductData> petMarketSearchProducts({
  required String query,
  String? mainCategory,
}) {
  final q = query.trim().toLowerCase();
  if (q.isEmpty) return const [];

  final mains = mainCategory == null
      ? const ['cat', 'dog', 'smart', 'bird', 'rodent']
      : [mainCategory];

  const subsByMain = <String, List<String>>{
    'cat': [
      'Mama',
      'Yavru',
      'Kum',
      'Ödül',
      'Bakım',
      'Oyuncak',
      'Sağlık',
      'Taşıma',
    ],
    'dog': [
      'Mama',
      'Yavru',
      'Mini Irk',
      'Ödül',
      'Tasma',
      'Oyuncak',
      'Bakım',
      'Yatak',
    ],
    'smart': [
      'Akıllı Pet',
      'Mama Kabı',
      'Su Kabı',
      'Takip',
      'Kamera',
      'Tuvalet',
      'Bakım',
    ],
    'bird': ['Mama', 'Kafes', 'Oyuncak'],
    'rodent': ['Mama', 'Kafes', 'Oyuncak'],
  };

  final seen = <String>{};
  final results = <MarketProductData>[];

  for (final main in mains) {
    for (final sub in subsByMain[main] ?? const ['Mama']) {
      for (final product in petMarketProductsFor(
        mainCategory: main,
        subCategory: sub,
      )) {
        if (seen.contains(product.id)) continue;
        final haystack =
            '${product.title} ${product.subtitle} ${product.brand} '
            '${product.dietTag} ${product.petTag} $sub'
                .toLowerCase();
        if (haystack.contains(q)) {
          seen.add(product.id);
          results.add(product);
        }
      }
    }
  }

  return results;
}

List<MarketProductData> _catProductsFor(String subCategory) {
  switch (subCategory) {
    case 'Ödül':
      return const [
        MarketProductData(
          id: 'cat-reward-1',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Kuzu Etli Ödül',
          subtitle: 'Kedi Ödül Maması',
          petTag: 'Kediler',
          dietTag: 'Doğal',
          rating: 4.5,
          reviewCount: 42,
          discount: 18,
          weights: ['80 g', '150 g', '300 g'],
          prices: [179.9, 249.9, 399.9],
          oldPrices: [219.9, 299.9, 479.9],
          features: petMarketCatFeatures,
        ),
        MarketProductData(
          id: 'cat-reward-2',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Somonlu Lokma',
          subtitle: 'Kedi Ödül Lokması',
          petTag: 'Kediler',
          dietTag: 'Tahılsız',
          rating: 4.6,
          reviewCount: 55,
          discount: 20,
          weights: ['90 g', '180 g', '360 g'],
          prices: [159.9, 229.9, 379.9],
          oldPrices: [199.9, 279.9, 459.9],
          features: petMarketCatFeatures,
        ),
        MarketProductData(
          id: 'cat-reward-3',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Tavuklu Çubuk',
          subtitle: 'Proteinli Kedi Ödülü',
          petTag: 'Kediler',
          dietTag: 'Protein',
          rating: 4.4,
          reviewCount: 31,
          discount: 12,
          weights: ['60 g', '120 g', '240 g'],
          prices: [139.9, 199.9, 329.9],
          oldPrices: [159.9, 229.9, 379.9],
          features: petMarketCatFeatures,
        ),
        MarketProductData(
          id: 'cat-reward-4',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Peynirli Kedi Ödülü',
          subtitle: 'Yumuşak Lokma Serisi',
          petTag: 'Kediler',
          dietTag: 'Lezzetli',
          rating: 4.3,
          reviewCount: 28,
          discount: 10,
          weights: ['75 g', '150 g', '300 g'],
          prices: [149.9, 219.9, 349.9],
          oldPrices: [169.9, 249.9, 389.9],
          features: petMarketCatFeatures,
        ),
        MarketProductData(
          id: 'cat-reward-5',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Balıklı Kedi Ödülü',
          subtitle: 'Omega-3 Destekli',
          petTag: 'Kediler',
          dietTag: 'Omega-3',
          rating: 4.7,
          reviewCount: 63,
          discount: 16,
          weights: ['85 g', '170 g', '340 g'],
          prices: [169.9, 239.9, 389.9],
          oldPrices: [199.9, 279.9, 459.9],
          features: petMarketCatFeatures,
        ),
        MarketProductData(
          id: 'cat-reward-6',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Dentastix Kedi',
          subtitle: 'Diş Sağlığı Ödülü',
          petTag: 'Kediler',
          dietTag: 'Diş Bakım',
          rating: 4.5,
          reviewCount: 47,
          discount: 14,
          weights: ['50 g', '100 g', '200 g'],
          prices: [129.9, 189.9, 299.9],
          oldPrices: [149.9, 219.9, 349.9],
          features: petMarketCatFeatures,
        ),
      ];
    case 'Yavru':
      return _catMamaProducts(
        suffix: 'yavru',
        titlePrefix: 'Yavru',
        subtitlePrefix: 'Yavru Kedi Maması',
      );
    case 'Kum':
      return _catMamaProducts(
        suffix: 'kum',
        titlePrefix: 'Kum',
        subtitlePrefix: 'Kedi Kumu',
      );
    case 'Bakım':
      return _catMamaProducts(
        suffix: 'bakim',
        titlePrefix: 'Bakım',
        subtitlePrefix: 'Kedi Bakım',
      );
    case 'Oyuncak':
      return _catMamaProducts(
        suffix: 'oyuncak',
        titlePrefix: 'Oyuncak',
        subtitlePrefix: 'Kedi Oyuncağı',
      );
    case 'Sağlık':
      return _catMamaProducts(
        suffix: 'saglik',
        titlePrefix: 'Sağlık',
        subtitlePrefix: 'Kedi Sağlık',
      );
    case 'Taşıma':
      return _catMamaProducts(
        suffix: 'tasima',
        titlePrefix: 'Taşıma',
        subtitlePrefix: 'Kedi Taşıma',
      );
    default:
      return _catMamaProducts();
  }
}

List<MarketProductData> _catMamaProducts({
  String suffix = 'mama',
  String titlePrefix = '',
  String subtitlePrefix = 'Kedi Maması',
}) {
  final p = titlePrefix.isEmpty ? '' : '$titlePrefix ';
  return [
    MarketProductData(
      id: 'cat-$suffix-1',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: '${p}Pro Plan Sterilised',
      subtitle: '$subtitlePrefix — Somonlu',
      petTag: 'Kediler',
      dietTag: 'Tahılsız',
      rating: 4.8,
      reviewCount: 126,
      discount: 15,
      weights: ['1.5 kg', '3 kg', '10 kg'],
      prices: [654, 1099, 2499],
      oldPrices: [769, 1299, 2940],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'cat-$suffix-2',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: '${p}N&D Kuzu Kısır',
      subtitle: '$subtitlePrefix — Tahılsız',
      petTag: 'Kediler',
      dietTag: 'Tahılsız',
      rating: 4.7,
      reviewCount: 98,
      discount: 15,
      weights: ['1.5 kg', '5 kg', '10 kg'],
      prices: [699, 1649, 2499],
      oldPrices: [829, 1949, 2940],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'cat-$suffix-3',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: '${p}Royal Canin Indoor',
      subtitle: '$subtitlePrefix — Ev Kedisi',
      petTag: 'Kediler',
      dietTag: 'İç Mekan',
      rating: 4.6,
      reviewCount: 84,
      discount: 12,
      weights: ['2 kg', '4 kg', '10 kg'],
      prices: [749, 1399, 2699],
      oldPrices: [849, 1599, 3099],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'cat-$suffix-4',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: '${p}Hill\'s Science Plan',
      subtitle: '$subtitlePrefix — Yetişkin',
      petTag: 'Kediler',
      dietTag: 'Bilimsel',
      rating: 4.5,
      reviewCount: 72,
      discount: 10,
      weights: ['1.5 kg', '3 kg', '7 kg'],
      prices: [599, 999, 1999],
      oldPrices: [669, 1099, 2249],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'cat-$suffix-5',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: '${p}Reflex Plus Kısır',
      subtitle: '$subtitlePrefix — Tavuklu',
      petTag: 'Kediler',
      dietTag: 'Ekonomik',
      rating: 4.4,
      reviewCount: 56,
      discount: 18,
      weights: ['1.5 kg', '3 kg', '8 kg'],
      prices: [449, 799, 1699],
      oldPrices: [549, 979, 2099],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'cat-$suffix-6',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: '${p}Brit Care Hairball',
      subtitle: '$subtitlePrefix — Tüy Yumağı',
      petTag: 'Kediler',
      dietTag: 'Özel Formül',
      rating: 4.6,
      reviewCount: 91,
      discount: 14,
      weights: ['2 kg', '5 kg', '10 kg'],
      prices: [679, 1549, 2599],
      oldPrices: [789, 1799, 2999],
      features: petMarketCatFeatures,
    ),
  ];
}

List<MarketProductData> _dogProductsFor(String subCategory) {
  switch (subCategory) {
    case 'Ödül':
      return const [
        MarketProductData(
          id: 'dog-reward-1',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Kuzu Etli Ödül',
          subtitle: 'Köpek Ödül Maması',
          petTag: 'Köpekler',
          dietTag: 'Doğal',
          rating: 4.5,
          reviewCount: 42,
          discount: 18,
          weights: ['100 g', '200 g', '400 g'],
          prices: [189.9, 269.9, 429.9],
          oldPrices: [229.9, 329.9, 519.9],
          features: petMarketDogFeatures,
        ),
        MarketProductData(
          id: 'dog-reward-2',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Somonlu Lokma',
          subtitle: 'Köpek Ödül Lokması',
          petTag: 'Köpekler',
          dietTag: 'Tahılsız',
          rating: 4.6,
          reviewCount: 55,
          discount: 20,
          weights: ['120 g', '240 g', '480 g'],
          prices: [169.9, 249.9, 399.9],
          oldPrices: [209.9, 299.9, 479.9],
          features: petMarketDogFeatures,
        ),
        MarketProductData(
          id: 'dog-reward-3',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Kemik Şeklinde Ödül',
          subtitle: 'Diş Temizleyici',
          petTag: 'Köpekler',
          dietTag: 'Diş Bakım',
          rating: 4.4,
          reviewCount: 38,
          discount: 15,
          weights: ['150 g', '300 g', '600 g'],
          prices: [199.9, 289.9, 449.9],
          oldPrices: [234.9, 339.9, 529.9],
          features: petMarketDogFeatures,
        ),
        MarketProductData(
          id: 'dog-reward-4',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Tavuklu Çubuk',
          subtitle: 'Proteinli Köpek Ödülü',
          petTag: 'Köpekler',
          dietTag: 'Protein',
          rating: 4.3,
          reviewCount: 29,
          discount: 12,
          weights: ['80 g', '160 g', '320 g'],
          prices: [149.9, 219.9, 359.9],
          oldPrices: [169.9, 249.9, 409.9],
          features: petMarketDogFeatures,
        ),
        MarketProductData(
          id: 'dog-reward-5',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Peynirli Köpek Ödülü',
          subtitle: 'Yumuşak Lokma Serisi',
          petTag: 'Köpekler',
          dietTag: 'Lezzetli',
          rating: 4.5,
          reviewCount: 44,
          discount: 10,
          weights: ['100 g', '200 g', '400 g'],
          prices: [159.9, 239.9, 389.9],
          oldPrices: [179.9, 269.9, 429.9],
          features: petMarketDogFeatures,
        ),
        MarketProductData(
          id: 'dog-reward-6',
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
          title: 'Dentastix Köpek',
          subtitle: 'Diş Sağlığı Ödülü',
          petTag: 'Köpekler',
          dietTag: 'Diş Bakım',
          rating: 4.7,
          reviewCount: 67,
          discount: 14,
          weights: ['90 g', '180 g', '360 g'],
          prices: [179.9, 259.9, 419.9],
          oldPrices: [209.9, 299.9, 489.9],
          features: petMarketDogFeatures,
        ),
      ];
    case 'Yavru':
      return _dogMamaProducts('Yavru');
    case 'Mini Irk':
      return _dogMamaProducts('Mini Irk');
    case 'Kum':
      return _dogMamaProducts('Kum');
    case 'Bakım':
      return _dogMamaProducts('Bakım');
    case 'Oyuncak':
      return _dogMamaProducts('Oyuncak');
    case 'Sağlık':
      return _dogMamaProducts('Sağlık');
    case 'Taşıma':
      return _dogMamaProducts('Taşıma');
    default:
      return _dogMamaProducts(subCategory);
  }
}

List<MarketProductData> _dogMamaProducts(String subCategory) {
  final suffix = subCategory.toLowerCase().replaceAll(' ', '-');
  return [
    MarketProductData(
      id: 'dog-$suffix-1',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'N&D Kuzu Köpek',
      subtitle: '$subCategory — Tahılsız',
      petTag: 'Köpekler',
      dietTag: 'Tahılsız',
      rating: 4.7,
      reviewCount: 112,
      discount: 15,
      weights: ['2.5 kg', '7 kg', '12 kg'],
      prices: [899, 1899, 2699],
      oldPrices: [1049, 2249, 3199],
      features: petMarketDogFeatures,
    ),
    MarketProductData(
      id: 'dog-$suffix-2',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Pro Plan Hassas',
      subtitle: '$subCategory — Sindirim',
      petTag: 'Köpekler',
      dietTag: 'Sindirim',
      rating: 4.6,
      reviewCount: 87,
      discount: 14,
      weights: ['3 kg', '7 kg', '14 kg'],
      prices: [1099, 2199, 3599],
      oldPrices: [1279, 2549, 4199],
      features: petMarketDogFeatures,
    ),
    MarketProductData(
      id: 'dog-$suffix-3',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Royal Canin Medium',
      subtitle: '$subCategory — Orta Irk',
      petTag: 'Köpekler',
      dietTag: 'Orta Irk',
      rating: 4.5,
      reviewCount: 76,
      discount: 12,
      weights: ['4 kg', '10 kg', '15 kg'],
      prices: [999, 2199, 3299],
      oldPrices: [1149, 2499, 3799],
      features: petMarketDogFeatures,
    ),
    MarketProductData(
      id: 'dog-$suffix-4',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Hill\'s Science Plan',
      subtitle: '$subCategory — Yetişkin',
      petTag: 'Köpekler',
      dietTag: 'Bilimsel',
      rating: 4.4,
      reviewCount: 64,
      discount: 10,
      weights: ['3 kg', '7 kg', '12 kg'],
      prices: [849, 1799, 2899],
      oldPrices: [949, 1999, 3199],
      features: petMarketDogFeatures,
    ),
    MarketProductData(
      id: 'dog-$suffix-5',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Reflex Plus Köpek',
      subtitle: '$subCategory — Tavuklu',
      petTag: 'Köpekler',
      dietTag: 'Ekonomik',
      rating: 4.3,
      reviewCount: 52,
      discount: 18,
      weights: ['3 kg', '8 kg', '15 kg'],
      prices: [549, 1199, 1999],
      oldPrices: [669, 1449, 2449],
      features: petMarketDogFeatures,
    ),
    MarketProductData(
      id: 'dog-$suffix-6',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Brit Care Sensitive',
      subtitle: '$subCategory — Hassas',
      petTag: 'Köpekler',
      dietTag: 'Hassas',
      rating: 4.6,
      reviewCount: 88,
      discount: 14,
      weights: ['3 kg', '7 kg', '12 kg'],
      prices: [799, 1699, 2699],
      oldPrices: [929, 1979, 3149],
      features: petMarketDogFeatures,
    ),
  ];
}

List<MarketProductData> _birdProductsFor(String subCategory) {
  final suffix = subCategory.toLowerCase().replaceAll(' ', '-');
  return [
    MarketProductData(
      id: 'bird-$suffix-1',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Muhabbet Kuşu Yemi',
      subtitle: '$subCategory — Vitaminli',
      petTag: 'Kuşlar',
      dietTag: 'Vitamin',
      rating: 4.6,
      reviewCount: 58,
      discount: 15,
      weights: ['500 g', '1 kg', '2 kg'],
      prices: [89.9, 149.9, 259.9],
      oldPrices: [109.9, 179.9, 309.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'bird-$suffix-2',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Papağan Karışık Yem',
      subtitle: '$subCategory — Premium',
      petTag: 'Kuşlar',
      dietTag: 'Premium',
      rating: 4.7,
      reviewCount: 72,
      discount: 18,
      weights: ['750 g', '1.5 kg', '3 kg'],
      prices: [129.9, 219.9, 389.9],
      oldPrices: [159.9, 269.9, 479.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'bird-$suffix-3',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Kuş Gaga Taşı',
      subtitle: '$subCategory — Mineral',
      petTag: 'Kuşlar',
      dietTag: 'Mineral',
      rating: 4.4,
      reviewCount: 41,
      discount: 12,
      weights: ['1 Adet', '2 Adet', '4 Adet'],
      prices: [49.9, 89.9, 159.9],
      oldPrices: [59.9, 109.9, 189.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'bird-$suffix-4',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Kuş Oyuncak Seti',
      subtitle: '$subCategory — Renkli',
      petTag: 'Kuşlar',
      dietTag: 'Oyuncak',
      rating: 4.5,
      reviewCount: 36,
      discount: 14,
      weights: ['S', 'M', 'L'],
      prices: [79.9, 119.9, 169.9],
      oldPrices: [99.9, 149.9, 199.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'bird-$suffix-5',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Kuş Kafes Aksesuarı',
      subtitle: '$subCategory — Aksesuar',
      petTag: 'Kuşlar',
      dietTag: 'Aksesuar',
      rating: 4.3,
      reviewCount: 29,
      discount: 10,
      weights: ['Standart', 'Plus', 'XL'],
      prices: [99.9, 149.9, 219.9],
      oldPrices: [119.9, 179.9, 259.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'bird-$suffix-6',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Kuş Vitamin Damlası',
      subtitle: '$subCategory — Sağlık',
      petTag: 'Kuşlar',
      dietTag: 'Sağlık',
      rating: 4.6,
      reviewCount: 53,
      discount: 16,
      weights: ['30 ml', '50 ml', '100 ml'],
      prices: [69.9, 99.9, 169.9],
      oldPrices: [84.9, 119.9, 199.9],
      features: petMarketCatFeatures,
    ),
  ];
}

List<MarketProductData> _rodentProductsFor(String subCategory) {
  final suffix = subCategory.toLowerCase().replaceAll(' ', '-');
  return [
    MarketProductData(
      id: 'rodent-$suffix-1',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Hamster Yemi',
      subtitle: '$subCategory — Karışık',
      petTag: 'Kemirgen',
      dietTag: 'Karışık',
      rating: 4.5,
      reviewCount: 47,
      discount: 14,
      weights: ['400 g', '800 g', '1.5 kg'],
      prices: [79.9, 129.9, 219.9],
      oldPrices: [99.9, 159.9, 269.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'rodent-$suffix-2',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Ginepig Pelet Mama',
      subtitle: '$subCategory — Vitamin C',
      petTag: 'Kemirgen',
      dietTag: 'Vitamin C',
      rating: 4.6,
      reviewCount: 61,
      discount: 16,
      weights: ['500 g', '1 kg', '2 kg'],
      prices: [99.9, 169.9, 289.9],
      oldPrices: [119.9, 199.9, 349.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'rodent-$suffix-3',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Kemirgen Talaş',
      subtitle: '$subCategory — Hijyenik',
      petTag: 'Kemirgen',
      dietTag: 'Hijyen',
      rating: 4.4,
      reviewCount: 38,
      discount: 12,
      weights: ['1 kg', '2 kg', '5 kg'],
      prices: [59.9, 99.9, 199.9],
      oldPrices: [74.9, 124.9, 249.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'rodent-$suffix-4',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Hamster Çarkı',
      subtitle: '$subCategory — Sessiz',
      petTag: 'Kemirgen',
      dietTag: 'Oyuncak',
      rating: 4.7,
      reviewCount: 84,
      discount: 18,
      weights: ['S', 'M', 'L'],
      prices: [119.9, 159.9, 209.9],
      oldPrices: [149.9, 199.9, 259.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'rodent-$suffix-5',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Kemirgen Su Şişesi',
      subtitle: '$subCategory — Damlatmaz',
      petTag: 'Kemirgen',
      dietTag: 'Aksesuar',
      rating: 4.3,
      reviewCount: 32,
      discount: 10,
      weights: ['80 ml', '125 ml', '250 ml'],
      prices: [49.9, 69.9, 99.9],
      oldPrices: [59.9, 84.9, 119.9],
      features: petMarketCatFeatures,
    ),
    MarketProductData(
      id: 'rodent-$suffix-6',
      imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      title: 'Kemirgen Vitamin Seti',
      subtitle: '$subCategory — Sağlık',
      petTag: 'Kemirgen',
      dietTag: 'Sağlık',
      rating: 4.5,
      reviewCount: 44,
      discount: 15,
      weights: ['Mini', 'Standart', 'Plus'],
      prices: [89.9, 129.9, 179.9],
      oldPrices: [109.9, 159.9, 219.9],
      features: petMarketCatFeatures,
    ),
  ];
}

List<MarketProductData> _smartProductsFor(String subCategory) {
  final suffix = subCategory.toLowerCase().replaceAll(' ', '-');
  return [
    MarketProductData(
      id: 'smart-$suffix-1',
      imagePath: 'assets/images/market_akilli_pet.png',
      title: 'Otomatik Mama Kabı',
      subtitle: '$subCategory — Wi-Fi',
      petTag: 'Akıllı',
      dietTag: 'Wi-Fi',
      rating: 4.7,
      reviewCount: 84,
      discount: 20,
      weights: ['3 L', '5 L', '6 L'],
      prices: [1999, 2499, 2899],
      oldPrices: [2499, 3099, 3499],
      features: petMarketSmartFeatures,
    ),
    MarketProductData(
      id: 'smart-$suffix-2',
      imagePath: 'assets/images/market_akilli_pet.png',
      title: 'Akıllı Su Pınarı',
      subtitle: '$subCategory — Filtreli',
      petTag: 'Akıllı',
      dietTag: 'Filtreli',
      rating: 4.6,
      reviewCount: 61,
      discount: 18,
      weights: ['2 L', '3 L', '4 L'],
      prices: [1549, 1799, 2099],
      oldPrices: [1899, 2199, 2599],
      features: petMarketSmartFeatures,
    ),
    MarketProductData(
      id: 'smart-$suffix-3',
      imagePath: 'assets/images/market_akilli_pet.png',
      title: 'GPS Takip Tasma',
      subtitle: '$subCategory — Konum',
      petTag: 'Akıllı',
      dietTag: 'GPS',
      rating: 4.5,
      reviewCount: 47,
      discount: 15,
      weights: ['S', 'M', 'L'],
      prices: [1299, 1399, 1499],
      oldPrices: [1529, 1649, 1769],
      features: petMarketSmartFeatures,
    ),
    MarketProductData(
      id: 'smart-$suffix-4',
      imagePath: 'assets/images/market_akilli_pet.png',
      title: 'Pet Kamera Pro',
      subtitle: '$subCategory — 1080p',
      petTag: 'Akıllı',
      dietTag: 'Kamera',
      rating: 4.4,
      reviewCount: 39,
      discount: 12,
      weights: ['Stand', 'Duvar', 'Tavan'],
      prices: [899, 949, 999],
      oldPrices: [1029, 1079, 1139],
      features: petMarketSmartFeatures,
    ),
    MarketProductData(
      id: 'smart-$suffix-5',
      imagePath: 'assets/images/market_akilli_pet.png',
      title: 'Akıllı Kum Kabı',
      subtitle: '$subCategory — Otomatik',
      petTag: 'Akıllı',
      dietTag: 'Temizlik',
      rating: 4.6,
      reviewCount: 73,
      discount: 16,
      weights: ['Kompakt', 'Standart', 'XL'],
      prices: [3499, 4299, 4999],
      oldPrices: [4169, 5119, 5949],
      features: petMarketSmartFeatures,
    ),
    MarketProductData(
      id: 'smart-$suffix-6',
      imagePath: 'assets/images/market_akilli_pet.png',
      title: 'Uzaktan Bakım Seti',
      subtitle: '$subCategory — Kombo',
      petTag: 'Akıllı',
      dietTag: 'Set',
      rating: 4.5,
      reviewCount: 58,
      discount: 14,
      weights: ['Mini', 'Plus', 'Max'],
      prices: [2799, 3299, 3799],
      oldPrices: [3259, 3839, 4429],
      features: petMarketSmartFeatures,
    ),
  ];
}
