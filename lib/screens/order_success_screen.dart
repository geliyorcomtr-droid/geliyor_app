import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/screens/gift_select_screen.dart';
import 'package:geliyor_app/screens/home_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class OrderSuccessScreen extends StatelessWidget {
  const OrderSuccessScreen({
    super.key,
    required this.cartTotal,
    required this.itemCount,
    this.deliverySlot = 'Sabah',
    this.deliveryTime = '09:00 - 12:00',
    this.paymentMethod = 'Kapıda Nakit',
  });

  final double cartTotal;
  final int itemCount;
  final String deliverySlot;
  final String deliveryTime;
  final String paymentMethod;

  static const String ibanHolder = 'FATİH EROĞLU';
  static const String ibanNumber = 'TR64 0006 2000 1234 5678 9012 34';

  bool get _isBankTransfer => paymentMethod == 'Havale / EFT';

  String get _orderNo {
    final stamp = DateTime.now().millisecondsSinceEpoch % 10000000;
    return '#GLR$stamp';
  }

  String get _orderDate {
    const months = [
      'Ocak',
      'Şubat',
      'Mart',
      'Nisan',
      'Mayıs',
      'Haziran',
      'Temmuz',
      'Ağustos',
      'Eylül',
      'Ekim',
      'Kasım',
      'Aralık',
    ];
    final now = DateTime.now();
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    return '${now.day} ${months[now.month - 1]} ${now.year} • $hour:$minute';
  }

  String get _orderTime {
    final now = DateTime.now();
    return '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
  }

  String _formatPrice(double price) {
    final whole = price.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '${buffer.toString()} TL';
  }

  void _goHome(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final totalText = _formatPrice(cartTotal);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(context),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSuccessBanner(),
              const SizedBox(height: 12),
              _buildStatusTracker(),
              const SizedBox(height: 12),
              _buildDeliveryCard(),
              const SizedBox(height: 12),
              if (_isBankTransfer) ...[
                _buildIbanCard(context),
                const SizedBox(height: 12),
              ],
              _buildOrderDetails(context, totalText),
              const SizedBox(height: 12),
              _buildGiftButton(context),
              const SizedBox(height: 8),
              _buildContinueButton(context),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.home),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          AppBackButton(onPressed: () => _goHome(context)),
          const Expanded(
            child: Text(
              'Sipariş Alındı',
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
                  Icons.check_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 13,
                ),
                SizedBox(width: 4),
                Text(
                  'Onaylandı',
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

  Widget _buildSuccessBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.selected,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.check_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Siparişiniz alındı',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F9EE),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Onaylandı',
                        style: TextStyle(
                          color: AppColors.success,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text(
                  'Teşekkür ederiz. Siparişiniz işleme alındı, en kısa sürede kapınızdayız.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusTracker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('1', 'Sipariş Durumu'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.fromLTRB(8, 14, 8, 12),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _buildStatusStep(
                icon: Icons.shopping_bag_outlined,
                label: 'Alındı',
                time: _orderTime,
                active: true,
              ),
              Expanded(child: Container(height: 2, color: AppColors.primary)),
              _buildStatusStep(
                icon: Icons.inventory_2_outlined,
                label: 'Hazırlanıyor',
                active: false,
              ),
              Expanded(child: Container(height: 2, color: AppColors.border)),
              _buildStatusStep(
                icon: Icons.delivery_dining_rounded,
                label: 'Yolda',
                active: false,
              ),
              Expanded(child: Container(height: 2, color: AppColors.border)),
              _buildStatusStep(
                icon: Icons.home_outlined,
                label: 'Teslim',
                active: false,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusStep({
    required IconData icon,
    required String label,
    String? time,
    required bool active,
  }) {
    return SizedBox(
      width: 62,
      child: Column(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: active ? AppColors.primary : AppColors.border,
                width: 1.4,
              ),
            ),
            child: Icon(
              icon,
              size: 16,
              color: active ? AppColors.surface : AppColors.subText,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: active ? AppColors.primary : AppColors.subText,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            time ?? ' ',
            style: TextStyle(
              color: active ? AppColors.primary : Colors.transparent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('2', 'Tahmini Teslimat'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.selected,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.border),
                ),
                child: const Icon(
                  Icons.delivery_dining_rounded,
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
                      deliveryTime,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$deliverySlot teslimat dilimi',
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Siparişiniz yola çıktığında bildirim gönderilir.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIbanCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(_isBankTransfer ? '3' : '2', 'Havale / EFT Bilgileri'),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.selected,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Ödemeyi aşağıdaki IBAN’a yapmanız yeterlidir.',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              _ibanInfoRow(label: 'Alıcı', value: ibanHolder),
              const SizedBox(height: 10),
              _ibanInfoRow(
                label: 'IBAN',
                value: ibanNumber,
                copyable: true,
                onCopy: () => _copyIban(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ibanInfoRow({
    required String label,
    required String value,
    bool copyable = false,
    VoidCallback? onCopy,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w900,
              height: 1.3,
            ),
          ),
        ),
        if (copyable)
          GestureDetector(
            onTap: onCopy,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: AppColors.selected,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.copy_rounded,
                color: AppColors.primary,
                size: 15,
              ),
            ),
          ),
      ],
    );
  }

  void _copyIban(BuildContext context) {
    Clipboard.setData(ClipboardData(text: ibanNumber.replaceAll(' ', '')));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('IBAN kopyalandı'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, String totalText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(_isBankTransfer ? '4' : '3', 'Sipariş Detayı'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              _detailRow(
                icon: Icons.tag_rounded,
                label: 'Sipariş No',
                value: _orderNo,
              ),
              const SizedBox(height: 10),
              _detailRow(
                icon: Icons.calendar_today_outlined,
                label: 'Sipariş Tarihi',
                value: _orderDate,
              ),
              const SizedBox(height: 10),
              _detailRow(
                icon: Icons.shopping_bag_outlined,
                label: 'Ürün',
                value: '$itemCount adet',
              ),
              const SizedBox(height: 10),
              _detailRow(
                icon: Icons.payments_outlined,
                label: 'Ödeme',
                value: paymentMethod,
              ),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Divider(
                  height: 1,
                  color: AppColors.border.withValues(alpha: 0.7),
                ),
              ),
              _detailRow(
                icon: Icons.local_shipping_outlined,
                label: 'Teslimat',
                value: 'Ücretsiz',
                valueColor: AppColors.primary,
              ),
              const SizedBox(height: 10),
              _detailRow(
                icon: Icons.payments_outlined,
                label: 'Toplam',
                value: totalText,
                valueColor: AppColors.primary,
                bold: true,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool bold = false,
  }) {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: AppColors.selected,
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.border),
          ),
          child: Icon(icon, color: AppColors.primary, size: 15),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.text,
              fontSize: bold ? 14 : 12,
              fontWeight: bold ? FontWeight.w900 : FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }

  Widget _sectionHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: AppTextStyles.sectionHeader)),
      ],
    );
  }

  Widget _buildGiftButton(BuildContext context) {
    return AppPressableButton.outline(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GiftSelectScreen(orderTotal: cartTotal),
          ),
        );
      },
      width: double.infinity,
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.card_giftcard_rounded, size: 20),
          SizedBox(width: 8),
          Text(
            'Dostun için Hediye Seç',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }

  Widget _buildContinueButton(BuildContext context) {
    return AppPressableButton.primary(
      onTap: () => _goHome(context),
      width: double.infinity,
      height: 48,
      child: const Text(
        'Alışverişe Devam Et',
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
