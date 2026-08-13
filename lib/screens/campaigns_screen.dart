import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key});

  static void _openProducts(
    BuildContext context, {
    String mainCategory = 'cat',
    String? subCategory,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PetMarketProductsScreen(
          initialMainCategory: mainCategory,
          initialSubCategory: subCategory,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FilterSubpageLayout(
      title: 'Kampanyalar',
      items: [
        FilterSubpageItem(
          title: 'Ayın Fırsatları',
          subtitle: 'Ay boyunca geçerli indirimli ürünler',
          icon: Icons.calendar_month_rounded,
          iconColor: AppColors.primary,
          emoji: '🎁',
          onTap: () => _openProducts(context),
        ),
        FilterSubpageItem(
          title: 'Günün Fırsatları',
          subtitle: 'Bugün geçerli sınırlı süreli fırsatlar',
          icon: Icons.alarm_rounded,
          iconColor: AppColors.warning,
          emoji: '🎁',
          onTap: () => _openProducts(context),
        ),
        FilterSubpageItem(
          title: 'Kedi Kampanyaları',
          subtitle: 'Kedi ürünlerinde özel indirimler',
          imagePath: 'assets/images/urunler_kedi.png',
          emoji: '🎁',
          onTap: () => _openProducts(context, mainCategory: 'cat'),
        ),
        FilterSubpageItem(
          title: 'Köpek Kampanyaları',
          subtitle: 'Köpek ürünlerinde özel indirimler',
          imagePath: 'assets/images/urunler_kopek.png',
          emoji: '🎁',
          onTap: () => _openProducts(context, mainCategory: 'dog'),
        ),
        FilterSubpageItem(
          title: 'İndirimli Mamalar',
          subtitle: 'Seçili mamalarda avantajlı fiyatlar',
          imagePath: 'assets/images/petmarket_mama.png',
          emoji: '🎁',
          onTap: () => _openProducts(context, subCategory: 'Mama'),
        ),
        FilterSubpageItem(
          title: 'Sepete Özel Fırsatlar',
          subtitle: 'Ekstra indirim ve hediye kampanyaları',
          imagePath: 'assets/images/cok_satan_urunler.png',
          emoji: '🎁',
          onTap: () => _openProducts(context),
        ),
      ],
    );
  }
}
