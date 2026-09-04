import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/order_confirm_screen.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/courier_fee.dart';
import 'package:geliyor_app/utils/product_price.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/cart_product_card.dart';

class EasyOrderScreen extends StatefulWidget {
  const EasyOrderScreen({super.key});

  @override
  State<EasyOrderScreen> createState() => _EasyOrderScreenState();
}

class _EasyOrderScreenState extends State<EasyOrderScreen> {
  late final List<_EasyOrderItem> _items;

  @override
  void initState() {
    super.initState();
    _items = OrderStore.instance.lastOrderItems
        .map(
          (item) => _EasyOrderItem(
            title: item.title,
            subtitle: item.subtitle,
            weight: item.weight,
            badge: 'Son siparişinden',
            price: item.price,
            oldPrice: item.oldPrice,
            imagePath: item.imagePath,
            quantity: item.quantity,
          ),
        )
        .toList();
  }

  double get _subtotal =>
      _items.fold(0, (sum, item) => sum + item.price * item.quantity);

  double get _courierFee => CourierFee.forSubtotal(_subtotal);

  double get _payableTotal => CourierFee.payableTotal(_subtotal);

  String _formatPrice(double price) {
    final whole = price.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '₺${buffer.toString()},00';
  }

  void _remove(int index) {
    if (_items.length <= 1) return;
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 12),
              _buildProductsHeader(),
              const SizedBox(height: 8),
              for (int i = 0; i < _items.length; i++) ...[
                _buildProductCard(i, _items[i]),
                if (i != _items.length - 1) const SizedBox(height: 8),
              ],
              const SizedBox(height: 8),
              _buildAddProductRow(),
              const SizedBox(height: 12),
              _buildSummaryRow(),
              const SizedBox(height: 10),
              _buildConfirmButton(),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.home),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: IgnorePointer(
              child: Text(
                'Kolay Sipariş',
                textAlign: TextAlign.center,
                style: AppTextStyles.pageHeader,
              ),
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return const AppBannerSlot(
      placement: BannerPlacement.easyOrder,
      fallbackAssets: ['assets/images/kolay_siparis_banner.png'],
    );
  }

  Widget _buildProductsHeader() {
    final order = OrderStore.instance;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Son Siparişini Tekrarla',
                style: AppTextStyles.sectionHeader,
              ),
              const SizedBox(height: 2),
              Text(
                order.hasLastOrder
                    ? 'Sipariş No: ${order.lastOrderId} · ${order.lastOrderDate}\nÜrünleri incele, gerekirse düzenle ve onayla.'
                    : 'Henüz siparişin yok. İlk siparişini oluşturduğunda burada görünecek.',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProductCard(int index, _EasyOrderItem item) {
    return CartProductCard(
      item: CartItem(
        id: '${item.title}-$index',
        imagePath: item.imagePath,
        title: item.title,
        unitPrice: item.price,
        oldPrice: item.oldPrice,
        discountPercent:
            discountPercentFromPrices(item.price, item.oldPrice) ?? 15,
        weight: item.weight,
        brand: item.badge == 'Son siparişinden' ? null : item.badge,
        quantity: item.quantity,
      ),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
      ),
      onQuantityChanged: (qty) => setState(() => _items[index].quantity = qty),
      onRemove: () => _remove(index),
    );
  }

  Widget _buildAddProductRow() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: const Row(
          children: [
            Icon(Icons.add_circle_outline_rounded, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Ürün Ekle',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow() {
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
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.selected,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.delivery_dining_rounded,
              color: AppColors.primary,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tahmini Teslimat',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'Yarın, 10:00 - 12:00 arası',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _courierFee > 0
                    ? '${CourierFee.amount.round()} TL getirme ücreti'
                    : 'Kurye ücretsiz',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _formatPrice(_payableTotal),
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    return AppPressableButton.outline(
      onTap: _items.isEmpty
          ? null
          : () {
              OrderStore.instance.setLastOrder(
                items: _items
                    .map(
                      (item) => LastOrderItem(
                        id: '${item.title}-${item.weight}',
                        title: item.title,
                        subtitle: item.subtitle,
                        weight: item.weight,
                        price: item.price,
                        oldPrice: item.oldPrice,
                        imagePath: item.imagePath,
                        quantity: item.quantity,
                      ),
                    )
                    .toList(),
              );
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderConfirmScreen(
                    cartTotal: _subtotal,
                    itemCount: _items.fold(0, (s, i) => s + i.quantity),
                  ),
                ),
              );
            },
      width: double.infinity,
      height: 52,
      padding: EdgeInsets.zero,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_outline_rounded, size: 16),
              SizedBox(width: 6),
              Text(
                'Siparişi Onayla',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            _formatPrice(_payableTotal),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _EasyOrderItem {
  _EasyOrderItem({
    required this.title,
    required this.subtitle,
    required this.weight,
    required this.badge,
    required this.price,
    required this.oldPrice,
    required this.imagePath,
    this.quantity = 1,
  });

  final String title;
  final String subtitle;
  final String weight;
  final String badge;
  final double price;
  final double oldPrice;
  final String imagePath;
  int quantity;
}
