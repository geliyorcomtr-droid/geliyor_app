import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/auto_order_settings_screen.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/food_tracking_screen.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/info_guide_sheet.dart';

class SmartPlanScreen extends StatefulWidget {
  const SmartPlanScreen({super.key});

  @override
  State<SmartPlanScreen> createState() => _SmartPlanScreenState();
}

class _SmartPlanScreenState extends State<SmartPlanScreen> {
  /// Ana sayfa servis kartlarıyla aynı tonlar.
  static const _easyOrderColor = Color(0xFF22C55E); // Kolay Sipariş
  static const _knowledgeColor = Color(0xFFF59E0B); // Bilgi Bankası
  static const _hangiMamaColor = Color(0xFF8B5CF6); // Hangi Mama

  Color _softFill(Color color) => color.withValues(alpha: 0.12);

  Color _buttonFill(Color color) =>
      Color.lerp(color, Colors.white, 0.28) ?? color;

  TextStyle _sectionTitle(Color color) => TextStyle(
    fontFamily: AppTextStyles.fontFamily,
    color: color,
    fontSize: 16,
    fontWeight: FontWeight.w900,
    height: 1.15,
    letterSpacing: -0.2,
  );

  TextStyle _bodyText(Color color) => const TextStyle(
    color: AppColors.text,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    height: 1.35,
  );

  TextStyle _accentText(Color color) => TextStyle(
    color: color,
    fontSize: 12,
    fontWeight: FontWeight.w900,
    height: 1.3,
  );

  TextStyle _chipText(Color color, {bool selected = false}) => TextStyle(
    color: selected ? color : AppColors.text,
    fontSize: 12,
    fontWeight: FontWeight.w800,
  );

  Widget _coloredButton({
    required Color color,
    required VoidCallback onTap,
    required Widget child,
    double height = 36,
    double? width,
    bool solid = false,
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12),
  }) {
    final fill = solid ? color : _buttonFill(color);
    return AppPressableButton(
      onTap: onTap,
      height: height,
      width: width,
      padding: padding,
      backgroundColor: fill,
      pressedBackgroundColor: color,
      foregroundColor: AppColors.surface,
      pressedForegroundColor: AppColors.surface,
      borderColor: fill,
      pressedBorderColor: color,
      builder: (pressed) => DefaultTextStyle.merge(
        style: const TextStyle(
          color: AppColors.surface,
          fontWeight: FontWeight.w800,
        ),
        child: IconTheme.merge(
          data: const IconThemeData(color: AppColors.surface),
          child: child,
        ),
      ),
    );
  }

  Future<void> _pickCustomFoodReminderDays() async {
    final store = NotificationSettingsStore.instance;
    final controller = TextEditingController(
      text: '${store.customSmartFoodReminderDays}',
    );
    final result = await showDialog<int>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          title: const Text(
            'Özel Hatırlatma',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Kaç gün önce?',
              hintText: 'Örn: 7',
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                final days = int.tryParse(controller.text.trim());
                if (days != null && days > 0 && days <= 30) {
                  Navigator.of(context).pop(days);
                }
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );
    controller.dispose();
    if (result != null) {
      store.setCustomSmartFoodReminderDays(result);
      store.setSmartFoodReminderDays(-1);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _buildTopBanner(),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: NotificationSettingsStore.instance,
                builder: (context, _) => _buildAutoOrderBanner(),
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: NotificationSettingsStore.instance,
                builder: (context, _) => _buildSmartReminder(),
              ),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: Listenable.merge([
                  PetStore.instance,
                  OrderStore.instance,
                  FoodTrackingStore.instance,
                  BrandRepository.instance,
                ]),
                builder: (context, _) => _buildFoodTrackingCard(),
              ),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Akıllı Planım', style: AppTextStyles.pageHeader),
                const SizedBox(width: 4),
                const Icon(
                  Icons.pets_rounded,
                  color: AppColors.primary,
                  size: 18,
                ),
              ],
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return SizedBox(
      height: BannerPlacement.smartPlan.height,
      child: Row(
        children: [
          _featureCard(
            color: _easyOrderColor,
            icon: Icons.autorenew_rounded,
            title: 'Otomatik Sipariş',
            imagePath: 'assets/images/smart_plan_auto_order.jpg',
            body:
                'Otomatik sipariş, dostunun maması bitmeden siparişin senin yerine hazırlanmasıdır. Kalan gün azaldığında sistem siparişi oluşturur; ayarına göre senden onay ister veya doğrudan yola çıkar. Böylece mama stoku sıfırlanmaz.',
          ),
          const SizedBox(width: 8),
          _featureCard(
            color: _knowledgeColor,
            icon: Icons.notifications_rounded,
            title: 'Akıllı Hatırlatma',
            imagePath: 'assets/images/smart_plan_reminder.jpg',
            body:
                'Akıllı hatırlatma, mama bitmeden kaç gün önce uyarılacağını senin seçmendir. 1, 3, 5 gün kala veya özel bir günde bildirim alırsın; stok azalınca unutmazsın.',
          ),
          const SizedBox(width: 8),
          _featureCard(
            color: _hangiMamaColor,
            icon: Icons.inventory_2_rounded,
            title: 'Mama Takibi',
            imagePath: 'assets/images/smart_plan_food_track.jpg',
            body:
                'Manuel mama takibi, aldığın paketin kilosunu ve tarihini senin girmenle çalışır. Uygulama günlük tüketime bakarak kaç gün kaldığını hesaplar. Sipariş geçmişin olmasa da stoku kendin takip edebilirsin.',
          ),
        ],
      ),
    );
  }

  Widget _featureCard({
    required Color color,
    required IconData icon,
    required String title,
    required String imagePath,
    required String body,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: () => _showWhatIs(
          title: title,
          color: color,
          icon: icon,
          body: body,
        ),
        behavior: HitTestBehavior.opaque,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Image.asset(
              imagePath,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              filterQuality: FilterQuality.medium,
              cacheWidth: 360,
              errorBuilder: (context, error, stackTrace) => ColoredBox(
                color: color.withValues(alpha: 0.12),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showWhatIs({
    required String title,
    required Color color,
    required IconData icon,
    required String body,
  }) {
    InfoGuideSheet.showCentered(
      context,
      dismissOnContentTap: true,
      height: 280,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: color.withValues(alpha: 0.45)),
                ),
                child: Icon(icon, color: color, size: 26),
              ),
              const SizedBox(height: 12),
              Text(
                title.replaceAll('\n', ' '),
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: Text(
                  body,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                ),
              ),
              const Text(
                'Kapatmak için tekrar dokunun',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAutoOrderBanner() {
    const color = _easyOrderColor;
    final enabled = NotificationSettingsStore.instance.autoOrderNotifications;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.autorenew_rounded, color: color, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Otomatik Sipariş', style: _sectionTitle(color)),
              ),
              SizedBox(
                height: 24,
                child: Switch(
                  value: enabled,
                  onChanged: (v) => NotificationSettingsStore.instance
                      .setAutoOrderNotifications(v),
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mama bitmeden sipariş zamanı bildirimi alın.',
            style: _bodyText(color),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: _softFill(color),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Icon(
                  enabled
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    enabled
                        ? 'Otomatik sipariş özelliği açık.'
                        : 'Otomatik sipariş özelliği kapalı.',
                    style: _accentText(color),
                  ),
                ),
                _coloredButton(
                  color: color,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AutoOrderSettingsScreen(),
                      ),
                    );
                  },
                  height: 34,
                  child: const Text('Ayarlar', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartReminder() {
    const color = _knowledgeColor;
    final store = NotificationSettingsStore.instance;
    final reminderEnabled = store.smartFoodReminderEnabled;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: color,
                size: 17,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Akıllı Hatırlatma', style: _sectionTitle(color)),
              ),
              SizedBox(
                height: 24,
                child: Switch(
                  value: reminderEnabled,
                  onChanged: store.setSmartFoodReminderEnabled,
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: color,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Mama bitmeden kaç gün önce hatırlatılmasını istersiniz?',
            style: _bodyText(color),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _reminderChip(1, '1 Gün', color),
              const SizedBox(width: 6),
              _reminderChip(3, '3 Gün', color),
              const SizedBox(width: 6),
              _reminderChip(5, '5 Gün', color),
              const SizedBox(width: 6),
              _reminderChip(
                -1,
                'Özel',
                color,
                icon: Icons.calendar_today_rounded,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              color: _softFill(color),
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: color.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: color,
                  size: 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.foodReminderSummary,
                    style: _accentText(color),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _reminderChip(int days, String label, Color color, {IconData? icon}) {
    final store = NotificationSettingsStore.instance;
    final reminderEnabled = store.smartFoodReminderEnabled;
    final reminderDays = store.smartFoodReminderDays;
    final selected = reminderDays == days && reminderEnabled;
    final displayLabel = days == -1 && selected && reminderDays == -1
        ? '${store.customSmartFoodReminderDays} Gün'
        : label;

    return Expanded(
      child: GestureDetector(
        onTap: reminderEnabled
            ? () {
                if (days == -1) {
                  _pickCustomFoodReminderDays();
                } else {
                  store.setSmartFoodReminderDays(days);
                }
              }
            : null,
        child: Container(
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? _softFill(color) : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? color : color.withValues(alpha: 0.28),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 13,
                  color: selected
                      ? color
                      : (reminderEnabled
                            ? AppColors.text
                            : AppColors.subText.withValues(alpha: 0.6)),
                ),
                const SizedBox(width: 4),
              ],
              Text(
                displayLabel,
                style: _chipText(color, selected: selected).copyWith(
                  color: selected
                      ? color
                      : (reminderEnabled ? AppColors.text : AppColors.subText),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodTrackingCard() {
    const color = _hangiMamaColor;
    final order = OrderStore.instance;
    final hasOrder =
        order.hasLastOrder || order.lastOrderId.trim().isNotEmpty;
    final bagPath = _trackingBagImage;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: 18,
            top: 58,
            child: Icon(
              Icons.pets_rounded,
              size: 42,
              color: color.withValues(alpha: 0.10),
            ),
          ),
          Positioned(
            left: 8,
            bottom: 52,
            child: Icon(
              Icons.pets_rounded,
              size: 36,
              color: color.withValues(alpha: 0.08),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: _hangiMamaColor,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.inventory_2_rounded,
                      color: AppColors.surface,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mama Tüketim Takibi',
                          style: TextStyle(
                            color: _hangiMamaColor,
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Mamanın ne zaman biteceğini takip et, zamanında haber al.',
                          style: TextStyle(
                            color: AppColors.subText,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  _howItWorksChip(color),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 210,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _trackingOptionCard(
                        color: color,
                        title: 'Siparişten\nOtomatik Takip',
                        subtitle: hasOrder
                            ? 'Siparişinizdeki mama sisteme eklendi.'
                            : 'Siparişindeki mama otomatik takip edilir.',
                        icon: Icons.shopping_cart_rounded,
                        buttonLabel: 'Siparişten Takip',
                        buttonIcon: Icons.shopping_cart_outlined,
                        onTap: _openOrderTrackingSheet,
                        illustration: _trackingBagFill(bagPath),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _trackingOptionCard(
                        color: color,
                        title: 'Manuel Takip',
                        subtitle: 'Dışarıdan aldığın mamayı ekle.',
                        icon: Icons.edit_rounded,
                        buttonLabel: 'Mama Ekle',
                        buttonIcon: Icons.add_rounded,
                        onTap: _openFoodTracking,
                        illustration: _trackingBagFill(bagPath),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String get _trackingBagImage {
    final items = OrderStore.instance.lastOrderItems;
    if (items.isNotEmpty && items.first.imagePath.trim().isNotEmpty) {
      return items.first.imagePath;
    }
    return 'assets/images/kitir_kitir_bag.jpg';
  }

  Widget _howItWorksChip(Color color) {
    return GestureDetector(
      onTap: () => _showWhatIs(
        title: 'Mama Takibi',
        color: color,
        icon: Icons.inventory_2_rounded,
        body:
            'Manuel mama takibi, aldığın paketin kilosunu ve tarihini senin girmenle çalışır. Uygulama günlük tüketime bakarak kaç gün kaldığını hesaplar. Sipariş geçmişin olmasa da stoku kendin takip edebilirsin.',
      ),
      child: Container(
        height: 28,
        padding: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Nasıl Çalışır?',
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.chevron_right_rounded, color: color, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _trackingOptionCard({
    required Color color,
    required String title,
    required String subtitle,
    required IconData icon,
    required String buttonLabel,
    required IconData buttonIcon,
    required VoidCallback onTap,
    required Widget illustration,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withValues(alpha: 0.18)),
        ),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        child: Column(
        children: [
          SizedBox(
            height: 56,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: AppColors.surface, size: 14),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w900,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(child: illustration),
          IgnorePointer(
            child: _coloredButton(
              color: color,
              onTap: onTap,
              solid: true,
              width: double.infinity,
              height: 34,
              padding: EdgeInsets.zero,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(buttonIcon, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    buttonLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _trackingBagFill(String path) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: SizedBox.expand(
        child: buildProductImage(
          path,
          fit: BoxFit.contain,
          filterQuality: FilterQuality.high,
          errorWidget: Image.asset(
            'assets/images/kitir_kitir_bag.jpg',
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }

  Widget _bagImage(String path, {double height = 78}) {
    return SizedBox(
      height: height,
      width: 52,
      child: buildProductImage(
        path,
        fit: BoxFit.contain,
        height: height,
        width: 52,
        filterQuality: FilterQuality.high,
        errorWidget: Image.asset(
          'assets/images/kitir_kitir_bag.jpg',
          fit: BoxFit.contain,
          height: height,
          width: 52,
        ),
      ),
    );
  }

  void _openFoodTracking() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const FoodTrackingScreen()));
  }

  void _openOrderTrackingSheet() {
    const color = _hangiMamaColor;
    final order = OrderStore.instance;
    final items = order.lastOrderItems;
    final mama = items.isNotEmpty ? items.first : null;
    final hasOrder =
        order.hasLastOrder || order.lastOrderId.trim().isNotEmpty;
    final bagPath = mama != null && mama.imagePath.trim().isNotEmpty
        ? mama.imagePath
        : 'assets/images/kitir_kitir_bag.jpg';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppPageFrame.width),
            child: Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: SizedBox(
                height: media.size.height * 0.5,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    12 + media.padding.bottom,
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.28),
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 14),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.shopping_cart_rounded,
                          color: color,
                          size: 24,
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        'Siparişten Otomatik Takip',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: hasOrder
                            ? _orderTrackingActiveBody(
                                color: color,
                                bagPath: bagPath,
                                mama: mama,
                              )
                            : _orderTrackingEmptyBody(color),
                      ),
                      const SizedBox(height: 10),
                      _coloredButton(
                        color: color,
                        solid: true,
                        onTap: () => Navigator.of(sheetContext).pop(),
                        width: double.infinity,
                        height: 42,
                        child: const Text(
                          'Anladım',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _orderTrackingActiveBody({
    required Color color,
    required String bagPath,
    required LastOrderItem? mama,
  }) {
    return SingleChildScrollView(
      child: Column(
        children: [
          _bagImage(bagPath, height: 88),
          if (mama != null) ...[
            const SizedBox(height: 8),
            Text(
              mama.title,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
            if (mama.weight.trim().isNotEmpty)
              Text(
                mama.weight,
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
          ],
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: color.withValues(alpha: 0.22)),
            ),
            child: Column(
              children: [
                Icon(Icons.check_circle_rounded, color: color, size: 22),
                const SizedBox(height: 8),
                const Text(
                  'Sipariş verdiğiniz için sistem takibi otomatik başlatmıştır.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Siparişinizdeki mamadan otomatik tüketim takibi başladı.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
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

  Widget _orderTrackingEmptyBody(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: const Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.shopping_bag_outlined,
            color: _hangiMamaColor,
            size: 28,
          ),
          SizedBox(height: 10),
          Text(
            'Henüz bir siparişiniz yok',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _hangiMamaColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Uygulamadan mama siparişi verdiğinizde tüketim takibi otomatik başlar.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
