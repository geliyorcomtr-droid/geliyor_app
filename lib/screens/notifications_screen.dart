import 'package:flutter/material.dart';
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
  _NotificationItem? _selected;

  final List<_FilterChipData> filters = const [
    _FilterChipData(id: 0, label: 'Tümü'),
    _FilterChipData(id: 1, label: 'Okunmamış', showDot: true),
    _FilterChipData(id: 2, label: 'Kampanyalar'),
    _FilterChipData(id: 3, label: 'Hatırlatmalar'),
    _FilterChipData(id: 4, label: 'Sistem'),
  ];

  late List<_NotificationItem> notifications;

  @override
  void initState() {
    super.initState();
    notifications = [
      _NotificationItem(
        id: 'n1',
        title: 'Plan hatırlatması',
        description: 'Minnoş için tıraş saati yaklaşıyor. Planını kontrol et.',
        detail:
            'Minnoş için planladığın tıraş hatırlatmasının zamanı yaklaşıyor. '
            'Planını kontrol ederek randevuyu onaylayabilir veya erteleyebilirsin.\n\n'
            'Hatırlatmalar, pet takvimine göre otomatik oluşturulur. '
            'İstersen bildirim ayarlarından hatırlatma süresini değiştirebilirsin.',
        time: '5 dk önce',
        dateLabel: '12 Mayıs 2025',
        category: _NotifCategory.reminder,
        icon: Icons.pets_rounded,
        iconBg: AppColors.primary,
        scheduleText: '12 Mayıs 2025 14:00',
        unread: true,
      ),
      _NotificationItem(
        id: 'n2',
        title: 'Özel kampanya',
        description: 'Seçili mamalarda %20 indirim seni bekliyor.',
        detail:
            'Seçili mama ürünlerinde %20 indirim kampanyası başladı. '
            'Kampanya stoklarla sınırlıdır ve seçili markalarda geçerlidir.\n\n'
            'Pet Market üzerinden kampanyalı ürünleri inceleyebilir, '
            'sepete ekleyerek indirimli fiyattan sipariş verebilirsin.',
        time: '1 saat önce',
        dateLabel: 'Bugün',
        category: _NotifCategory.campaign,
        icon: Icons.local_offer_rounded,
        iconBg: AppColors.success,
        unread: true,
      ),
      _NotificationItem(
        id: 'n3',
        title: 'Puan kazandınız',
        description: 'Son siparişinden 150 Pati Puan kazandın.',
        detail:
            'Son siparişin başarıyla tamamlandı ve hesabına 150 Pati Puan eklendi. '
            'Puanlarını kampanya ve hediye ürünlerde kullanabilirsin.\n\n'
            'Güncel puan bakiyeni Kampanya & Puanlar sayfasından takip edebilirsin.',
        time: 'Dün 18:40',
        dateLabel: 'Dün',
        category: _NotifCategory.system,
        icon: Icons.card_giftcard_rounded,
        iconBg: AppColors.primaryLight,
        unread: false,
      ),
      _NotificationItem(
        id: 'n4',
        title: 'Sipariş kargoya verildi',
        description: 'GL-10428 numaralı siparişin yola çıktı.',
        detail:
            'GL-10428 numaralı siparişin kargoya verildi ve yola çıktı. '
            'Tahmini teslimat aralığı sipariş özetinde görüntülenir.\n\n'
            'Kargo hareketlerini Siparişlerim sayfasından anlık olarak takip edebilirsin.',
        time: 'Dün 11:20',
        dateLabel: 'Dün',
        category: _NotifCategory.system,
        icon: Icons.local_shipping_rounded,
        iconBg: AppColors.warning,
        unread: false,
      ),
      _NotificationItem(
        id: 'n5',
        title: "Asistan'dan öneri",
        description: 'Minnoş için uygun ödül mamaları önerildi.',
        detail:
            'Asistan, Minnoş’un profiline göre ödül mamaları önerdi. '
            'Öneriler yaş, kilo ve tercih edilen lezzetlere göre şekillenir.\n\n'
            'Önerilen ürünleri Asistan veya Pet Market üzerinden inceleyebilirsin.',
        time: '2 gün önce',
        dateLabel: '2 gün önce',
        category: _NotifCategory.system,
        icon: Icons.smart_toy_outlined,
        iconBg: AppColors.primaryLight,
        unread: false,
      ),
      _NotificationItem(
        id: 'n6',
        title: 'Sağlık hatırlatması',
        description: 'Parazit koruma uygulaması için hatırlatma.',
        detail:
            'Parazit koruma uygulaması için hatırlatma zamanı geldi. '
            'Uygulama tarihini sağlık takviminden güncelleyebilirsin.\n\n'
            'Düzenli koruma, dostunun sağlığı için önemlidir. '
            'Hatırlatıcıyı tamamlandı olarak işaretlemeyi unutma.',
        time: '3 gün önce',
        dateLabel: '3 gün önce',
        category: _NotifCategory.reminder,
        icon: Icons.health_and_safety_rounded,
        iconBg: AppColors.error,
        scheduleText: '10 Mayıs 2025 09:00',
        unread: false,
      ),
      _NotificationItem(
        id: 'n7',
        title: 'Hoş geldiniz!',
        description: 'geliyor.tr ailesine katıldığın için teşekkürler.',
        detail:
            'geliyor.tr ailesine katıldığın için teşekkürler. '
            'Pet Market, akıllı plan, sağlık takibi ve asistan özelliklerini keşfedebilirsin.\n\n'
            'Profilini tamamlayarak dostuna özel öneriler almaya hemen başlayabilirsin.',
        time: '1 hafta önce',
        dateLabel: '1 hafta önce',
        category: _NotifCategory.system,
        icon: Icons.auto_awesome_rounded,
        iconBg: AppColors.warning,
        unread: false,
      ),
      _NotificationItem(
        id: 'n8',
        title: 'Sistem bildirimi',
        description: 'Profil bilgilerin başarıyla güncellendi.',
        detail:
            'Profil bilgilerin başarıyla güncellendi. '
            'Değişiklikler hesabına anında yansır.\n\n'
            'Güvenlik için şüpheli bir güncelleme fark edersen '
            'Gizlilik ve Güvenlik ayarlarından giriş bildirimlerini açabilirsin.',
        time: '1 hafta önce',
        dateLabel: '1 hafta önce',
        category: _NotifCategory.system,
        icon: Icons.notifications_rounded,
        iconBg: AppColors.subText,
        unread: false,
      ),
    ];
  }

  List<_NotificationItem> get filteredNotifications {
    switch (selectedFilter) {
      case 1:
        return notifications.where((n) => n.unread).toList();
      case 2:
        return notifications
            .where((n) => n.category == _NotifCategory.campaign)
            .toList();
      case 3:
        return notifications
            .where((n) => n.category == _NotifCategory.reminder)
            .toList();
      case 4:
        return notifications
            .where((n) => n.category == _NotifCategory.system)
            .toList();
      default:
        return notifications;
    }
  }

  String get _categoryLabel {
    return switch (_selected?.category) {
      _NotifCategory.campaign => 'Kampanya',
      _NotifCategory.reminder => 'Hatırlatma',
      _NotifCategory.system => 'Sistem',
      null => '',
    };
  }

  void _markAllRead() {
    setState(() {
      for (final item in notifications) {
        item.unread = false;
      }
    });
  }

  void _openNotification(_NotificationItem item) {
    setState(() {
      item.unread = false;
      _selected = item;
    });
  }

  void _closeDetail() {
    setState(() => _selected = null);
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
              ? _closeDetail
              : () => Navigator.of(context).maybePop(),
          trailing: showingDetail
              ? null
              : GestureDetector(
                  onTap: () {},
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
        content: showingDetail ? _buildDetail(_selected!) : _buildList(),
      ),
    );
  }

  Widget _buildList() {
    final items = filteredNotifications;

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
          child: items.isEmpty
              ? _buildEmptyState()
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

  Widget _buildDetail(_NotificationItem item) {
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
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.selected,
                                      borderRadius: BorderRadius.circular(999),
                                      border: Border.all(
                                        color: AppColors.border,
                                      ),
                                    ),
                                    child: Text(
                                      _categoryLabel,
                                      style: const TextStyle(
                                        color: AppColors.primary,
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    item.time,
                                    style: const TextStyle(
                                      color: AppColors.subText,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: AppColors.primary,
                            size: 16,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              item.scheduleText ?? item.dateLabel,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
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
                      item.detail,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 13,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      item.description,
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 13,
                        height: 1.4,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          AppPressableButton.primary(
            onTap: _closeDetail,
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
          for (int i = 0; i < filters.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(child: _buildFilterChip(filters[i])),
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
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.border.withValues(alpha: 0.75),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.22),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
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
                const SizedBox(width: 3),
              ],
              Text(
                filter.label,
                maxLines: 1,
                style: TextStyle(
                  color: selected ? AppColors.surface : AppColors.subText,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationCard(_NotificationItem item) {
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
                    item.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 11,
                      height: 1.25,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (item.scheduleText != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        const Icon(
                          Icons.calendar_month_rounded,
                          color: AppColors.primary,
                          size: 13,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          item.scheduleText!,
                          style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  item.time,
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
        onTap: _markAllRead,
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

  Widget _buildEmptyState() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_off_outlined,
              color: AppColors.border,
              size: 42,
            ),
            SizedBox(height: 10),
            Text(
              'Bu kategoride bildirim yok',
              style: TextStyle(
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
}

enum _NotifCategory { campaign, reminder, system }

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

class _NotificationItem {
  _NotificationItem({
    required this.id,
    required this.title,
    required this.description,
    required this.detail,
    required this.time,
    required this.dateLabel,
    required this.category,
    required this.icon,
    required this.iconBg,
    this.scheduleText,
    required this.unread,
  });

  final String id;
  final String title;
  final String description;
  final String detail;
  final String time;
  final String dateLabel;
  final _NotifCategory category;
  final IconData icon;
  final Color iconBg;
  final String? scheduleText;
  bool unread;
}
