import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

enum _OrderStatus { preparing, shipping, delivered, cancelled }

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  _OrderStatus? _activeFilter;
  int _currentPage = 1;
  static const int _pageSize = 4;

  static const List<_OrderItem> _allOrders = [
    _OrderItem(
      id: '12345',
      dateLabel: '10 Mayıs 2024 • 14:30',
      total: '1.249,90 TL',
      status: _OrderStatus.delivered,
      statusMessage: 'Siparişiniz 12 Mayıs 2024 tarihinde teslim edildi.',
      actionLabel: 'Tekrarla',
      images: [
        'assets/images/nd_kuzu_kisir.jpg',
        'assets/images/nd_kuzu_kisir.jpg',
        'assets/images/nd_kuzu_kisir.jpg',
      ],
    ),
    _OrderItem(
      id: '12344',
      dateLabel: '08 Mayıs 2024 • 09:15',
      total: '899,00 TL',
      status: _OrderStatus.shipping,
      statusMessage: 'Siparişiniz kargoya verildi.',
      actionLabel: 'Sipariş Takibi',
      images: [
        'assets/images/nd_kuzu_kisir.jpg',
        'assets/images/nd_kuzu_kisir.jpg',
      ],
    ),
    _OrderItem(
      id: '12343',
      dateLabel: '05 Mayıs 2024 • 18:45',
      total: '2.150,00 TL',
      status: _OrderStatus.preparing,
      statusMessage: 'Siparişiniz hazırlanıyor.',
      actionLabel: 'Detayları Gör',
      images: [
        'assets/images/nd_kuzu_kisir.jpg',
        'assets/images/nd_kuzu_kisir.jpg',
        'assets/images/nd_kuzu_kisir.jpg',
        'assets/images/nd_kuzu_kisir.jpg',
      ],
    ),
    _OrderItem(
      id: '12342',
      dateLabel: '01 Mayıs 2024 • 11:20',
      total: '450,00 TL',
      status: _OrderStatus.cancelled,
      statusMessage: 'Siparişiniz iptal edildi.',
      actionLabel: 'Detayları Gör',
      images: [
        'assets/images/nd_kuzu_kisir.jpg',
      ],
    ),
    _OrderItem(
      id: '12341',
      dateLabel: '28 Nisan 2024 • 16:05',
      total: '3.420,00 TL',
      status: _OrderStatus.delivered,
      statusMessage: 'Siparişiniz 30 Nisan 2024 tarihinde teslim edildi.',
      actionLabel: 'Tekrarla',
      images: [
        'assets/images/nd_kuzu_kisir.jpg',
        'assets/images/nd_kuzu_kisir.jpg',
      ],
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_OrderItem> get _filteredOrders {
    final query = _searchController.text.trim().toLowerCase();
    return _allOrders.where((order) {
      final matchesFilter =
          _activeFilter == null || order.status == _activeFilter;
      final matchesSearch = query.isEmpty ||
          order.id.contains(query) ||
          order.dateLabel.toLowerCase().contains(query) ||
          order.total.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
  }

  int get _totalPages {
    final count = _filteredOrders.length;
    if (count == 0) return 1;
    return (count / _pageSize).ceil();
  }

  List<_OrderItem> get _pageOrders {
    final filtered = _filteredOrders;
    if (filtered.isEmpty) return const [];
    final safePage = _currentPage.clamp(1, _totalPages);
    final start = (safePage - 1) * _pageSize;
    final end = (start + _pageSize).clamp(0, filtered.length);
    return filtered.sublist(start, end);
  }

  void _setFilter(_OrderStatus? status) {
    setState(() {
      _activeFilter = status;
      _currentPage = 1;
    });
  }

  void _setPage(int page) {
    setState(() => _currentPage = page.clamp(1, _totalPages));
  }

  @override
  Widget build(BuildContext context) {
    final pageOrders = _pageOrders;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        activeTab: AppNavTab.profile,
        header: _buildHeader(),
        content: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: _buildSearchBar(),
            ),
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: pageOrders.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                      itemCount: pageOrders.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (context, index) =>
                          _buildOrderCard(pageOrders[index]),
                    ),
            ),
            _buildPagination(),
            const SizedBox(height: 4),
          ],
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.profile),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: IgnorePointer(
              child: Text(
                'Siparişlerim',
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

  Widget _buildSearchBar() {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.subText, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() => _currentPage = 1),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Sipariş, ürün veya teslimat numarası ile ara',
                hintStyle: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _currentPage = 1);
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.subText,
                size: 16,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTabs() {
    const tabs = <(String, _OrderStatus?)>[
      ('Tümü', null),
      ('Hazırlanıyor', _OrderStatus.preparing),
      ('Kargoda', _OrderStatus.shipping),
      ('Teslim Edildi', _OrderStatus.delivered),
      ('İptal Edildi', _OrderStatus.cancelled),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: tabs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final (label, status) = tabs[index];
          final selected = _activeFilter == status;

          return GestureDetector(
            onTap: () => _setFilter(status),
            child: Column(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  height: 2,
                  width: selected ? 28 : 0,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.selected,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(
                Icons.inventory_2_outlined,
                color: AppColors.primary,
                size: 28,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Bu filtrede sipariş bulunamadı',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Farklı bir durum seçebilir veya aramayı temizleyebilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(_OrderItem order) {
    final style = _statusStyle(order.status);
    final visibleImages = order.images.take(3).toList();
    final extraCount = order.images.length - visibleImages.length;

    return Container(
      decoration: BoxDecoration(
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
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.selected,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: const Icon(
                        Icons.inventory_2_outlined,
                        color: AppColors.primary,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Sipariş No #${order.id}',
                            style: const TextStyle(
                              color: AppColors.text,
                              fontSize: 12,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          Text(
                            order.dateLabel,
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _buildStatusBadge(order.status, style),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: AppColors.subText,
                      size: 18,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 58,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            for (final image in visibleImages) ...[
                              _buildProductThumb(image),
                              const SizedBox(width: 6),
                            ],
                            if (extraCount > 0) _buildMoreThumb(extraCount),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Toplam Tutar',
                                style: TextStyle(
                                  color: AppColors.subText,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                order.total,
                                style: const TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                          AppPressableButton.outline(
                            onTap: () {},
                            height: 24,
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              order.actionLabel,
                              style: const TextStyle(fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            color: style.bannerColor,
            child: Row(
              children: [
                Icon(style.bannerIcon, size: 14, color: style.color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    order.statusMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: style.color,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
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

  Widget _buildStatusBadge(_OrderStatus status, _StatusStyle style) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: style.badgeBackground,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: style.color.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.badgeIcon, size: 11, color: style.color),
          const SizedBox(width: 4),
          Text(
            style.label,
            style: TextStyle(
              color: style.color,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductThumb(String imagePath) {
    return Container(
      width: 46,
      height: 58,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.all(4),
      child: Image.asset(
        imagePath,
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) => const Icon(
          Icons.pets_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      ),
    );
  }

  Widget _buildMoreThumb(int count) {
    return Container(
      width: 46,
      height: 58,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '+$count',
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _buildPagination() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _paginationButton(
            icon: Icons.chevron_left_rounded,
            enabled: _currentPage > 1,
            onTap: () => _setPage(_currentPage - 1),
          ),
          const SizedBox(width: 12),
          Text(
            'Sayfa $_currentPage / $_totalPages',
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 12),
          _paginationButton(
            icon: Icons.chevron_right_rounded,
            enabled: _currentPage < _totalPages,
            onTap: () => _setPage(_currentPage + 1),
          ),
        ],
      ),
    );
  }

  Widget _paginationButton({
    required IconData icon,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: enabled ? AppColors.selected : AppColors.surface,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.border),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled ? AppColors.primary : AppColors.subText,
        ),
      ),
    );
  }

  _StatusStyle _statusStyle(_OrderStatus status) {
    return switch (status) {
      _OrderStatus.delivered => const _StatusStyle(
          label: 'Teslim Edildi',
          color: AppColors.success,
          badgeBackground: Color(0xFFEAF9EF),
          bannerColor: Color(0xFFF0FBF4),
          badgeIcon: Icons.check_circle_rounded,
          bannerIcon: Icons.check_circle_outline_rounded,
        ),
      _OrderStatus.shipping => const _StatusStyle(
          label: 'Kargoda',
          color: AppColors.primary,
          badgeBackground: AppColors.selected,
          bannerColor: Color(0xFFF2F8FF),
          badgeIcon: Icons.local_shipping_outlined,
          bannerIcon: Icons.info_outline_rounded,
        ),
      _OrderStatus.preparing => const _StatusStyle(
          label: 'Hazırlanıyor',
          color: AppColors.warning,
          badgeBackground: Color(0xFFFFF7E8),
          bannerColor: Color(0xFFFFFAF0),
          badgeIcon: Icons.schedule_rounded,
          bannerIcon: Icons.schedule_rounded,
        ),
      _OrderStatus.cancelled => const _StatusStyle(
          label: 'İptal Edildi',
          color: AppColors.subText,
          badgeBackground: Color(0xFFF3F4F6),
          bannerColor: Color(0xFFF8FAFC),
          badgeIcon: Icons.cancel_outlined,
          bannerIcon: Icons.info_outline_rounded,
        ),
    };
  }
}

class _OrderItem {
  const _OrderItem({
    required this.id,
    required this.dateLabel,
    required this.total,
    required this.status,
    required this.statusMessage,
    required this.actionLabel,
    required this.images,
  });

  final String id;
  final String dateLabel;
  final String total;
  final _OrderStatus status;
  final String statusMessage;
  final String actionLabel;
  final List<String> images;
}

class _StatusStyle {
  const _StatusStyle({
    required this.label,
    required this.color,
    required this.badgeBackground,
    required this.bannerColor,
    required this.badgeIcon,
    required this.bannerIcon,
  });

  final String label;
  final Color color;
  final Color badgeBackground;
  final Color bannerColor;
  final IconData badgeIcon;
  final IconData bannerIcon;
}
