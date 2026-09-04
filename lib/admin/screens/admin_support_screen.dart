import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_theme.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminSupportTicket {
  const AdminSupportTicket({
    required this.id,
    required this.name,
    required this.email,
    required this.subject,
    required this.message,
    required this.status,
    this.reply = '',
    this.userId = '',
    this.kind = SupportTicketKinds.support,
    this.imageUrl = '',
    this.phone = '',
    this.productName = '',
    this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String subject;
  final String message;
  final String status;
  final String reply;
  final String userId;
  final String kind;
  final String imageUrl;
  final String phone;
  final String productName;
  final DateTime? createdAt;

  bool get isSupply => kind == SupportTicketKinds.supply;

  factory AdminSupportTicket.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final created = data[SupportTicketFields.createdAt];
    return AdminSupportTicket(
      id: doc.id,
      name: (data[SupportTicketFields.name] as String?) ?? '',
      email: (data[SupportTicketFields.email] as String?) ?? '',
      subject: (data[SupportTicketFields.subject] as String?) ?? '',
      message: (data[SupportTicketFields.message] as String?) ?? '',
      status: (data[SupportTicketFields.status] as String?) ??
          SupportTicketStatuses.open,
      reply: (data[SupportTicketFields.reply] as String?) ?? '',
      userId: (data[SupportTicketFields.userId] as String?) ?? '',
      kind: (data[SupportTicketFields.kind] as String?) ??
          SupportTicketKinds.support,
      imageUrl: ((data[SupportTicketFields.imageUrl] as String?) ?? '').trim(),
      phone: (data[SupportTicketFields.phone] as String?) ?? '',
      productName: (data[SupportTicketFields.productName] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}

class AdminSupportScreen extends StatefulWidget {
  const AdminSupportScreen({super.key});

  @override
  State<AdminSupportScreen> createState() => _AdminSupportScreenState();
}

class _AdminSupportScreenState extends State<AdminSupportScreen> {
  String _filter = SupportTicketStatuses.open;
  String? _selectedId;

  Color _color(String status) => switch (status) {
    SupportTicketStatuses.open => AdminAccents.support,
    SupportTicketStatuses.replied => AppColors.primary,
    _ => AppColors.subText,
  };

  String _label(AdminSupportTicket ticket) {
    if (ticket.isSupply) {
      return switch (ticket.status) {
        SupportTicketStatuses.replied => 'Tedarik',
        SupportTicketStatuses.closed => 'Tamamlandı',
        _ => 'Yeni',
      };
    }
    return switch (ticket.status) {
      SupportTicketStatuses.open => 'Açık',
      SupportTicketStatuses.replied => 'Yanıtlandı',
      _ => 'Kapalı',
    };
  }

  Future<void> _update(
    AdminSupportTicket ticket, {
    String? status,
    String? reply,
  }) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.supportTickets)
        .doc(ticket.id)
        .set({
          if (status != null) SupportTicketFields.status: status,
          if (reply != null) SupportTicketFields.reply: reply,
          SupportTicketFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Future<void> _reply(AdminSupportTicket ticket) async {
    final controller = TextEditingController(text: ticket.reply);
    final saved = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Yanıt yaz'),
        content: SizedBox(
          width: 420,
          child: TextField(
            controller: controller,
            maxLines: 6,
            decoration: const InputDecoration(
              hintText: 'Müşteriye iletilecek not',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (saved == null || saved.isEmpty) return;
    await _update(
      ticket,
      status: SupportTicketStatuses.replied,
      reply: saved,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.supportTickets)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snapshot.data!.docs.map(AdminSupportTicket.fromDoc).toList()
          ..sort((a, b) {
            final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return right.compareTo(left);
          });
        final visible = switch (_filter) {
          'all' => all,
          SupportTicketKinds.supply =>
            all.where((t) => t.isSupply).toList(),
          _ => all.where((t) => t.status == _filter).toList(),
        };

        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const AdminPageHeader(
                title: 'Talepler',
                subtitle:
                    'Yardım formu ve hangi mama tedarik talepleri.',
              ),
              Wrap(
                spacing: 8,
                children: [
                  _chip('Açık', SupportTicketStatuses.open, all),
                  _chip('Yanıtlandı', SupportTicketStatuses.replied, all),
                  _chip('Kapalı', SupportTicketStatuses.closed, all),
                  _chip('Mama tedarik', SupportTicketKinds.supply, all),
                  _chip('Tümü', 'all', all),
                ],
              ),
              const SizedBox(height: 12),
              Expanded(
                child: visible.isEmpty
                    ? const AdminPanel(
                        padding: EdgeInsets.all(32),
                        child: Center(
                          child: Text(
                            'Bu durumda talep yok.',
                            style: TextStyle(
                              color: AppColors.subText,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      )
                    : AdminPanel(
                        child: ListView.separated(
                          itemCount: visible.length,
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: AppColors.border,
                          ),
                          itemBuilder: (context, index) {
                            final ticket = visible[index];
                            return ListTile(
                              selected: _selectedId == ticket.id,
                              selectedTileColor: AppColors.selected,
                              onTap: () => _openTicket(ticket),
                              leading: _ticketImage(ticket),
                              title: Text(
                                ticket.isSupply
                                    ? (ticket.productName.isEmpty
                                        ? 'Mama tedarik talebi'
                                        : ticket.productName)
                                    : (ticket.subject.isEmpty
                                        ? 'Talep'
                                        : ticket.subject),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              subtitle: Text(
                                [
                                  if (ticket.isSupply) 'Mama tedarik',
                                  if (ticket.name.isNotEmpty) ticket.name,
                                  if (ticket.phone.isNotEmpty) ticket.phone,
                                  AdminUi.dateTime(ticket.createdAt),
                                  ticket.message,
                                ].join(' · '),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              ),
                              isThreeLine: true,
                              trailing: Wrap(
                                spacing: 6,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  AdminStatusChip(
                                    label: _label(ticket),
                                    color: _color(ticket.status),
                                  ),
                                  TextButton(
                                    onPressed: () => _reply(ticket),
                                    child: const Text('Yanıtla'),
                                  ),
                                  if (ticket.isSupply &&
                                      ticket.status ==
                                          SupportTicketStatuses.open)
                                    TextButton(
                                      onPressed: () => _update(
                                        ticket,
                                        status: SupportTicketStatuses.replied,
                                      ),
                                      child: const Text('Tedarik ediliyor'),
                                    ),
                                  if (ticket.status !=
                                      SupportTicketStatuses.closed)
                                    TextButton(
                                      onPressed: () => _update(
                                        ticket,
                                        status: SupportTicketStatuses.closed,
                                      ),
                                      child: Text(
                                        ticket.isSupply ? 'Tamamla' : 'Kapat',
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _ticketImage(AdminSupportTicket ticket) {
    if (ticket.imageUrl.isEmpty) {
      return CircleAvatar(
        backgroundColor: AppColors.selected,
        child: Icon(
          ticket.isSupply
              ? Icons.pets_rounded
              : Icons.support_agent_rounded,
          color: AppColors.primary,
          size: 20,
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: 56,
        height: 56,
        child: buildProductImage(
          ticket.imageUrl,
          width: 56,
          height: 56,
          fit: BoxFit.cover,
          errorWidget: CircleAvatar(
            backgroundColor: AppColors.selected,
            child: Icon(
              Icons.broken_image_outlined,
              color: AppColors.primary,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  void _openTicket(AdminSupportTicket ticket) {
    setState(() => _selectedId = ticket.id);
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text(
            ticket.isSupply
                ? (ticket.productName.isEmpty
                    ? 'Mama tedarik talebi'
                    : ticket.productName)
                : (ticket.subject.isEmpty ? 'Talep' : ticket.subject),
          ),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (ticket.imageUrl.isNotEmpty) ...[
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          maxHeight: 360,
                          minWidth: 280,
                        ),
                        child: buildProductImage(
                          ticket.imageUrl,
                          width: double.infinity,
                          fit: BoxFit.contain,
                          errorWidget: const Padding(
                            padding: EdgeInsets.all(24),
                            child: Center(
                              child: Text('Görsel yüklenemedi.'),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  Text(
                    [
                      if (ticket.isSupply) 'Mama tedarik',
                      if (ticket.name.isNotEmpty) ticket.name,
                      if (ticket.phone.isNotEmpty) ticket.phone,
                      if (ticket.email.isNotEmpty) ticket.email,
                      AdminUi.dateTime(ticket.createdAt),
                    ].join('\n'),
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (ticket.message.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(ticket.message),
                  ],
                  if (ticket.reply.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      'Yanıt: ${ticket.reply}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Kapat'),
            ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, String value, List<AdminSupportTicket> all) {
    final selected = _filter == value;
    final count = switch (value) {
      'all' => all.length,
      SupportTicketKinds.supply => all.where((t) => t.isSupply).length,
      _ => all.where((t) => t.status == value).length,
    };
    return FilterChip(
      label: Text('$label ($count)'),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => setState(() => _filter = value),
      selectedColor: AdminAccents.support.withValues(alpha: 0.16),
      labelStyle: TextStyle(
        color: selected ? AdminAccents.support : AppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      side: BorderSide(
        color: selected ? AdminAccents.support : AppColors.border,
      ),
    );
  }
}
