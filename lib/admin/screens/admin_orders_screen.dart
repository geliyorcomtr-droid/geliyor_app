import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key, this.statusFilter});

  final String? statusFilter;

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final _search = TextEditingController();
  String? _status;
  String? _selectedId;

  static const _statuses = [
    OrderStatuses.preparing,
    OrderStatuses.shipping,
    OrderStatuses.delivered,
    OrderStatuses.cancelled,
  ];

  @override
  void initState() {
    super.initState();
    _status = widget.statusFilter;
  }

  @override
  void didUpdateWidget(covariant AdminOrdersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.statusFilter != widget.statusFilter) {
      _status = widget.statusFilter;
    }
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setStatus(AdminOrder order, String status) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.orders)
        .doc(order.id)
        .set({
          OrderFields.status: status,
          OrderFields.statusMessage: AdminUi.orderStatusMessage(status),
          OrderFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _confirmDelivered(AdminOrder order) async {
    if (order.status == OrderStatuses.delivered) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Siparişi teslim et'),
        content: const Text(
          'Sipariş teslim edildi olarak işaretlenecek ve müşteriye '
          'NetGSM üzerinden “siparişiniz teslim edilmiştir” SMS’i gidecek.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Teslim et ve SMS gönder'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _setStatus(order, OrderStatuses.delivered);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Teslim kaydedildi. SMS gönderiliyor.')),
    );
  }

  List<AdminOrder> _filter(List<AdminOrder> orders) {
    var list = [...orders]
      ..sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    if (_status != null) {
      list = list.where((o) => o.status == _status).toList();
    }
    final query = _search.text.trim().toLowerCase();
    if (query.isEmpty) return list;
    return list.where((order) {
      return order.id.toLowerCase().contains(query) ||
          order.customerName.toLowerCase().contains(query) ||
          order.phone.toLowerCase().contains(query) ||
          order.address.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection(FirestoreCollections.orders)
        .limit(200);

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Hata: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!.docs.map(AdminOrder.fromDoc).toList();
        final visible = _filter(all);
        AdminOrder? selected;
        for (final order in visible) {
          if (order.id == _selectedId) selected = order;
        }
        selected ??= visible.isEmpty ? null : visible.first;

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AdminPageHeader(
                title: 'Siparişler',
                subtitle:
                    'Durumu güncelleyin, adresi ve ürünleri kontrol edin.',
                actions: [
                  Text(
                    '${visible.length} kayıt',
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              _filters(all),
              const SizedBox(height: 12),
              Expanded(
                child: visible.isEmpty
                    ? const AdminPanel(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Bu filtrede sipariş yok.\nUygulamadan tamamlanan siparişler burada listelenir.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: AppColors.subText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : LayoutBuilder(
                        builder: (context, constraints) {
                          final wide = constraints.maxWidth >= 920;
                          if (!wide) {
                            return ListView.separated(
                              itemCount: visible.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final order = visible[index];
                                return _orderCard(
                                  order,
                                  selected: false,
                                  onTap: () => _showDetailSheet(order),
                                );
                              },
                            );
                          }
                          return Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              SizedBox(
                                width: 360,
                                child: AdminPanel(
                                  child: ListView.separated(
                                    itemCount: visible.length,
                                    separatorBuilder: (_, _) => const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                    itemBuilder: (context, index) {
                                      final order = visible[index];
                                      return _orderCard(
                                        order,
                                        selected: selected?.id == order.id,
                                        onTap: () => setState(
                                          () => _selectedId = order.id,
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: selected == null
                                    ? const SizedBox.shrink()
                                    : _detail(selected),
                              ),
                            ],
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _filters(List<AdminOrder> all) {
    Widget chip(String label, String? value) {
      final selected = _status == value;
      final count = value == null
          ? all.length
          : all.where((o) => o.status == value).length;
      return FilterChip(
        label: Text('$label ($count)'),
        selected: selected,
        showCheckmark: false,
        onSelected: (_) => setState(() => _status = value),
        selectedColor: (value == null
                ? AppColors.primary
                : AdminUi.orderStatusColor(value))
            .withValues(alpha: 0.16),
        labelStyle: TextStyle(
          color: selected
              ? (value == null
                    ? AppColors.primary
                    : AdminUi.orderStatusColor(value))
              : AppColors.text,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
        side: BorderSide(
          color: selected
              ? (value == null
                    ? AppColors.primary
                    : AdminUi.orderStatusColor(value))
              : AppColors.border,
        ),
        backgroundColor: AppColors.surface,
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 260,
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: 'Ad, telefon veya sipariş no',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
        ),
        chip('Tümü', null),
        chip('Hazırlanıyor', OrderStatuses.preparing),
        chip('Kargoda', OrderStatuses.shipping),
        chip('Teslim', OrderStatuses.delivered),
        chip('İptal', OrderStatuses.cancelled),
      ],
    );
  }

  Widget _orderCard(
    AdminOrder order, {
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Material(
      color: selected ? AppColors.selected : AppColors.surface,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      order.customerName.isEmpty
                          ? '#${order.id.length > 8 ? order.id.substring(0, 8) : order.id}'
                          : order.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: order.status == OrderStatuses.delivered
                        ? 'Teslim edildi'
                        : 'Teslim et — müşteriye SMS gider',
                    visualDensity: VisualDensity.compact,
                    onPressed: order.status == OrderStatuses.delivered
                        ? null
                        : () => _confirmDelivered(order),
                    icon: Icon(
                      order.status == OrderStatuses.delivered
                          ? Icons.check_circle_rounded
                          : Icons.check_circle_outline_rounded,
                      color: order.status == OrderStatuses.delivered
                          ? AppColors.success
                          : AppColors.primary,
                    ),
                  ),
                  Text(
                    AdminUi.money(order.total),
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${AdminUi.dateTime(order.createdAt)} · ${order.itemCount} ürün',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              AdminStatusChip(
                label: AdminUi.orderStatusLabel(order.status),
                color: AdminUi.orderStatusColor(order.status),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showDetailSheet(AdminOrder order) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.86,
        child: _detail(order),
      ),
    );
  }

  Widget _detail(AdminOrder order) {
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
      child: ListView(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  order.customerName.isEmpty ? 'Sipariş detayı' : order.customerName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              DropdownButton<String>(
                value: _statuses.contains(order.status)
                    ? order.status
                    : OrderStatuses.preparing,
                underline: const SizedBox.shrink(),
                items: [
                  for (final status in _statuses)
                    DropdownMenuItem(
                      value: status,
                      child: Text(AdminUi.orderStatusLabel(status)),
                    ),
                ],
                onChanged: (value) {
                  if (value != null) _setStatus(order, value);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '#${order.id}',
            style: const TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 14),
          if (order.status != OrderStatuses.delivered)
            Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: FilledButton.icon(
                onPressed: () => _confirmDelivered(order),
                icon: const Icon(Icons.check_circle_rounded),
                label: const Text('Teslim edildi — SMS gönder'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(44),
                ),
              ),
            ),
          Wrap(
            spacing: 16,
            runSpacing: 10,
            children: [
              _info('Tarih', AdminUi.dateTime(order.createdAt)),
              _info('Ödeme', order.paymentMethod.isEmpty ? '—' : order.paymentMethod),
              _info(
                'Teslimat',
                order.deliverySlot.isEmpty ? '—' : order.deliverySlot,
              ),
              _info('Telefon', order.phone.isEmpty ? '—' : order.phone),
              _info(
                'Sipariş SMS',
                order.smsCreatedAt != null
                    ? AdminUi.dateTime(order.smsCreatedAt)
                    : 'Bekleniyor',
              ),
              _info(
                'Teslim SMS',
                order.smsDeliveredAt != null
                    ? AdminUi.dateTime(order.smsDeliveredAt)
                    : (order.status == OrderStatuses.delivered
                          ? 'Gönderiliyor'
                          : 'Teslim ikonuna basınca'),
              ),
            ],
          ),
          if (order.smsLastError.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              'SMS hatası: ${order.smsLastError}',
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w700,
                fontSize: 12,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Adres',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 4),
          Text(
            order.address.isEmpty ? 'Adres girilmemiş' : order.address,
            style: const TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Ürünler',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (order.items.isEmpty)
            const Text(
              'Ürün kalemi yok.',
              style: TextStyle(color: AppColors.subText),
            )
          else
            for (final item in order.items)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: buildProductImage(
                          item.imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: const ColoredBox(
                            color: AppColors.selected,
                            child: Icon(Icons.pets_rounded, size: 20),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '${item.quantity} adet'
                            '${item.weight.isEmpty ? '' : ' · ${item.weight}'}',
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      AdminUi.money(item.lineTotal),
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),
          const Divider(height: 28),
          Row(
            children: [
              const Text(
                'Toplam',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
              ),
              const Spacer(),
              Text(
                AdminUi.money(order.total),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 18,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _info(String label, String value) {
    return SizedBox(
      width: 180,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
