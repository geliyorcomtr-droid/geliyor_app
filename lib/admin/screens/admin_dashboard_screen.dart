import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_member.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/admin/admin_nav.dart';
import 'package:geliyor_app/admin/admin_theme.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key, this.onOpenPage});

  final void Function(
    AdminPage page, {
    String? orderStatus,
    bool newProduct,
  })?
  onOpenPage;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _subs = <StreamSubscription<dynamic>>[];
  List<AdminOrder> _orders = [];
  List<AdminProduct> _products = [];
  List<AdminMember> _members = [];
  int _openTickets = 0;
  bool _ready = false;
  Object? _error;

  @override
  void initState() {
    super.initState();
    final db = FirebaseFirestore.instance;
    _subs.add(
      db.collection(FirestoreCollections.orders).snapshots().listen((snap) {
        if (!mounted) return;
        setState(() {
          _orders = snap.docs.map(AdminOrder.fromDoc).toList()
            ..sort((a, b) {
              final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
              return right.compareTo(left);
            });
          _ready = true;
        });
      }, onError: (e) => setState(() => _error = e)),
    );
    _subs.add(
      db.collection(FirestoreCollections.products).snapshots().listen((snap) {
        if (!mounted) return;
        setState(() {
          _products = snap.docs.map(AdminProduct.fromDoc).toList();
        });
      }),
    );
    _subs.add(
      db.collection(FirestoreCollections.users).snapshots().listen((snap) {
        final members = <AdminMember>[];
        for (final doc in snap.docs) {
          try {
            members.add(AdminMember.fromDoc(doc));
          } catch (_) {}
        }
        if (!mounted) return;
        setState(() => _members = members);
      }),
    );
    _subs.add(
      db.collection(FirestoreCollections.supportTickets).snapshots().listen((
        snap,
      ) {
        if (!mounted) return;
        setState(() {
          _openTickets = snap.docs.where((doc) {
            final status = doc.data()[SupportTicketFields.status] as String?;
            return status != SupportTicketStatuses.closed;
          }).length;
        });
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }

  void _open(AdminPage page, {String? orderStatus, bool newProduct = false}) {
    widget.onOpenPage?.call(
      page,
      orderStatus: orderStatus,
      newProduct: newProduct,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return Center(child: Text('Hata: $_error'));
    }
    if (!_ready) {
      return const Center(child: CircularProgressIndicator());
    }

    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayOrders = _orders
        .where(
          (o) => o.createdAt != null && !o.createdAt!.isBefore(todayStart),
        )
        .length;
    final preparing = _orders
        .where((o) => o.status == OrderStatuses.preparing)
        .length;
    final shipping = _orders
        .where((o) => o.status == OrderStatuses.shipping)
        .length;
    final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
    final weekRevenue = _orders
        .where(
          (o) =>
              o.status != OrderStatuses.cancelled &&
              o.createdAt != null &&
              !o.createdAt!.isBefore(weekStart),
        )
        .fold<double>(0, (sum, o) => sum + o.total);
    final lowStock = _products.where((p) => p.active && p.stock <= 5).toList();
    final recent = _orders.take(6).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const AdminPageHeader(
          title: 'Bugün ne var?',
          subtitle: 'Sipariş, stok, üye ve talepleri tek bakışta yönetin.',
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final width = wide
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: AdminStatCard(
                    value: '$todayOrders',
                    label: 'Bugünkü sipariş',
                    icon: Icons.inbox_rounded,
                    color: AdminAccents.orders,
                    onTap: () => _open(AdminPage.orders),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: AdminStatCard(
                    value: '$preparing',
                    label: 'Hazırlanıyor',
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.warning,
                    onTap: () => _open(
                      AdminPage.orders,
                      orderStatus: OrderStatuses.preparing,
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: AdminStatCard(
                    value: '${_members.length}',
                    label: 'Kayıtlı üye',
                    icon: Icons.groups_rounded,
                    color: AdminAccents.members,
                    onTap: () => _open(AdminPage.members),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: AdminStatCard(
                    value: '$_openTickets',
                    label: 'Açık talep',
                    icon: Icons.support_agent_rounded,
                    color: AdminAccents.support,
                    onTap: () => _open(AdminPage.support),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 900;
            final width = wide
                ? (constraints.maxWidth - 36) / 4
                : (constraints.maxWidth - 12) / 2;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: width,
                  child: AdminStatCard(
                    value: '${_products.where((p) => p.active).length}',
                    label: 'Aktif ürün',
                    icon: Icons.inventory_2_rounded,
                    color: AdminAccents.products,
                    onTap: () => _open(AdminPage.products),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: AdminStatCard(
                    value: '${lowStock.length}',
                    label: 'Düşük stok',
                    icon: Icons.warning_amber_rounded,
                    color: AppColors.error,
                    onTap: () => _open(AdminPage.products),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: AdminStatCard(
                    value: '$shipping',
                    label: 'Kargoda',
                    icon: Icons.local_shipping_rounded,
                    color: AppColors.primary,
                    onTap: () => _open(
                      AdminPage.orders,
                      orderStatus: OrderStatuses.shipping,
                    ),
                  ),
                ),
                SizedBox(
                  width: width,
                  child: AdminStatCard(
                    value: AdminUi.money(weekRevenue),
                    label: 'Bu hafta ciro',
                    icon: Icons.payments_rounded,
                    color: AppColors.success,
                    onTap: () => _open(AdminPage.orders),
                  ),
                ),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            FilledButton.icon(
              onPressed: () => _open(AdminPage.products, newProduct: true),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: const Text('Yeni ürün'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _open(AdminPage.orders),
              icon: const Icon(Icons.local_shipping_outlined, size: 18),
              label: const Text('Siparişler'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _open(AdminPage.members),
              icon: const Icon(Icons.person_search_rounded, size: 18),
              label: const Text('Üyeler'),
            ),
            FilledButton.tonalIcon(
              onPressed: () => _open(AdminPage.support),
              icon: const Icon(Icons.chat_outlined, size: 18),
              label: const Text('Talepler'),
            ),
          ],
        ),
        const SizedBox(height: 18),
        LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 980;
            final recentCard = _recentOrders(recent);
            final stockCard = _lowStock(lowStock);
            if (!wide) {
              return Column(
                children: [
                  recentCard,
                  const SizedBox(height: 12),
                  stockCard,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: recentCard),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: stockCard),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _recentOrders(List<AdminOrder> orders) {
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Son siparişler',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.text,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => _open(AdminPage.orders),
                child: const Text('Tümü'),
              ),
            ],
          ),
          if (orders.isEmpty)
            const Padding(
              padding: EdgeInsets.fromLTRB(0, 8, 0, 16),
              child: Text(
                'Henüz sipariş yok. Uygulamadan verilen siparişler burada görünür.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            for (final order in orders)
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _open(AdminPage.orders),
                title: Text(
                  order.customerName.isEmpty
                      ? 'Sipariş ${order.id.length > 8 ? order.id.substring(0, 8) : order.id}'
                      : order.customerName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  '${AdminUi.dateTime(order.createdAt)} · ${order.itemCount} ürün',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AdminUi.money(order.total),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    AdminStatusChip(
                      label: AdminUi.orderStatusLabel(order.status),
                      color: AdminUi.orderStatusColor(order.status),
                    ),
                  ],
                ),
              ),
        ],
      ),
    );
  }

  Widget _lowStock(List<AdminProduct> products) {
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Düşük stok',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          if (products.isEmpty)
            const Padding(
              padding: EdgeInsets.only(bottom: 12),
              child: Text(
                'Kritik stokta ürün yok.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            for (final product in products.take(6))
              ListTile(
                contentPadding: EdgeInsets.zero,
                onTap: () => _open(AdminPage.products),
                title: Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
                subtitle: Text(
                  product.brand.isEmpty ? 'Stok ${product.stock}' : product.brand,
                ),
                trailing: AdminStatusChip(
                  label: '${product.stock}',
                  color: product.stock <= 0 ? AppColors.error : AppColors.warning,
                ),
              ),
        ],
      ),
    );
  }
}
