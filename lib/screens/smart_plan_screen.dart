import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/food_tracking_screen.dart';
import 'package:geliyor_app/services/food_remaining_estimator.dart';
import 'package:geliyor_app/services/user_profile_sync.dart';
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
  /// Üstteki üç kart görselinin iç rengi.
  static const _autoOrderFrame = Color(0xFF00A840);
  static const _reminderFrame = Color(0xFFF88818);
  static const _foodTrackFrame = Color(0xFF8850F0);
  static const _hangiMamaColor = AppColors.primary;

  Color _buttonFill(Color color) =>
      Color.lerp(color, Colors.white, 0.28) ?? color;

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
              _buildAutoOrderBanner(),
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: NotificationSettingsStore.instance,
                builder: (context, _) => _buildSmartReminder(),
              ),
              const SizedBox(height: 12),
              _buildTrackingStrips(),
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
    return StreamBuilder<List<AppBanner>>(
      stream: BannerRepository.instance.watchAll(),
      builder: (context, snapshot) {
        final banners = snapshot.data ?? const <AppBanner>[];
        return SizedBox(
          height: BannerPlacement.smartPlanAutoOrder.height,
          child: Row(
            children: [
              _featureCard(
                color: _autoOrderFrame,
                cardPlacement: BannerPlacement.smartPlanAutoOrder,
                detailPlacement: BannerPlacement.smartPlanAutoOrderDetail,
                fallbackCard: 'assets/images/smart_plan_auto_order.jpg',
                banners: banners,
              ),
              const SizedBox(width: 8),
              _featureCard(
                color: _reminderFrame,
                cardPlacement: BannerPlacement.smartPlanReminder,
                detailPlacement: BannerPlacement.smartPlanReminderDetail,
                fallbackCard: 'assets/images/smart_plan_reminder.jpg',
                banners: banners,
              ),
              const SizedBox(width: 8),
              _featureCard(
                color: _foodTrackFrame,
                cardPlacement: BannerPlacement.smartPlanFoodTrack,
                detailPlacement: BannerPlacement.smartPlanFoodTrackDetail,
                fallbackCard: 'assets/images/smart_plan_food_track.jpg',
                banners: banners,
              ),
            ],
          ),
        );
      },
    );
  }

  String _bannerPath(
    List<AppBanner> banners,
    BannerPlacement placement, {
    String fallback = '',
  }) {
    final list = banners
        .where(
          (item) =>
              item.active &&
              item.placement == placement.id &&
              item.displayImage.trim().isNotEmpty,
        )
        .toList();
    final live = AppBanner.latestLive(list);
    if (live == null) return fallback;
    if (live.imageUrl.trim().isNotEmpty) {
      return AppBanner.liveNetworkPath(list);
    }
    final asset = live.assetPath.trim();
    return asset.isNotEmpty ? asset : fallback;
  }

  Widget _featureCard({
    required Color color,
    required BannerPlacement cardPlacement,
    required BannerPlacement detailPlacement,
    required String fallbackCard,
    required List<AppBanner> banners,
  }) {
    final cardPath = _bannerPath(banners, cardPlacement, fallback: fallbackCard);
    final detailPath = _bannerPath(
      banners,
      detailPlacement,
      fallback: cardPath,
    );
    return Expanded(
      child: GestureDetector(
        onTap: () => _showDetailImage(detailPath),
        behavior: HitTestBehavior.opaque,
        child: Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(cardPlacement.boxRadius),
            border: Border.all(color: color, width: 1),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: cardPath.isEmpty
                ? ColoredBox(color: color.withValues(alpha: 0.12))
                : buildProductImage(
                    cardPath,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: double.infinity,
                    alignment: Alignment.center,
                    filterQuality: FilterQuality.medium,
                    cacheWidth: 360,
                    errorWidget: ColoredBox(
                      color: color.withValues(alpha: 0.12),
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  void _showDetailImage(String imagePath) {
    final path = imagePath.trim();
    if (path.isEmpty) return;
    final slot = BannerPlacement.smartPlanAutoOrderDetail;
    InfoGuideSheet.showCentered(
      context,
      dismissOnContentTap: true,
      height: slot.height,
      maxWidth: slot.boxWidth,
      builder: (sheetContext) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(slot.boxRadius),
          child: ColoredBox(
            color: AppColors.surface,
            child: buildProductImage(
              path,
              fit: BoxFit.contain,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              cacheWidth: 1083,
            ),
          ),
        );
      },
    );
  }

  Widget _buildAutoOrderBanner() {
    return ListenableBuilder(
      listenable: NotificationSettingsStore.instance,
      builder: (context, _) {
        return StreamBuilder<List<AppBanner>>(
          stream: BannerRepository.instance.watchAll(),
          builder: (context, snapshot) {
            final path = _bannerPath(
              snapshot.data ?? const [],
              BannerPlacement.smartPlanAutoOrderStrip,
              fallback: 'assets/images/smart_plan_auto_order_strip.jpg',
            );
            return LayoutBuilder(
              builder: (context, constraints) {
                const framePad = 3.0;
                final width = constraints.maxWidth - framePad * 2;
                final height = width * 139 / 361;
                return Container(
                  padding: const EdgeInsets.all(framePad),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: SizedBox(
                      width: width,
                      height: height,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          buildProductImage(
                            path,
                            fit: BoxFit.fill,
                            width: width,
                            height: height,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.high,
                            cacheWidth: 1024,
                          ),
                          Positioned(
                            left: width * 0.05,
                            top: height * 0.66,
                            width: width * 0.90,
                            height: height * 0.24,
                            child: _subscriptionControl(),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _subscriptionControl() {
    final store = NotificationSettingsStore.instance;
    final enabled = store.subscriptionEnabled;
    const subscribeGreen = Color(0xFF00964F);
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final toggleH = h * 0.86;
        final fontSize = (h * 0.62).clamp(14.0, 20.0);
        final statusSize = (h * 0.58).clamp(13.0, 18.0);
        return Align(
          alignment: Alignment.centerLeft,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  'Aboneliğim',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: enabled ? subscribeGreen : const Color(0xFF8AA894),
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
              ),
              Text(
                enabled ? 'Aktif' : 'Pasif',
                maxLines: 1,
                style: TextStyle(
                  color: enabled
                      ? subscribeGreen
                      : const Color(0xFF374151),
                  fontSize: statusSize,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              SizedBox(width: toggleH * 0.22),
            GestureDetector(
              onTap: () => store.setSubscriptionEnabled(!enabled),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: toggleH,
                width: toggleH * 1.85,
                padding: EdgeInsets.all(toggleH * 0.08),
                decoration: BoxDecoration(
                  color: enabled ? subscribeGreen : const Color(0xFFD5DDD8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  alignment: enabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: toggleH * 0.84,
                    height: toggleH * 0.84,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        );
      },
    );
  }

  Widget _buildSmartReminder() {
    return StreamBuilder<List<AppBanner>>(
      stream: BannerRepository.instance.watchAll(),
      builder: (context, snapshot) {
        final path = _bannerPath(
          snapshot.data ?? const [],
          BannerPlacement.smartPlanReminderStrip,
          fallback: 'assets/images/smart_plan_reminder_strip.jpg',
        );
        return LayoutBuilder(
          builder: (context, constraints) {
            const framePad = 3.0;
            final width = constraints.maxWidth - framePad * 2;
            final height = width * 778 / 2022;
            return Container(
              padding: const EdgeInsets.all(framePad),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      buildProductImage(
                        path,
                        fit: BoxFit.fill,
                        width: width,
                        height: height,
                        alignment: Alignment.center,
                        filterQuality: FilterQuality.high,
                        cacheWidth: 2022,
                      ),
                      Positioned(
                        left: width * 0.012,
                        top: height * 0.545,
                        width: width * 0.976,
                        height: height * 0.403,
                        child: _reminderControlCard(),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _reminderControlCard() {
    final store = NotificationSettingsStore.instance;
    final enabled = store.smartFoodReminderEnabled;
    const accent = AppColors.statNumber;
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        final gap = (h * 0.05).clamp(2.0, 6.0);
        final padTop = h * 0.04;
        final padBottom = h * 0.05;
        final chipH = h * 0.42;
        final toggleH = chipH;
        final sentenceSize = (chipH * 0.38).clamp(11.0, 15.0);
        return ClipRRect(
          borderRadius: BorderRadius.circular(h * 0.22),
          child: ColoredBox(
            color: AppColors.surface,
            child: Padding(
              padding: EdgeInsets.fromLTRB(h * 0.08, padTop, h * 0.08, padBottom),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Mama bitmeden kaç gün önce hatırlatılsın?',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.text,
                            fontSize: sentenceSize,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ),
                      SizedBox(width: gap),
                      GestureDetector(
                        onTap: () =>
                            store.setSmartFoodReminderEnabled(!enabled),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          height: toggleH,
                          width: toggleH * 1.75,
                          padding: EdgeInsets.all(toggleH * 0.08),
                          decoration: BoxDecoration(
                            color: enabled ? accent : AppColors.border,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: AnimatedAlign(
                            duration: const Duration(milliseconds: 180),
                            alignment: enabled
                                ? Alignment.centerRight
                                : Alignment.centerLeft,
                            child: Container(
                              width: toggleH * 0.84,
                              height: toggleH * 0.84,
                              decoration: const BoxDecoration(
                                color: AppColors.surface,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  SizedBox(
                    height: chipH,
                    child: Opacity(
                      opacity: enabled ? 1 : 0.4,
                      child: IgnorePointer(
                        ignoring: !enabled,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _reminderChip(1, '1 Gün', accent),
                            SizedBox(width: gap),
                            _reminderChip(2, '2 Gün', accent),
                            SizedBox(width: gap),
                            _reminderChip(3, '3 Gün', accent),
                            SizedBox(width: gap),
                            _reminderChip(7, '7 Gün', accent),
                            SizedBox(width: gap),
                            _reminderChip(
                              -1,
                              'Özel',
                              accent,
                              icon: Icons.calendar_today_rounded,
                            ),
                          ],
                        ),
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

  Widget _reminderChip(
    int days,
    String label,
    Color color, {
    IconData? icon,
  }) {
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
        child: LayoutBuilder(
          builder: (context, chipConstraints) {
            final chipH = chipConstraints.maxHeight;
            final fontSize = (chipH * 0.42).clamp(11.0, 15.0);
            return Container(
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? color : AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected ? color : color.withValues(alpha: 0.45),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: fontSize,
                      color: selected
                          ? AppColors.surface
                          : (reminderEnabled
                              ? AppColors.text
                              : AppColors.subText),
                    ),
                    const SizedBox(width: 3),
                  ],
                  Flexible(
                    child: Text(
                      displayLabel,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: selected ? AppColors.surface : AppColors.text,
                        fontSize: fontSize,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildTrackingStrips() {
    return StreamBuilder<List<AppBanner>>(
      stream: BannerRepository.instance.watchAll(),
      builder: (context, snapshot) {
        final banners = snapshot.data ?? const <AppBanner>[];
        return Column(
          children: [
            _trackStrip(
              banners: banners,
              placement: BannerPlacement.smartPlanOrderTrackStrip,
              fallback: 'assets/images/smart_plan_order_track_strip.jpg',
              onTap: _openOrderTrackingSheet,
            ),
            const SizedBox(height: 12),
            _trackStrip(
              banners: banners,
              placement: BannerPlacement.smartPlanManualTrackStrip,
              fallback: 'assets/images/smart_plan_manual_track_strip.jpg',
              onTap: _openFoodTracking,
            ),
          ],
        );
      },
    );
  }

  Widget _trackStrip({
    required List<AppBanner> banners,
    required BannerPlacement placement,
    required String fallback,
    required VoidCallback onTap,
  }) {
    final path = _bannerPath(banners, placement, fallback: fallback);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const framePad = 3.0;
          final width = constraints.maxWidth - framePad * 2;
          final height = width * 139 / 361;
          return Container(
            padding: const EdgeInsets.all(framePad),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.25),
              ),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(21),
              child: SizedBox(
                width: width,
                height: height,
                child: buildProductImage(
                  path,
                  fit: BoxFit.fill,
                  width: width,
                  height: height,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  cacheWidth: 1024,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  void _openFoodTracking() {
    FoodTrackingScreen.showSheet(context);
  }

  void _openOrderTrackingSheet() {
    if (!OrderStore.instance.hasLastOrder) {
      unawaited(UserProfileSync.refreshLastOrder());
    }
    const color = _hangiMamaColor;
    final order = OrderStore.instance;
    final hasOrder =
        order.hasLastOrder || order.lastOrderId.trim().isNotEmpty;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final media = MediaQuery.of(sheetContext);
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: AppPageFrame.width,
              maxHeight: media.size.height * 0.72,
            ),
            child: Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              clipBehavior: Clip.antiAlias,
              child: SizedBox(
                height:
                    FoodTrackingScreen.sheetFrameHeight + media.padding.bottom,
                child: Stack(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        16,
                        8,
                        16,
                        12 + media.padding.bottom,
                      ),
                      child: ListenableBuilder(
                        listenable: Listenable.merge([
                          NotificationSettingsStore.instance,
                          OrderStore.instance,
                          PetStore.instance,
                        ]),
                        builder: (context, _) {
                          final trackingOn = NotificationSettingsStore
                              .instance
                              .orderFoodTrackingEnabled;
                          return Column(
                            children: [
                              Container(
                                width: 36,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.28),
                                  borderRadius: BorderRadius.circular(999),
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
                              const SizedBox(height: 10),
                              _orderTrackingToggle(
                                enabled: trackingOn,
                                onChanged: NotificationSettingsStore
                                    .instance
                                    .setOrderFoodTrackingEnabled,
                              ),
                              const SizedBox(height: 8),
                              Expanded(
                                child: hasOrder
                                    ? _orderTrackingActiveBody(
                                        color: color,
                                        trackingOn: trackingOn,
                                      )
                                    : _orderTrackingEmptyBody(
                                        color,
                                        trackingOn: trackingOn,
                                      ),
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
                          );
                        },
                      ),
                    ),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: GestureDetector(
                        onTap: () => Navigator.of(sheetContext).pop(),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.border),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.text,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _orderTrackingToggle({
    required bool enabled,
    required ValueChanged<bool> onChanged,
  }) {
    const onColor = AppColors.primary;
    return SizedBox(
      height: 42,
      width: double.infinity,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: enabled ? AppColors.selected : AppColors.background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: enabled ? onColor.withValues(alpha: 0.35) : AppColors.border,
          ),
        ),
        child: Row(
          children: [
            const Text(
              'Otomatik takip',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              enabled ? 'Aktif' : 'Pasif',
              style: TextStyle(
                color: enabled ? onColor : AppColors.subText,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => onChanged(!enabled),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                height: 26,
                width: 46,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: enabled ? onColor : const Color(0xFFD5DDD8),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: AnimatedAlign(
                  duration: const Duration(milliseconds: 180),
                  alignment: enabled
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  child: Container(
                    width: 20,
                    height: 20,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderTrackingActiveBody({
    required Color color,
    required bool trackingOn,
  }) {
    final estimate = FoodRemainingEstimator.estimateFromLastOrder();
    final days = estimate?.remainingDays;
    final kgLabel = estimate == null ? '' : _kgLabel(estimate.bagKg);
    final petLabel = estimate?.shareLabel ?? '';
    final items = OrderStore.instance.lastOrderItems;
    final food = estimate?.food ?? (items.isNotEmpty ? items.first : null);
    final imagePath = (estimate?.imagePath ?? food?.imagePath ?? '').trim();
    final title = (food?.title ?? estimate?.foodTitle ?? '').trim();
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSide = constraints.maxHeight.clamp(72.0, 110.0);
        return Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (imagePath.isNotEmpty) ...[
              SizedBox(
                width: imageSide,
                height: imageSide,
                child: buildProductImage(
                  imagePath,
                  fit: BoxFit.contain,
                  width: imageSide,
                  height: imageSide,
                  filterQuality: FilterQuality.high,
                ),
              ),
              const SizedBox(width: 10),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (title.isNotEmpty)
                    Text(
                      title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.15,
                      ),
                    ),
                  if (days != null) ...[
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: '$days',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const TextSpan(text: ' gün kaldı'),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Girilen $kgLabel paket ve $petLabel verilerine göre ortalama tüketim hesaplanmıştır.',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.25,
                      ),
                    ),
                  ] else
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Text(
                        'Paket kilosu ve dost bilgisi tamamlandığında ortalama tüketim burada hesaplanır.',
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.subText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          height: 1.25,
                        ),
                      ),
                    ),
                  if (!trackingOn) ...[
                    const SizedBox(height: 4),
                    Text(
                      'Otomatik takip kapalı.',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  String _kgLabel(double kg) {
    final text = kg == kg.roundToDouble()
        ? kg.toStringAsFixed(0)
        : kg.toStringAsFixed(1).replaceAll('.', ',');
    return '$text kg';
  }

  Widget _orderTrackingEmptyBody(Color color, {required bool trackingOn}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.22)),
      ),
      child: Column(
        children: [
          const Text(
            'Henüz bir siparişiniz yok',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _hangiMamaColor,
              fontSize: 15,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            trackingOn
                ? 'Uygulamadan mama siparişi verdiğinizde tüketim takibi otomatik başlar.'
                : 'Otomatik takip kapalı. Sipariş verseniz de mama takibi buradan başlamaz.',
            textAlign: TextAlign.center,
            style: const TextStyle(
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
