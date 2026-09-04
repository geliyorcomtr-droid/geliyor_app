import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/data/order_repository.dart';
import 'package:geliyor_app/screens/addresses_screen.dart';
import 'package:geliyor_app/screens/order_success_screen.dart';
import 'package:geliyor_app/state/address_store.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/coupon_store.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/courier_fee.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/coupon_sheet.dart';

class OrderConfirmScreen extends StatefulWidget {
  const OrderConfirmScreen({
    super.key,
    required this.cartTotal,
    required this.itemCount,
    this.saveCartAsLastOrder = false,
  });

  final double cartTotal;
  final int itemCount;
  final bool saveCartAsLastOrder;

  @override
  State<OrderConfirmScreen> createState() => _OrderConfirmScreenState();
}

class _OrderConfirmScreenState extends State<OrderConfirmScreen> {
  String selectedDeliveryTime = 'Sabah';
  String selectedPayment = 'Kapıda Nakit';

  @override
  void initState() {
    super.initState();
    AddressStore.instance.addListener(_onChanged);
    CouponStore.instance.addListener(_onChanged);
    CouponStore.instance.ensureLoaded();
  }

  @override
  void dispose() {
    AddressStore.instance.removeListener(_onChanged);
    CouponStore.instance.removeListener(_onChanged);
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _openAddressPicker() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const AddressesScreen(selectForDelivery: true),
      ),
    );
  }

  Future<void> _submitOrder(String deliveryTime) async {
    if (!AddressStore.instance.hasDeliveryAddress) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş için teslimat adresi ekleyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AddressesScreen(selectForDelivery: true),
        ),
      );
      return;
    }

    final ok = await LoginGate.require(
      context: context,
      message: 'Sipariş vermek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;

    if (!AddressStore.instance.hasDeliveryAddress) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş için teslimat adresi ekleyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      await Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const AddressesScreen(selectForDelivery: true),
        ),
      );
      return;
    }

    try {
      final id = await OrderRepository.instance.placeCurrentCart(
        paymentMethod: selectedPayment,
        deliverySlot: deliveryTime,
      );
      if (id == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sipariş oluşturulamadı. Giriş yapıp tekrar deneyin.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
      OrderStore.instance.saveLastOrderFromCart(orderId: id);
      final coupon = CouponStore.instance.selected;
      final couponDiscount = CouponStore.instance.discountFor(widget.cartTotal);
      await CouponStore.instance.onOrderPlaced();
      CartStore.instance.clear();
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderSuccessScreen(
            cartTotal: widget.cartTotal,
            itemCount: widget.itemCount,
            deliverySlot: selectedDeliveryTime,
            deliveryTime: deliveryTime,
            paymentMethod: selectedPayment,
            couponTitle: coupon?.title ?? '',
            couponDiscount: couponDiscount,
            orderId: id,
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Sipariş gönderilemedi. Lütfen tekrar deneyin.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatPrice(double price) {
    final whole = price.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    final coupons = CouponStore.instance;
    final courierFee = CourierFee.forSubtotal(widget.cartTotal);
    final couponDiscount = coupons.discountFor(widget.cartTotal);
    final payableTotal = coupons.payableTotal(widget.cartTotal);
    final productText = '${_formatPrice(widget.cartTotal)} TL';
    final payableText = '${_formatPrice(payableTotal)} TL';
    final courierText = courierFee > 0
        ? '${_formatPrice(courierFee)} TL'
        : 'Ücretsiz';

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
              _buildHeroBanner(),
              const SizedBox(height: 12),
              _buildAddressSection(),
              const SizedBox(height: 12),
              _buildDeliveryTimeSection(),
              const SizedBox(height: 12),
              _buildPaymentSection(),
              const SizedBox(height: 12),
              _buildCouponSection(couponDiscount),
              const SizedBox(height: 12),
              _buildOrderSummary(
                productText,
                courierText,
                payableText,
                courierFee,
                couponDiscount,
              ),
              const SizedBox(height: 10),
              _buildCompleteButton(payableText),
              const SizedBox(height: 8),
              _buildTrustBadges(CourierFee.isFree(widget.cartTotal)),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          const Expanded(
            child: Text(
              'Siparişini Onayla',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageHeader,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.verified_user_outlined,
                  color: AppColors.primary,
                  size: 13,
                ),
                SizedBox(width: 4),
                Text(
                  'Güvenli',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${widget.itemCount} ürün hazır',
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                const Text(
                  'Adres ve ödeme bilgisini onaylayın.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          AppPressableButton.soft(
            onTap: () => Navigator.of(context).maybePop(),
            height: 32,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: const Text('Düzenle', style: TextStyle(fontSize: 11)),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressSection() {
    final hasAddress = AddressStore.instance.hasDeliveryAddress;
    final address = hasAddress ? AddressStore.instance.defaultAddress : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          '1',
          'Teslimat Adresi',
          showChange: true,
          onChange: _openAddressPicker,
        ),
        const SizedBox(height: 8),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: _openAddressPicker,
            borderRadius: BorderRadius.circular(24),
            child: Ink(
              padding: const EdgeInsets.all(12),
              decoration: _cardDecoration(),
              child: address == null
              ? Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Kayıtlı adres yok. Lütfen adres ekleyin.',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    AppPressableButton.primary(
                      onTap: _openAddressPicker,
                      height: 32,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: const Text(
                        'Adres Ekle',
                        style: TextStyle(fontSize: 11),
                      ),
                    ),
                  ],
                )
              : Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Icon(
                        address.icon,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              _TagChip(label: address.title),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  address.address,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          if (address.cityDistrictLabel.isNotEmpty)
                            Text(
                              address.cityDistrictLabel,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          if (address.cityDistrictLabel.isNotEmpty)
                            const SizedBox(height: 4),
                          Text(
                            address.contactName,
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDeliveryTimeSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('2', 'Teslimat Zamanı'),
        const SizedBox(height: 4),
        const Text(
          'Size en uygun teslimat zamanını seçin.',
          style: TextStyle(
            color: AppColors.subText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _timeCard('Sabah', '09:00 - 12:00', Icons.wb_sunny_outlined),
        const SizedBox(height: 6),
        _timeCard('Öğle', '12:00 - 18:00', Icons.wb_twilight_outlined),
        const SizedBox(height: 6),
        _timeCard('Akşam', '19:00 - 22:00', Icons.nightlight_round),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.selected,
            borderRadius: BorderRadius.circular(999),
          ),
          child: const Row(
            children: [
              Icon(Icons.schedule_rounded, color: AppColors.primary, size: 15),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Belirtilen saat aralığında kapınızdayız.',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _timeCard(String id, String time, IconData icon) {
    final selected = selectedDeliveryTime == id;

    return GestureDetector(
      onTap: () => setState(() => selectedDeliveryTime = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.selected : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 1.6 : 1.2,
          ),
        ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    time,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCouponSection(double couponDiscount) {
    final selected = CouponStore.instance.selected;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('4', 'Kupon'),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => CouponSheet.show(context, subtotal: widget.cartTotal),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected != null ? AppColors.selected : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected != null
                    ? AppColors.primaryLight
                    : AppColors.border,
                width: selected != null ? 1.6 : 1.2,
              ),
            ),
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
                  child: const Icon(
                    Icons.local_offer_outlined,
                    color: AppColors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selected == null ? 'Kupon kullan' : selected.title,
                        style: TextStyle(
                          color: selected != null
                              ? AppColors.primary
                              : AppColors.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        selected == null
                            ? 'Tanımlı veya kazandığınız kuponları uygulayın'
                            : '${selected.code} · -${_formatPrice(couponDiscount)} TL',
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  selected != null
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected != null
                      ? AppColors.primary
                      : AppColors.subText,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('3', 'Ödeme Yöntemi'),
        const SizedBox(height: 4),
        const Text(
          'Şimdi al, online ödeme yok.',
          style: TextStyle(
            color: AppColors.subText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        _paymentOption(
          'Kapıda Nakit',
          'Teslimatta nakit ödeme',
          Icons.payments_outlined,
        ),
        const SizedBox(height: 6),
        _paymentOption(
          'Kapıda Kredi Kartı / POS',
          'POS cihazı ile ödeme',
          Icons.credit_card_outlined,
        ),
        const SizedBox(height: 6),
        _paymentOption(
          'Havale / EFT',
          'Banka transferi',
          Icons.account_balance_outlined,
        ),
        if (selectedPayment == 'Havale / EFT') ...[
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'IBAN bilgileri bir sonraki sayfada paylaşılacaktır.',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _paymentOption(String id, String subtitle, IconData icon) {
    final selected = selectedPayment == id;

    return GestureDetector(
      onTap: () => setState(() => selectedPayment = id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.selected : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primaryLight : AppColors.border,
            width: selected ? 1.6 : 1.2,
          ),
        ),
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
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    id,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.border,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummary(
    String productText,
    String courierText,
    String payableText,
    double courierFee,
    double couponDiscount,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('5', 'Sipariş Özeti'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _summaryRow('${widget.itemCount} ürün', productText),
              if (couponDiscount > 0) ...[
                const SizedBox(height: 6),
                _summaryRow(
                  'Kupon',
                  '-${_formatPrice(couponDiscount)} TL',
                  valueColor: AppColors.primary,
                ),
              ],
              const SizedBox(height: 6),
              _summaryRow(
                'Getirme ücreti',
                courierText,
                valueColor: courierFee > 0 ? AppColors.text : AppColors.primary,
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Divider(height: 1, color: AppColors.border),
              ),
              Row(
                children: [
                  const Text(
                    'Ödenecek tutar',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    payableText,
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
        ),
      ],
    );
  }

  Widget _summaryRow(String label, String value, {Color? valueColor}) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.subText,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            color: valueColor ?? AppColors.text,
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildCompleteButton(String payableText) {
    final deliveryTime = selectedDeliveryTime == 'Sabah'
        ? '09:00 - 12:00'
        : selectedDeliveryTime == 'Öğle'
        ? '12:00 - 18:00'
        : '19:00 - 22:00';

    return AppPressableButton.primary(
      onTap: () {
        unawaited(_submitOrder(deliveryTime));
      },
      width: double.infinity,
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          const Icon(Icons.delivery_dining_rounded, size: 24),
          const SizedBox(width: 8),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Siparişi Tamamla',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w900),
                ),
                Text(
                  '3 saat içinde kapında',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          Text(
            payableText,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.chevron_right_rounded, size: 22),
        ],
      ),
    );
  }

  Widget _buildTrustBadges(bool courierFree) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _TrustBadge(
            icon: Icons.delivery_dining_rounded,
            label: courierFree ? 'Ücretsiz Kurye' : 'Hızlı Kurye',
          ),
          const _TrustBadge(icon: Icons.shield_outlined, label: 'Güvenli Teslimat'),
          const _TrustBadge(icon: Icons.support_agent_rounded, label: '7/24 Destek'),
        ],
      ),
    );
  }

  Widget _sectionHeader(
    String number,
    String title, {
    bool showChange = false,
    VoidCallback? onChange,
  }) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: AppTextStyles.sectionHeader)),
        if (showChange)
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onChange,
            child: const Row(
              children: [
                Text(
                  'Değiştir',
                  style: TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
              ],
            ),
          ),
      ],
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 9,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _TrustBadge extends StatelessWidget {
  const _TrustBadge({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: AppColors.primary, size: 14),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(
            color: AppColors.subText,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
