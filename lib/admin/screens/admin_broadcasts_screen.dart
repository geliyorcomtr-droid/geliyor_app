import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminBroadcastsScreen extends StatefulWidget {
  const AdminBroadcastsScreen({super.key});

  @override
  State<AdminBroadcastsScreen> createState() => _AdminBroadcastsScreenState();
}

class _AdminBroadcastsScreenState extends State<AdminBroadcastsScreen> {
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _sending = false;
  bool _testOnly = true;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: 'europe-west1');

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final title = _title.text.trim();
    final body = _body.text.trim();
    if (title.isEmpty || body.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Başlık ve metin gerekli.')),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_testOnly ? 'Kendinize test edin' : 'Tüm üyelere gönder'),
        content: Text(
          _testOnly
              ? 'Bu duyuru yalnızca sizin hesabınıza düşecek. Üyelere gitmez.'
              : 'Bu duyuru tüm aktif üyelere uygulama içi bildirim ve '
                    'push olarak gidecek. Devam edilsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(_testOnly ? 'Test gönder' : 'Gönder'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sending = true);
    try {
      final result = await _functions.httpsCallable('sendBroadcast').call({
        'title': title,
        'body': body,
        'target': _testOnly ? 'self' : 'all',
      });
      final data = result.data;
      final count = data is Map ? data['sentCount'] : null;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _testOnly
                ? 'Test duyurusu gönderildi.'
                : 'Duyuru $count üyeye gönderildi.',
          ),
        ),
      );
      if (!_testOnly) {
        _title.clear();
        _body.clear();
      }
    } on FirebaseFunctionsException catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.message ?? 'Gönderilemedi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gönderilemedi: $error')));
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const AdminPageHeader(
            title: 'Duyurular',
            subtitle:
                'Kampanya ve genel duyuruları uygulamaya push olarak gönderin.',
          ),
          AdminPanel(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _title,
                  maxLength: 80,
                  enabled: !_sending,
                  decoration: const InputDecoration(
                    labelText: 'Başlık',
                    hintText: 'Örn. Hafta sonu indirimi',
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _body,
                  maxLength: 500,
                  maxLines: 4,
                  enabled: !_sending,
                  decoration: const InputDecoration(
                    labelText: 'Metin',
                    hintText: 'Kısa, net bir duyuru yazın.',
                    alignLabelWithHint: true,
                  ),
                ),
                const SizedBox(height: 8),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _testOnly,
                  onChanged: _sending
                      ? null
                      : (value) => setState(() => _testOnly = value),
                  title: const Text(
                    'Önce kendime test et',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text(
                    'Kapalıysa tüm aktif üyelere gider.',
                    style: TextStyle(fontSize: 12),
                  ),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: FilledButton.icon(
                    onPressed: _sending ? null : _send,
                    icon: _sending
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send_rounded, size: 18),
                    label: Text(
                      _sending
                          ? 'Gönderiliyor…'
                          : (_testOnly ? 'Test gönder' : 'Herkese gönder'),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Gönderilen duyurular',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.text,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: FirebaseFirestore.instance
                  .collection(FirestoreCollections.broadcasts)
                  .orderBy('createdAt', descending: true)
                  .limit(40)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AdminPanel(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'Kayıtlar yüklenemedi: ${snapshot.error}',
                      style: const TextStyle(color: AppColors.error),
                    ),
                  );
                }
                final docs = snapshot.data?.docs ?? [];
                if (snapshot.connectionState == ConnectionState.waiting &&
                    docs.isEmpty) {
                  return const AdminPanel(
                    padding: EdgeInsets.all(32),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (docs.isEmpty) {
                  return const AdminPanel(
                    padding: EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        'Henüz duyuru gönderilmedi.',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  );
                }
                return AdminPanel(
                  child: ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, _) =>
                        const Divider(height: 1, color: AppColors.border),
                    itemBuilder: (context, index) {
                      final data = docs[index].data();
                      final created = data['createdAt'];
                      final createdAt = created is Timestamp
                          ? created.toDate()
                          : null;
                      final target = data['target'] == 'self'
                          ? 'Test'
                          : 'Tüm üyeler';
                      final count = data['sentCount'] ?? data['recipientCount'];
                      return ListTile(
                        title: Text(
                          (data['title'] as String?)?.trim().isNotEmpty == true
                              ? data['title'] as String
                              : 'Duyuru',
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${AdminUi.dateTime(createdAt)} · ${data['body'] ?? ''}',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: AdminStatusChip(
                          label: '$target · $count',
                          color: data['target'] == 'self'
                              ? AppColors.subText
                              : AppColors.success,
                        ),
                        isThreeLine: true,
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
