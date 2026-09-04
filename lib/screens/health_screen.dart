import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/emergency_support_screen.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/medicine_treatment_screen.dart';
import 'package:geliyor_app/screens/special_foods_screen.dart';
import 'package:geliyor_app/screens/vaccine_calendar_screen.dart';
import 'package:geliyor_app/state/health_calendar_store.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class HealthScreen extends StatefulWidget {
  const HealthScreen({super.key});

  @override
  State<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends State<HealthScreen> {
  static const Color _asi = Color(0xFFFF6600);
  static const Color _ilac = Color(0xFF00A859);
  static const Color _mama = Color(0xFF9B4DCA);
  static const Color _acil = Color(0xFFE60000);

  static const _monthNames = [
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
  static const _monthShort = [
    'OCA',
    'ŞUB',
    'MAR',
    'NİS',
    'MAY',
    'HAZ',
    'TEM',
    'AĞU',
    'EYL',
    'EKİ',
    'KAS',
    'ARA',
  ];
  static const _times = ['09:00', '13:00', '17:00', '20:00'];
  static const _timeLabels = ['Sabah', 'Öğle', 'Akşam', 'Gece'];

  late final List<_HealthProcedure> _procedures;

  bool _reminderOpen = false;
  int _selectedProcedure = 0;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();
  int _selectedTime = 3;
  bool _showAllUpcoming = false;
  bool _showAllPast = false;

  @override
  void initState() {
    super.initState();
    _selectedTime = NotificationSettingsStore.instance.healthReminderTimeIndex;
    final today = _dateOnly(DateTime.now());

    _procedures = [
      _HealthProcedure(
        icon: Icons.vaccines_outlined,
        color: _asi,
        title: 'Karma Aşı',
        frequency: 'Yılda Bir',
        intervalMonths: 12,
        lastDoneDate: _addMonths(today.add(const Duration(days: 20)), -12),
      ),
      _HealthProcedure(
        icon: Icons.shield_outlined,
        color: const Color(0xFF00A859),
        title: 'Dış Parazit',
        frequency: 'Her Ay',
        intervalMonths: 1,
        lastDoneDate: _addMonths(today.add(const Duration(days: 30)), -1),
      ),
      _HealthProcedure(
        icon: Icons.bug_report_outlined,
        color: const Color(0xFF8B5CF6),
        title: 'İç Parazit',
        frequency: '3 Ayda Bir',
        intervalMonths: 3,
        lastDoneDate: _addMonths(today.add(const Duration(days: 36)), -3),
      ),
      _HealthProcedure(
        icon: Icons.vaccines_outlined,
        color: _asi,
        title: 'Kuduz Aşısı',
        frequency: 'Yılda Bir',
        intervalMonths: 12,
        lastDoneDate: _addMonths(today.add(const Duration(days: 59)), -12),
      ),
      _HealthProcedure(
        icon: Icons.medical_services_outlined,
        color: AppColors.primaryLight,
        title: 'Veteriner Kontrolü',
        frequency: '6 Ayda Bir',
        intervalMonths: 6,
        lastDoneDate: _addMonths(today.add(const Duration(days: 71)), -6),
      ),
    ];

    for (final p in _procedures) {
      p.recalculateNextDue();
    }
    _applySavedDates();
    HealthCalendarStore.instance.addListener(_onCalendarChanged);
  }

  void _onCalendarChanged() {
    if (!mounted) return;
    setState(_applySavedDates);
  }

  void _applySavedDates() {
    HealthCalendarStore.instance.overlayLastDone((title, lastDone) {
      for (final p in _procedures) {
        if (p.title == title) {
          p.applyDoneDate(lastDone);
        }
      }
    });
  }

  @override
  void dispose() {
    HealthCalendarStore.instance.removeListener(_onCalendarChanged);
    super.dispose();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static DateTime _addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = date.day > maxDay ? maxDay : date.day;
    return DateTime(year, month, day);
  }

  static int _daysUntil(DateTime due) {
    final today = _dateOnly(DateTime.now());
    return _dateOnly(due).difference(today).inDays;
  }

  static String _healthCategoryFor(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('parazit')) return 'parasite';
    if (lower.contains('aşı') || lower.contains('asi')) return 'vaccine';
    return 'checkup';
  }

  String _formatFullDate(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1]} ${date.year}';

  String _formatDayMonth(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1]}';

  List<_HealthProcedure> get _upcomingSorted {
    final list = _procedures.where((p) => p.nextDueDate != null).toList()
      ..sort((a, b) => a.nextDueDate!.compareTo(b.nextDueDate!));
    return list;
  }

  List<_HealthProcedure> get _pastSorted {
    final list = _procedures.where((p) => p.lastDoneDate != null).toList()
      ..sort((a, b) => b.lastDoneDate!.compareTo(a.lastDoneDate!));
    return list;
  }

  _HealthProcedure get _currentProcedure =>
      _procedures[_selectedProcedure.clamp(0, _procedures.length - 1)];

  DateTime get _nextReminderDate =>
      _addMonths(_dateOnly(_selectedDate), _currentProcedure.intervalMonths);

  void _openReminder(_HealthProcedure item) {
    final index = _procedures.indexWhere((e) => e.title == item.title);
    final base = item.lastDoneDate ?? DateTime.now();
    setState(() {
      _selectedProcedure = index >= 0 ? index : 0;
      _selectedDate = _dateOnly(base);
      _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
      _reminderOpen = true;
    });
  }

  void _closeReminder() => setState(() => _reminderOpen = false);

  void _saveReminder() {
    final store = NotificationSettingsStore.instance;
    final p = _currentProcedure;
    final doneDate = _dateOnly(_selectedDate);
    final next = _addMonths(doneDate, p.intervalMonths);
    final daysLeft = _daysUntil(next);

    store.setHealthReminderTimeIndex(_selectedTime);

    setState(() {
      p.applyDoneDate(doneDate);
      _reminderOpen = false;
    });
    unawaited(
      HealthCalendarStore.instance.recordDone(
        title: p.title,
        category: _healthCategoryFor(p.title),
        frequency: p.frequency,
        intervalMonths: p.intervalMonths,
        doneDate: doneDate,
      ),
    );

    final notificationLine = store.healthNotificationLine(next);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: AppColors.text,
        behavior: SnackBarBehavior.floating,
        content: Text(
          '${p.title}\n'
          'İşlem: ${_formatDayMonth(doneDate)} ${_times[_selectedTime]}\n'
          'Sonraki hatırlatma: ${_formatDayMonth(next)} '
          '($daysLeft gün kaldı • ${p.frequency})\n'
          '$notificationLine',
          style: const TextStyle(fontSize: 12, height: 1.3),
        ),
      ),
    );
  }

  void _openVaccineCalendar() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const VaccineCalendarScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(context),
        content: Stack(
          children: [
            SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Column(
                children: [
                  const Text(
                    'Misket’in sağlığını takip et, mutlu ve sağlıklı bir yaşam destekle.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildTopBanner(),
                  const SizedBox(height: 10),
                  _buildPetTypeSelector(),
                  const SizedBox(height: 12),
                  _buildServiceCards(context),
                  const SizedBox(height: 12),
                  _buildUpcomingSection(),
                  const SizedBox(height: 10),
                  _buildPastSection(),
                  const SizedBox(height: 10),
                  _buildBottomBanner(),
                ],
              ),
            ),
            if (_reminderOpen) _buildReminderOverlay(),
          ],
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
                const Text('Pet E-nabız', style: AppTextStyles.pageHeader),
                const SizedBox(width: 4),
                const Icon(
                  Icons.favorite_rounded,
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
    return const AppBannerSlot(
      placement: BannerPlacement.healthTop,
      fallbackAssets: ['assets/images/saglik_banner.png'],
    );
  }

  Widget _buildPetTypeSelector() {
    return Row(
      children: [
        Expanded(
          child: _petTypeBox(
            label: 'Kedi',
            iconPath: 'assets/images/app_ikonlar/normal_kedi.png',
            selected: true,
            enabled: true,
            onTap: () {},
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _petTypeBox(
            label: 'Köpek',
            iconPath: 'assets/images/app_ikonlar/kopek.png',
            selected: false,
            enabled: false,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text(
                    'Köpek sağlığı yakında eklenecek.',
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _petTypeBox({
    required String label,
    required String iconPath,
    required bool selected,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return AppPressableButton(
      onTap: onTap,
      height: 36,
      padding: EdgeInsets.zero,
      backgroundColor: selected ? AppColors.selected : AppColors.surface,
      pressedBackgroundColor: selected
          ? AppColors.primary
          : AppColors.selected,
      foregroundColor: selected ? AppColors.primary : AppColors.subText,
      pressedForegroundColor: selected
          ? AppColors.surface
          : AppColors.primary,
      borderColor: selected ? AppColors.primaryLight : AppColors.border,
      pressedBorderColor: AppColors.primary,
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Stack(
          children: [
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    iconPath,
                    width: 18,
                    height: 18,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => Icon(
                      Icons.pets_rounded,
                      size: 16,
                      color: selected ? AppColors.primary : AppColors.subText,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    label,
                    style: TextStyle(
                      color: selected ? AppColors.primary : AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            if (selected)
              Positioned(
                right: 6,
                top: 6,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: AppColors.surface,
                    size: 10,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBanner() {
    return const AppBannerSlot(
      placement: BannerPlacement.healthBottom,
      fallbackAssets: ['assets/images/saglik_alt_banner.png'],
    );
  }

  Widget _buildServiceCards(BuildContext context) {
    return SizedBox(
      height: 118,
      child: Row(
        children: [
          _serviceCard(
            title: 'Aşı\nTakvimi',
            iconPath: 'assets/images/app_ikonlar/asi_takvimi.png',
            color: _asi,
            onTap: _openVaccineCalendar,
          ),
          const SizedBox(width: 8),
          _serviceCard(
            title: 'İlaç &\nTedavi',
            iconPath: 'assets/images/app_ikonlar/ilac_tedavi.png',
            color: _ilac,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const MedicineTreatmentScreen(),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
          _serviceCard(
            title: 'Özel\nMamalar',
            iconPath: 'assets/images/app_ikonlar/mama_kabi.png',
            color: _mama,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const SpecialFoodsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
          _serviceCard(
            title: 'Acil\nDurum',
            iconPath: 'assets/images/app_ikonlar/acil_durum.png',
            color: _acil,
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const EmergencySupportScreen(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _serviceCard({
    required String title,
    required String iconPath,
    required Color color,
    VoidCallback? onTap,
  }) {
    final softBorder = _softBorderColor(color);
    final softCircle = _softCircleColor(color);
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(6, 10, 6, 8),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: softBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(
                iconPath,
                width: 42,
                height: 42,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(Icons.pets_rounded, color: color, size: 34);
                },
              ),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.15,
                ),
              ),
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  color: softCircle,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: color,
                  size: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _softCircleColor(Color color) {
    return Color.lerp(color, Colors.white, 0.72) ??
        color.withValues(alpha: 0.22);
  }

  Color _softBorderColor(Color color) {
    return Color.lerp(color, Colors.white, 0.58) ??
        color.withValues(alpha: 0.42);
  }

  Widget _buildUpcomingSection() {
    final all = _upcomingSorted;
    final items = _showAllUpcoming ? all : all.take(2).toList();

    return Column(
      children: [
        _sectionHeader(
          title: 'Yaklaşan İşlemler',
          action: _showAllUpcoming ? 'Daralt' : 'Tümünü Gör',
          onAction: () {
            if (all.length <= 2) {
              _openVaccineCalendar();
              return;
            }
            setState(() => _showAllUpcoming = !_showAllUpcoming);
          },
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _upcomingItem(items[i]),
        ],
      ],
    );
  }

  Widget _buildPastSection() {
    final all = _pastSorted;
    final items = _showAllPast ? all : all.take(2).toList();

    return Column(
      children: [
        _sectionHeader(
          title: 'Geçmiş İşlemler',
          action: _showAllPast ? 'Daralt' : 'Tüm Geçmiş',
          onAction: () {
            if (all.length <= 2) {
              _openVaccineCalendar();
              return;
            }
            setState(() => _showAllPast = !_showAllPast);
          },
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _pastItem(items[i]),
        ],
      ],
    );
  }

  Widget _sectionHeader({
    required String title,
    required String action,
    required VoidCallback onAction,
  }) {
    return Row(
      children: [
        Expanded(child: Text(title, style: AppTextStyles.sectionHeader)),
        GestureDetector(
          onTap: onAction,
          child: Row(
            children: [
              Text(
                action,
                style: AppTextStyles.seeAllAction,
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.primary,
                size: 20,
              ),
            ],
          ),
        ),
      ],
    );
  }

  BoxDecoration _boxDecoration(Color softBorder) {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: softBorder, width: 1),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 6,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _upcomingItem(_HealthProcedure item) {
    item.recalculateNextDue();
    final due = item.nextDueDate!;
    final daysLeft = _daysUntil(due);
    final softBorder = _softBorderColor(item.color);

    final String daysMain;
    final String daysSub;
    if (daysLeft < 0) {
      daysMain = '${-daysLeft}';
      daysSub = 'gün geçti';
    } else if (daysLeft == 0) {
      daysMain = '0';
      daysSub = 'bugün';
    } else {
      daysMain = '$daysLeft';
      daysSub = 'gün kaldı';
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: _boxDecoration(softBorder),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${due.day}',
                  style: TextStyle(
                    color: item.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _monthShort[due.month - 1],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
              decoration: _boxDecoration(softBorder),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: item.color,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          item.icon,
                          color: AppColors.surface,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _formatFullDate(due),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        Text(
                          item.frequency,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.color.withValues(alpha: 0.85),
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: item.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: softBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          daysMain,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          daysSub,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 32,
                    child: Center(
                      child: GestureDetector(
                        onTap: () => _openReminder(item),
                        behavior: HitTestBehavior.opaque,
                        child: Container(
                          height: 28,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.surface,
                            borderRadius: BorderRadius.circular(999),
                            border: Border.all(color: softBorder),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                color: item.color,
                                size: 12,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                'Hatırlatıcı',
                                style: TextStyle(
                                  color: item.color,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pastItem(_HealthProcedure item) {
    final done = item.lastDoneDate!;
    final daysAgo = _dateOnly(
      DateTime.now(),
    ).difference(_dateOnly(done)).inDays;
    final softBorder = _softBorderColor(AppColors.success);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: 52,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            decoration: _boxDecoration(softBorder),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${done.day}',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _monthShort[done.month - 1],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Container(
              padding: const EdgeInsets.fromLTRB(8, 6, 6, 6),
              decoration: _boxDecoration(softBorder),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 32,
                    height: 32,
                    child: Center(
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: AppColors.surface,
                          size: 15,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          _formatFullDate(done),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    height: 36,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: softBorder),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$daysAgo',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            height: 1,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Text(
                          'gün önce',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.success,
                            fontSize: 7.5,
                            fontWeight: FontWeight.w800,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                  SizedBox(
                    height: 32,
                    child: Center(
                      child: Container(
                        height: 28,
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: softBorder),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.bookmark_rounded,
                              color: AppColors.success,
                              size: 12,
                            ),
                            SizedBox(width: 3),
                            Text(
                              'Tamamlandı',
                              style: TextStyle(
                                color: AppColors.success,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                              ),
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
        ],
      ),
    );
  }

  Widget _buildReminderOverlay() {
    return Positioned.fill(
      child: Stack(
        children: [
          GestureDetector(
            onTap: _closeReminder,
            child: Container(color: Colors.black.withValues(alpha: 0.35)),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: AppPageFrame.contentHeight - 8,
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(14, 8, 8, 0),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.notifications_active_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Hatırlatıcı Ayarla',
                                style: TextStyle(
                                  color: AppColors.text,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              Text(
                                'İşlem tarihini seçin; sonraki hatırlatma periyoda göre hesaplanır.',
                                style: TextStyle(
                                  color: AppColors.subText,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          onPressed: _closeReminder,
                          icon: const Icon(
                            Icons.close_rounded,
                            color: AppColors.subText,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, color: AppColors.border),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(flex: 42, child: _buildProcedureList()),
                          const SizedBox(width: 8),
                          Expanded(flex: 58, child: _buildDateTimePanel()),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
                    child: Column(
                      children: [
                        _buildSummaryBox(),
                        const SizedBox(height: 8),
                        AppPressableButton.primary(
                          onTap: _saveReminder,
                          width: double.infinity,
                          height: 42,
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.notifications_active_rounded,
                                size: 16,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Hatırlatıcıyı Kaydet',
                                style: TextStyle(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProcedureList() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: _procedures.length,
        itemBuilder: (context, index) {
          final item = _procedures[index];
          final selected = index == _selectedProcedure;
          return GestureDetector(
            onTap: () => setState(() => _selectedProcedure = index),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
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
                  Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: item.color,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(item.icon, color: AppColors.surface, size: 13),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primary
                                : AppColors.text,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          item.frequency,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: selected
                                ? AppColors.primaryLight
                                : AppColors.subText,
                            fontSize: 8,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateTimePanel() {
    final store = NotificationSettingsStore.instance;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Column(
          children: [
            Expanded(child: _buildCalendar()),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Bildirim: Kaç Gün Önce',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                for (final days in [1, 3, 7]) ...[
                  if (days != 1) const SizedBox(width: 6),
                  Expanded(
                    child: _healthDaysChip(
                      days: days,
                      selected: store.healthReminderDaysBefore == days,
                      onTap: () => store.setHealthReminderDaysBefore(days),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 8),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Saat Seçin',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (int i = 0; i < _times.length; i++)
                  GestureDetector(
                    onTap: () {
                      setState(() => _selectedTime = i);
                      store.setHealthReminderTimeIndex(i);
                    },
                    child: Container(
                      width: 72,
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      decoration: BoxDecoration(
                        color: _selectedTime == i
                            ? AppColors.primary
                            : AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: _selectedTime == i
                              ? AppColors.primary
                              : AppColors.border,
                        ),
                      ),
                      child: Column(
                        children: [
                          Text(
                            _times[i],
                            style: TextStyle(
                              color: _selectedTime == i
                                  ? AppColors.surface
                                  : AppColors.text,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          Text(
                            _timeLabels[i],
                            style: TextStyle(
                              color: _selectedTime == i
                                  ? AppColors.surface
                                  : AppColors.subText,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _healthDaysChip({
    required int days,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.selected : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Text(
          '$days Gün',
          style: TextStyle(
            color: selected ? AppColors.primary : AppColors.text,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  Widget _buildCalendar() {
    final first = DateTime(_visibleMonth.year, _visibleMonth.month, 1);
    final daysInMonth = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
      0,
    ).day;
    final startWeekday = first.weekday;
    const weekDays = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 6),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Text(
                'İşlem Tarihi',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month - 1,
                    );
                  });
                },
                child: const Icon(
                  Icons.chevron_left_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
              Text(
                '${_monthNames[_visibleMonth.month - 1]} ${_visibleMonth.year}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              GestureDetector(
                onTap: () {
                  setState(() {
                    _visibleMonth = DateTime(
                      _visibleMonth.year,
                      _visibleMonth.month + 1,
                    );
                  });
                },
                child: const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.primary,
                  size: 20,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final d in weekDays)
                Expanded(
                  child: Text(
                    d,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Expanded(
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              itemCount: startWeekday - 1 + daysInMonth,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemBuilder: (context, index) {
                if (index < startWeekday - 1) {
                  return const SizedBox.shrink();
                }
                final day = index - (startWeekday - 1) + 1;
                final date = DateTime(
                  _visibleMonth.year,
                  _visibleMonth.month,
                  day,
                );
                final selected =
                    date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.primary : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '$day',
                      style: TextStyle(
                        color: selected ? AppColors.surface : AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryBox() {
    final store = NotificationSettingsStore.instance;
    final p = _currentProcedure;
    final next = _nextReminderDate;
    final daysLeft = _daysUntil(next);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          RichText(
            text: TextSpan(
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              children: [
                const TextSpan(text: 'İşlem: '),
                TextSpan(
                  text: p.title,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                TextSpan(
                  text: '  (${p.frequency})',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Uygulama tarihi: ${_formatDayMonth(_selectedDate)} • ${_times[_selectedTime]}',
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sonraki hatırlatma: ${_formatDayMonth(next)}  •  $daysLeft gün kaldı',
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            store.healthNotificationLine(next),
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _HealthProcedure {
  _HealthProcedure({
    required this.icon,
    required this.color,
    required this.title,
    required this.frequency,
    required this.intervalMonths,
    this.lastDoneDate,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String frequency;
  final int intervalMonths;
  DateTime? lastDoneDate;
  DateTime? nextDueDate;

  void applyDoneDate(DateTime doneDate) {
    lastDoneDate = DateTime(doneDate.year, doneDate.month, doneDate.day);
    recalculateNextDue();
  }

  void recalculateNextDue() {
    if (lastDoneDate == null || intervalMonths <= 0) {
      nextDueDate = null;
      return;
    }
    nextDueDate = _HealthScreenState._addMonths(
      DateTime(lastDoneDate!.year, lastDoneDate!.month, lastDoneDate!.day),
      intervalMonths,
    );
  }
}
