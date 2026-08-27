import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/trust_badge_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminTrustBadgesScreen extends StatefulWidget {
  const AdminTrustBadgesScreen({super.key});

  @override
  State<AdminTrustBadgesScreen> createState() => _AdminTrustBadgesScreenState();
}

class _AdminTrustBadgesScreenState extends State<AdminTrustBadgesScreen> {
  bool _seeding = true;
  bool _uploading = false;
  final _search = TextEditingController();
  int _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _seedBadges();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _seedBadges() async {
    try {
      await TrustBadgeRepository.instance.ensureDefaults();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Güven rozetleri yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _editBadge(AppTrustBadge? existing, int nextOrder) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    final order = TextEditingController(
      text: '${existing?.order ?? nextOrder}',
    );
    var active = existing?.active ?? true;
    var dialogUploading = false;
    final isExistingRating =
        existing != null && TrustBadgeRepository.isRatingBadge(existing);

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final isRating =
              isExistingRating ||
              TrustBadgeRepository.isRatingBadge(
                AppTrustBadge(
                  id: existing?.id ?? _badgeId(name.text),
                  name: name.text,
                ),
              );
          return AlertDialog(
            title: Text(
              existing == null
                  ? 'Güven Rozeti Ekle'
                  : 'Güven Rozetini Düzenle',
            ),
            content: SizedBox(
              width: 520,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _badgeImage(
                    imageUrl: imageUrl.text,
                    assetPath: existing?.assetPath ?? '',
                    name: name.text,
                    id: existing?.id,
                    size: 110,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: name,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Rozet adı',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: order,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Sıra No',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (!isRating) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: imageUrl,
                      decoration: const InputDecoration(
                        labelText: 'Görsel URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: dialogUploading
                          ? null
                          : () async {
                              setDialogState(() => dialogUploading = true);
                              final url = await _pickAndUploadImage();
                              if (url != null) {
                                imageUrl.text = url;
                                setDialogState(() {});
                              }
                              setDialogState(() => dialogUploading = false);
                            },
                      icon: const Icon(Icons.upload_rounded),
                      label: Text(
                        dialogUploading ? 'Yükleniyor...' : 'Görsel Ekle',
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 12),
                    const Text(
                      'Puan rozeti sarı yıldız ikonu kullanır; özel görsel yok.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => setDialogState(() => active = !active),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'Yayın Durumu',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Switch(
                              value: active,
                              onChanged: (value) =>
                                  setDialogState(() => active = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext, false),
                child: const Text('Vazgeç'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext, true),
                child: const Text('Kaydet'),
              ),
            ],
          );
        },
      ),
    );

    final badgeName = name.text.trim();
    final uploadedImage = imageUrl.text.trim();
    final badgeOrder = int.tryParse(order.text.trim()) ?? nextOrder;
    name.dispose();
    imageUrl.dispose();
    order.dispose();
    if (save != true || badgeName.isEmpty) return;

    final id = existing?.id ?? _badgeId(badgeName);
    final asRating = TrustBadgeRepository.isRatingBadge(
      AppTrustBadge(id: id, name: badgeName),
    );
    await TrustBadgeRepository.instance.save(
      AppTrustBadge(
        id: id,
        name: badgeName,
        imageUrl: asRating ? '' : uploadedImage,
        assetPath: asRating ? '' : (existing?.assetPath ?? ''),
        order: badgeOrder,
        active: active,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$badgeName kaydedildi.')));
  }

  Future<void> _toggleActive(AppTrustBadge badge) async {
    await TrustBadgeRepository.instance.save(
      badge.copyWith(active: !badge.active),
    );
  }

  Future<void> _changeImage(AppTrustBadge badge) async {
    if (TrustBadgeRepository.isRatingBadge(badge)) return;
    final url = await _pickAndUploadImage();
    if (url == null) return;
    await TrustBadgeRepository.instance.save(badge.copyWith(imageUrl: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${badge.name} görseli güncellendi.')),
    );
  }

  Future<void> _deleteBadge(AppTrustBadge badge) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Güven rozetini kaldır'),
        content: Text('"${badge.name}" listeden kaldırılsın mı?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TrustBadgeRepository.instance.delete(badge.id);
  }

  Future<String?> _pickAndUploadImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final reference = FirebaseStorage.instance.ref(
        'trust_badges/${DateTime.now().microsecondsSinceEpoch}_$safeName',
      );
      await reference.putData(
        bytes,
        SettableMetadata(contentType: _contentTypeFor(file.name)),
      );
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppTrustBadge>>(
      stream: TrustBadgeRepository.instance.watchAll(),
      builder: (context, snapshot) {
        if (_seeding || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final badges = snapshot.data!
            .where((badge) => !TrustBadgeRepository.isSmartSuggestionBadge(badge))
            .where((badge) => !TrustBadgeRepository.isProteinBadge(badge))
            .toList();
        final query = _search.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? badges
            : badges
                  .where((badge) => badge.name.toLowerCase().contains(query))
                  .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Güven Rozetleri',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ürün detayında görselin solunda gösterilen rozetleri yönetin. '
              'Puan / Değerlendirme rozeti her zaman sarı yıldız ikonu kullanır; '
              'özel görsel yüklenmez.',
              style: TextStyle(
                color: AppColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            _buildToolbar(badges.length),
            const SizedBox(height: 14),
            if (badges.isEmpty)
              _emptyPanel()
            else
              _buildTable(filtered, badges.length),
          ],
        );
      },
    );
  }

  Widget _buildToolbar(int total) {
    return Wrap(
      spacing: 14,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: 148,
          child: DropdownButtonFormField<int>(
            initialValue: _pageSize,
            isExpanded: true,
            isDense: true,
            decoration: const InputDecoration(
              isDense: true,
              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 25, child: Text('25 Satır')),
              DropdownMenuItem(value: 50, child: Text('50 Satır')),
              DropdownMenuItem(value: 100, child: Text('100 Satır')),
            ],
            onChanged: (value) {
              if (value != null) setState(() => _pageSize = value);
            },
          ),
        ),
        Text(
          'Toplam $total Sonuç',
          style: const TextStyle(
            color: AppColors.subText,
            fontWeight: FontWeight.w600,
          ),
        ),
        FilledButton.icon(
          onPressed: _uploading ? null : () => _editBadge(null, total),
          icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
          label: const Text('Yeni Ekle'),
        ),
        SizedBox(
          width: 180,
          child: TextField(
            controller: _search,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Ara',
              suffixIcon: Icon(Icons.search_rounded),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
              border: OutlineInputBorder(),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTable(List<AppTrustBadge> badges, int nextOrder) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) {
          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                headingRowColor: const WidgetStatePropertyAll(
                  AppColors.selected,
                ),
                headingRowHeight: 46,
                dataRowMinHeight: 70,
                dataRowMaxHeight: 70,
                columnSpacing: 34,
                horizontalMargin: 14,
                columns: const [
                  DataColumn(label: Text('Resim')),
                  DataColumn(label: Text('Rozet Adı')),
                  DataColumn(label: Text('Sıra No')),
                  DataColumn(label: Text('Yayın Durumu')),
                  DataColumn(label: Text('İşlem')),
                ],
                rows: [
                  for (final badge in badges.take(_pageSize))
                    DataRow(
                      cells: [
                        DataCell(
                          InkWell(
                            onTap: _uploading ||
                                    TrustBadgeRepository.isRatingBadge(badge)
                                ? null
                                : () => _changeImage(badge),
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 68,
                              height: 52,
                              child: _badgeImage(
                                imageUrl: badge.imageUrl,
                                assetPath: badge.assetPath,
                                name: badge.name,
                                id: badge.id,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 250,
                            child: Text(
                              TrustBadgeRepository.displayName(badge),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text('${badge.order}')),
                        DataCell(
                          TextButton(
                            onPressed: () => _toggleActive(badge),
                            child: Text(
                              badge.active ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                color: badge.active
                                    ? AppColors.success
                                    : AppColors.error,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                tooltip: TrustBadgeRepository.isRatingBadge(badge)
                                    ? 'Sarı yıldız (değiştirilemez)'
                                    : 'Görsel Ekle / Değiştir',
                                onPressed: _uploading ||
                                        TrustBadgeRepository.isRatingBadge(badge)
                                    ? null
                                    : () => _changeImage(badge),
                                icon: Icon(
                                  TrustBadgeRepository.isRatingBadge(badge)
                                      ? Icons.star_rounded
                                      : Icons.image_outlined,
                                  size: 19,
                                  color: TrustBadgeRepository.isRatingBadge(badge)
                                      ? AppColors.warning
                                      : null,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Düzenle',
                                onPressed: () => _editBadge(badge, nextOrder),
                                icon: const Icon(Icons.edit_outlined, size: 19),
                              ),
                              IconButton(
                                tooltip: 'Sil',
                                onPressed: () => _deleteBadge(badge),
                                icon: const Icon(
                                  Icons.delete_outline_rounded,
                                  size: 19,
                                  color: AppColors.error,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _badgeImage({
    required String imageUrl,
    required String assetPath,
    required String name,
    String? id,
    double? size,
  }) {
    final isRating = TrustBadgeRepository.isRatingBadge(
      AppTrustBadge(id: id ?? '', name: name),
    );
    if (isRating) {
      return Container(
        width: size,
        height: size,
        padding: const EdgeInsets.all(5),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: const Icon(
          Icons.star_rounded,
          color: AppColors.warning,
          size: 28,
        ),
      );
    }

    final lower = name.toLowerCase();
    final fallback = Center(
      child: Container(
        color: AppColors.subText,
        alignment: Alignment.center,
        child: const Text(
          'RESİM\nYOK',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.surface,
            fontSize: 11,
            fontWeight: FontWeight.w900,
            height: 1.1,
          ),
        ),
      ),
    );
    final isProtein = lower.contains('protein');
    final isPreferred = lower.contains('tercih');
    final isRepurchase = lower.contains('tekrar');
    final isAffordable = lower.contains('uygun');
    final resolvedAsset = isProtein
        ? TrustBadgeRepository.proteinIconPath
        : isPreferred
        ? TrustBadgeRepository.preferredIconPath
        : isRepurchase
        ? TrustBadgeRepository.repurchaseIconPath
        : isAffordable
        ? TrustBadgeRepository.affordableIconPath
        : assetPath;
    final image = imageUrl.isNotEmpty
        ? buildProductImage(
            imageUrl,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorWidget: fallback,
          )
        : resolvedAsset.isNotEmpty
        ? buildProductImage(
            resolvedAsset,
            fit: BoxFit.contain,
            errorWidget: fallback,
          )
        : fallback;

    return Container(
      width: size,
      height: size,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: image,
    );
  }

  Widget _emptyPanel() {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text(
        'Henüz güven rozeti yok. “Yeni Ekle” ile başlayın.',
        style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _badgeId(String name) {
    final slug = name
        .toLowerCase()
        .replaceAll('ı', 'i')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ş', 's')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c')
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-+|-+$'), '');
    final base = slug.isEmpty ? 'rozet' : slug;
    return '$base-${DateTime.now().millisecondsSinceEpoch}';
  }

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
