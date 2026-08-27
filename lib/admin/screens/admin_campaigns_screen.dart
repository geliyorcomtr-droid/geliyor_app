import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/campaign_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminCampaignsScreen extends StatefulWidget {
  const AdminCampaignsScreen({super.key});

  @override
  State<AdminCampaignsScreen> createState() => _AdminCampaignsScreenState();
}

class _AdminCampaignsScreenState extends State<AdminCampaignsScreen> {
  bool _seeding = true;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  Future<void> _seed() async {
    try {
      await CampaignRepository.instance.ensureDefaults();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kampanyalar yüklenemedi: $error')));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _save(AppCampaign campaign) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.campaigns)
        .doc(campaign.id)
        .set(campaign.toMap(), SetOptions(merge: true));
  }

  Future<void> _edit(AppCampaign? existing, int nextOrder) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final subtitle = TextEditingController(text: existing?.subtitle ?? '');
    final image = TextEditingController(text: existing?.imageUrl ?? '');
    var mainCategory = existing?.mainCategory ?? 'cat';
    final subCategory = TextEditingController(text: existing?.subCategory ?? '');
    var active = existing?.active ?? true;
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Kampanya ekle' : 'Kampanyayı düzenle'),
          content: SizedBox(
            width: 420,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                  ),
                  TextField(
                    controller: subtitle,
                    decoration: const InputDecoration(labelText: 'Açıklama'),
                  ),
                  TextField(
                    controller: image,
                    decoration: const InputDecoration(
                      labelText: 'Görsel URL (isteğe bağlı)',
                    ),
                  ),
                  TextField(
                    controller: subCategory,
                    decoration: const InputDecoration(
                      labelText: 'Alt kategori (ör. Mama)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: mainCategory,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Ana kategori'),
                    items: const [
                      DropdownMenuItem(value: 'cat', child: Text('Kedi')),
                      DropdownMenuItem(value: 'dog', child: Text('Köpek')),
                      DropdownMenuItem(value: 'smart', child: Text('Akıllı')),
                    ],
                    onChanged: (value) {
                      if (value != null) setDialog(() => mainCategory = value);
                    },
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Uygulamada göster'),
                    value: active,
                    onChanged: (value) => setDialog(() => active = value),
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
                if (title.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    await _save(
      AppCampaign(
        id:
            existing?.id ??
            FirebaseFirestore.instance.collection('campaigns').doc().id,
        title: title.text.trim(),
        subtitle: subtitle.text.trim(),
        imageUrl: image.text.trim(),
        assetPath: existing?.assetPath ?? '',
        mainCategory: mainCategory,
        subCategory: subCategory.text.trim(),
        order: existing?.order ?? nextOrder,
        active: active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppCampaign>>(
      stream: CampaignRepository.instance.watchAll(),
      builder: (context, snapshot) {
        if (_seeding || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final campaigns = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            AdminPageHeader(
              title: 'Kampanyalar',
              subtitle: 'Uygulamadaki Kampanyalar sekmesinde görünen kartlar.',
              actions: [
                FilledButton.icon(
                  onPressed: () => _edit(null, campaigns.length),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Yeni'),
                ),
              ],
            ),
            AdminPanel(
              child: Column(
                children: [
                  for (int i = 0; i < campaigns.length; i++) ...[
                    if (i > 0) const Divider(height: 1, color: AppColors.border),
                    ListTile(
                      onTap: () => _edit(campaigns[i], campaigns.length),
                      title: Text(
                        campaigns[i].title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      subtitle: Text(campaigns[i].subtitle),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AdminStatusChip(
                            label: campaigns[i].active ? 'Açık' : 'Kapalı',
                            color: campaigns[i].active
                                ? AppColors.success
                                : AppColors.subText,
                          ),
                          Switch(
                            value: campaigns[i].active,
                            onChanged: (value) =>
                                _save(campaigns[i].copyWith(active: value)),
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
