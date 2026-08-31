import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/notification_settings_screen.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/notifications_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  int selectedFilter = 0;
  AppNotification? _selected;

  static const _filters = [
    _FilterChipData(id: 0, label: 'Tümü'),
    _FilterChipData(id: 1, label: 'Okunmamış', showDot: true),
    _FilterChipData(id: 2, label: 'Kampanyalar'),
    _FilterChipData(id: 3, label: 'Hatırlatmalar'),
    _FilterChipData(id: 4, label: 'Sistem'),
  ];

  NotificationsStore get _store => NotificationsStore.instance;

  List<AppNotification> _filtered(List<AppNotification> all) {
    switch (selectedFilter) {
      case 1:
        return all.where((n) => n.unread).toList();
      case 2:
        return all
            .where((n) => n.category == AppNotificationCategory.campaign)
            .toList();
      case 3:
        return all
            .where((n) => n.category == AppNotificationCategory.reminder)
            .toList();
      case 4:
        return all
            .where(
              (n) =>
                  n.category == AppNotificationCategory.system ||
                  n.category == AppNotificationCategory.order,
            )
            .toList();
      default:
        return all;
    }
  }

  String get _categoryLabel {
    return switch (_selected?.category) {
      AppNotificationCategory.campaign => 'Kampanya',
      AppNotificationCategory.reminder => 'Hatırlatma',
      AppNotificationCategory.order => 'Sipariş',
      AppNotificationCategory.system => 'Sistem',
      null => '',
    };
  }

  Future<void> _openNotification(AppNotification item) async {
    setState(() => _selected = item);
    if (item.unread) {
      await _store.markRead(item.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final showingDetail = _selected != null;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: AppPageHeader(
          title: showingDetail ? 'Bildirim Detayı' : 'Bildirimler',
          onBack: showingDetail
              ? () => setState(() => _selected = null)
              : () => Navigator.of(context).maybePop(),
          trailing: showingDetail
              ? null
              : GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.selected,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: AppColors.border.withValues(alpha: 0.8),
                      ),
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                ),
        ),
        content: ListenableBuilder(
          listenable: Listenable.merge([_store, AuthStore.instance]),
          builder: (context, _) {
            if (showingDetail && _selected != null) {
              return _buildDetail(_selected!);
            }
            return _buildList(_filtered(_store.items));
          },
        ),
      ),
    );
  }

  Widget _buildList(List<AppNotification> items) {
    final loggedIn = AuthStore.instance.isLoggedIn;

    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppPageFrame.contentHorizontalPadding,
          ),
          child: Text(
            'Tüm bildirimlerinizi burada görüntüleyebilirsiniz.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(height: 34, child: _buildFilters()),
        const SizedBox(height: 10),
        Expanded(
          child: !loggedIn
              ? _buildEmptyState('Giriş yapınca bildirimleriniz burada görünür.')
              : items.isEmpty
              ? _buildEmptyState('Bu kategoride bildirim yok')
              : ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppPageFrame.contentHorizontalPadding,
                    2,
                    AppPageFrame.contentHorizontalPadding,
                    12,
                  ),
                  itemCount: items.length + 1,
                  separatorBuilder: (_, index) {
                    if (index == items.length - 1) {
                      return const SizedBox(height: 14);
                    }
                    return const SizedBox(height: 8);
                  },
                  itemBuilder: (context, index) {
                    if (index == items.length) {
                      return _buildMarkAllRead();
                    }
                    return _buildNotificationCard(items[index]);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildDetail(AppNotification item) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppPageFrame.contentHorizontalPadding,
        0,
        AppPageFrame.contentHorizontalPadding,
        8,
      ),
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.border),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            color: item.iconBg,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Icon(
                            item.icon,
                            color: AppColors.surface,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _categoryLabel,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _dateLabel(item.createdAt),
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Ayrıntı',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AppPressableButton.primary(
            onTap: () => setState(() => _selected = null),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: const Text(
              'Listeye Dön',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppPageFrame.contentHorizontalPadding,
      ),
      child: Row(
        children: [
          for (int i = 0; i < _filters.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(child: _buildFilterChip(_filters[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildFilterChip(_FilterChipData filter) {
    final selected = selectedFilter == filter.id;

    return GestureDetector(
      onTap: () => setState(() => selectedFilter = filter.id),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (filter.showDot) ...[
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  color: selected ? AppColors.surface : AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 4),
            ],
            Flexible(
              child: Text(
                filter.label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.surface : AppColors.text,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard(AppNotification item) {
    return GestureDetector(
      onTap: () => _openNotification(item),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
        decoration: BoxDecoration(
          color: item.unread ? AppColors.selected : AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: item.unread
                ? AppColors.border
                : AppColors.border.withValues(alpha: 0.55),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: item.iconBg,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Icon(item.icon, color: AppColors.surface, size: 22),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  const SizedBox(height: 3),
                  Text(
                    item.body,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _relativeTime(item.createdAt),
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                if (item.unread)
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  )
                else
                  const Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.subText,
                    size: 20,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMarkAllRead() {
    return Center(
      child: AppPressableButton.soft(
        onTap: _store.markAllRead,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.done_all_rounded, size: 16),
            SizedBox(width: 6),
            Text(
              'Tümünü okundu olarak işaretle',
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.notifications_off_outlined,
              color: AppColors.border,
              size: 42,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.subText,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _relativeTime(DateTime? date) {
    if (date == null) return '';
    final diff = DateTime.now().difference(date);
    if (diff.inMinutes < 1) return 'Şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk önce';
    if (diff.inHours < 24) return '${diff.inHours} sa önce';
    if (diff.inDays == 1) return 'Dün';
    if (diff.inDays < 7) return '${diff.inDays} gün önce';
    return _dateLabel(date);
  }

  String _dateLabel(DateTime? date) {
    if (date == null) return '';
    String two(int n) => n.toString().padLeft(2, '0');
    return '${two(date.day)}.${two(date.month)}.${date.year}';
  }
}

class _FilterChipData {
  const _FilterChipData({
    required this.id,
    required this.label,
    this.showDot = false,
  });

  final int id;
  final String label;
  final bool showDot;
}
