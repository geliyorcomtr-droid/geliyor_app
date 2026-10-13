import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/trust_badge_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:geliyor_app/utils/storage_metadata.dart';
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
    final detailImageUrl = TextEditingController(
      text: existing?.detailImageUrl ?? '',
    );
    final order = TextEditingController(
      text: '${existing?.order ?? nextOrder}',
    );
    var active = existing?.active ?? true;
    var dialogUploading = false;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: Text(
              existing == null
                  ? 'Güven Rozeti Ekle'
                  : 'Güven Rozetini Düzenle',
            ),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _imageSlot(
                            title: 'İkon',
                            imageUrl: imageUrl.text,
                            assetPath:
                                (existing?.assetPath.trim().isNotEmpty ?? false)
                                ? existing!.assetPath
                                : TrustBadgeRepository.defaultAssetPathFor(
                                    AppTrustBadge(
                                      id: existing?.id ?? '',
                                      name: name.text,
                                    ),
                                  ),
                            name: name.text,
                            id: existing?.id,
                            uploading: dialogUploading,
                            onUpload: () async {
                              setDialogState(() => dialogUploading = true);
                              final url = await _pickAndUploadImage();
                              if (url != null) imageUrl.text = url;
                              setDialogState(() => dialogUploading = false);
                            },
                            onDelete: imageUrl.text.trim().isEmpty
                                ? null
                                : () =>
                                      setDialogState(() => imageUrl.clear()),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _imageSlot(
                            title: 'Açılan görsel',
                            imageUrl: detailImageUrl.text,
                            assetPath: '',
                            name: name.text,
                            id: existing?.id,
                            emptyHint: 'Yükle',
                            uploading: dialogUploading,
                            onUpload: () async {
                              setDialogState(() => dialogUploading = true);
                              final url = await _pickAndUploadImage(
                                style: UploadImageStyle.photo,
                                folder: 'trust_badges/detail',
                              );
                              if (url != null) detailImageUrl.text = url;
                              setDialogState(() => dialogUploading = false);
                            },
                            onDelete: detailImageUrl.text.trim().isEmpty
                                ? null
                                : () => setDialogState(
                                    () => detailImageUrl.clear(),
                                  ),
                          ),
                        ),
                      ],
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
    final uploadedDetail = detailImageUrl.text.trim();
    final badgeOrder = int.tryParse(order.text.trim()) ?? nextOrder;
    name.dispose();
    imageUrl.dispose();
    detailImageUrl.dispose();
    order.dispose();
    if (save != true || badgeName.isEmpty) return;

    final id = existing?.id ?? _badgeId(badgeName);
    await TrustBadgeRepository.instance.save(
      AppTrustBadge(
        id: id,
        name: badgeName,
        imageUrl: uploadedImage,
        detailImageUrl: uploadedDetail,
        assetPath: uploadedImage.isNotEmpty
            ? ''
            : TrustBadgeRepository.defaultAssetPathFor(
                AppTrustBadge(id: id, name: badgeName),
              ),
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
    final url = await _pickAndUploadImage();
    if (url == null) return;
    await TrustBadgeRepository.instance.save(
      badge.copyWith(imageUrl: url, assetPath: ''),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${badge.name} görseli güncellendi.')),
    );
  }

  Future<void> _removeImage(AppTrustBadge badge) async {
    if (badge.imageUrl.trim().isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Görseli sil'),
        content: Text('"${badge.name}" için yüklenen görsel silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TrustBadgeRepository.instance.save(
      badge.copyWith(
        imageUrl: '',
        assetPath: TrustBadgeRepository.defaultAssetPathFor(badge),
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${badge.name} görseli silindi.')),
    );
  }

  Future<void> _changeDetailImage(AppTrustBadge badge) async {
    final url = await _pickAndUploadImage(
      style: UploadImageStyle.photo,
      folder: 'trust_badges/detail',
    );
    if (url == null) return;
    await TrustBadgeRepository.instance.save(
      badge.copyWith(detailImageUrl: url),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${badge.name} açılan görseli güncellendi.')),
    );
  }

  Future<void> _removeDetailImage(AppTrustBadge badge) async {
    if (badge.detailImageUrl.trim().isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Açılan görseli sil'),
        content: Text(
          '"${badge.name}" için tıklanınca açılan görsel silinsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await TrustBadgeRepository.instance.save(
      badge.copyWith(detailImageUrl: ''),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${badge.name} açılan görseli silindi.')),
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

  Future<String?> _pickAndUploadImage({
    UploadImageStyle style = UploadImageStyle.icon,
    String folder = 'trust_badges',
  }) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final prepared = prepareUploadImage(
        bytes,
        file.name,
        style: style,
      );
      final reference = FirebaseStorage.instance.ref(
        '$folder/${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await reference.putData(
        prepared.bytes,
        storageImageMetadata(prepared.contentType),
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
              'İkon ile tıklanınca açılan görsel birbirinden bağımsızdır; ikonun yanındaki alana açılan görseli yükleyin.',
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
                dataRowMinHeight: 86,
                dataRowMaxHeight: 86,
                columnSpacing: 34,
                horizontalMargin: 14,
                columns: const [
                  DataColumn(label: Text('İkon / Açılan görsel')),
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
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: _uploading
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
                              const SizedBox(width: 8),
                              InkWell(
                                onTap: _uploading
                                    ? null
                                    : () => _changeDetailImage(badge),
                                borderRadius: BorderRadius.circular(16),
                                child: SizedBox(
                                  width: 68,
                                  height: 52,
                                  child: _badgeImage(
                                    imageUrl: badge.detailImageUrl,
                                    assetPath: '',
                                    name: badge.name,
                                    id: badge.id,
                                    emptyHint: 'Açılan',
                                  ),
                                ),
                              ),
                            ],
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
                                tooltip: badge.imageUrl.trim().isEmpty
                                    ? 'İkon Yükle'
                                    : 'İkonu Değiştir',
                                onPressed: _uploading
                                    ? null
                                    : () => _changeImage(badge),
                                icon: const Icon(
                                  Icons.image_outlined,
                                  size: 19,
                                ),
                              ),
                              IconButton(
                                tooltip: 'İkonu Sil',
                                onPressed: _uploading ||
                                        badge.imageUrl.trim().isEmpty
                                    ? null
                                    : () => _removeImage(badge),
                                icon: const Icon(
                                  Icons.hide_image_outlined,
                                  size: 19,
                                ),
                              ),
                              IconButton(
                                tooltip: badge.detailImageUrl.trim().isEmpty
                                    ? 'Açılan Görsel Yükle'
                                    : 'Açılan Görseli Değiştir',
                                onPressed: _uploading
                                    ? null
                                    : () => _changeDetailImage(badge),
                                icon: const Icon(
                                  Icons.photo_outlined,
                                  size: 19,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Açılan Görseli Sil',
                                onPressed: _uploading ||
                                        badge.detailImageUrl.trim().isEmpty
                                    ? null
                                    : () => _removeDetailImage(badge),
                                icon: const Icon(
                                  Icons.hide_image_outlined,
                                  size: 19,
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

  Widget _imageSlot({
    required String title,
    required String imageUrl,
    required String assetPath,
    required String name,
    required bool uploading,
    required Future<void> Function() onUpload,
    required VoidCallback? onDelete,
    String? id,
    String emptyHint = '',
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: AppColors.text,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: _badgeImage(
            imageUrl: imageUrl,
            assetPath: assetPath,
            name: name,
            id: id,
            size: 110,
            emptyHint: emptyHint,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: uploading ? null : onUpload,
          icon: const Icon(Icons.upload_rounded, size: 18),
          label: Text(
            uploading
                ? 'Yükleniyor...'
                : (imageUrl.trim().isEmpty ? 'Yükle' : 'Değiştir'),
          ),
        ),
        const SizedBox(height: 6),
        OutlinedButton.icon(
          onPressed: uploading ? null : onDelete,
          icon: const Icon(Icons.delete_outline_rounded, size: 18),
          label: const Text('Sil'),
        ),
      ],
    );
  }

  Widget _badgeImage({
    required String imageUrl,
    required String assetPath,
    required String name,
    String? id,
    double? size,
    String emptyHint = '',
  }) {
    final badge = AppTrustBadge(
      id: id ?? '',
      name: name,
      imageUrl: imageUrl,
      assetPath: assetPath,
    );
    final url = emptyHint.isNotEmpty
        ? imageUrl.trim()
        : TrustBadgeRepository.displayImageUrl(badge);
    final asset = emptyHint.isNotEmpty
        ? ''
        : TrustBadgeRepository.displayAssetPath(badge);
    final isRating = TrustBadgeRepository.isRatingBadge(badge);
    final fallback = emptyHint.isNotEmpty
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.add_photo_alternate_outlined,
                  color: AppColors.primary,
                  size: 22,
                ),
                const SizedBox(height: 2),
                Text(
                  emptyHint,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          )
        : isRating
        ? const Icon(
            Icons.star_rounded,
            color: AppColors.warning,
            size: 28,
          )
        : Center(
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
    final image = url.isNotEmpty
        ? buildProductImage(
            url,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorWidget: fallback,
          )
        : asset.isNotEmpty
        ? buildProductImage(
            asset,
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
}
