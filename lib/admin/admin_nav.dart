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
  knowledge,
  support,
  bankTransfer,
  adoption,
}

class AdminNavChild {
  const AdminNavChild({
    required this.page,
    required this.label,
    this.orderStatus,
    this.newProduct = false,
    this.bannerGroup,
    this.knowledgeGroup,
    this.adoptionStatus,
  });

  final AdminPage page;
  final String label;
  final String? orderStatus;
  final bool newProduct;
  final String? bannerGroup;
  final String? knowledgeGroup;
  final String? adoptionStatus;
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
    children: [
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Tüm sayfalar',
        bannerGroup: 'all',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Ana Sayfa',
        bannerGroup: 'home',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Dost Ekle',
        bannerGroup: 'dost_ekle',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Pet Market',
        bannerGroup: 'pet_market',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Sahiplendirme',
        bannerGroup: 'sahiplendirme',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Pet E-nabız',
        bannerGroup: 'health',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Akıllı Plan',
        bannerGroup: 'smart_plan',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Kolay Sipariş',
        bannerGroup: 'easy_order',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Mama Takibi',
        bannerGroup: 'food_tracking',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Kampanya & Puan',
        bannerGroup: 'campaigns_points',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Asistan',
        bannerGroup: 'assistant',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Bilgi Bankası',
        bannerGroup: 'knowledge',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Makaleler',
        bannerGroup: 'articles',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Dostlarım',
        bannerGroup: 'meet_pet',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Acil Destek',
        bannerGroup: 'emergency',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'İlaç & Tedavi',
        bannerGroup: 'medicine',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Aşı Takvimi',
        bannerGroup: 'vaccine',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Öne Çıkan Sorular',
        bannerGroup: 'featured_questions',
      ),
      AdminNavChild(
        page: AdminPage.banners,
        label: 'Tüm Konular',
        bannerGroup: 'all_topics',
      ),
    ],
  ),
  AdminNavItem(
    page: AdminPage.knowledge,
    label: 'Bilgi Bankası',
    icon: Icons.menu_book_rounded,
    accent: AdminAccents.knowledge,
    children: [
      AdminNavChild(
        page: AdminPage.knowledge,
        label: 'Tüm Konular',
        knowledgeGroup: 'topics',
      ),
      AdminNavChild(
        page: AdminPage.knowledge,
        label: 'Öne Çıkan Sorular',
        knowledgeGroup: 'questions',
      ),
      AdminNavChild(
        page: AdminPage.knowledge,
        label: 'Makaleler',
        knowledgeGroup: 'articles',
      ),
    ],
  ),
  AdminNavItem(
    page: AdminPage.adoption,
    label: 'Sahiplendirme',
    icon: Icons.pets_rounded,
    accent: AdminAccents.adoption,
    children: [
      AdminNavChild(
        page: AdminPage.adoption,
        label: 'Bekleyen',
        adoptionStatus: 'pending',
      ),
      AdminNavChild(
        page: AdminPage.adoption,
        label: 'Yayında',
        adoptionStatus: 'approved',
      ),
      AdminNavChild(
        page: AdminPage.adoption,
        label: 'Reddedilen',
        adoptionStatus: 'rejected',
      ),
    ],
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

String adminPageTitle(
  AdminPage page, {
  String? orderStatus,
  String? knowledgeGroup,
  String? adoptionStatus,
}) {
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
    AdminPage.knowledge => switch (knowledgeGroup) {
      'questions' => 'Öne Çıkan Sorular',
      'articles' => 'Makaleler',
      _ => 'Tüm Konular',
    },
    AdminPage.support => 'Müşteri talepleri',
    AdminPage.adoption => switch (adoptionStatus) {
      'approved' => 'Yayındaki ilanlar',
      'rejected' => 'Reddedilen ilanlar',
      'pending' => 'Onay bekleyen ilanlar',
      _ => 'Sahiplendirme ilanları',
    },
    AdminPage.bankTransfer => 'Havale / EFT',
  };
}
