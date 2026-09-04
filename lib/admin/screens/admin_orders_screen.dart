import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/order_no.dart';
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
  String? _deletingId;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

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

  Future<void> _copyText(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _showBirfaturaSetup() async {
    Map<String, dynamic>? config;
    String? error;
    try {
      final result = await _functions.httpsCallable('getBirfaturaConfig').call();
      final data = result.data;
      if (data is Map) {
        config = Map<String, dynamic>.from(data);
      }
    } on FirebaseFunctionsException catch (e) {
      error = e.message?.trim().isNotEmpty == true
          ? e.message
          : 'BirFatura ayarı alınamadı.';
    } catch (_) {
      error = 'BirFatura ayarı alınamadı.';
    }
    if (!mounted) return;
    if (config == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'BirFatura ayarı alınamadı.')),
      );
      return;
    }
    final siteUrl = '${config['siteUrl'] ?? 'https://geliyortrapp.web.app'}';
    final apiBase = '${config['apiBase'] ?? '$siteUrl/api'}';
    final token = '${config['token'] ?? ''}';
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('BirFatura bağlantısı'),
        content: SizedBox(
          width: 460,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'BirFatura paneline kendi şifrenizle girin. '
                'Ayarlar → Mağaza → Özel Entegrasyon → Yeni Mağaza.',
              ),
              const SizedBox(height: 12),
              const Text(
                'Web sitesi adresi',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              SelectableText(siteUrl),
              TextButton(
                onPressed: () => _copyText(siteUrl, 'Site adresi kopyalandı.'),
                child: const Text('Kopyala'),
              ),
              const Text(
                'API şifresi (panel giriş şifresi değil)',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
              ),
              SelectableText(token),
              TextButton(
                onPressed: () => _copyText(token, 'API şifresi kopyalandı.'),
                child: const Text('Kopyala'),
              ),
              const SizedBox(height: 8),
              Text(
                'Altyapı: Kendi Alt Yapımız. BirFatura bu adrese POST /api/orderStatus, '
                '/api/paymentMethods ve /api/orders çağrıları atar.\n'
                'API: $apiBase',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Tamam'),
          ),
        ],
      ),
    );
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
    await _dispatchNotice(order.id);
  }

  Future<void> _dispatchNotice(String orderId, {bool force = false}) async {
    try {
      final result = await _functions
          .httpsCallable('dispatchOrderNotice')
          .call(<String, dynamic>{
            'orderId': orderId,
            if (force) 'force': true,
          });
      final data = result.data;
      if (data is Map && data['smsOk'] == false) {
        debugPrint('dispatchOrderNotice sms failed: ${data['smsError']}');
      }
    } on FirebaseFunctionsException catch (error) {
      debugPrint('dispatchOrderNotice: ${error.code} ${error.message}');
    } catch (error) {
      debugPrint('dispatchOrderNotice: $error');
    }
  }

  Future<void> _confirmStatusChange(AdminOrder order, String status) async {
    if (status == order.status) return;
    if (status == OrderStatuses.delivered) {
      await _confirmDelivered(order);
      return;
    }

    final sendsNotice = status == OrderStatuses.shipping ||
        status == OrderStatuses.cancelled;
    if (sendsNotice) {
      final cancel = status == OrderStatuses.cancelled;
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(cancel ? 'Siparişi iptal et' : 'Siparişi kuryeye ver'),
          content: Text(
            cancel
                ? 'Müşteriye iptal SMS’i ve uygulama bildirimi gidecek.'
                : 'Müşteriye “siparişiniz yola çıktı” SMS’i ve uygulama bildirimi gidecek.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Onayla ve bildir'),
            ),
          ],
        ),
      );
      if (ok != true || !mounted) return;
    }

    await _setStatus(order, status);
    if (!mounted || !sendsNotice) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Durum güncellendi. SMS ve bildirim gönderiliyor.'),
      ),
    );
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

  Future<void> _confirmDelete(AdminOrder order) async {
    if (_deletingId != null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Siparişi sil'),
        content: const Text(
          'Sipariş tamamen silinecek. Stok geri yüklenecek, kullanılan '
          'kupon iade edilecek ve işlem hiç olmamış sayılacak. '
          'Müşteriye SMS gitmez. Bu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil ve stoğu geri yükle'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _deletingId = order.id);
    try {
      await _functions.httpsCallable('deleteOrder').call(<String, dynamic>{
        'orderId': order.id,
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş silindi. Stok geri yüklendi.')),
      );
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.message?.trim().isNotEmpty == true
                ? error.message!
                : 'Sipariş silinemedi.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sipariş silinemedi. Lütfen tekrar deneyin.')),
      );
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
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
          OrderNo.fromId(order.id).toLowerCase().contains(query) ||
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
                  TextButton.icon(
                    onPressed: _showBirfaturaSetup,
                    icon: const Icon(Icons.receipt_long_outlined),
                    label: const Text('BirFatura'),
                  ),
                  const SizedBox(width: 8),
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
        chip('Kuryede', OrderStatuses.shipping),
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
                          ? OrderNo.labeled(order.id)
                          : order.customerName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Siparişi sil — stok geri yüklenir',
                    visualDensity: VisualDensity.compact,
                    onPressed: _deletingId == order.id
                        ? null
                        : () => _confirmDelete(order),
                    icon: Icon(
                      Icons.delete_outline_rounded,
                      color: _deletingId == order.id
                          ? AppColors.subText
                          : AppColors.error,
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
                '${AdminUi.dateTime(order.createdAt)} · ${order.itemCount} ürün'
                '${order.gifts.isEmpty ? '' : ' · ${order.gifts.length} hediye'}',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  AdminStatusChip(
                    label: AdminUi.orderStatusLabel(order.status),
                    color: AdminUi.orderStatusColor(order.status),
                  ),
                  if (order.gifts.isNotEmpty)
                    AdminStatusChip(
                      label: '${order.gifts.length} hediye',
                      color: AppColors.primary,
                    ),
                ],
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
        child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(FirestoreCollections.orders)
              .doc(order.id)
              .snapshots(),
          builder: (context, snap) {
            final doc = snap.data;
            if (doc != null &&
                !doc.exists &&
                snap.connectionState == ConnectionState.active) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (ctx.mounted) Navigator.pop(ctx);
              });
              return const SizedBox.shrink();
            }
            final live = doc != null && doc.exists
                ? AdminOrder.fromDoc(doc)
                : order;
            return _detail(live);
          },
        ),
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
                  if (value != null) _confirmStatusChange(order, value);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            OrderNo.labeled(order.id),
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
              if (order.couponCode.isNotEmpty)
                _info(
                  'Kupon',
                  '${order.couponCode}'
                  '${order.couponDiscount > 0 ? ' (−${AdminUi.money(order.couponDiscount)})' : ''}',
                ),
              _info('Telefon', order.phone.isEmpty ? '—' : order.phone),
              _info(
                'Sipariş SMS',
                order.smsCreatedAt != null
                    ? AdminUi.dateTime(order.smsCreatedAt)
                    : 'Bekleniyor',
              ),
              _info(
                'Kurye SMS',
                order.smsShippingAt != null
                    ? AdminUi.dateTime(order.smsShippingAt)
                    : (order.status == OrderStatuses.shipping
                          ? 'Gönderiliyor'
                          : 'Kuryede olunca'),
              ),
              _info(
                'İptal SMS',
                order.smsCancelledAt != null
                    ? AdminUi.dateTime(order.smsCancelledAt)
                    : (order.status == OrderStatuses.cancelled
                          ? 'Gönderiliyor'
                          : 'İptalde gider'),
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
          if (order.status == OrderStatuses.cancelled ||
              order.status == OrderStatuses.shipping ||
              order.status == OrderStatuses.delivered) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await _dispatchNotice(order.id, force: true);
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('SMS ve bildirim gönderildi.')),
                );
              },
              icon: const Icon(Icons.sms_outlined),
              label: const Text('SMS ve bildirimi gönder'),
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
          if (order.billingAddress.isNotEmpty ||
              order.billingNationalId.isNotEmpty ||
              order.billingTaxId.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'Fatura bilgisi',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                _info(
                  'Hesap',
                  order.billingAccountType == 'corporate'
                      ? 'Kurumsal'
                      : 'Bireysel',
                ),
                if (order.billingName.isNotEmpty)
                  _info('Unvan', order.billingName),
                if (order.billingNationalId.isNotEmpty)
                  _info('T.C.', order.billingNationalId),
                if (order.billingTaxId.isNotEmpty)
                  _info('Vergi no', order.billingTaxId),
                if (order.billingTaxOffice.isNotEmpty)
                  _info('Vergi dairesi', order.billingTaxOffice),
              ],
            ),
            if (order.billingAddress.isNotEmpty &&
                order.billingAddress != order.address) ...[
              const SizedBox(height: 6),
              Text(
                order.billingAddress,
                style: const TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ],
          if (order.invoiceNumber.isNotEmpty ||
              order.invoiceLink.isNotEmpty ||
              order.cargoTrackingCode.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text(
              'BirFatura',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 16,
              runSpacing: 10,
              children: [
                if (order.invoiceNumber.isNotEmpty)
                  _info('Fatura no', order.invoiceNumber),
                if (order.invoiceDate.isNotEmpty)
                  _info('Fatura tarihi', order.invoiceDate),
                if (order.invoiceLink.isNotEmpty)
                  _info('Fatura linki', order.invoiceLink),
                if (order.cargoCompany.isNotEmpty)
                  _info('Kargo', order.cargoCompany),
                if (order.cargoTrackingCode.isNotEmpty)
                  _info('Takip no', order.cargoTrackingCode),
              ],
            ),
          ],
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
          const SizedBox(height: 16),
          const Text(
            'Hediyeler',
            style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
          const SizedBox(height: 8),
          if (order.gifts.isEmpty)
            const Text(
              'Hediye seçilmedi.',
              style: TextStyle(color: AppColors.subText),
            )
          else
            for (final gift in order.gifts)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: buildProductImage(
                          gift.imageUrl,
                          fit: BoxFit.contain,
                          errorWidget: const ColoredBox(
                            color: AppColors.selected,
                            child: Icon(Icons.card_giftcard_rounded, size: 20),
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
                            gift.title.isEmpty ? 'Hediye' : gift.title,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            gift.premium ? 'Premium hediye' : 'Sipariş hediyesi',
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Text(
                      'Ücretsiz',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
          const Divider(height: 28),
          if (order.courierFee > 0 || order.subtotal > 0) ...[
            Row(
              children: [
                const Text(
                  'Ara toplam',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  AdminUi.money(order.subtotal > 0 ? order.subtotal : order.total),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  'Getirme ücreti',
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  order.courierFee > 0
                      ? AdminUi.money(order.courierFee)
                      : 'Ücretsiz',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: order.courierFee > 0
                        ? AppColors.text
                        : AppColors.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
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
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: _deletingId == order.id
                ? null
                : () => _confirmDelete(order),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.error,
              side: const BorderSide(color: AppColors.error),
              minimumSize: const Size.fromHeight(44),
            ),
            icon: const Icon(Icons.delete_outline_rounded),
            label: Text(
              _deletingId == order.id ? 'Siliniyor…' : 'Siparişi sil',
            ),
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
