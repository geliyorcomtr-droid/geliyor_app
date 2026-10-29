import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/product_advantage_category.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:geliyor_app/utils/storage_metadata.dart';
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
  bool _moving = false;
  final _search = TextEditingController();
  final _expandedCategoryIds = <String>{};

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
        SnackBar(content: Text('Ürün özellikleri yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editOverlayTemplate() async {
    var imageUrl = '';
    try {
      imageUrl =
          await ProductAdvantageRepository.instance.fetchOverlayTemplateUrl();
    } catch (_) {}
    if (!mounted) return;
    var dialogUploading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> upload() async {
            setDialogState(() => dialogUploading = true);
            final url = await _pickAndUpload(
              style: UploadImageStyle.photo,
              folder: 'product_advantages/overlay',
            );
            if (url != null) {
              await ProductAdvantageRepository.instance
                  .saveOverlayTemplateUrl(url);
              imageUrl = url;
            }
            setDialogState(() => dialogUploading = false);
          }

          Future<void> remove() async {
            if (imageUrl.trim().isEmpty) return;
            final confirmed = await showDialog<bool>(
              context: dialogContext,
              builder: (confirmContext) => AlertDialog(
                title: const Text('Kalıbı sil'),
                content: const Text(
                  'Açılan görsel kalıbı silinsin mi? '
                  'İkonlara tıklanınca arka plan boş kalır.',
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(confirmContext, false),
                    child: const Text('Vazgeç'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(confirmContext, true),
                    child: const Text('Sil'),
                  ),
                ],
              ),
            );
            if (confirmed != true) return;
            await ProductAdvantageRepository.instance.saveOverlayTemplateUrl('');
            setDialogState(() => imageUrl = '');
          }

          return AlertDialog(
            title: const Text('Açılan görsel kalıbı'),
            content: SizedBox(
              width: 420,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Bu görsel bütün ürün özelliği ikonlarına tıklanınca arka plan olur. '
                      'Başlık ve açıklama otomatik biner.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _imageSlot(
                      title: 'Kalıp görsel',
                      imageUrl: imageUrl,
                      assetPath: '',
                      name: '',
                      emptyHint: 'Yükle',
                      uploading: dialogUploading,
                      onUpload: upload,
                      onDelete: imageUrl.trim().isEmpty ? null : remove,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              OutlinedButton.icon(
                onPressed: dialogUploading || imageUrl.trim().isEmpty
                    ? null
                    : remove,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Sil'),
              ),
              OutlinedButton.icon(
                onPressed: dialogUploading ? null : upload,
                icon: const Icon(Icons.upload_rounded, size: 18),
                label: Text(
                  dialogUploading
                      ? 'Yükleniyor...'
                      : (imageUrl.trim().isEmpty ? 'Yükle' : 'Değiştir'),
                ),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text('Tamam'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _edit(
    AppProductAdvantage? existing,
    int nextOrder, {
    required List<ProductAdvantageCategory> categories,
  }) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final fullName = TextEditingController(text: existing?.fullName ?? '');
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
    final fallbackCategoryId = categories.any(
          (category) => category.id == ProductAdvantageCategory.diger.id,
        )
        ? ProductAdvantageCategory.diger.id
        : (categories.isEmpty
              ? ProductAdvantageCategory.diger.id
              : categories.first.id);
    var categoryId = existing?.resolvedCategoryId ?? fallbackCategoryId;
    if (!categories.any((category) => category.id == categoryId)) {
      categoryId = fallbackCategoryId;
    }
    var dialogUploading = false;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
            existing == null ? 'Ürün Özelliği Ekle' : 'Özelliği Düzenle',
          ),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _imageSlot(
                    title: 'İkon',
                    imageUrl: imageUrl.text,
                    assetPath:
                        (existing?.assetPath.trim().isNotEmpty ?? false)
                        ? existing!.assetPath
                        : ProductAdvantageRepository.defaultAssetPathForId(
                            existing?.id ?? '',
                            name: name.text,
                            isStat: isStat,
                          ),
                    name: name.text,
                    uploading: dialogUploading,
                    onUpload: () async {
                      setDialogState(() => dialogUploading = true);
                      final url = await _pickAndUpload();
                      if (url != null) imageUrl.text = url;
                      setDialogState(() => dialogUploading = false);
                    },
                    onDelete: imageUrl.text.trim().isEmpty
                        ? null
                        : () => setDialogState(() => imageUrl.clear()),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      labelText: isStat
                          ? 'Etiket (ör. Protein Değeri)'
                          : 'Özellik adı',
                      helperText: isStat
                          ? null
                          : 'İkon kartında görünen kısa ad (ör. B. pudra, Emici)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  if (!isStat) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: fullName,
                      decoration: const InputDecoration(
                        labelText: 'Tam ad',
                        helperText:
                            'İkona tıklanınca açılan başlık (ör. Bebek pudrası, Hızlı emici özellikli)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    value: categoryId,
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      for (final category in categories)
                        DropdownMenuItem(
                          value: category.id,
                          child: Text(category.label),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialogState(() => categoryId = value);
                    },
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
                      maxLines: 6,
                      style: const TextStyle(fontSize: 15, height: 1.35),
                      decoration: const InputDecoration(
                        labelText: 'Açıklama',
                        helperText:
                            'İkona tıklanınca kalıp görselin beyaz alanına yazılır.',
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
                  const SizedBox(height: 10),
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
    final itemFullName = fullName.text.trim();
    final itemDescription = description.text.trim();
    final itemValue = value.text.trim();
    final uploadedImage = imageUrl.text.trim();
    final itemOrder = int.tryParse(order.text.trim()) ?? nextOrder;
    name.dispose();
    fullName.dispose();
    description.dispose();
    value.dispose();
    imageUrl.dispose();
    order.dispose();
    if (save != true || itemName.isEmpty) return;

    final id = existing?.id ?? _slugId(itemName);
    await ProductAdvantageRepository.instance.save(
      AppProductAdvantage(
        id: id,
        name: itemName,
        fullName: itemFullName,
        description: itemDescription,
        value: itemValue,
        isStat: isStat,
        imageUrl: uploadedImage,
        detailImageUrl: existing?.detailImageUrl ?? '',
        assetPath: uploadedImage.isNotEmpty
            ? ''
            : ProductAdvantageRepository.defaultAssetPathForId(
                id,
                name: itemName,
                isStat: isStat,
              ),
        order: itemOrder,
        categoryId: categoryId,
        active: active,
      ),
    );
  }

  Future<void> _changeImage(AppProductAdvantage item) async {
    final url = await _pickAndUpload();
    if (url == null) return;
    await ProductAdvantageRepository.instance.save(
      item.copyWith(imageUrl: url, assetPath: ''),
    );
  }

  Future<void> _removeImage(AppProductAdvantage item) async {
    if (item.imageUrl.trim().isEmpty) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Görseli sil'),
        content: Text('"${item.name}" için yüklenen görsel silinsin mi?'),
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
    await ProductAdvantageRepository.instance.save(
      item.copyWith(
        imageUrl: '',
        assetPath: ProductAdvantageRepository.defaultAssetPathForId(
          item.id,
          name: item.name,
          isStat: item.isStat,
        ),
      ),
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
        title: const Text('Ürün özelliğini kaldır'),
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

  Future<void> _addCategory() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Yeni kategori'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Kategori adı',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(dialogContext, true),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    try {
      if (ok != true) return;
      if (name.text.trim().isEmpty) return;
      await ProductAdvantageRepository.instance.addCategory(name.text);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori eklenemedi: $error')),
      );
    } finally {
      name.dispose();
    }
  }

  Future<void> _renameCategory(ProductAdvantageCategory category) async {
    final name = TextEditingController(text: category.label);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategori adını değiştir'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Kategori adı',
            border: OutlineInputBorder(),
          ),
          onSubmitted: (_) => Navigator.pop(dialogContext, true),
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
    );
    try {
      if (ok != true) return;
      final next = name.text.trim();
      if (next.isEmpty || next == category.label.trim()) return;
      await ProductAdvantageRepository.instance.renameCategory(
        categoryId: category.id,
        label: next,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori adı "$next" olarak kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori adı değiştirilemedi: $error')),
      );
    } finally {
      name.dispose();
    }
  }

  Future<void> _editCategoryColor(ProductAdvantageCategory category) async {
    final color = TextEditingController(text: category.color);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) {
          final parsed = _categoryColor(color.text);
          return AlertDialog(
            title: Text('${category.label} rengi'),
            content: SizedBox(
              width: 360,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: parsed,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: color,
                    autofocus: true,
                    onChanged: (_) => setDialogState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Renk kodu',
                      hintText: ProductAdvantageCategory.defaultColorHex,
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => Navigator.pop(dialogContext, true),
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
    try {
      if (ok != true) return;
      final next = ProductAdvantageCategory.normalizeColor(color.text);
      if (next.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Renk kodu #RRGGBB formatında olmalı.')),
        );
        return;
      }
      if (next == category.color) return;
      await ProductAdvantageRepository.instance.setCategoryColor(
        categoryId: category.id,
        color: next,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${category.label} rengi $next olarak kaydedildi.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Renk kaydedilemedi: $error')),
      );
    } finally {
      color.dispose();
    }
  }

  Color _categoryColor(String raw) {
    final normalized = ProductAdvantageCategory.normalizeColor(raw);
    final hex = normalized.isEmpty
        ? ProductAdvantageCategory.defaultColorHex
        : normalized;
    final value = int.tryParse(hex.substring(1), radix: 16) ??
        int.parse(
          ProductAdvantageCategory.defaultColorHex.substring(1),
          radix: 16,
        );
    return Color(0xFF000000 | value);
  }

  Future<void> _deleteCategory({
    required ProductAdvantageCategory category,
    required List<AppProductAdvantage> catalog,
    required List<ProductAdvantageCategory> categories,
  }) async {
    if (categories.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('En az bir kategori kalmalı.')),
      );
      return;
    }
    final remaining = [
      for (final item in categories)
        if (item.id != category.id) item,
    ];
    final fallback = remaining.any(
          (item) => item.id == ProductAdvantageCategory.diger.id,
        )
        ? ProductAdvantageCategory.diger
        : remaining.first;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kategoriyi sil'),
        content: Text(
          '"${category.label}" silinsin mi? İçindeki özellikler '
          '"${fallback.label}" kategorisine taşınır.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ProductAdvantageRepository.instance.deleteCategory(
        categoryId: category.id,
        catalog: catalog,
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kategori silinemedi: $error')),
      );
    }
  }

  Future<String?> _pickAndUpload({
    UploadImageStyle style = UploadImageStyle.icon,
    String folder = 'product_advantages',
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
      final ref = FirebaseStorage.instance.ref(
        '$folder/'
        '${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await ref.putData(
        prepared.bytes,
        storageImageMetadata(prepared.contentType),
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
    return StreamBuilder<List<ProductAdvantageCategory>>(
      stream: ProductAdvantageRepository.instance.watchCategories(),
      initialData: ProductAdvantageRepository.instance.cachedCategories,
      builder: (context, categorySnapshot) {
        final categories =
            categorySnapshot.data ?? ProductAdvantageCategory.values;
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
                      .where(
                        (item) =>
                            item.name.toLowerCase().contains(query) ||
                            item.fullName.toLowerCase().contains(query),
                      )
                      .toList();
            return ListView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
              children: [
                const Text(
                  'Öne Çıkan Özellikler',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.text,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ürün detayında görselin sağında ilk 5, altta en fazla 6 özellik gösterilir. '
                  'Özellikleri kategorilere sürükleyerek ayırın; bir öğeyi başka grubun içine bırakınca o kategoriye geçer. '
                  'Kategori adını “Adı değiştir” ile güncelleyebilirsiniz.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 14),
                const Divider(height: 1, color: AppColors.border),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(
                      'Toplam ${items.length} Sonuç',
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    FilledButton.icon(
                      onPressed: _uploading
                          ? null
                          : () => _edit(
                              null,
                              items.length,
                              categories: categories,
                            ),
                      icon: const Icon(
                        Icons.add_circle_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Yeni ikon'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _uploading ? null : _addCategory,
                      icon: const Icon(Icons.create_new_folder_outlined, size: 18),
                      label: const Text('Yeni kategori'),
                    ),
                    OutlinedButton.icon(
                      onPressed: _uploading ? null : _editOverlayTemplate,
                      icon: const Icon(Icons.photo_outlined, size: 18),
                      label: const Text('Açılan görsel'),
                    ),
                    SizedBox(
                      width: 160,
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
                const SizedBox(height: 14),
                if (items.isEmpty)
                  _empty()
                else
                  _boards(filtered, items, categories),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _move({
    required List<AppProductAdvantage> catalog,
    required List<ProductAdvantageCategory> categories,
    required String id,
    required String categoryId,
    String? beforeId,
  }) async {
    if (_moving) return;
    _moving = true;
    setState(() {});
    try {
      await ProductAdvantageRepository.instance.moveToCategory(
        catalog: catalog,
        id: id,
        categoryId: categoryId,
        beforeId: beforeId,
        categories: categories,
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

  bool _isCategoryExpanded(
    ProductAdvantageCategory category,
    List<AppProductAdvantage> items,
  ) {
    if (_search.text.trim().isNotEmpty && items.isNotEmpty) return true;
    return _expandedCategoryIds.contains(category.id);
  }

  void _toggleCategory(String id) {
    setState(() {
      if (_expandedCategoryIds.contains(id)) {
        _expandedCategoryIds.remove(id);
      } else {
        _expandedCategoryIds.add(id);
      }
    });
  }

  Widget _boards(
    List<AppProductAdvantage> visible,
    List<AppProductAdvantage> catalog,
    List<ProductAdvantageCategory> categories,
  ) {
    final grouped = ProductAdvantageRepository.grouped(
      visible,
      categories: categories,
    );
    return Column(
      children: [
        for (final category in categories) ...[
          const SizedBox(height: 12),
          _categoryBoard(
            category: category,
            items: grouped[category.id] ?? const [],
            catalog: catalog,
            categories: categories,
          ),
        ],
      ],
    );
  }

  Widget _categoryBoard({
    required ProductAdvantageCategory category,
    required List<AppProductAdvantage> items,
    required List<AppProductAdvantage> catalog,
    required List<ProductAdvantageCategory> categories,
  }) {
    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          !_moving && details.data.trim().isNotEmpty,
      onAcceptWithDetails: (details) {
        _move(
          catalog: catalog,
          categories: categories,
          id: details.data,
          categoryId: category.id,
        );
      },
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        final expanded = _isCategoryExpanded(category, items);
        return AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          width: double.infinity,
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
              Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 8, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () => _toggleCategory(category.id),
                          borderRadius: BorderRadius.circular(18),
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
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
                                    category.label,
                                    style: _headStyle,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${items.length}',
                                  style: const TextStyle(
                                    color: AppColors.subText,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _moving || _uploading
                          ? null
                          : () => _renameCategory(category),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Adı değiştir'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                    Tooltip(
                      message: category.color,
                      child: InkWell(
                        onTap: _moving || _uploading
                            ? null
                            : () => _editCategoryColor(category),
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _categoryColor(category.color),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: _moving || _uploading
                          ? null
                          : () => _editCategoryColor(category),
                      style: TextButton.styleFrom(
                        foregroundColor: _categoryColor(category.color),
                        visualDensity: VisualDensity.compact,
                      ),
                      child: const Text('Renk'),
                    ),
                    TextButton.icon(
                      onPressed: _moving ||
                              _uploading ||
                              categories.length <= 1
                          ? null
                          : () => _deleteCategory(
                              category: category,
                              catalog: catalog,
                              categories: categories,
                            ),
                      icon: const Icon(
                        Icons.delete_outline_rounded,
                        size: 18,
                      ),
                      label: const Text('Sil'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.subText,
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
              if (expanded) ...[
                if (items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.fromLTRB(12, 0, 12, 14),
                    child: Text(
                      'Bu kategoride henüz özellik yok.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  )
                else
                  for (var i = 0; i < items.length; i++)
                    _advantageRow(
                      item: items[i],
                      catalog: catalog,
                      categories: categories,
                      showDivider: i > 0,
                      nextOrder: catalog.length,
                    ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _advantageRow({
    required AppProductAdvantage item,
    required List<AppProductAdvantage> catalog,
    required List<ProductAdvantageCategory> categories,
    required bool showDivider,
    required int nextOrder,
  }) {
    final row = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          const MouseRegion(
            cursor: SystemMouseCursors.grab,
            child: Icon(
              Icons.drag_indicator_rounded,
              color: AppColors.subText,
            ),
          ),
          const SizedBox(width: 6),
          SizedBox(
            width: 52,
            height: 44,
            child: InkWell(
              onTap: _uploading ? null : () => _changeImage(item),
              onLongPress: _uploading || item.imageUrl.trim().isEmpty
                  ? null
                  : () => _removeImage(item),
              child: KeyedSubtree(
                key: ValueKey(item.id),
                child: _image(
                  imageUrl: ProductAdvantageRepository.displayImageUrl(item),
                  assetPath: ProductAdvantageRepository.displayAssetPath(item),
                  name: item.name,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                if (item.fullName.trim().isNotEmpty &&
                    item.fullName.trim() != item.name.trim())
                  Text(
                    item.fullName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                if (item.description.isNotEmpty)
                  Text(
                    item.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 13,
                      height: 1.35,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 64,
            child: TextButton(
              onPressed: () => _toggle(item),
              style: TextButton.styleFrom(
                padding: EdgeInsets.zero,
                visualDensity: VisualDensity.compact,
              ),
              child: Text(
                item.active ? 'Aktif' : 'Pasif',
                style: TextStyle(
                  color: item.active ? AppColors.success : AppColors.error,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          PopupMenuButton<String>(
            tooltip: 'Kategoriye taşı',
            enabled: !_moving,
            onSelected: (categoryId) {
              _move(
                catalog: catalog,
                categories: categories,
                id: item.id,
                categoryId: categoryId,
              );
            },
            itemBuilder: (context) => [
              for (final category in categories)
                if (category.id != item.resolvedCategoryId)
                  PopupMenuItem(
                    value: category.id,
                    child: Text(category.label),
                  ),
            ],
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Text(
                'Taşı',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 84,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  tooltip: 'Düzenle',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () =>
                      _edit(item, nextOrder, categories: categories),
                  icon: const Icon(Icons.edit_outlined, size: 20),
                ),
                IconButton(
                  tooltip: 'Sil',
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 36,
                    minHeight: 36,
                  ),
                  onPressed: () => _delete(item),
                  icon: const Icon(
                    Icons.delete_outline_rounded,
                    size: 20,
                    color: AppColors.error,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );

    return DragTarget<String>(
      onWillAcceptWithDetails: (details) =>
          !_moving && details.data != item.id,
      onAcceptWithDetails: (details) {
        _move(
          catalog: catalog,
          categories: categories,
          id: details.data,
          categoryId: item.resolvedCategoryId,
          beforeId: item.id,
        );
      },
      builder: (context, candidate, _) {
        final hovering = candidate.isNotEmpty;
        return Draggable<String>(
          data: item.id,
          maxSimultaneousDrags: _moving ? 0 : 1,
          feedback: Material(
            elevation: 8,
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            child: SizedBox(
              width: 280,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(
                  item.name,
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

  static const _headStyle = TextStyle(
    fontWeight: FontWeight.w800,
    fontSize: 13,
    color: AppColors.text,
  );

  Widget _imageSlot({
    required String title,
    required String imageUrl,
    required String assetPath,
    required String name,
    required bool uploading,
    required Future<void> Function() onUpload,
    required VoidCallback? onDelete,
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
          child: _image(
            imageUrl: imageUrl,
            assetPath: assetPath,
            name: name,
            size: 104,
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

  Widget _image({
    required String imageUrl,
    required String assetPath,
    required String name,
    double? size,
    String emptyHint = '',
  }) {
    final fallback = Center(
      child: emptyHint.isNotEmpty
          ? Column(
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
            )
          : Text(
              name.isEmpty ? '?' : name.characters.first,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            ),
    );
    final resolvedAsset = emptyHint.isNotEmpty
        ? ''
        : (assetPath.trim().isNotEmpty
            ? assetPath.trim()
            : (name.toLowerCase().contains('protein')
                ? ProductAdvantageRepository.proteinIconPath
                : ''));
    final child = imageUrl.trim().isNotEmpty
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
      child: const Text('Henüz ürün özelliği yok.'),
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
}
