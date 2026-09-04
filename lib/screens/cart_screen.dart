import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/order_confirm_screen.dart';
import 'package:geliyor_app/screens/product_detail_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/coupon_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/courier_fee.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/cart_product_card.dart';
import 'package:geliyor_app/widgets/coupon_sheet.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  @override
  void initState() {
    super.initState();
    CouponStore.instance.ensureLoaded();
  }

  String _formatPrice(double price, {bool withDecimals = false}) {
    final fixed = withDecimals ? price.toStringAsFixed(2) : price.round().toString();
    final parts = fixed.split('.');
    final whole = parts.first;
    final buffer = StringBuffer();

    for (int i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) {
        buffer.write('.');
      }
    }

    if (withDecimals && parts.length > 1) {
      return '${buffer.toString()},${parts.last}';
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        CartStore.instance,
        CouponStore.instance,
      ]),
      builder: (context, _) {
        final cart = CartStore.instance;
        final cartItems = cart.items;
        final totalQuantity = cart.totalQuantity;
        final cartTotal = cart.cartTotal;
        final cartDiscount = cart.cartDiscount;
        final courierFee = cart.courierFee;
        final payableTotal = CouponStore.instance.payableTotal(cartTotal);

        return Scaffold(
          backgroundColor: AppColors.background,
          body: AppPageFrame.standard(
            backgroundColor: AppColors.background,
            activeTab: AppNavTab.cart,
            header: _buildHeader(totalQuantity),
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(
                        Icons.shopping_bag_outlined,
                        color: AppColors.primary,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sepetim ($totalQuantity ürün)',
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  for (int i = 0; i < cartItems.length; i++) ...[
                    _buildProductCard(i, cartItems[i]),
                    if (i != cartItems.length - 1) const SizedBox(height: 8),
                  ],
                  const SizedBox(height: 10),
                  _buildSummaryCard(cartTotal, cartDiscount, courierFee, payableTotal),
                  const SizedBox(height: 10),
                  _buildCheckoutBar(cartTotal, payableTotal, totalQuantity),
                ],
              ),
            ),
            navbar: const AppBottomNavbar(activeTab: AppNavTab.cart),
          ),
        );
      },
    );
  }

  Widget _buildHeader(int totalQuantity) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Sepetim',
                  style: AppTextStyles.pageHeader,
                ),
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.selected,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(color: AppColors.primary, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    '$totalQuantity',
                    style: AppTextStyles.pageHeader,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(
            width: 40,
            child: Icon(Icons.pets_rounded, color: AppColors.primary, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow() {
    return Column(
      children: [
        _infoBanner(
          icon: Icons.delivery_dining_rounded,
          child: RichText(
            text: const TextSpan(
              style: TextStyle(
                color: AppColors.text,
                fontSize: 11.5,
                height: 1.3,
                fontWeight: FontWeight.w600,
              ),
              children: [
                TextSpan(text: 'Siparişiniz '),
                TextSpan(
                  text: '3 saat',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(text: ' içinde kapınızda.'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoBanner({required IconData icon, required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: _pillDecoration(fill: AppColors.selected),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(child: child),
        ],
      ),
    );
  }

  Widget _buildProductCard(int index, CartItem item) {
    return CartProductCard(
      item: item,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const ProductDetailScreen()),
      ),
      onQuantityChanged: (qty) => _syncCartQuantity(index, qty),
      onRemove: () => CartStore.instance.removeItem(index),
    );
  }

  void _syncCartQuantity(int index, int targetQty) {
    final items = CartStore.instance.items;
    if (index < 0 || index >= items.length) return;
    final current = items[index].quantity;
    if (targetQty > current) {
      for (var i = 0; i < targetQty - current; i++) {
        CartStore.instance.increaseQuantity(index);
      }
    } else if (targetQty < current) {
      for (var i = 0; i < current - targetQty; i++) {
        CartStore.instance.decreaseQuantity(index);
      }
    }
  }

  Widget _buildSummaryCard(
    double cartTotal,
    double cartDiscount,
    double courierFee,
    double payableTotal,
  ) {
    final cartOldTotal = cartTotal + cartDiscount;
    final remainingForFree = CourierFee.remainingForFree(cartTotal);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _pillDecoration(),
      child: Column(
        children: [
          _summaryRow('Ara toplam', '${_formatPrice(cartOldTotal)} TL'),
          const SizedBox(height: 6),
          _summaryRow(
            'Sepet indirimi',
            '-${_formatPrice(cartDiscount)} TL',
            valueColor: AppColors.primary,
          ),
          const SizedBox(height: 6),
          _summaryRow(
            'Getirme ücreti',
            courierFee > 0 ? '${_formatPrice(courierFee)} TL' : 'Ücretsiz',
            valueColor: courierFee > 0 ? AppColors.text : AppColors.primary,
          ),
          const SizedBox(height: 10),
          _couponRow(cartTotal),
          if (CouponStore.instance.discountFor(cartTotal) > 0) ...[
            const SizedBox(height: 10),
            _summaryRow(
              'Kupon',
              '-${_formatPrice(CouponStore.instance.discountFor(cartTotal))} TL',
              valueColor: AppColors.primary,
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1, color: AppColors.border),
          ),
          _summaryRow(
            'Ödenecek tutar',
            '${_formatPrice(payableTotal)} TL',
            bold: true,
            valueColor: AppColors.primary,
          ),
          const SizedBox(height: 10),
          if (cartDiscount > 0) ...[
            _summaryBanner(
              icon: Icons.local_offer_outlined,
              text: '${_formatPrice(cartDiscount)} TL sepette indirim uygulandı',
            ),
            const SizedBox(height: 8),
          ],
          _summaryBanner(
            icon: Icons.delivery_dining_rounded,
            text: remainingForFree > 0
                ? 'Ücretsiz kurye için ${_formatPrice(remainingForFree)} TL daha ekleyin'
                : '599 TL ve üzeri siparişlerde getirme ücreti yok',
          ),
        ],
      ),
    );
  }

  Widget _couponRow(double cartTotal) {
    final selected = CouponStore.instance.selected;
    return GestureDetector(
      onTap: () {
        CouponStore.instance.ensureLoaded();
        CouponSheet.show(context, subtotal: cartTotal);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected != null ? AppColors.selected : AppColors.background,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected != null ? AppColors.primaryLight : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.local_offer_outlined,
              color: AppColors.primary,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                selected == null
                    ? 'Kupon kullan'
                    : '${selected.code} uygulandı',
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              selected == null ? 'Seç' : 'Değiştir',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _summaryBanner({required IconData icon, required String text}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary, width: 1.5),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryRow(
    String label,
    String value, {
    bool bold = false,
    Color? valueColor,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: TextStyle(
            color: bold ? AppColors.text : AppColors.subText,
            fontSize: bold ? 13 : 12,
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.text,
            fontSize: bold ? 15 : 12,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutBar(
    double cartTotal,
    double payableTotal,
    int totalQuantity,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
      decoration: _pillDecoration(),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Toplam',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${_formatPrice(payableTotal)} TL',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          AppPressableButton.primary(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => OrderConfirmScreen(
                    cartTotal: cartTotal,
                    itemCount: totalQuantity,
                    saveCartAsLastOrder: true,
                  ),
                ),
              );
            },
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.pets_rounded, size: 18),
                SizedBox(width: 6),
                Text(
                  'Sepeti Onayla',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _pillDecoration({Color fill = AppColors.surface}) {
    return BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
