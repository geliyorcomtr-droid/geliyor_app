import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminProductAdvantagesScreen extends StatefulWidget {
  const AdminProductAdvantagesScreen({super.key});

  @override
  State<AdminProductAdvantagesScreen> createState() =>
      _AdminProductAdvantagesScreenState();
}

class _AdminProductAdvantagesScreenState
    extends State<AdminProductAdvantagesScreen> {
  bool _loading = true;
  bool _uploading = false;
  final _search = TextEditingController();

  @override
  void initState() {
    super.initState();
    _seed();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _seed() async {
    try {
      await ProductAdvantageRepository.instance.ensureDefaults();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ürün avantajları yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _edit(AppProductAdvantage? existing, int nextOrder) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    final value = TextEditingController(text: existing?.value ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    final order = TextEditingController(
      text: '${existing?.order ?? nextOrder}',
    );
    var active = existing?.active ?? true;
    var isStat = existing?.isStat ?? false;
    var dialogUploading = false;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Ürün Avantajı Ekle' : 'Avantajı Düzenle',
          ),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _image(
                    imageUrl: imageUrl.text,
                    assetPath: existing?.assetPath ?? '',
                    name: name.text,
                    size: 104,
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: isStat ? 'Etiket (ör. Protein İçerir)' : 'Avantaj adı',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => setDialogState(() => isStat = !isStat),
                      borderRadius: BorderRadius.circular(18),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        child: Row(
                          children: [
                            const Expanded(
                              child: Text(
                                'İstatistik kartı (ikon yerine değer göster)',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Switch(
                              value: isStat,
                              onChanged: (v) => setDialogState(() => isStat = v),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (isStat) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: value,
                      decoration: const InputDecoration(
                        labelText: 'Varsayılan değer (ör. % 41)',
                        helperText:
                            'Ürün formunda ürüne özel değer girilebilir.',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  if (!isStat) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: description,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
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
                  if (!isStat) ...[
                    TextField(
                      controller: imageUrl,
                      decoration: const InputDecoration(
                        labelText: 'Görsel URL',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: dialogUploading
                          ? null
                          : () async {
                              setDialogState(() => dialogUploading = true);
                              final url = await _pickAndUpload();
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
                    const SizedBox(height: 10),
                  ],
                  Material(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      onTap: () => setDialogState(() => active = !active),
                      borderRadius: BorderRadius.circular(18),
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
        ),
      ),
    );

    final itemName = name.text.trim();
    final itemDescription = description.text.trim();
    final itemValue = value.text.trim();
    final uploadedImage = imageUrl.text.trim();
    final itemOrder = int.tryParse(order.text.trim()) ?? nextOrder;
    name.dispose();
    description.dispose();
    value.dispose();
    imageUrl.dispose();
    order.dispose();
    if (save != true || itemName.isEmpty) return;

    await ProductAdvantageRepository.instance.save(
      AppProductAdvantage(
        id: existing?.id ?? _slugId(itemName),
        name: itemName,
        description: itemDescription,
        value: itemValue,
        isStat: isStat,
        imageUrl: uploadedImage,
        assetPath: existing?.assetPath ?? '',
        order: itemOrder,
        active: active,
      ),
    );
  }

  Future<void> _changeImage(AppProductAdvantage item) async {
    final url = await _pickAndUpload();
    if (url == null) return;
    await ProductAdvantageRepository.instance.save(
      item.copyWith(imageUrl: url),
    );
  }

  Future<void> _toggle(AppProductAdvantage item) async {
    await ProductAdvantageRepository.instance.save(
      item.copyWith(active: !item.active),
    );
  }

  Future<void> _delete(AppProductAdvantage item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Ürün avantajını kaldır'),
        content: Text('"${item.name}" listeden kaldırılsın mı?'),
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
    if (confirmed == true) {
      await ProductAdvantageRepository.instance.delete(item.id);
    }
  }

  Future<String?> _pickAndUpload() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final ref = FirebaseStorage.instance.ref(
        'product_advantages/'
        '${DateTime.now().microsecondsSinceEpoch}_$safeName',
      );
      await ref.putData(
        bytes,
        SettableMetadata(contentType: _contentType(file.name)),
      );
      return ref.getDownloadURL();
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
    return StreamBuilder<List<AppProductAdvantage>>(
      stream: ProductAdvantageRepository.instance.watchAll(),
      builder: (context, snapshot) {
        if (_loading || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final items = snapshot.data!;
        final query = _search.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? items
            : items
                  .where((item) => item.name.toLowerCase().contains(query))
                  .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Ürün Avantajları',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Ürün detayında görselin sağında gösterilen avantajları yönetin.',
              style: TextStyle(
                color: AppColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            Row(
              children: [
                Text(
                  'Toplam ${items.length} Sonuç',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: _uploading
                      ? null
                      : () => _edit(null, items.length),
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                  label: const Text('Yeni Ekle'),
                ),
                const SizedBox(width: 10),
                SizedBox(
                  width: 190,
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Ara',
                      suffixIcon: Icon(Icons.search_rounded),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (items.isEmpty) _empty() else _table(filtered, items.length),
          ],
        );
      },
    );
  }

  Widget _table(List<AppProductAdvantage> items, int nextOrder) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: DataTable(
              headingRowColor: const WidgetStatePropertyAll(AppColors.selected),
              headingRowHeight: 46,
              dataRowMinHeight: 72,
              dataRowMaxHeight: 72,
              columns: const [
                DataColumn(label: Text('Resim')),
                DataColumn(label: Text('Avantaj Adı')),
                DataColumn(label: Text('Sıra No')),
                DataColumn(label: Text('Yayın Durumu')),
                DataColumn(label: Text('İşlem')),
              ],
              rows: [
                for (final item in items)
                  DataRow(
                    cells: [
                      DataCell(
                        InkWell(
                          onTap: _uploading ? null : () => _changeImage(item),
                          child: SizedBox(
                            width: 68,
                            height: 54,
                            child: _image(
                              imageUrl: item.imageUrl,
                              assetPath: item.assetPath,
                              name: item.name,
                            ),
                          ),
                        ),
                      ),
                      DataCell(
                        SizedBox(
                          width: 280,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              if (item.description.isNotEmpty)
                                Text(
                                  item.description,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: AppColors.subText,
                                    fontSize: 11,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                      DataCell(Text('${item.order}')),
                      DataCell(
                        TextButton(
                          onPressed: () => _toggle(item),
                          child: Text(
                            item.active ? 'Aktif' : 'Pasif',
                            style: TextStyle(
                              color: item.active
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
                              tooltip: 'Görsel Ekle / Değiştir',
                              onPressed: _uploading
                                  ? null
                                  : () => _changeImage(item),
                              icon: const Icon(Icons.image_outlined),
                            ),
                            IconButton(
                              tooltip: 'Düzenle',
                              onPressed: () => _edit(item, nextOrder),
                              icon: const Icon(Icons.edit_outlined),
                            ),
                            IconButton(
                              tooltip: 'Sil',
                              onPressed: () => _delete(item),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _image({
    required String imageUrl,
    required String assetPath,
    required String name,
    double? size,
  }) {
    final fallback = Center(
      child: Text(
        name.isEmpty ? '?' : name.characters.first,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final isProtein = name.toLowerCase().contains('protein');
    final resolvedAsset = isProtein
        ? ProductAdvantageRepository.proteinIconPath
        : assetPath;
    final child = imageUrl.isNotEmpty
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
      child: child,
    );
  }

  Widget _empty() {
    return Container(
      height: 180,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: const Text('Henüz ürün avantajı yok.'),
    );
  }

  String _slugId(String name) {
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
    return '${slug.isEmpty ? 'avantaj' : slug}-'
        '${DateTime.now().millisecondsSinceEpoch}';
  }

  String _contentType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
