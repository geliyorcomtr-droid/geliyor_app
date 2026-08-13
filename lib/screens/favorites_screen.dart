import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/favorite_store.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/cart_product_card.dart';

enum _FavoriteTab { products, pets, categories }

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  _FavoriteTab _activeTab = _FavoriteTab.products;
  final Map<String, int> _quantities = {};

  static const _categories = [
    _FavoriteCategory(
      title: 'Kedi Mamaları',
      subtitle: 'Kuru ve yaş mama',
      icon: Icons.rice_bowl_rounded,
      count: 24,
    ),
    _FavoriteCategory(
      title: 'Sağlık Ürünleri',
      subtitle: 'Takviye ve bakım',
      icon: Icons.medical_services_outlined,
      count: 12,
    ),
    _FavoriteCategory(
      title: 'Akıllı Pet',
      subtitle: 'Otomatik ürünler',
      icon: Icons.auto_awesome_rounded,
      count: 8,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final pets = PetStore.instance.pets.take(2).toList();

    return ListenableBuilder(
      listenable: FavoriteStore.instance,
      builder: (context, _) {
        final products = FavoriteStore.instance.items;

        return Scaffold(
          backgroundColor: AppColors.background,
          body: AppPageFrame.standard(
            backgroundColor: AppColors.background,
            activeTab: AppNavTab.profile,
            header: _buildHeader(context),
            content: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                  child: _buildTabs(pets.length, products.length),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Column(
                      children: [
                        ...switch (_activeTab) {
                          _FavoriteTab.products => products.isEmpty
                              ? [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 24,
                                    ),
                                    child: Text(
                                      'Henüz favori ürününüz yok.',
                                      style: TextStyle(
                                        color: AppColors.subText
                                            .withValues(alpha: 0.95),
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ]
                              : products
                                  .map(
                                    (product) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: _buildProductCard(product),
                                    ),
                                  )
                                  .toList(),
                          _FavoriteTab.pets => pets
                              .map(
                                (pet) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildPetCard(
                                    pet.name,
                                    pet.species,
                                    pet.imagePath,
                                  ),
                                ),
                              )
                              .toList(),
                          _FavoriteTab.categories => _categories
                              .map(
                                (category) => Padding(
                                  padding: const EdgeInsets.only(bottom: 10),
                                  child: _buildCategoryCard(category),
                                ),
                              )
                              .toList(),
                        },
                        _buildInfoBanner(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            navbar: const AppBottomNavbar(activeTab: AppNavTab.profile),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Favorilerim',
                  textAlign: TextAlign.center,
                  style: AppTextStyles.pageHeader,
                ),
                Text(
                  'Beğendiğiniz ürün, kategori ve dostları kolayca bulabilirsiniz.',
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.subText.withValues(alpha: 0.95),
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildTabs(int petCount, int productCount) {
    return Row(
      children: [
        Expanded(
          child: _buildTabChip(
            icon: Icons.shopping_bag_outlined,
            label: 'Ürünlerim ($productCount)',
            selected: _activeTab == _FavoriteTab.products,
            onTap: () => setState(() => _activeTab = _FavoriteTab.products),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildTabChip(
            icon: Icons.pets_rounded,
            label: 'Dostlarım ($petCount)',
            selected: _activeTab == _FavoriteTab.pets,
            onTap: () => setState(() => _activeTab = _FavoriteTab.pets),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: _buildTabChip(
            icon: Icons.grid_view_rounded,
            label: 'Kategorilerim (${_categories.length})',
            selected: _activeTab == _FavoriteTab.categories,
            onTap: () => setState(() => _activeTab = _FavoriteTab.categories),
          ),
        ),
      ],
    );
  }

  Widget _buildTabChip({
    required IconData icon,
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 13,
              color: selected ? AppColors.surface : AppColors.subText,
            ),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.surface : AppColors.subText,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductCard(FavoriteItem product) {
    final qty = _quantities[product.id] ?? 1;

    return CartProductCard(
      item: CartItem(
        id: product.id,
        imagePath: product.imagePath,
        title: product.title,
        unitPrice: product.unitPrice,
        oldPrice: product.oldPrice,
        discountPercent: product.discountPercent,
        weight: product.weight,
        brand: product.brand,
        quantity: qty,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
      ),
      onQuantityChanged: (next) {
        setState(() => _quantities[product.id] = next);
      },
      onAddToCart: () {
        final count = _quantities[product.id] ?? 1;
        for (var i = 0; i < count; i++) {
          CartStore.instance.addItem(
            id: product.id,
            imagePath: product.imagePath,
            title: product.title,
            unitPrice: product.unitPrice,
            oldPrice: product.oldPrice,
            discountPercent: product.discountPercent,
            weight: product.weight,
          );
        }
        _showAddedToCartDialog(product.title);
      },
    );
  }

  void _showAddedToCartDialog(String productTitle) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: AppPageFrame.width - 48,
              constraints: const BoxConstraints(maxHeight: 280),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Ürün sepete eklenmiştir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppPressableButton.primary(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    width: double.infinity,
                    height: 40,
                    child: const Text(
                      'Sepete Git',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppPressableButton.outline(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    width: double.infinity,
                    height: 40,
                    child: const Text(
                      'Alışverişe Devam Et',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPetCard(String name, String species, String imagePath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border, width: 2),
            ),
            child: ClipOval(
              child: Image.asset(
                imagePath,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.pets_rounded,
                  color: AppColors.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  species,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.subText, size: 20),
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_FavoriteCategory category) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(category.icon, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.title,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  '${category.subtitle} • ${category.count} ürün',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.favorite_rounded, color: AppColors.error, size: 16),
          const SizedBox(width: 6),
          const Icon(Icons.chevron_right_rounded,
              color: AppColors.subText, size: 20),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: const BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.pets_rounded, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Fiyatlar değişebilir. Favorilere eklediğiniz ürünlerin fiyatları zaman içinde güncellenebilir.',
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: AppColors.primary.withValues(alpha: 0.8),
            size: 20,
          ),
        ],
      ),
    );
  }
}

class _FavoriteCategory {
  const _FavoriteCategory({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.count,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final int count;
}
