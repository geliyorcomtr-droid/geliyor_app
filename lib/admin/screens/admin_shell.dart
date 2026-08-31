import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_auth.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/admin/admin_nav.dart';
import 'package:geliyor_app/admin/admin_theme.dart';
import 'package:geliyor_app/admin/screens/admin_banners_screen.dart';
import 'package:geliyor_app/admin/screens/admin_brands_screen.dart';
import 'package:geliyor_app/admin/screens/admin_broadcasts_screen.dart';
import 'package:geliyor_app/admin/screens/admin_campaigns_screen.dart';
import 'package:geliyor_app/admin/screens/admin_categories_screen.dart';
import 'package:geliyor_app/admin/screens/admin_dashboard_screen.dart';
import 'package:geliyor_app/admin/screens/admin_members_screen.dart';
import 'package:geliyor_app/admin/screens/admin_orders_screen.dart';
import 'package:geliyor_app/admin/screens/admin_product_advantages_screen.dart';
import 'package:geliyor_app/admin/screens/admin_product_form_screen.dart';
import 'package:geliyor_app/admin/screens/admin_products_screen.dart';
import 'package:geliyor_app/admin/screens/admin_support_screen.dart';
import 'package:geliyor_app/admin/screens/admin_trust_badges_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  AdminPage _page = AdminPage.dashboard;
  String? _orderStatus;
  bool _productFormOpen = false;
  AdminProduct? _editingProduct;
  final Set<AdminPage> _expanded = {AdminPage.orders, AdminPage.products};

  void _go(
    AdminPage page, {
    String? orderStatus,
    bool newProduct = false,
    AdminProduct? product,
  }) {
    setState(() {
      _page = page;
      _orderStatus = page == AdminPage.orders ? orderStatus : null;
      if (newProduct) {
        _page = AdminPage.products;
        _productFormOpen = true;
        _editingProduct = null;
      } else if (product != null) {
        _page = AdminPage.products;
        _productFormOpen = true;
        _editingProduct = product;
      } else {
        _productFormOpen = false;
        _editingProduct = null;
      }
    });
  }

  void _closeProductForm() {
    setState(() {
      _page = AdminPage.products;
      _productFormOpen = false;
      _editingProduct = null;
    });
  }

  Widget get _body {
    if (_productFormOpen) {
      final editing = _editingProduct;
      return AdminProductFormScreen(
        key: ValueKey(
          editing == null
              ? 'product-new'
              : (editing.id.isEmpty
                    ? 'product-copy-${editing.title}'
                    : 'product-edit-${editing.id}'),
        ),
        product: editing,
        onClose: _closeProductForm,
      );
    }
    return switch (_page) {
      AdminPage.dashboard => AdminDashboardScreen(
        onOpenPage: (page, {orderStatus, newProduct = false}) {
          _go(page, orderStatus: orderStatus, newProduct: newProduct);
        },
      ),
      AdminPage.orders => AdminOrdersScreen(statusFilter: _orderStatus),
      AdminPage.products => AdminProductsScreen(
        onAddProduct: () => _go(AdminPage.products, newProduct: true),
        onEditProduct: (product) => _go(AdminPage.products, product: product),
        onCopyProduct: (product) =>
            _go(AdminPage.products, product: product.asCopy()),
      ),
      AdminPage.brands => const AdminBrandsScreen(),
      AdminPage.categories => const AdminCategoriesScreen(),
      AdminPage.trustBadges => const AdminTrustBadgesScreen(),
      AdminPage.advantages => const AdminProductAdvantagesScreen(),
      AdminPage.members => const AdminMembersScreen(),
      AdminPage.campaigns => const AdminCampaignsScreen(),
      AdminPage.broadcasts => const AdminBroadcastsScreen(),
      AdminPage.banners => const AdminBannersScreen(),
      AdminPage.support => const AdminSupportScreen(),
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AdminAccents.canvas,
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildTopBar(),
                Expanded(child: _body),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      width: 252,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(right: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            margin: const EdgeInsets.all(12),
            padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF6366F1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'geliyor.tr',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  AdminAuth.instance.email ?? 'Yönetim',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.86),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(10, 4, 10, 16),
              children: [for (final item in adminNavItems) _navTile(item)],
            ),
          ),
        ],
      ),
    );
  }

  bool _childSelected(AdminNavChild child) {
    if (child.newProduct) return _productFormOpen;
    if (child.page == AdminPage.products) {
      return _page == AdminPage.products && !_productFormOpen;
    }
    return _page == child.page && _orderStatus == child.orderStatus;
  }

  bool _isSelected(AdminNavItem item) {
    if (_page == item.page) return true;
    return item.children.any((child) => child.page == _page);
  }

  Widget _navTile(AdminNavItem item) {
    final selected = _isSelected(item);
    final expanded = _expanded.contains(item.page);
    final hasChildren = item.children.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Column(
        children: [
          Material(
            color: selected ? item.accent.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              onTap: () {
                setState(() {
                  if (hasChildren) {
                    if (expanded) {
                      _expanded.remove(item.page);
                    } else {
                      _expanded.add(item.page);
                    }
                  }
                });
                _go(item.page);
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: item.accent.withValues(alpha: selected ? 1 : 0.16),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        item.icon,
                        size: 18,
                        color: selected ? Colors.white : item.accent,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: selected ? item.accent : AppColors.text,
                        ),
                      ),
                    ),
                    if (hasChildren)
                      Icon(
                        expanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.subText,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (hasChildren && expanded)
            Padding(
              padding: const EdgeInsets.only(left: 42, top: 2, bottom: 4),
              child: Column(
                children: [
                  for (final child in item.children)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(999),
                        onTap: () => _go(
                          child.page,
                          orderStatus: child.orderStatus,
                          newProduct: child.newProduct,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          child: Text(
                            child.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: _childSelected(child)
                                  ? item.accent
                                  : AppColors.subText,
                            ),
                          ),
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

  Widget _buildTopBar() {
    return Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          Text(
            _productFormOpen
                ? (_editingProduct == null ? 'Yeni ürün' : 'Ürünü düzenle')
                : adminPageTitle(_page, orderStatus: _orderStatus),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const Spacer(),
          Text(
            'geliyor.tr yönetim',
            style: TextStyle(
              color: AppColors.subText.withValues(alpha: 0.9),
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            tooltip: 'Çıkış',
            onPressed: () => AdminAuth.instance.signOut(),
            icon: const Icon(Icons.logout_rounded, color: AppColors.subText),
          ),
        ],
      ),
    );
  }
}
