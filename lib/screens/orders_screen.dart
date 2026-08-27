import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/cart_screen.dart';
import 'package:geliyor_app/state/cart_store.dart';
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
  String? _expandedOrderId;
  int _currentPage = 1;
  static const int _pageSize = 4;

  static const List<_OrderItem> _allOrders = [];

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
      final matchesSearch =
          query.isEmpty ||
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

  void _toggleOrderDetails(_OrderItem order) {
    setState(() {
      _expandedOrderId = _expandedOrderId == order.id ? null : order.id;
    });
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
              padding: const EdgeInsets.fromLTRB(
                AppPageFrame.contentHorizontalPadding,
                0,
                AppPageFrame.contentHorizontalPadding,
                8,
              ),
              child: _buildSearchBar(),
            ),
            _buildTabs(),
            const SizedBox(height: 8),
            Expanded(
              child: pageOrders.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(
                        AppPageFrame.contentHorizontalPadding,
                        0,
                        AppPageFrame.contentHorizontalPadding,
                        8,
                      ),
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
                'SipariÅŸlerim',
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
                hintText: 'SipariÅŸ, Ã¼rÃ¼n veya teslimat numarasÄ± ile ara',
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
      ('TÃ¼mÃ¼', null),
      ('HazÄ±rlanÄ±yor', _OrderStatus.preparing),
      ('Kargoda', _OrderStatus.shipping),
      ('Teslim Edildi', _OrderStatus.delivered),
      ('Ä°ptal Edildi', _OrderStatus.cancelled),
    ];

    return SizedBox(
      height: 34,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppPageFrame.contentHorizontalPadding,
        ),
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
              'Bu filtrede sipariÅŸ bulunamadÄ±',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.text,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'FarklÄ± bir durum seÃ§ebilir veya aramayÄ± temizleyebilirsin.',
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
    final images = order.images;
    final visibleImages = images.take(3).toList();
    final extraCount = images.length - visibleImages.length;
    final isExpanded = _expandedOrderId == order.id;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _toggleOrderDetails(order),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isExpanded ? AppColors.primary : AppColors.border,
            width: isExpanded ? 1.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withValues(alpha: 0.03),
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
                              'SipariÅŸ No #${order.id}',
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
                      AnimatedRotation(
                        turns: isExpanded ? 0.25 : 0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.chevron_right_rounded,
                          color: AppColors.subText,
                          size: 18,
                        ),
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
                              onTap: () => _onOrderAction(order),
                              height: 24,
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                              ),
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
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 220),
              sizeCurve: Curves.easeOut,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _buildOrderDetails(order, style),
              crossFadeState: isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(_OrderItem order, _StatusStyle style) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 14),
      decoration: const BoxDecoration(
        color: AppColors.background,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('SipariÅŸ DetayÄ±', style: AppTextStyles.sectionHeader),
              const Spacer(),
              Text(
                '${order.lines.length} Ã¼rÃ¼n',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...order.lines.map(_buildOrderLineDetail),
          const SizedBox(height: 10),
          _buildDetailInfoTile(
            icon: Icons.location_on_outlined,
            title: 'Teslimat Adresi',
            value: 'Ev Adresim â€¢ Ä°stanbul',
          ),
          const SizedBox(height: 8),
          _buildDetailInfoTile(
            icon: Icons.credit_card_rounded,
            title: 'Ã–deme',
            value: 'Banka / Kredi KartÄ± â€¢â€¢â€¢â€¢ 4242',
          ),
          const SizedBox(height: 8),
          _buildDetailInfoTile(
            icon: style.badgeIcon,
            iconColor: style.color,
            title: 'SipariÅŸ Durumu',
            value: order.statusMessage,
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                const Text(
                  'Ã–denen Toplam',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  order.total,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderLineDetail(_OrderLine line) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Image.asset(
                line.imagePath,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) =>
                    const Icon(Icons.pets_rounded, color: AppColors.primary),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${line.weight} â€¢ ${line.quantity} adet',
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfoTile({
    required IconData icon,
    required String title,
    required String value,
    Color iconColor = AppColors.primary,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: const BoxDecoration(
              color: AppColors.selected,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 17),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: AppColors.text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
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
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.pets_rounded, color: AppColors.primary, size: 20),
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
      padding: const EdgeInsets.fromLTRB(
        AppPageFrame.contentHorizontalPadding,
        0,
        AppPageFrame.contentHorizontalPadding,
        4,
      ),
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

  void _onOrderAction(_OrderItem order) {
    if (order.actionLabel == 'Tekrarla') {
      _repeatOrder(order);
      return;
    }
    _toggleOrderDetails(order);
  }

  void _repeatOrder(_OrderItem order) {
    if (order.lines.isEmpty) return;

    for (final line in order.lines) {
      for (var i = 0; i < line.quantity; i++) {
        CartStore.instance.addItem(
          id: line.id,
          imagePath: line.imagePath,
          title: line.title,
          unitPrice: line.unitPrice,
          oldPrice: line.oldPrice,
          weight: line.weight,
        );
      }
    }

    final subtitle = order.lines.length == 1
        ? order.lines.first.title
        : 'SipariÅŸ #${order.id} â€¢ ${order.lines.length} Ã¼rÃ¼n';
    _showAddedToCartDialog(subtitle);
  }

  void _showAddedToCartDialog(String productTitle) {
    showDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withValues(alpha: 0.35),
      builder: (dialogContext) {
        return Center(
          child: Material(
            color: Colors.transparent,
            child: Container(
              width: AppPageFrame.width - 48,
              constraints: const BoxConstraints(maxHeight: 280),
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 14),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: AppColors.success,
                      size: 26,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'ÃœrÃ¼n sepete eklenmiÅŸtir',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    productTitle,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),
                  AppPressableButton.primary(
                    onTap: () {
                      Navigator.of(dialogContext).pop();
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => const CartScreen()),
                      );
                    },
                    width: double.infinity,
                    height: 40,
                    child: const Text(
                      'Sepete Git',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AppPressableButton.outline(
                    onTap: () => Navigator.of(dialogContext).pop(),
                    width: double.infinity,
                    height: 40,
                    child: const Text(
                      'AlÄ±ÅŸveriÅŸe Devam Et',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
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
        label: 'HazÄ±rlanÄ±yor',
        color: AppColors.warning,
        badgeBackground: Color(0xFFFFF7E8),
        bannerColor: Color(0xFFFFFAF0),
        badgeIcon: Icons.schedule_rounded,
        bannerIcon: Icons.schedule_rounded,
      ),
      _OrderStatus.cancelled => const _StatusStyle(
        label: 'Ä°ptal Edildi',
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
    required this.lines,
  });

  final String id;
  final String dateLabel;
  final String total;
  final _OrderStatus status;
  final String statusMessage;
  final String actionLabel;
  final List<_OrderLine> lines;

  List<String> get images => lines.map((line) => line.imagePath).toList();
}

class _OrderLine {
  const _OrderLine({
    required this.id,
    required this.title,
    required this.weight,
    required this.unitPrice,
    required this.oldPrice,
    required this.imagePath,
    this.quantity = 1,
  });

  final String id;
  final String title;
  final String weight;
  final double unitPrice;
  final double oldPrice;
  final String imagePath;
  final int quantity;
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
