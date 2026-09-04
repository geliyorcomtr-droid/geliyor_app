import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/auto_order_settings_screen.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/food_tracking_screen.dart';
import 'package:geliyor_app/services/food_remaining_estimator.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

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
    EdgeInsetsGeometry padding = const EdgeInsets.symmetric(horizontal: 12),
  }) {
    final fill = _buttonFill(color);
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
                const Text(
                  'Akıllı Planım',
                  style: AppTextStyles.pageHeader,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.pets_rounded, color: AppColors.primary, size: 18),
              ],
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildTopBanner() {
    return const AppBannerSlot(
      placement: BannerPlacement.smartPlan,
      fallbackAssets: ['assets/images/akilli_plan_banner.png'],
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.45)),
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
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.45)),
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
                style: _chipText(
                  color,
                  selected: selected,
                ).copyWith(
                  color: selected
                      ? color
                      : (reminderEnabled
                          ? AppColors.text
                          : AppColors.subText),
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
    final estimate = FoodRemainingEstimator.compute();
    final tracking = FoodTrackingStore.instance.isActive;
    final stockAccent = estimate == null
        ? color
        : _stockColor(estimate.stockLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.inventory_2_outlined, color: color, size: 17),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Mama Takibi', style: _sectionTitle(color)),
              ),
              _sourceChip(
                estimate == null
                    ? 'Beklemede'
                    : (estimate.fromManual ? 'Manuel' : 'Son sipariş'),
                color,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (estimate == null)
            _emptyFoodBody(color)
          else
            _activeFoodBody(estimate, color, stockAccent),
          const SizedBox(height: 10),
          _coloredButton(
            color: color,
            onTap: _openFoodTracking,
            width: double.infinity,
            height: 38,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tracking ? Icons.tune_rounded : Icons.add_rounded,
                  size: 15,
                ),
                const SizedBox(width: 6),
                Text(
                  tracking ? 'Takibi Düzenle' : 'Mama Takibi Başlat',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeFoodBody(
    FoodRemainingEstimate estimate,
    Color theme,
    Color stockAccent,
  ) {
    final percent = (estimate.remainingRatio * 100).round();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: _softFill(theme),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: theme.withValues(alpha: 0.22)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estimate.foodTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: theme,
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_formatBagKg(estimate.bagKg)} paket  ·  ${estimate.shareLabel}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statTile('Günlük', '${estimate.dailyGrams} g', theme),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statTile(
                'Kalan',
                '${estimate.remainingDays} gün',
                theme,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statTile('Stok', '%$percent', theme),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: estimate.remainingRatio,
            minHeight: 8,
            backgroundColor: _softFill(theme),
            color: stockAccent,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _stockHint(estimate),
            style: TextStyle(
              color: stockAccent,
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyFoodBody(Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: _softFill(color),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          Text(
            'Henüz takip edilen mama yok',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: color,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dışarıdan aldığınız paketi ekleyin veya son siparişinizden otomatik takip başlasın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value, Color color) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: _softFill(color),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceChip(String label, Color color) {
    return Container(
      height: 26,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: _softFill(color),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  void _openFoodTracking() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const FoodTrackingScreen()),
    );
  }

  Color _stockColor(FoodStockLevel level) {
    return switch (level) {
      FoodStockLevel.safe => AppColors.primary,
      FoodStockLevel.watch => AppColors.warning,
      FoodStockLevel.low =>
        Color.lerp(AppColors.warning, AppColors.error, 0.45)!,
      FoodStockLevel.critical => AppColors.error,
    };
  }

  String _stockHint(FoodRemainingEstimate estimate) {
    return switch (estimate.stockLevel) {
      FoodStockLevel.safe =>
        '${estimate.remainingDays} gün yetecek stok var.',
      FoodStockLevel.watch => 'Stok azalıyor, siparişi planlayın.',
      FoodStockLevel.low => 'Mama yakında bitecek.',
      FoodStockLevel.critical => 'Kritik seviye — hemen yenileyin.',
    };
  }

  String _formatBagKg(double kg) {
    if (kg <= 0) return '-';
    return kg == kg.roundToDouble()
        ? '${kg.toStringAsFixed(0)} kg'
        : '${kg.toStringAsFixed(1).replaceAll('.', ',')} kg';
  }
}
