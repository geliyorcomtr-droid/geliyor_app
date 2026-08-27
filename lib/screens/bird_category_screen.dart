import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/pet_market_products_screen.dart';
import 'package:geliyor_app/widgets/filter_subpage_layout.dart';

class BirdCategoryScreen extends StatelessWidget {
  const BirdCategoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FilterSubpageLayout(
      title: 'Kuş',
      items: [
        FilterSubpageItem(
          title: 'Kuş Ürünleri',
          subtitle: 'Yem, aksesuar ve bakım ürünleri',
          imagePath: 'assets/images/urunler_kus.png',
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const PetMarketProductsScreen(
                  initialMainCategory: 'bird',
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
