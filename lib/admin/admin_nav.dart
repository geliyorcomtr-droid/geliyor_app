import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_theme.dart';

enum AdminPage {
  dashboard,
  orders,
  products,
  brands,
  categories,
  trustBadges,
  advantages,
  members,
  campaigns,
  coupons,
  broadcasts,
  banners,
  support,
  bankTransfer,
}

class AdminNavChild {
  const AdminNavChild({
    required this.page,
    required this.label,
    this.orderStatus,
    this.newProduct = false,
  });

  final AdminPage page;
  final String label;
  final String? orderStatus;
  final bool newProduct;
}

class AdminNavItem {
  const AdminNavItem({
    required this.page,
    required this.label,
    required this.icon,
    required this.accent,
    this.children = const [],
  });

  final AdminPage page;
  final String label;
  final IconData icon;
  final Color accent;
  final List<AdminNavChild> children;
}

const adminNavItems = <AdminNavItem>[
  AdminNavItem(
    page: AdminPage.dashboard,
    label: 'Panel',
    icon: Icons.dashboard_rounded,
    accent: AdminAccents.dashboard,
  ),
  AdminNavItem(
    page: AdminPage.orders,
    label: 'Siparişler',
    icon: Icons.delivery_dining_rounded,
    accent: AdminAccents.orders,
    children: [
      AdminNavChild(page: AdminPage.orders, label: 'Tümü'),
      AdminNavChild(
        page: AdminPage.orders,
        label: 'Hazırlanıyor',
        orderStatus: 'preparing',
      ),
      AdminNavChild(
        page: AdminPage.orders,
        label: 'Kuryede',
        orderStatus: 'shipping',
      ),
      AdminNavChild(
        page: AdminPage.orders,
        label: 'Teslim',
        orderStatus: 'delivered',
      ),
      AdminNavChild(
        page: AdminPage.orders,
        label: 'İptal',
        orderStatus: 'cancelled',
      ),
    ],
  ),
  AdminNavItem(
    page: AdminPage.products,
    label: 'Ürünler',
    icon: Icons.inventory_2_rounded,
    accent: AdminAccents.products,
    children: [
      AdminNavChild(page: AdminPage.products, label: 'Ürün Listesi'),
      AdminNavChild(
        page: AdminPage.products,
        label: 'Yeni Ürün',
        newProduct: true,
      ),
      AdminNavChild(page: AdminPage.brands, label: 'Markalar'),
      AdminNavChild(page: AdminPage.categories, label: 'Kategoriler'),
      AdminNavChild(page: AdminPage.trustBadges, label: 'Güven Rozetleri'),
      AdminNavChild(page: AdminPage.advantages, label: 'Ürün Özellikleri'),
    ],
  ),
  AdminNavItem(
    page: AdminPage.members,
    label: 'Üyeler',
    icon: Icons.groups_rounded,
    accent: AdminAccents.members,
  ),
  AdminNavItem(
    page: AdminPage.campaigns,
    label: 'Kampanyalar',
    icon: Icons.campaign_rounded,
    accent: AdminAccents.campaigns,
    children: [
      AdminNavChild(page: AdminPage.campaigns, label: 'Kampanya Kartları'),
      AdminNavChild(page: AdminPage.coupons, label: 'Kuponlar'),
    ],
  ),
  AdminNavItem(
    page: AdminPage.broadcasts,
    label: 'Duyurular',
    icon: Icons.notifications_active_rounded,
    accent: AdminAccents.broadcasts,
  ),
  AdminNavItem(
    page: AdminPage.banners,
    label: 'Bannerlar',
    icon: Icons.image_rounded,
    accent: AdminAccents.banners,
  ),
  AdminNavItem(
    page: AdminPage.support,
    label: 'Talepler',
    icon: Icons.support_agent_rounded,
    accent: AdminAccents.support,
  ),
  AdminNavItem(
    page: AdminPage.bankTransfer,
    label: 'Havale / EFT',
    icon: Icons.account_balance_rounded,
    accent: AdminAccents.bankTransfer,
  ),
];

String adminPageTitle(AdminPage page, {String? orderStatus}) {
  return switch (page) {
    AdminPage.dashboard => 'Panel',
    AdminPage.orders => switch (orderStatus) {
      'preparing' => 'Hazırlanan siparişler',
      'shipping' => 'Kuryedeki siparişler',
      'delivered' => 'Teslim edilenler',
      'cancelled' => 'İptal edilenler',
      _ => 'Siparişler',
    },
    AdminPage.products => 'Ürünler',
    AdminPage.brands => 'Markalar',
    AdminPage.categories => 'Kategoriler',
    AdminPage.trustBadges => 'Güven Rozetleri',
    AdminPage.advantages => 'Ürün Özellikleri',
    AdminPage.members => 'Üyeler',
    AdminPage.campaigns => 'Kampanyalar',
    AdminPage.coupons => 'Kuponlar',
    AdminPage.broadcasts => 'Duyurular',
    AdminPage.banners => 'Sayfa bannerları',
    AdminPage.support => 'Müşteri talepleri',
    AdminPage.bankTransfer => 'Havale / EFT',
  };
}
