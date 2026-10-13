import 'package:geliyor_app/data/health_product_groups.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';

/// Kategori görseli: adminde yüklenen adres varsa o, yoksa bilinen ikon.
String categoryIconPath({
  required String mainId,
  required String title,
  String imageUrl = '',
  List<AppProductAdvantage> catalog = const [],
}) {
  final uploaded = imageUrl.trim();
  if (uploaded.isNotEmpty) return uploaded;

  final group = HealthProductGroup.forCategoryTitle(title);
  if (group != null) {
    final live = ProductAdvantageRepository.iconForHealthGroup(
      group,
      catalog: catalog,
    );
    if (live.trim().isNotEmpty) return live.trim();
    if (group.iconPath.trim().isNotEmpty) return group.iconPath.trim();
  }

  final key = PetLifeStage.normalizeTitle(title);
  if (mainId == 'dog' && (key == 'yavru' || key == 'mini irk yavru')) {
    return 'assets/images/petmarket_kopek_yavru.png';
  }
  return switch (key) {
    'yetiskin' || 'mama' => 'assets/images/petmarket_mama.png',
    'yavru' => 'assets/images/petmarket_yavru.png',
    'kum' => 'assets/images/petmarket_kum.png',
    'odul' => 'assets/images/petmarket_odul.png',
    'bakim' => 'assets/images/petmarket_bakim.png',
    'oyuncak' || 'oyun' => 'assets/images/petmarket_oyun.png',
    'saglik' => 'assets/images/petmarket_saglik.png',
    'tasima' => 'assets/images/petmarket_tasima.png',
    'mini irk' => 'assets/images/petmarket_mini_irk.png',
    'akilli pet' => 'assets/images/petmarket_akilli_ikon.png',
    _ => '',
  };
}
