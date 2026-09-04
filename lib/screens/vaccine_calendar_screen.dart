import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/state/health_calendar_store.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

enum _ItemCategory { vaccine, parasite, checkup, info }

class VaccineCalendarScreen extends StatefulWidget {
  const VaccineCalendarScreen({
    super.key,
    this.openReminder = false,
  });

  final bool openReminder;

  @override
  State<VaccineCalendarScreen> createState() => _VaccineCalendarScreenState();
}

class _VaccineCalendarScreenState extends State<VaccineCalendarScreen> {
  int _selectedTab = 0;
  bool _reminderOpen = false;
  int _selectedProcedure = 0;
  DateTime _visibleMonth = DateTime(DateTime.now().year, DateTime.now().month);
  DateTime _selectedDate = DateTime.now();

  late final List<_UpcomingItem> _allItems;

  NotificationSettingsStore get _notifyStore =>
      NotificationSettingsStore.instance;

  bool get _calendarEnabled => _notifyStore.vaccineCalendarEnabled;

  int get _selectedTime => _notifyStore.healthReminderTimeIndex;

  static const _tabs = ['Aşılar', 'Parazit', 'Kontroller'];
  static const _times = ['09:00', '13:00', '17:00', '20:00'];
  static const _timeLabels = ['Sabah', 'Öğle', 'Akşam', 'Gece'];
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
  static const _weekDays = ['Pt', 'Sa', 'Ça', 'Pe', 'Cu', 'Ct', 'Pz'];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    _allItems = [
      _UpcomingItem(
        icon: Icons.vaccines_outlined,
        color: AppColors.primary,
        title: 'Karma Aşı',
        frequency: 'Yılda Bir',
        category: _ItemCategory.vaccine,
        intervalMonths: 12,
        lastDoneDate: _addMonths(today.add(const Duration(days: 20)), -12),
      ),
      _UpcomingItem(
        icon: Icons.bug_report_outlined,
        color: const Color(0xFF8B5CF6),
        title: 'İç Parazit',
        frequency: '3 Ayda Bir',
        category: _ItemCategory.parasite,
        intervalMonths: 3,
        lastDoneDate: _addMonths(today.add(const Duration(days: 36)), -3),
      ),
      _UpcomingItem(
        icon: Icons.shield_outlined,
        color: const Color(0xFF00A859),
        title: 'Dış Parazit',
        frequency: 'Her Ay',
        category: _ItemCategory.parasite,
        intervalMonths: 1,
        lastDoneDate: _addMonths(today.add(const Duration(days: 30)), -1),
      ),
      _UpcomingItem(
        icon: Icons.vaccines_outlined,
        color: const Color(0xFFFF6600),
        title: 'Kuduz Aşısı',
        frequency: 'Yılda Bir',
        category: _ItemCategory.vaccine,
        intervalMonths: 12,
        lastDoneDate: _addMonths(today.add(const Duration(days: 59)), -12),
      ),
      _UpcomingItem(
        icon: Icons.medical_services_outlined,
        color: AppColors.primaryLight,
        title: 'Veteriner Kontrolü',
        frequency: '6 Ayda Bir',
        category: _ItemCategory.checkup,
        intervalMonths: 6,
        lastDoneDate: _addMonths(today.add(const Duration(days: 71)), -6),
      ),
      _UpcomingItem(
        icon: Icons.mood_outlined,
        color: const Color(0xFF8B5CF6),
        title: 'Diş Kontrolü',
        frequency: 'Yılda Bir',
        category: _ItemCategory.checkup,
        intervalMonths: 12,
        lastDoneDate: _addMonths(today.add(const Duration(days: 110)), -12),
      ),
      _UpcomingItem(
        icon: Icons.monitor_weight_outlined,
        color: const Color(0xFFFF6600),
        title: 'Kilo Kontrolü',
        frequency: '3 Ayda Bir',
        category: _ItemCategory.checkup,
        intervalMonths: 3,
        lastDoneDate: _addMonths(today.add(const Duration(days: 90)), -3),
      ),
      _UpcomingItem(
        icon: Icons.bloodtype_outlined,
        color: const Color(0xFFE60000),
        title: 'Kan Tahlili',
        frequency: 'Yılda Bir (7+ yaşta 6 ayda bir)',
        category: _ItemCategory.checkup,
        intervalMonths: 12,
        lastDoneDate: _addMonths(today.add(const Duration(days: 138)), -12),
      ),
      _UpcomingItem(
        icon: Icons.vaccines_outlined,
        color: const Color(0xFFE60000),
        title: 'Lösemi Aşısı',
        frequency: 'Yılda Bir (Gerekiyorsa)',
        category: _ItemCategory.vaccine,
        intervalMonths: 12,
        lastDoneDate: _addMonths(today.add(const Duration(days: 175)), -12),
      ),
      _UpcomingItem(
        icon: Icons.menu_book_outlined,
        color: AppColors.primary,
        title: 'Koruyucu aşılar',
        frequency: 'Hastalıklara karşı güçlü koruma',
        category: _ItemCategory.info,
        intervalMonths: 0,
      ),
      _UpcomingItem(
        icon: Icons.health_and_safety_outlined,
        color: const Color(0xFF00A859),
        title: 'Düzenli kontroller',
        frequency: 'Erken teşhis, sağlıklı yaşam',
        category: _ItemCategory.info,
        intervalMonths: 0,
      ),
      _UpcomingItem(
        icon: Icons.event_available_outlined,
        color: const Color(0xFFFF6600),
        title: 'Aşı takvimi takibi',
        frequency: 'Doğru zamanda, doğru aşı',
        category: _ItemCategory.info,
        intervalMonths: 0,
      ),
      _UpcomingItem(
        icon: Icons.favorite_outline_rounded,
        color: const Color(0xFFE60000),
        title: 'Uzun ve mutlu yaşam',
        frequency: 'Sevginizle birlikte sağlıklı yarınlar',
        category: _ItemCategory.info,
        intervalMonths: 0,
      ),
    ];

    for (final item in _allItems) {
      item.recalculateNextDue();
    }
    _applySavedDates();
    _reminderOpen = widget.openReminder;
    HealthCalendarStore.instance.addListener(_onCalendarChanged);
  }

  void _onCalendarChanged() {
    if (!mounted) return;
    setState(_applySavedDates);
  }

  void _applySavedDates() {
    HealthCalendarStore.instance.overlayLastDone((title, lastDone) {
      for (final item in _allItems) {
        if (item.title == title) {
          item.applyDoneDate(lastDone);
        }
      }
    });
  }

  @override
  void dispose() {
    HealthCalendarStore.instance.removeListener(_onCalendarChanged);
    super.dispose();
  }

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

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// Bugünden sonraki aşı/hatırlatma tarihine kalan gün.
  static int daysUntilDue(DateTime due) {
    final today = _dateOnly(DateTime.now());
    return _dateOnly(due).difference(today).inDays;
  }

  List<_UpcomingItem> get _reminderProcedures =>
      _allItems.where((e) => e.category != _ItemCategory.info).toList();

  List<_UpcomingItem> get _filteredItems {
    switch (_selectedTab) {
      case 1:
        return _allItems
            .where((e) => e.category == _ItemCategory.parasite)
            .toList();
      case 2:
        return _allItems
            .where((e) => e.category == _ItemCategory.checkup)
            .toList();
      default:
        return _allItems
            .where((e) => e.category == _ItemCategory.vaccine)
            .toList();
    }
  }

  _UpcomingItem get _currentProcedure =>
      _reminderProcedures[_selectedProcedure.clamp(
        0,
        _reminderProcedures.length - 1,
      )];

  /// Seçilen uygulama tarihinden periyot kadar sonraki hatırlatma tarihi.
  DateTime get _nextReminderDate =>
      _addMonths(_dateOnly(_selectedDate), _currentProcedure.intervalMonths);

  int _daysUntil(DateTime due) => daysUntilDue(due);

  String _formatDayMonth(DateTime date) =>
      '${date.day} ${_monthNames[date.month - 1]}';

  void _openReminder(_UpcomingItem item) {
    if (!_calendarEnabled || item.category == _ItemCategory.info) return;
    final index = _reminderProcedures.indexWhere((e) => e.title == item.title);
    final base = item.lastDoneDate ?? DateTime.now();
    setState(() {
      _selectedProcedure = index >= 0 ? index : 0;
      _selectedDate = _dateOnly(base);
      _visibleMonth = DateTime(_selectedDate.year, _selectedDate.month);
      _reminderOpen = true;
    });
  }

  void _closeReminder() => setState(() => _reminderOpen = false);

  void _setCalendarEnabled(bool enabled) {
    _notifyStore.setVaccineCalendarEnabled(enabled);
    if (!enabled) setState(() => _reminderOpen = false);
  }

  void _saveReminder() {
    if (!_calendarEnabled) return;
    final store = _notifyStore;
    final p = _currentProcedure;
    final doneDate = _dateOnly(_selectedDate);
    final next = _addMonths(doneDate, p.intervalMonths);
    final daysLeft = _daysUntil(next);

    setState(() {
      p.applyDoneDate(doneDate);
      _reminderOpen = false;
    });
    unawaited(
      HealthCalendarStore.instance.recordDone(
        title: p.title,
        category: p.category.name,
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

  @override
  Widget build(BuildContext context) {
    final items = _filteredItems;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(context),
        content: ListenableBuilder(
          listenable: _notifyStore,
          builder: (context, _) {
            return Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 6),
                  child: Column(
                    children: [
                      const Text(
                        'Dostunuzun sağlıklı ve mutlu bir yaşam sürmesi için aşı, parazit ve kontrolleri zamanında yapmayı unutmayın.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.subText,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w500,
                          height: 1.25,
                        ),
                      ),
                      const SizedBox(height: 8),
                      _buildBanner(),
                      const SizedBox(height: 8),
                      _buildTabs(),
                      const SizedBox(height: 8),
                      Expanded(
                        child: Opacity(
                          opacity: _calendarEnabled ? 1 : 0.45,
                          child: IgnorePointer(
                            ignoring: !_calendarEnabled,
                            child: Container(
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                                itemCount: items.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: 6),
                                itemBuilder: (context, index) {
                                  return _buildUpcomingRow(items[index]);
                                },
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                if (_reminderOpen && _calendarEnabled) _buildReminderOverlay(),
              ],
            );
          },
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
            child: IgnorePointer(
              child: Text(
                'Aşı Takvimi',
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/asi_takvimi_banner.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 88,
            color: AppColors.selected,
            alignment: Alignment.center,
            child: const Icon(
              Icons.health_and_safety_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          );
        },
      ),
    );
  }

  Widget _buildTabs() {
    final selectedTabColor =
        Color.lerp(AppColors.primary, Colors.white, 0.35) ??
            AppColors.primaryLight;
    return SizedBox(
      height: 30,
      child: Row(
        children: [
          for (int index = 0; index < _tabs.length; index++) ...[
            if (index > 0) const SizedBox(width: 6),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedTab = index),
                child: Container(
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: _selectedTab == index
                        ? selectedTabColor
                        : AppColors.surface,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _selectedTab == index
                          ? selectedTabColor
                          : AppColors.border,
                    ),
                  ),
                  child: Text(
                    _tabs[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _selectedTab == index
                          ? AppColors.surface
                          : AppColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ),
          ],
          const SizedBox(width: 6),
          SizedBox(
            width: 42,
            height: 30,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Switch(
                value: _calendarEnabled,
                onChanged: _setCalendarEnabled,
                activeThumbColor: AppColors.surface,
                activeTrackColor: AppColors.primaryLight,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _softBorderColor(Color color) {
    return Color.lerp(color, Colors.white, 0.58) ??
        color.withValues(alpha: 0.42);
  }

  Widget _buildUpcomingRow(_UpcomingItem item) {
    final softBorder = _softBorderColor(item.color);
    final isInfo = item.category == _ItemCategory.info;
    // Her çizimde yeniden hesapla — kayıttan sonra gün sayısı aktif kalsın.
    item.recalculateNextDue();
    final due = item.nextDueDate;
    final daysLeft = item.daysRemaining;
    final dayText = due == null ? '—' : '${due.day}';
    final monthText = due == null ? 'BİLGİ' : _monthShort[due.month - 1];

    String daysMain;
    String daysSub;
    if (isInfo || daysLeft == null) {
      daysMain = '—';
      daysSub = 'Bilgi';
    } else if (daysLeft < 0) {
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
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  dayText,
                  style: TextStyle(
                    color: item.color,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  monthText,
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
                          item.frequency,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: item.color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
                          ),
                        ),
                        if (!isInfo && due != null) ...[
                          const SizedBox(height: 1),
                          Text(
                            _formatDayMonth(due),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: item.color,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (!isInfo) ...[
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
          Positioned(
            left: 0,
            right: 0,
            top: 8,
            bottom: 0,
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
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
                          Expanded(
                            flex: 42,
                            child: _buildProcedureList(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            flex: 58,
                            child: _buildDateTimePanel(),
                          ),
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
    final procedures = _reminderProcedures;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 4),
        itemCount: procedures.length,
        itemBuilder: (context, index) {
          final item = procedures[index];
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
                            color: selected ? AppColors.primary : AppColors.text,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            height: 1.15,
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
    final store = _notifyStore;

    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        return Column(
          children: [
            Expanded(child: _buildCalendar()),
            const SizedBox(height: 8),
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bildirim: Kaç Gün Önce',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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
                              onTap: () =>
                                  store.setHealthReminderDaysBefore(days),
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Saat Seçin',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (int i = 0; i < _times.length; i++)
                          GestureDetector(
                            onTap: () => store.setHealthReminderTimeIndex(i),
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
                ),
              ),
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
    final daysInMonth =
        DateTime(_visibleMonth.year, _visibleMonth.month + 1, 0).day;
    final startWeekday = first.weekday;

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
              for (final d in _weekDays)
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
                childAspectRatio: 1.1,
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
                final selected = date.year == _selectedDate.year &&
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
    final store = _notifyStore;
    final p = _currentProcedure;
    final next = _nextReminderDate;
    final daysLeft = _daysUntil(next);
    final dateText = _formatDayMonth(_selectedDate);
    final nextText = _formatDayMonth(next);

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
            'Uygulama tarihi: $dateText • ${_times[_selectedTime]} (${_timeLabels[_selectedTime]})',
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 10,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Sonraki hatırlatma: $nextText  •  $daysLeft gün kaldı',
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

class _UpcomingItem {
  _UpcomingItem({
    required this.icon,
    required this.color,
    required this.title,
    required this.frequency,
    required this.category,
    required this.intervalMonths,
    this.lastDoneDate,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String frequency;
  final _ItemCategory category;
  final int intervalMonths;
  DateTime? lastDoneDate;
  DateTime? nextDueDate;

  int? get daysRemaining {
    recalculateNextDue();
    final due = nextDueDate;
    if (due == null) return null;
    return _VaccineCalendarScreenState.daysUntilDue(due);
  }

  void applyDoneDate(DateTime doneDate) {
    lastDoneDate = DateTime(doneDate.year, doneDate.month, doneDate.day);
    recalculateNextDue();
  }

  void recalculateNextDue() {
    if (category == _ItemCategory.info || intervalMonths <= 0) {
      nextDueDate = null;
      return;
    }
    if (lastDoneDate == null) {
      nextDueDate = null;
      return;
    }
    nextDueDate = _VaccineCalendarScreenState._addMonths(
      DateTime(lastDoneDate!.year, lastDoneDate!.month, lastDoneDate!.day),
      intervalMonths,
    );
  }
}
