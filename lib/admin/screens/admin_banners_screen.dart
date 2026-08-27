import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key});

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  bool _seeding = true;
  bool _uploading = false;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  Future<void> _seed() async {
    try {
      await BannerRepository.instance.ensureDefaults();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Bannerlar yüklenemedi: $error')));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _save(AppBanner banner) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.banners)
        .doc(banner.id)
        .set(banner.toMap(), SetOptions(merge: true));
  }

  Future<void> _delete(AppBanner banner) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Bannerı sil'),
        content: Text('“${banner.title}” silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.banners)
        .doc(banner.id)
        .delete();
  }

  Future<String?> _upload() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final reference = FirebaseStorage.instance.ref(
        'banners/${DateTime.now().microsecondsSinceEpoch}_$safeName',
      );
      await reference.putData(bytes);
      return reference.getDownloadURL();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Görsel yüklenemedi: $error')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _edit({
    AppBanner? existing,
    required BannerPlacement placement,
    required int nextOrder,
  }) async {
    final title = TextEditingController(text: existing?.title ?? '');
    var imageUrl = existing?.imageUrl ?? '';
    var active = existing?.active ?? true;
    var selectedPlacement = existing?.placement ?? placement.id;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) {
          final slot = BannerPlacement.byId(selectedPlacement);
          return AlertDialog(
            title: Text(existing == null ? 'Banner ekle' : 'Bannerı düzenle'),
            content: SizedBox(
              width: 460,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.selected,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(
                        'Önerilen ölçü: ${slot.sizeLabel}',
                        style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 110,
                      width: double.infinity,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: buildProductImage(
                          imageUrl.isNotEmpty
                              ? imageUrl
                              : (existing?.assetPath ?? ''),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Başlık'),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<String>(
                      initialValue: selectedPlacement,
                      decoration: const InputDecoration(labelText: 'Bölüm'),
                      items: [
                        for (final item in BannerPlacement.values)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text('${item.title}  ·  ${item.sizeLabel}'),
                          ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setDialog(() => selectedPlacement = value);
                      },
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _uploading
                          ? null
                          : () async {
                              final url = await _upload();
                              if (url != null) setDialog(() => imageUrl = url);
                            },
                      icon: const Icon(Icons.upload_rounded),
                      label: Text(_uploading ? 'Yükleniyor…' : 'Görsel yükle'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Yayında göster'),
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
          );
        },
      ),
    );
    if (saved != true) return;
    await _save(
      AppBanner(
        id:
            existing?.id ??
            FirebaseFirestore.instance.collection('banners').doc().id,
        title: title.text.trim(),
        imageUrl: imageUrl,
        assetPath: existing?.assetPath ?? '',
        placement: selectedPlacement,
        order: existing?.order ?? nextOrder,
        active: active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppBanner>>(
      stream: BannerRepository.instance.watchAll(),
      builder: (context, snapshot) {
        if (_seeding || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final banners = snapshot.data!;
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const AdminPageHeader(
              title: 'Bannerlar',
              subtitle:
                  'Her sayfa ayrı bölüm. Ortak carousel yapısı; ölçü her bölümün kendi yüksekliğidir.',
            ),
            for (final slot in BannerPlacement.values) ...[
              _SectionBlock(
                placement: slot,
                banners: banners
                    .where((item) => item.placement == slot.id)
                    .toList(),
                onAdd: () => _edit(
                  placement: slot,
                  nextOrder: banners.where((b) => b.placement == slot.id).length,
                ),
                onEdit: (banner) => _edit(
                  existing: banner,
                  placement: slot,
                  nextOrder: banners.length,
                ),
                onToggle: (banner, value) =>
                    _save(banner.copyWith(active: value)),
                onDelete: _delete,
              ),
              const SizedBox(height: 18),
            ],
          ],
        );
      },
    );
  }
}

class _SectionBlock extends StatelessWidget {
  const _SectionBlock({
    required this.placement,
    required this.banners,
    required this.onAdd,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  final BannerPlacement placement;
  final List<AppBanner> banners;
  final VoidCallback onAdd;
  final ValueChanged<AppBanner> onEdit;
  final void Function(AppBanner banner, bool value) onToggle;
  final ValueChanged<AppBanner> onDelete;

  @override
  Widget build(BuildContext context) {
    return AdminPanel(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      placement.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.text,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _SizeChip(label: placement.sizeLabel),
                        if (placement.description.isNotEmpty)
                          _SizeChip(label: placement.description),
                        _SizeChip(label: '${banners.length} görsel'),
                      ],
                    ),
                  ],
                ),
              ),
              FilledButton.icon(
                onPressed: onAdd,
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (banners.isEmpty)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                'Bu bölümde henüz banner yok. Önerilen yükleme boyutu: ${placement.sizeLabel}',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                for (final banner in banners)
                  SizedBox(
                    width: 260,
                    child: Material(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => onEdit(banner),
                        child: Ink(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(16),
                                ),
                                child: AspectRatio(
                                  aspectRatio:
                                      BannerPlacement.width / placement.height,
                                  child: buildProductImage(
                                    banner.displayImage,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  10,
                                  8,
                                  4,
                                  8,
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            banner.title,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                            ),
                                          ),
                                          Text(
                                            banner.active ? 'Yayında' : 'Gizli',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: banner.active
                                                  ? AppColors.success
                                                  : AppColors.subText,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Switch(
                                      value: banner.active,
                                      onChanged: (value) =>
                                          onToggle(banner, value),
                                    ),
                                    IconButton(
                                      tooltip: 'Sil',
                                      onPressed: () => onDelete(banner),
                                      icon: const Icon(
                                        Icons.delete_outline_rounded,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
        ],
      ),
    );
  }
}

class _SizeChip extends StatelessWidget {
  const _SizeChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: AppColors.primary,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
