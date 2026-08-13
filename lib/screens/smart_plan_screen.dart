import 'package:flutter/material.dart';
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
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class SmartPlanScreen extends StatefulWidget {
  const SmartPlanScreen({super.key});

  @override
  State<SmartPlanScreen> createState() => _SmartPlanScreenState();
}

class _SmartPlanScreenState extends State<SmartPlanScreen> {
  bool _autoOrderEnabled = true;

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
              _buildAutoOrderBanner(),
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
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        'assets/images/akilli_plan_banner.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 160,
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.center,
            child: const Icon(
              Icons.pets_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          );
        },
      ),
    );
  }

  Widget _buildAutoOrderBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.autorenew_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Otomatik Sipariş',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: Switch(
                  value: _autoOrderEnabled,
                  onChanged: (v) => setState(() => _autoOrderEnabled = v),
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: AppColors.primaryLight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Mama bitmeden siparişinizin otomatik oluşturulmasını sağlayın.',
            style: TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                Icon(
                  _autoOrderEnabled
                      ? Icons.check_circle_outline_rounded
                      : Icons.pause_circle_outline_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _autoOrderEnabled
                        ? 'Otomatik sipariş özelliği açık.'
                        : 'Otomatik sipariş özelliği kapalı.',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                AppPressableButton.primary(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AutoOrderSettingsScreen(),
                      ),
                    );
                  },
                  height: 32,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: const Text('Ayarlar', style: TextStyle(fontSize: 11)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmartReminder() {
    final store = NotificationSettingsStore.instance;
    final reminderEnabled = store.smartFoodReminderEnabled;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_active_rounded,
                color: AppColors.primary,
                size: 16,
              ),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Akıllı Hatırlatma',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              SizedBox(
                height: 24,
                child: Switch(
                  value: reminderEnabled,
                  onChanged: store.setSmartFoodReminderEnabled,
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: AppColors.primaryLight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Mama bitmeden kaç gün önce hatırlatılmasını istersiniz?',
            style: TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _reminderChip(1, '1 Gün'),
              const SizedBox(width: 6),
              _reminderChip(3, '3 Gün'),
              const SizedBox(width: 6),
              _reminderChip(5, '5 Gün'),
              const SizedBox(width: 6),
              _reminderChip(-1, 'Özel', icon: Icons.calendar_today_rounded),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    store.foodReminderSummary,
                    style: const TextStyle(
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
      ),
    );
  }

  Widget _reminderChip(int days, String label, {IconData? icon}) {
    final store = NotificationSettingsStore.instance;
    final reminderEnabled = store.smartFoodReminderEnabled;
    final reminderDays = store.smartFoodReminderDays;
    final selected = reminderDays == days && reminderEnabled;
    final displayLabel = days == -1 &&
            selected &&
            reminderDays == -1
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
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? AppColors.selected : AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.5 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 12,
                  color: selected ? AppColors.primary : AppColors.subText,
                ),
                const SizedBox(width: 3),
              ],
              Text(
                displayLabel,
                style: TextStyle(
                  color: selected
                      ? AppColors.primary
                      : (reminderEnabled ? AppColors.text : AppColors.subText),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFoodTrackingCard() {
    final estimate = FoodRemainingEstimator.compute();
    final tracking = FoodTrackingStore.instance.isActive;
    final accent = estimate == null
        ? AppColors.primary
        : _stockColor(estimate.stockLevel);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: accent, size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  'Mama Takibi',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              _sourceChip(
                estimate == null
                    ? 'Beklemede'
                    : (estimate.fromManual ? 'Manuel' : 'Son sipariş'),
                accent,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (estimate == null)
            _emptyFoodBody()
          else
            _activeFoodBody(estimate, accent),
          const SizedBox(height: 10),
          AppPressableButton.primary(
            onTap: _openFoodTracking,
            width: double.infinity,
            height: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  tracking ? Icons.tune_rounded : Icons.add_rounded,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  tracking ? 'Takibi Düzenle' : 'Mama Takibi Başlat',
                  style: const TextStyle(fontSize: 12.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _activeFoodBody(FoodRemainingEstimate estimate, Color accent) {
    final percent = (estimate.remainingRatio * 100).round();
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.selected,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: Image.asset(
                  estimate.imagePath ?? 'assets/images/akilli_plan_mama.png',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Icon(Icons.rice_bowl_rounded, color: accent);
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estimate.foodTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${_formatBagKg(estimate.bagKg)} paket  ·  ${estimate.pet.name}',
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
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _statTile('Günlük', '${estimate.dailyGrams} g'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statTile('Kalan', '${estimate.remainingDays} gün'),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _statTile('Stok', '%$percent'),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            value: estimate.remainingRatio,
            minHeight: 8,
            backgroundColor: AppColors.selected,
            color: accent,
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerLeft,
          child: Text(
            _stockHint(estimate),
            style: TextStyle(
              color: accent,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _emptyFoodBody() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(18),
      ),
      child: const Column(
        children: [
          Icon(Icons.rice_bowl_rounded, color: AppColors.primary, size: 28),
          SizedBox(height: 8),
          Text(
            'Henüz takip edilen mama yok',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'Dışarıdan aldığınız paketi ekleyin veya son siparişinizden otomatik takip başlasın.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  Widget _statTile(String label, String value) {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sourceChip(String label, Color color) {
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
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
