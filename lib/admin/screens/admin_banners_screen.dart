import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/knowledge_article_repository.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminBannersScreen extends StatefulWidget {
  const AdminBannersScreen({super.key, this.initialGroup = 'all'});

  final String initialGroup;

  @override
  State<AdminBannersScreen> createState() => _AdminBannersScreenState();
}

class _AdminBannersScreenState extends State<AdminBannersScreen> {
  bool _seeding = true;
  bool _uploading = false;
  late String _group = widget.initialGroup;

  bool _matches(BannerPlacement slot) {
    if (_group == 'all') return true;
    if (_group == 'ads') return slot.pageId == 'home';
    return slot.pageId == _group;
  }

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
      if (bytes.isEmpty) {
        throw Exception('Dosya okunamadı, başka bir görsel dene.');
      }
      final prepared = prepareUploadImage(bytes, file.name);
      final reference = FirebaseStorage.instance.ref(
        'banners/${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await reference.putData(
        prepared.bytes,
        SettableMetadata(contentType: prepared.contentType),
      );
      return reference.getDownloadURL();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel yüklenemedi: $error')),
        );
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
    final title = TextEditingController(
      text: existing?.title.isNotEmpty == true
          ? existing!.title
          : placement.title,
    );
    var imageUrl = existing?.imageUrl ?? '';
    var active = existing?.active ?? true;
    var selectedPlacement = existing?.placement ?? placement.id;
    var linkType = existing?.linkType ?? BannerLinkType.none;
    if (linkType != BannerLinkType.product &&
        linkType != BannerLinkType.article) {
      linkType = BannerLinkType.none;
    }
    var linkId = existing?.linkId ?? '';

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
                        'Nereye ait: ${slot.belongsLabel}\nÖlçü: ${slot.pxLabel}\nGörsel otomatik küçültülür (en fazla ~250 KB).',
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
                          width: double.infinity,
                          height: double.infinity,
                          filterQuality: FilterQuality.medium,
                          cacheWidth: 1080,
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
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Bölüm'),
                      items: [
                        for (final item in BannerPlacement.values)
                          DropdownMenuItem(
                            value: item.id,
                            child: Text(
                              '${item.belongsLabel}  ·  ${item.pxLabel}',
                            ),
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
                    const SizedBox(height: 12),
                    const Text(
                      'Tıklanınca',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        for (final option in const [
                          (BannerLinkType.none, 'Yok'),
                          (BannerLinkType.product, 'Ürün'),
                          (BannerLinkType.article, 'Makale'),
                        ])
                          ChoiceChip(
                            label: Text(option.$2),
                            selected: linkType == option.$1,
                            onSelected: (_) {
                              setDialog(() {
                                linkType = option.$1;
                                linkId = '';
                              });
                            },
                          ),
                      ],
                    ),
                    if (linkType == BannerLinkType.product) ...[
                      const SizedBox(height: 10),
                      StreamBuilder<List<AdminProduct>>(
                        stream: ProductRepository.instance.watchAll(),
                        builder: (context, snapshot) {
                          final products = snapshot.data ?? const <AdminProduct>[];
                          final ids = {for (final item in products) item.id};
                          final selected = ids.contains(linkId) ? linkId : null;
                          return DropdownButtonFormField<String>(
                            key: ValueKey('product-$selected-${products.length}'),
                            initialValue: selected,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Ürün',
                            ),
                            items: [
                              for (final item in products)
                                DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialog(() => linkId = value);
                            },
                          );
                        },
                      ),
                    ],
                    if (linkType == BannerLinkType.article) ...[
                      const SizedBox(height: 10),
                      StreamBuilder<List<AppKnowledgeArticle>>(
                        stream:
                            KnowledgeArticleRepository.instance.watchActive(),
                        builder: (context, snapshot) {
                          final articles =
                              snapshot.data ?? AppKnowledgeArticle.defaults();
                          final ids = {for (final item in articles) item.id};
                          final selected =
                              ids.contains(linkId) ? linkId : null;
                          return DropdownButtonFormField<String>(
                            key: ValueKey(
                              'article-$selected-${articles.length}',
                            ),
                            initialValue: selected,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Makale',
                            ),
                            items: [
                              for (final item in articles)
                                DropdownMenuItem(
                                  value: item.id,
                                  child: Text(
                                    item.title,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                            ],
                            onChanged: (value) {
                              if (value == null) return;
                              setDialog(() => linkId = value);
                            },
                          );
                        },
                      ),
                    ],
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
                  if (title.text.trim().isEmpty) {
                    title.text = slot.title;
                  }
                  Navigator.pop(ctx, true);
                },
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );
    if (saved != true) {
      title.dispose();
      return;
    }
    final resolvedTitle = title.text.trim().isEmpty
        ? placement.title
        : title.text.trim();
    title.dispose();
    try {
      await _save(
        AppBanner(
          id:
              existing?.id ??
              FirebaseFirestore.instance.collection('banners').doc().id,
          title: resolvedTitle,
          imageUrl: imageUrl,
          assetPath: existing?.assetPath ?? '',
          placement: selectedPlacement,
          order: existing?.order ?? nextOrder,
          active: active,
          linkType: linkType,
          linkId: linkType == BannerLinkType.none ? '' : linkId,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilemedi: $error')),
      );
    }
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
        final visibleSlots = BannerPlacement.values.where(_matches).toList();
        final pageBoxes = <(String pageId, String pageLabel, List<BannerPlacement> slots)>[
          for (final page in BannerPlacement.pages)
            if (visibleSlots.any((slot) => slot.pageId == page.$1))
              (
                page.$1,
                page.$2,
                visibleSlots.where((slot) => slot.pageId == page.$1).toList(),
              ),
        ];
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const AdminPageHeader(
              title: 'Bannerlar',
              subtitle:
                  'Her kutu bir uygulama sayfasına aittir. Banner ve reklamlar o sayfanın kutusunda durur; üstte ölçü (px) ve nereye ait olduğu yazar.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _groupChip('all', 'Tüm sayfalar'),
                for (final page in BannerPlacement.pages)
                  _groupChip(page.$1, page.$2),
              ],
            ),
            const SizedBox(height: 16),
            for (final box in pageBoxes) ...[
              _PageCategoryBox(
                pageLabel: box.$2,
                slotCount: box.$3.length,
                children: [
                  for (final slot in box.$3) ...[
                    _SectionBlock(
                      placement: slot,
                      banners: banners
                          .where((item) => item.placement == slot.id)
                          .toList(),
                      onAdd: () => _edit(
                        placement: slot,
                        nextOrder: banners
                            .where((b) => b.placement == slot.id)
                            .length,
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
                    if (slot != box.$3.last) const SizedBox(height: 14),
                  ],
                ],
              ),
              const SizedBox(height: 18),
            ],
          ],
        );
      },
    );
  }

  Widget _groupChip(String value, String label) {
    final selected = _group == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _group = value),
      selectedColor: AppColors.selected,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.text,
        fontWeight: FontWeight.w800,
      ),
    );
  }
}

class _PageCategoryBox extends StatelessWidget {
  const _PageCategoryBox({
    required this.pageLabel,
    required this.slotCount,
    required this.children,
  });

  final String pageLabel;
  final int slotCount;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  pageLabel,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
              ),
              _SizeChip(label: '$slotCount bölüm'),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Bu kutudaki banner ve reklamlar yalnızca $pageLabel sayfasına aittir.',
            style: const TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
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
                      placement.slotLabel.isEmpty
                          ? placement.title
                          : placement.slotLabel,
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
                        _SizeChip(label: placement.pxLabel),
                        _SizeChip(label: placement.belongsLabel),
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
                                      placement.boxWidth / placement.height,
                                  child: Stack(
                                    fit: StackFit.expand,
                                    children: [
                                      buildProductImage(
                                        banner.displayImage,
                                        fit: BoxFit.cover,
                                        width: double.infinity,
                                        height: double.infinity,
                                        filterQuality: FilterQuality.medium,
                                        cacheWidth: 1080,
                                      ),
                                      Positioned(
                                        left: 8,
                                        right: 8,
                                        bottom: 8,
                                        child: Wrap(
                                          spacing: 6,
                                          runSpacing: 4,
                                          children: [
                                            _OverlayChip(
                                              label: placement.pxLabel,
                                            ),
                                            _OverlayChip(
                                              label: placement.belongsLabel,
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
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
                                            '${placement.pxLabel} · ${placement.belongsLabel}',
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: const TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.primary,
                                            ),
                                          ),
                                          Text(
                                            [
                                              banner.active ? 'Yayında' : 'Gizli',
                                              if (banner.linkType ==
                                                  BannerLinkType.product)
                                                'Ürüne git',
                                              if (banner.linkType ==
                                                  BannerLinkType.article)
                                                'Makaleye git',
                                            ].join(' · '),
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

class _OverlayChip extends StatelessWidget {
  const _OverlayChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
