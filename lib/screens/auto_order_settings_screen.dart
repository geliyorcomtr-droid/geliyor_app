import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

class AutoOrderSettingsScreen extends StatefulWidget {
  const AutoOrderSettingsScreen({super.key});

  @override
  State<AutoOrderSettingsScreen> createState() =>
      _AutoOrderSettingsScreenState();
}

class _AutoOrderSettingsScreenState extends State<AutoOrderSettingsScreen> {
  bool _smartMode = true;
  bool _advancedMode = false;
  int _confirmMode = 0; // 0: otomatik, 1: sor
  int _deliverySlot = 0; // 0: sabah, 1: öğle, 2: akşam

  bool get _advancedEnabled => !_smartMode && _advancedMode;

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
              const Text(
                'Mama bitmeden otomatik sipariş ile her zaman hazırlıklı olun.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              _buildSmartModeCard(),
              const SizedBox(height: 10),
              _buildAdvancedToggleCard(),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: NotificationSettingsStore.instance,
                builder: (context, _) => _buildWhenToOrderCard(),
              ),
              const SizedBox(height: 10),
              _buildConfirmCard(),
              const SizedBox(height: 10),
              _buildDeliverySlotCard(),
              const SizedBox(height: 10),
              ListenableBuilder(
                listenable: NotificationSettingsStore.instance,
                builder: (context, _) => _buildNotificationsCard(),
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
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    'Otomatik Sipariş Ayarları',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.pageHeader,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.pets_rounded, color: AppColors.primary, size: 16),
              ],
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildSmartModeCard() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: AppColors.surface,
                  size: 18,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text(
                          'Akıllı Mod',
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.selected,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Önerilen',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        SizedBox(
                          height: 26,
                          child: Switch(
                            value: _smartMode,
                            onChanged: (v) {
                              setState(() {
                                _smartMode = v;
                                if (v) _advancedMode = false;
                              });
                            },
                            activeThumbColor: AppColors.surface,
                            activeTrackColor: AppColors.primaryLight,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Text(
                            'Geliyor.tr petinizin tüketimine göre siparişi en uygun zamanda oluşturur.',
                            style: TextStyle(
                              color: AppColors.subText,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              height: 1.3,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Image.asset(
                          'assets/images/akilli_mod_mama.png',
                          width: 64,
                          height: 56,
                          fit: BoxFit.contain,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(
                              Icons.pets_rounded,
                              color: AppColors.primary,
                              size: 40,
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _infoBanner(
            'Akıllı Mod açıkken gelişmiş ayarlar devre dışı kalır.',
          ),
        ],
      ),
    );
  }

  Widget _buildAdvancedToggleCard() {
    return Opacity(
      opacity: _smartMode ? 0.55 : 1,
      child: Container(
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
              decoration: const BoxDecoration(
                color: AppColors.selected,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.settings_rounded,
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
                    'Gelişmiş Ayarlar',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Akıllı Mod'u kapatarak tercihlerinizi kendiniz belirleyebilirsiniz.",
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 26,
              child: Switch(
                value: _advancedMode,
                onChanged: _smartMode
                    ? null
                    : (v) => setState(() => _advancedMode = v),
                activeThumbColor: AppColors.surface,
                activeTrackColor: AppColors.primaryLight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWhenToOrderCard() {
    final store = NotificationSettingsStore.instance;
    return Opacity(
      opacity: _advancedEnabled ? 1 : 0.55,
      child: IgnorePointer(
        ignoring: !_advancedEnabled,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.calendar_month_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '1. Sipariş Ne Zaman Oluşturulsun?',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Mama bitmeden kaç gün önce sipariş oluşturulmasını istersiniz?',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  for (final days in [1, 3, 5, 7]) ...[
                    if (days != 1) const SizedBox(width: 6),
                    Expanded(child: _dayOption(days)),
                  ],
                ],
              ),
              const SizedBox(height: 10),
              _infoBanner(store.autoOrderDaysSummary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _dayOption(int days) {
    final store = NotificationSettingsStore.instance;
    final selected = store.autoOrderDaysBefore == days;
    return GestureDetector(
      onTap: () => store.setAutoOrderDaysBefore(days),
      child: Container(
        padding: const EdgeInsets.fromLTRB(4, 8, 4, 6),
        decoration: BoxDecoration(
          color: selected ? AppColors.selected : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.border,
                size: 14,
              ),
            ),
            Icon(
              Icons.calendar_today_rounded,
              color: selected ? AppColors.primary : AppColors.subText,
              size: 16,
            ),
            const SizedBox(height: 4),
            Text(
              '$days Gün',
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'Önce',
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.subText,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (days == 3) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Önerilen',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ] else
              const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmCard() {
    return Opacity(
      opacity: _advancedEnabled ? 1 : 0.55,
      child: IgnorePointer(
        ignoring: !_advancedEnabled,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Text(
                    '2. Sipariş Onayı',
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Sipariş oluşturulmadan önce onaylamak ister misiniz?',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              _confirmOption(
                index: 0,
                title: 'Otomatik oluştur',
                subtitle: 'Onayım alınmadan siparişim oluşturulsun.',
                icon: Icons.shopping_bag_outlined,
              ),
              const SizedBox(height: 8),
              _confirmOption(
                index: 1,
                title: 'Önce bana sor',
                subtitle: 'Sipariş oluşturulmadan önce onayım istenir.',
                icon: Icons.forum_outlined,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _confirmOption({
    required int index,
    required String title,
    required String subtitle,
    required IconData icon,
  }) {
    final selected = _confirmMode == index;
    return GestureDetector(
      onTap: () => setState(() => _confirmMode = index),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: selected ? AppColors.selected : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.border,
              size: 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.text,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(icon, color: AppColors.primary, size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildDeliverySlotCard() {
    return Opacity(
      opacity: _advancedEnabled ? 1 : 0.55,
      child: IgnorePointer(
        ignoring: !_advancedEnabled,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(
                    Icons.access_time_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      '3. Tahmini Teslimat Saat Aralığı',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Siparişimin hangi saat aralığında teslim edilmesini istersiniz?',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _slotOption(
                      0,
                      'Sabah',
                      '09:00 - 12:00',
                      Icons.wb_sunny_outlined,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _slotOption(
                      1,
                      'Öğle',
                      '13:00 - 18:00',
                      Icons.wb_sunny_rounded,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: _slotOption(
                      2,
                      'Akşam',
                      '18:00 - 23:00',
                      Icons.nightlight_round,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _infoBanner(
                'Belirtilen saat aralığında teslimat için planlama yapılır.',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _slotOption(int index, String title, String time, IconData icon) {
    final selected = _deliverySlot == index;
    return GestureDetector(
      onTap: () => setState(() => _deliverySlot = index),
      child: Container(
        padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.selected : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.6 : 1,
          ),
        ),
        child: Column(
          children: [
            Align(
              alignment: Alignment.topRight,
              child: Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked,
                color: selected ? AppColors.primary : AppColors.border,
                size: 14,
              ),
            ),
            Icon(
              icon,
              color: selected ? AppColors.primary : AppColors.subText,
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: selected ? AppColors.primary : AppColors.subText,
                fontSize: 9,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsCard() {
    final store = NotificationSettingsStore.instance;
    return Opacity(
      opacity: _advancedEnabled ? 1 : 0.55,
      child: IgnorePointer(
        ignoring: !_advancedEnabled,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.notifications_active_outlined,
                color: AppColors.primary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '4. Bildirimler',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      store.autoOrderNotificationSummary,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                height: 26,
                child: Switch(
                  value: store.autoOrderNotifications,
                  onChanged: store.setAutoOrderNotifications,
                  activeThumbColor: AppColors.surface,
                  activeTrackColor: AppColors.primaryLight,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoBanner(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColors.primary,
            size: 15,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
