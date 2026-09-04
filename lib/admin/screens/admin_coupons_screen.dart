import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_member.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/coupon_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminCouponsScreen extends StatefulWidget {
  const AdminCouponsScreen({super.key});

  @override
  State<AdminCouponsScreen> createState() => _AdminCouponsScreenState();
}

class _AdminCouponsScreenState extends State<AdminCouponsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  bool _seeding = true;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _seed();
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  Future<void> _seed() async {
    try {
      await CouponRepository.instance.ensureDefaults();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kuponlar yüklenemedi: $error')));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_seeding) {
      return const Center(child: CircularProgressIndicator());
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminPageHeader(
                title: 'Kuponlar',
                subtitle:
                    'Herkese açık kodlar, müşteriye özel tanımlama ve mama bitiş bildirimi.',
              ),
              TabBar(
                controller: _tabs,
                labelColor: AppColors.primary,
                unselectedLabelColor: AppColors.subText,
                indicatorColor: AppColors.primary,
                tabs: const [
                  Tab(text: 'Kupon tanımları'),
                  Tab(text: 'Müşteriye özel'),
                  Tab(text: 'Mama bildirimi'),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabs,
            children: const [
              _CatalogTab(),
              _AssignTab(),
              _FoodReminderTab(),
            ],
          ),
        ),
      ],
    );
  }
}

class _CatalogTab extends StatelessWidget {
  const _CatalogTab();

  Future<void> _edit(
    BuildContext context,
    AppCoupon? existing,
    int nextOrder,
  ) async {
    final code = TextEditingController(text: existing?.code ?? '');
    final title = TextEditingController(text: existing?.title ?? '');
    final description = TextEditingController(text: existing?.description ?? '');
    final value = TextEditingController(
      text: existing == null ? '' : '${existing.value.round()}',
    );
    final minSubtotal = TextEditingController(
      text: existing == null ? '0' : '${existing.minSubtotal.round()}',
    );
    var type = existing?.type ?? CouponTypes.amount;
    var publicCoupon = existing?.publicCoupon ?? false;
    var singleUse = existing?.singleUse ?? true;
    var active = existing?.active ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Kupon ekle' : 'Kuponu düzenle'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: code,
                    textCapitalization: TextCapitalization.characters,
                    decoration: const InputDecoration(
                      labelText: 'Kupon kodu',
                      hintText: 'MAMA25',
                    ),
                  ),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                  ),
                  TextField(
                    controller: description,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama (isteğe bağlı)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: type,
                    decoration: const InputDecoration(labelText: 'İndirim türü'),
                    items: const [
                      DropdownMenuItem(
                        value: CouponTypes.amount,
                        child: Text('Tutar (TL)'),
                      ),
                      DropdownMenuItem(
                        value: CouponTypes.percent,
                        child: Text('Yüzde (%)'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialog(() => type = value);
                    },
                  ),
                  TextField(
                    controller: value,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: type == CouponTypes.percent
                          ? 'İndirim yüzdesi'
                          : 'İndirim tutarı (TL)',
                    ),
                  ),
                  TextField(
                    controller: minSubtotal,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Minimum sepet (TL)',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Herkese açık'),
                    subtitle: const Text(
                      'Kapalıysa yalnızca tanımlanan müşteriler kullanır.',
                    ),
                    value: publicCoupon,
                    onChanged: (v) => setDialog(() => publicCoupon = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Tek kullanımlık'),
                    value: singleUse,
                    onChanged: (v) => setDialog(() => singleUse = v),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Aktif'),
                    value: active,
                    onChanged: (v) => setDialog(() => active = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (code.text.trim().isEmpty || title.text.trim().isEmpty) {
                  return;
                }
                Navigator.pop(ctx, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final parsedValue =
        double.tryParse(value.text.trim().replaceAll(',', '.')) ?? 0;
    final parsedMin =
        double.tryParse(minSubtotal.text.trim().replaceAll(',', '.')) ?? 0;
    final normalizedCode = code.text.trim().toUpperCase();
    await CouponRepository.instance.save(
      AppCoupon(
        id:
            existing?.id ??
            normalizedCode.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-'),
        code: normalizedCode,
        title: title.text.trim(),
        description: description.text.trim(),
        type: type,
        value: parsedValue,
        minSubtotal: parsedMin < 0 ? 0 : parsedMin,
        publicCoupon: publicCoupon,
        singleUse: singleUse,
        active: active,
        order: existing?.order ?? nextOrder,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCoupon>>(
      stream: CouponRepository.instance.watchAll(),
      builder: (context, snapshot) {
        final coupons = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: () => _edit(context, null, coupons.length),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Yeni kupon'),
              ),
            ),
            const SizedBox(height: 12),
            AdminPanel(
              child: coupons.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Henüz kupon yok.',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < coupons.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          ListTile(
                            onTap: () =>
                                _edit(context, coupons[i], coupons.length),
                            title: Text(
                              coupons[i].title,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                            subtitle: Text(
                              '${coupons[i].code} · ${coupons[i].discountLabel}'
                              '${coupons[i].publicCoupon ? ' · Herkese açık' : ' · Müşteriye özel'}',
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AdminStatusChip(
                                  label: coupons[i].active ? 'Açık' : 'Kapalı',
                                  color: coupons[i].active
                                      ? AppColors.success
                                      : AppColors.subText,
                                ),
                                Switch(
                                  value: coupons[i].active,
                                  onChanged: (value) =>
                                      CouponRepository.instance.save(
                                        coupons[i].copyWith(active: value),
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _AssignTab extends StatefulWidget {
  const _AssignTab();

  @override
  State<_AssignTab> createState() => _AssignTabState();
}

class _AssignTabState extends State<_AssignTab> {
  final _search = TextEditingController();
  AdminMember? _member;
  String? _couponId;
  bool _busy = false;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _assign(List<AppCoupon> coupons) async {
    final member = _member;
    final couponId = _couponId;
    if (member == null || couponId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Müşteri ve kupon seçin.')),
      );
      return;
    }
    AppCoupon? coupon;
    for (final item in coupons) {
      if (item.id == couponId) coupon = item;
    }
    if (coupon == null) return;

    setState(() => _busy = true);
    try {
      try {
        await _functions.httpsCallable('assignUserCoupon').call({
          'userId': member.id,
          'couponId': coupon.id,
          'notify': true,
        });
      } catch (_) {
        await CouponRepository.instance.grantToUser(member.id, coupon.id);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${member.displayName.isEmpty ? 'Müşteriye' : member.displayName} '
            '${coupon.code} kuponu tanımlandı.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tanımlanamadı: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createPersonal(List<AppCoupon> coupons) async {
    final member = _member;
    if (member == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Önce müşteri seçin.')),
      );
      return;
    }
    final title = TextEditingController(
      text: '${member.displayName.isEmpty ? 'Özel' : member.displayName} kuponu',
    );
    final value = TextEditingController(text: '25');
    var type = CouponTypes.amount;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('Müşteriye özel kupon'),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: title,
                  decoration: const InputDecoration(labelText: 'Başlık'),
                ),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tür'),
                  items: const [
                    DropdownMenuItem(
                      value: CouponTypes.amount,
                      child: Text('Tutar (TL)'),
                    ),
                    DropdownMenuItem(
                      value: CouponTypes.percent,
                      child: Text('Yüzde (%)'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) setDialog(() => type = value);
                  },
                ),
                TextField(
                  controller: value,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Değer'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Oluştur ve tanımla'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    final amount = double.tryParse(value.text.trim().replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;
    final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
    final code = 'OZEL$stamp';
    final coupon = AppCoupon(
      id: 'ozel-${member.id}-$stamp',
      code: code,
      title: title.text.trim().isEmpty ? 'Özel kupon' : title.text.trim(),
      description: 'Yalnızca bu müşteri için tanımlandı.',
      type: type,
      value: amount,
      publicCoupon: false,
      singleUse: true,
      order: coupons.length,
    );
    setState(() => _busy = true);
    try {
      await CouponRepository.instance.save(coupon);
      try {
        await _functions.httpsCallable('assignUserCoupon').call({
          'userId': member.id,
          'couponId': coupon.id,
          'notify': true,
        });
      } catch (_) {
        await CouponRepository.instance.grantToUser(member.id, coupon.id);
      }
      if (!mounted) return;
      setState(() => _couponId = coupon.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$code kuponu oluşturuldu ve tanımlandı.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Oluşturulamadı: $error')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCoupon>>(
      stream: CouponRepository.instance.watchActive(),
      builder: (context, couponSnap) {
        final coupons = couponSnap.data ?? [];
        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection(FirestoreCollections.users)
              .snapshots(),
          builder: (context, userSnap) {
            final members = <AdminMember>[];
            for (final doc in userSnap.data?.docs ?? []) {
              try {
                final member = AdminMember.fromDoc(doc);
                if (!member.isAdminRole) members.add(member);
              } catch (_) {}
            }
            final query = _search.text.trim().toLowerCase();
            final visible = members.where((member) {
              if (query.isEmpty) return true;
              return '${member.displayName} ${member.phoneNumber} ${member.email}'
                  .toLowerCase()
                  .contains(query);
            }).toList();

            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Kayıtlı bir kuponu seçili müşteriye tanımlayın. '
                  'Müşteri sipariş onayında bu kuponu görür.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                AdminPanel(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      TextField(
                        controller: _search,
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          labelText: 'Müşteri ara',
                          hintText: 'Ad, telefon veya e-posta',
                          prefixIcon: Icon(Icons.search_rounded),
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxHeight: 220),
                        child: visible.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text(
                                  'Müşteri bulunamadı.',
                                  style: TextStyle(color: AppColors.subText),
                                ),
                              )
                            : ListView.builder(
                                itemCount: visible.length > 40
                                    ? 40
                                    : visible.length,
                                itemBuilder: (context, index) {
                                  final member = visible[index];
                                  final selected = _member?.id == member.id;
                                  return ListTile(
                                    selected: selected,
                                    selectedTileColor: AppColors.selected,
                                    title: Text(
                                      member.displayName.isEmpty
                                          ? 'İsimsiz üye'
                                          : member.displayName,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    subtitle: Text(
                                      [
                                        if (member.phoneNumber.isNotEmpty)
                                          member.phoneNumber,
                                        if (member.email.isNotEmpty)
                                          member.email,
                                      ].join(' · '),
                                    ),
                                    onTap: () =>
                                        setState(() => _member = member),
                                  );
                                },
                              ),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value:
                            coupons.any((c) => c.id == _couponId) ? _couponId : null,
                        decoration: const InputDecoration(
                          labelText: 'Tanımlanacak kupon',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          for (final coupon in coupons)
                            DropdownMenuItem(
                              value: coupon.id,
                              child: Text(
                                '${coupon.code} · ${coupon.title} (${coupon.discountLabel})',
                              ),
                            ),
                        ],
                        onChanged: (value) => setState(() => _couponId = value),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          FilledButton.icon(
                            onPressed: _busy ? null : () => _assign(coupons),
                            icon: const Icon(Icons.card_giftcard_rounded, size: 18),
                            label: Text(
                              _busy ? 'Tanımlanıyor…' : 'Kuponu tanımla',
                            ),
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton.icon(
                            onPressed: _busy
                                ? null
                                : () => _createPersonal(coupons),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Bu müşteriye özel yeni kupon'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _FoodReminderTab extends StatefulWidget {
  const _FoodReminderTab();

  @override
  State<_FoodReminderTab> createState() => _FoodReminderTabState();
}

class _FoodReminderTabState extends State<_FoodReminderTab> {
  bool _saving = false;
  String? _busyJobId;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  Future<void> _save(FoodCouponSettings current, {String? mode, String? couponId}) async {
    setState(() => _saving = true);
    try {
      await CouponRepository.instance.saveSettings(
        FoodCouponSettings(
          mode: mode ?? current.mode,
          couponId: couponId ?? current.couponId,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $error')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _assignJob(FoodCouponJob job, String couponId) async {
    setState(() => _busyJobId = job.id);
    try {
      try {
        await _functions.httpsCallable('assignUserCoupon').call({
          'userId': job.userId,
          'couponId': couponId,
          'queueId': job.id,
          'notify': true,
        });
      } catch (_) {
        await CouponRepository.instance.grantToUser(job.userId, couponId);
        await CouponRepository.instance.updateQueueStatus(
          job.id,
          status: FoodCouponQueueStatuses.assigned,
          couponId: couponId,
        );
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kupon tanımlandı ve bildirim gönderildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Tanımlanamadı: $error')));
    } finally {
      if (mounted) setState(() => _busyJobId = null);
    }
  }

  Future<void> _skipJob(FoodCouponJob job) async {
    await CouponRepository.instance.updateQueueStatus(
      job.id,
      status: FoodCouponQueueStatuses.skipped,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCoupon>>(
      stream: CouponRepository.instance.watchActive(),
      builder: (context, couponSnap) {
        final coupons = couponSnap.data ?? [];
        return StreamBuilder<FoodCouponSettings>(
          stream: CouponRepository.instance.watchSettings(),
          builder: (context, settingsSnap) {
            final settings = settingsSnap.data ?? const FoodCouponSettings();
            return StreamBuilder<List<FoodCouponJob>>(
              stream: CouponRepository.instance.watchQueue(),
              builder: (context, queueSnap) {
                final jobs = queueSnap.data ?? [];
                final pending = jobs.where((job) => job.isPending).toList();
                return ListView(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                  children: [
                    AdminPanel(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Mama bitmek üzere bildirimi',
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Müşterinin maması bitmeye yakınken gönderilen '
                            'hatırlatmaya kupon eklensin mi?',
                            style: TextStyle(
                              color: AppColors.subText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: FoodCouponModes.off,
                            groupValue: settings.mode,
                            title: const Text('Kupon yok'),
                            subtitle: const Text(
                              'Yalnızca mama bitiş hatırlatması gider.',
                            ),
                            onChanged: _saving
                                ? null
                                : (value) => _save(settings, mode: value),
                          ),
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: FoodCouponModes.automatic,
                            groupValue: settings.mode,
                            title: const Text('Otomatik'),
                            subtitle: const Text(
                              'Bildirim giderken seçili kupon müşteriye tanımlanır.',
                            ),
                            onChanged: _saving
                                ? null
                                : (value) => _save(settings, mode: value),
                          ),
                          RadioListTile<String>(
                            contentPadding: EdgeInsets.zero,
                            value: FoodCouponModes.manual,
                            groupValue: settings.mode,
                            title: const Text('Manuel'),
                            subtitle: const Text(
                              'Hatırlatma gider, kuponu bu listedeki müşteriye siz tanımlarsınız.',
                            ),
                            onChanged: _saving
                                ? null
                                : (value) => _save(settings, mode: value),
                          ),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<String>(
                            value: coupons.any((c) => c.id == settings.couponId)
                                ? settings.couponId
                                : (coupons.isEmpty ? null : coupons.first.id),
                            decoration: const InputDecoration(
                              labelText: 'Mama bildiriminde kullanılacak kupon',
                              border: OutlineInputBorder(),
                            ),
                            items: [
                              for (final coupon in coupons)
                                DropdownMenuItem(
                                  value: coupon.id,
                                  child: Text(
                                    '${coupon.code} · ${coupon.discountLabel}',
                                  ),
                                ),
                            ],
                            onChanged: _saving
                                ? null
                                : (value) {
                                    if (value != null) {
                                      _save(settings, couponId: value);
                                    }
                                  },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Manuel kuyruk (${pending.length})',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),
                    AdminPanel(
                      child: pending.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(24),
                              child: Text(
                                'Bekleyen mama kuponu yok.',
                                style: TextStyle(
                                  color: AppColors.subText,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            )
                          : Column(
                              children: [
                                for (int i = 0; i < pending.length; i++) ...[
                                  if (i > 0)
                                    const Divider(
                                      height: 1,
                                      color: AppColors.border,
                                    ),
                                  _queueTile(
                                    pending[i],
                                    coupons,
                                    settings.couponId,
                                  ),
                                ],
                              ],
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _queueTile(
    FoodCouponJob job,
    List<AppCoupon> coupons,
    String defaultCouponId,
  ) {
    final busy = _busyJobId == job.id;
    final couponId = coupons.any((c) => c.id == defaultCouponId)
        ? defaultCouponId
        : (coupons.isEmpty ? '' : coupons.first.id);
    return ListTile(
      title: Text(
        job.customerName.isEmpty ? 'Müşteri' : job.customerName,
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text(
        [
          if (job.phone.isNotEmpty) job.phone,
          if (job.petName.isNotEmpty) job.petName,
          if (job.foodTitle.isNotEmpty) job.foodTitle,
          '${job.remainingDays} gün',
        ].join(' · '),
      ),
      isThreeLine: true,
      trailing: Wrap(
        spacing: 6,
        children: [
          TextButton(
            onPressed: busy ? null : () => _skipJob(job),
            child: const Text('Atla'),
          ),
          FilledButton(
            onPressed: busy || couponId.isEmpty
                ? null
                : () => _assignJob(job, couponId),
            child: Text(busy ? '…' : 'Kupon tanımla'),
          ),
        ],
      ),
    );
  }
}
