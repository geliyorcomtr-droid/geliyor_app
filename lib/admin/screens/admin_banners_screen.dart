import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/knowledge_article_repository.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/data/welcome_splash_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:geliyor_app/utils/storage_metadata.dart';
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
  bool _moving = false;
  final _search = TextEditingController();
  final _expandedPageIds = <String>{};

  static const _hiddenPlacementPrefix = 'home_ad_';

  List<BannerPlacement> get _visiblePlacements => BannerPlacement.values
      .where((slot) => !slot.id.startsWith(_hiddenPlacementPrefix))
      .toList();

  List<(String pageId, String pageLabel)> get _pages {
    final seen = <String>{};
    return [
      for (final slot in _visiblePlacements)
        if (seen.add(slot.pageId)) (slot.pageId, slot.pageLabel),
    ];
  }

  List<BannerPlacement> _slotsForPage(String pageId) => _visiblePlacements
      .where((slot) => slot.pageId == pageId)
      .toList();

  String _defaultSlot(String pageId) => _slotsForPage(pageId).first.id;

  @override
  void initState() {
    super.initState();
    final group = widget.initialGroup.trim();
    if (group.isNotEmpty && group != 'all' && group != 'ads') {
      _expandedPageIds.add(group);
    }
    _seed();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _seed() async {
    try {
      await BannerRepository.instance.ensureDefaults();
      await BannerRepository.instance.pruneStaleStripBanners();
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
    await BannerRepository.instance.deleteBanner(banner);
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
        storageImageMetadata(prepared.contentType),
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
    var linkId = existing?.linkId ?? '';
    if (BannerPlacement.byId(selectedPlacement).pageId == 'reklam') {
      linkType = BannerLinkType.brand;
      if (linkId.trim().isEmpty) linkId = 'N&D';
    } else if (linkType != BannerLinkType.product &&
        linkType != BannerLinkType.article) {
      linkType = BannerLinkType.none;
    }

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
                      decoration: const InputDecoration(labelText: 'Kategori'),
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
                    if (slot.pageId == 'reklam') ...[
                      const SizedBox(height: 12),
                      const Text(
                        'Tıklanınca gidilecek marka',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      StreamBuilder<List<AppBrand>>(
                        stream: BrandRepository.instance.watchAll(
                          activeOnly: true,
                        ),
                        builder: (context, snapshot) {
                          final brands =
                              snapshot.data ??
                              BrandRepository.instance.cached
                                  .where((brand) => brand.active)
                                  .toList();
                          final names = [
                            for (final brand in brands)
                              if (brand.name.trim().isNotEmpty) brand.name.trim(),
                          ];
                          if (!names.contains('N&D')) names.insert(0, 'N&D');
                          final selected = names.contains(linkId)
                              ? linkId
                              : 'N&D';
                          return DropdownButtonFormField<String>(
                            key: ValueKey('brand-$selected-${names.length}'),
                            initialValue: selected,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              labelText: 'Marka',
                            ),
                            items: [
                              for (final name in names)
                                DropdownMenuItem(
                                  value: name,
                                  child: Text(
                                    name,
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
                    if (slot.pageId != 'smart_plan' &&
                        slot.pageId != 'reklam') ...[
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
                    ],
                    if (slot.pageId == 'smart_plan') ...[
                      const SizedBox(height: 12),
                      Text(
                        slot.id == BannerPlacement.smartPlanAutoOrderStrip.id
                            ? 'Abonelik şeridi. Ölçü 361×139 px. Görselin altındaki beyaz alanda “Aboneliğim” yazısı ve aç/kapa anahtarı uygulamada durur; tıklanınca sayfa açılmaz. Görseli değiştirebilir veya silebilirsiniz.'
                            : slot.id ==
                                  BannerPlacement.smartPlanReminderStrip.id
                            ? 'Akıllı Planım sayfasındaki hatırlatma görseli. Ölçü 361×139 px. Alttaki beyaz kutuda anahtar ve gün seçimi uygulamada çalışır; buradan yalnızca görseli değiştirin.'
                            : slot.id ==
                                  BannerPlacement.smartPlanOrderTrackStrip.id
                            ? 'Siparişten Otomatik Takip şeridi. Ölçü 361×139 px. Görselin herhangi bir yerine tıklanınca sipariş takip penceresi açılır. Görseli değiştirebilir veya silebilirsiniz.'
                            : slot.id ==
                                  BannerPlacement.smartPlanManualTrackStrip.id
                            ? 'Manuel Takip şeridi. Ölçü 361×139 px. Görselin herhangi bir yerine tıklanınca mama takip sayfası açılır. Görseli değiştirebilir veya silebilirsiniz.'
                            : 'Kutuya tıklanınca bu görsel açılır; tekrar dokununca kapanır. Yazı paneli yok.',
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
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
      final previousUrl = existing?.imageUrl.trim() ?? '';
      final nextUrl = imageUrl.trim();
      await _save(
        AppBanner(
          id:
              existing?.id ??
              FirebaseFirestore.instance.collection('banners').doc().id,
          title: resolvedTitle,
          imageUrl: nextUrl,
          assetPath: '',
          placement: selectedPlacement,
          order: existing?.order ?? nextOrder,
          active: active,
          linkType: () {
            final pageId = BannerPlacement.byId(selectedPlacement).pageId;
            if (pageId == 'smart_plan') return BannerLinkType.none;
            if (pageId == 'reklam') return BannerLinkType.brand;
            return linkType;
          }(),
          linkId: () {
            final pageId = BannerPlacement.byId(selectedPlacement).pageId;
            if (pageId == 'smart_plan') return '';
            if (pageId == 'reklam') {
              final brand = linkId.trim();
              return brand.isEmpty ? 'N&D' : brand;
            }
            if (linkType == BannerLinkType.none) return '';
            return linkId;
          }(),
          linkLabel: BannerPlacement.byId(selectedPlacement).pageId == 'reklam'
              ? (linkId.trim().isEmpty ? 'N&D' : linkId.trim())
              : (existing?.linkLabel ?? ''),
        ),
      );
      if (previousUrl.isNotEmpty && previousUrl != nextUrl) {
        await BannerRepository.deleteStorageUrl(previousUrl);
      }
      await BannerRepository.instance.pruneStaleStripBanners();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilemedi: $error')),
      );
    }
  }

  List<AppBanner> _bannersForPage(String pageId, List<AppBanner> all) {
    final slots = _slotsForPage(pageId);
    final rank = {for (var i = 0; i < slots.length; i++) slots[i].id: i};
    final list = all.where((item) => rank.containsKey(item.placement)).toList();
    list.sort((a, b) {
      final bySlot = (rank[a.placement] ?? 0).compareTo(rank[b.placement] ?? 0);
      if (bySlot != 0) return bySlot;
      return a.order.compareTo(b.order);
    });
    return list;
  }

  bool _isExpanded(String pageId, List<AppBanner> items) {
    if (_search.text.trim().isNotEmpty && items.isNotEmpty) return true;
    return _expandedPageIds.contains(pageId);
  }

  void _togglePage(String pageId) {
    setState(() {
      if (_expandedPageIds.contains(pageId)) {
        _expandedPageIds.remove(pageId);
      } else {
        _expandedPageIds.add(pageId);
      }
    });
  }

  Future<void> _move({
    required List<AppBanner> catalog,
    required String id,
    required String placement,
    String? beforeId,
  }) async {
    if (_moving) return;
    setState(() => _moving = true);
    try {
      await BannerRepository.instance.moveBanner(
        catalog: catalog,
        id: id,
        placement: placement,
        beforeId: beforeId,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Taşınamadı: $error')),
      );
    } finally {
      if (mounted) setState(() => _moving = false);
    }
  }

  Future<void> _addToPage(String pageId, List<AppBanner> catalog) async {
    final slots = _slotsForPage(pageId);
    if (slots.isEmpty) return;
    var slot = slots.first;
    if (slots.length > 1) {
      final picked = await showMenu<String>(
        context: context,
        position: const RelativeRect.fromLTRB(24, 80, 24, 0),
        items: [
          for (final item in slots)
            PopupMenuItem(
              value: item.id,
              child: Text('${item.slotLabel.isEmpty ? item.title : item.slotLabel} · ${item.pxLabel}'),
            ),
        ],
      );
      if (picked == null) return;
      slot = BannerPlacement.byId(picked);
    }
    if (!mounted) return;
    await _edit(
      placement: slot,
      nextOrder: catalog.where((item) => item.placement == slot.id).length,
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
        final query = _search.text.trim().toLowerCase();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const AdminPageHeader(
              title: 'Bannerlar',
              subtitle:
                  'Ana kategoriye tıklayınca o sayfanın banner görselleri açılır. '
                  'Görseli sürükleyerek sırasını veya kategorisini değiştirin.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  'Toplam ${banners.length} banner',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 180,
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Ara',
                      isDense: true,
                      suffixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            if (widget.initialGroup == 'all' ||
                widget.initialGroup == 'welcome_splash')
              _welcomeSplashBoard(),
            if (widget.initialGroup != 'welcome_splash')
              for (final page in _pages)
              _categoryBoard(
                pageId: page.$1,
                pageLabel: page.$2,
                banners: _bannersForPage(page.$1, banners).where((item) {
                  if (query.isEmpty) return true;
                  final slot = item.placementInfo;
                  final hay =
                      '${item.title} ${slot.pageLabel} ${slot.slotLabel} ${slot.title}'
                          .toLowerCase();
                  return hay.contains(query);
                }).toList(),
                catalog: banners,
              ),
          ],
        );
      },
    );
  }

  Widget _welcomeSplashBoard() {
    final query = _search.text.trim().toLowerCase();
    const label = 'karşılama görseli';
    if (query.isNotEmpty && !label.contains(query)) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: StreamBuilder<String>(
        stream: WelcomeSplashRepository.instance.watchImageUrl(),
        builder: (context, snapshot) {
          final imageUrl = (snapshot.data ?? '').trim();
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(12, 10, 8, 4),
                  child: Text(
                    'Karşılama',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 15,
                      color: AppColors.text,
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => _editWelcomeSplash(imageUrl),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(10, 4, 8, 10),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: SizedBox(
                            width: 92,
                            height: 52,
                            child: imageUrl.isEmpty
                                ? const ColoredBox(
                                    color: AppColors.background,
                                    child: Icon(
                                      Icons.image_outlined,
                                      color: AppColors.subText,
                                    ),
                                  )
                                : buildProductImage(
                                    imageUrl,
                                    fit: BoxFit.cover,
                                    width: 92,
                                    height: 52,
                                    cacheWidth: 360,
                                  ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Karşılama görseli',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                              Text(
                                '393 × 852 px',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                'Açılış ekranı',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.subText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Düzenle',
                          visualDensity: VisualDensity.compact,
                          onPressed: () => _editWelcomeSplash(imageUrl),
                          icon: const Icon(Icons.edit_outlined, size: 20),
                        ),
                        IconButton(
                          tooltip: 'Sil',
                          visualDensity: VisualDensity.compact,
                          onPressed: imageUrl.isEmpty
                              ? null
                              : () => _deleteWelcomeSplash(imageUrl),
                          icon: const Icon(
                            Icons.delete_outline_rounded,
                            size: 20,
                            color: AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _editWelcomeSplash(String imageUrl) async {
    var current = imageUrl.trim();
    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) {
          return AlertDialog(
            title: const Text('Karşılama görseli'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Ölçü 393×852 px. Görseli değiştirebilir veya silebilirsiniz.',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(24),
                    child: Container(
                      height: 280,
                      color: AppColors.background,
                      alignment: Alignment.center,
                      child: current.isEmpty
                          ? const Text(
                              'Görsel yok',
                              style: TextStyle(
                                color: AppColors.subText,
                                fontWeight: FontWeight.w700,
                              ),
                            )
                          : buildProductImage(
                              current,
                              fit: BoxFit.contain,
                              width: double.infinity,
                              height: 280,
                              cacheWidth: 1179,
                            ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: current.isEmpty
                    ? null
                    : () async {
                        Navigator.pop(ctx);
                        await _deleteWelcomeSplash(current);
                      },
                child: const Text('Sil'),
              ),
              FilledButton(
                onPressed: _uploading
                    ? null
                    : () async {
                        final next = await _uploadWelcomeSplash();
                        if (next == null) return;
                        setDialog(() => current = next);
                      },
                child: Text(current.isEmpty ? 'Yükle' : 'Değiştir'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<String?> _uploadWelcomeSplash() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final prepared = prepareUploadImage(
        bytes,
        file.name,
        style: UploadImageStyle.screen,
      );
      final ref = FirebaseStorage.instance.ref(
        'welcome_splash/${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await ref.putData(
        prepared.bytes,
        storageImageMetadata(prepared.contentType),
      );
      final url = await ref.getDownloadURL();
      final previous = WelcomeSplashRepository.instance.imageUrl.trim();
      await WelcomeSplashRepository.instance.saveImageUrl(url);
      if (previous.isNotEmpty && previous != url) {
        await BannerRepository.deleteStorageUrl(previous);
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Karşılama görseli güncellendi (${prepared.kiloBytes} KB).')),
        );
      }
      return url;
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

  Future<void> _deleteWelcomeSplash(String imageUrl) async {
    if (imageUrl.trim().isEmpty) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Karşılama görselini sil'),
        content: const Text(
          'Yüklenen görsel kaldırılsın mı? Uygulama varsayılan açılış ekranına döner.',
        ),
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
    await WelcomeSplashRepository.instance.clearImage();
    await BannerRepository.deleteStorageUrl(imageUrl);
  }

  Widget _emptySlotRow({
    required BannerPlacement slot,
    required List<AppBanner> catalog,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 8, 10),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.image_outlined,
              color: AppColors.subText,
              size: 22,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  slot.slotLabel.isEmpty ? slot.title : slot.slotLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  '${slot.pxLabel} · görsel eklenecek',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: _moving || _uploading
                ? null
                : () => _edit(
                    placement: slot,
                    nextOrder: catalog
                        .where((item) => item.placement == slot.id)
                        .length,
                  ),
            child: const Text('Görsel ekle'),
          ),
        ],
      ),
    );
  }

  Widget _categoryBoard({
    required String pageId,
    required String pageLabel,
    required List<AppBanner> banners,
    required List<AppBanner> catalog,
  }) {
    final slots = _slotsForPage(pageId);
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: DragTarget<String>(
        onWillAcceptWithDetails: (details) =>
            !_moving && details.data.trim().isNotEmpty,
        onAcceptWithDetails: (details) {
          var currentPlacement = '';
          for (final item in catalog) {
            if (item.id == details.data) currentPlacement = item.placement;
          }
          if (currentPlacement.isNotEmpty &&
              _slotsForPage(pageId).any((slot) => slot.id == currentPlacement)) {
            return;
          }
          _move(
            catalog: catalog,
            id: details.data,
            placement: _defaultSlot(pageId),
          );
        },
        builder: (context, candidate, _) {
          final hovering = candidate.isNotEmpty;
          final expanded = _isExpanded(pageId, banners);
          return AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            decoration: BoxDecoration(
              color: hovering ? AppColors.selected : AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: hovering ? AppColors.primary : AppColors.border,
                width: hovering ? 2 : 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => _togglePage(pageId),
                    borderRadius: BorderRadius.circular(18),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
                      child: Row(
                        children: [
                          Icon(
                            expanded
                                ? Icons.expand_less_rounded
                                : Icons.expand_more_rounded,
                            color: AppColors.primary,
                            size: 22,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              pageLabel,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: AppColors.text,
                              ),
                            ),
                          ),
                          Text(
                            '${banners.length}',
                            style: const TextStyle(
                              color: AppColors.subText,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          TextButton.icon(
                            onPressed: _moving || _uploading
                                ? null
                                : () => _addToPage(pageId, catalog),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Ekle'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              visualDensity: VisualDensity.compact,
                            ),
                          ),
                          if (expanded)
                            Text(
                              hovering ? 'Bırakın' : 'Buraya sürükleyin',
                              style: TextStyle(
                                color: hovering
                                    ? AppColors.primary
                                    : AppColors.subText,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (expanded) ...[
                  if (banners.isEmpty)
                    const Padding(
                      padding: EdgeInsets.fromLTRB(12, 0, 12, 14),
                      child: Text(
                        'Bu kategoride henüz banner yok.',
                        style: TextStyle(
                          color: AppColors.subText,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else ...[
                    if (pageId == BannerPlacement.home.pageId)
                      _homeTopBannerList(
                        banners: [
                          for (final item in banners)
                            if (item.placement == BannerPlacement.home.id) item,
                        ],
                        catalog: catalog,
                        slots: slots,
                      ),
                    for (var i = 0; i < banners.length; i++)
                      if (pageId != BannerPlacement.home.pageId ||
                          banners[i].placement != BannerPlacement.home.id)
                        _bannerRow(
                          banner: banners[i],
                          catalog: catalog,
                          slots: slots,
                          showDivider: i > 0,
                        ),
                  ],
                  if (pageId == BannerPlacement.adoption.pageId ||
                      pageId == BannerPlacement.campaignDiscount.pageId ||
                      pageId == BannerPlacement.emergency.pageId ||
                      pageId == BannerPlacement.platformPoster.pageId ||
                      pageId == BannerPlacement.ozelKolaySiparis.pageId ||
                      pageId == BannerPlacement.homeReklam.pageId)
                    for (final slot in slots)
                      if (!banners.any((item) => item.placement == slot.id))
                        _emptySlotRow(slot: slot, catalog: catalog),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  void _reorderHomeTop(
    List<AppBanner> top,
    List<AppBanner> catalog,
    int oldIndex,
    int newIndex,
  ) {
    if (_moving || top.isEmpty) return;
    if (oldIndex < 0 || oldIndex >= top.length || oldIndex == newIndex) return;
    final moving = top[oldIndex];
    final next = [...top]..removeAt(oldIndex);
    final beforeId = newIndex >= 0 && newIndex < next.length
        ? next[newIndex].id
        : null;
    _move(
      catalog: catalog,
      id: moving.id,
      placement: BannerPlacement.home.id,
      beforeId: beforeId,
    );
  }

  Widget _homeTopBannerList({
    required List<AppBanner> banners,
    required List<AppBanner> catalog,
    required List<BannerPlacement> slots,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(12, 0, 12, 4),
          child: Text(
            'Üst banner · tutamacı sürükleyerek sıralayın',
            style: TextStyle(
              color: AppColors.subText,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        if (banners.isEmpty)
          const Padding(
            padding: EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Text(
              'Üst banner yok.',
              style: TextStyle(
                color: AppColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: banners.length,
            onReorderItem: (oldIndex, newIndex) =>
                _reorderHomeTop(banners, catalog, oldIndex, newIndex),
            itemBuilder: (context, index) => _bannerRow(
              key: ValueKey('home-top-${banners[index].id}'),
              banner: banners[index],
              catalog: catalog,
              slots: slots,
              showDivider: index > 0,
              reorderIndex: index,
            ),
          ),
      ],
    );
  }

  Widget _bannerRow({
    Key? key,
    required AppBanner banner,
    required List<AppBanner> catalog,
    required List<BannerPlacement> slots,
    required bool showDivider,
    int? reorderIndex,
  }) {
    final slot = banner.placementInfo;
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          reorderIndex == null
              ? const MouseRegion(
                  cursor: SystemMouseCursors.grab,
                  child: Icon(
                    Icons.drag_indicator_rounded,
                    color: AppColors.subText,
                  ),
                )
              : ReorderableDragStartListener(
                  index: reorderIndex,
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(
                      Icons.drag_indicator_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                ),
          const SizedBox(width: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              width: 92,
              height: 52,
              child: buildProductImage(
                banner.displayImage,
                fit: BoxFit.cover,
                width: 92,
                height: 52,
                filterQuality: FilterQuality.medium,
                cacheWidth: 360,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  banner.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  slots.length > 1
                      ? '${slot.slotLabel.isEmpty ? slot.title : slot.slotLabel} · ${slot.pxLabel}'
                      : slot.pxLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (banner.linkType == BannerLinkType.brand &&
                    banner.linkId.trim().isNotEmpty)
                  Text(
                    'Marka: ${banner.linkId.trim()}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                Text(
                  banner.active ? 'Yayında' : 'Gizli',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: banner.active ? AppColors.success : AppColors.subText,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () => _save(banner.copyWith(active: !banner.active)),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
            ),
            child: Text(
              banner.active ? 'Aktif' : 'Pasif',
              style: TextStyle(
                color: banner.active ? AppColors.success : AppColors.error,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Kategori değiştir',
            enabled: !_moving,
            onSelected: (placement) {
              _move(
                catalog: catalog,
                id: banner.id,
                placement: placement,
              );
            },
            itemBuilder: (context) => [
              for (final page in _pages)
                for (final item in _slotsForPage(page.$1))
                  if (item.id != banner.placement)
                    PopupMenuItem(
                      value: item.id,
                      child: Text(
                        _slotsForPage(page.$1).length > 1
                            ? '${page.$2} · ${item.slotLabel.isEmpty ? item.title : item.slotLabel}'
                            : page.$2,
                      ),
                    ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Kategori',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Düzenle',
            visualDensity: VisualDensity.compact,
            onPressed: () => _edit(
              existing: banner,
              placement: slot,
              nextOrder: banner.order,
            ),
            icon: const Icon(Icons.edit_outlined, size: 20),
          ),
          IconButton(
            tooltip: 'Sil',
            visualDensity: VisualDensity.compact,
            onPressed: () => _delete(banner),
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );

    if (reorderIndex != null) {
      return DecoratedBox(
        key: key,
        decoration: BoxDecoration(
          border: Border(
            top: showDivider
                ? const BorderSide(color: AppColors.border)
                : BorderSide.none,
          ),
        ),
        child: row,
      );
    }

    return DragTarget<String>(
      key: key,
      onWillAcceptWithDetails: (details) =>
          !_moving && details.data != banner.id,
      onAcceptWithDetails: (details) {
        _move(
          catalog: catalog,
          id: details.data,
          placement: banner.placement,
          beforeId: banner.id,
        );
      },
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        return Draggable<String>(
          data: banner.id,
          maxSimultaneousDrags: _moving ? 0 : 1,
          feedback: Material(
            elevation: 8,
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 240,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  banner.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ),
          ),
          childWhenDragging: Opacity(opacity: 0.35, child: row),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: hovering ? AppColors.selected : null,
              border: Border(
                top: showDivider
                    ? const BorderSide(color: AppColors.border)
                    : BorderSide.none,
              ),
            ),
            child: row,
          ),
        );
      },
    );
  }
}
