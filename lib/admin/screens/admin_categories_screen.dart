import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/category_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({super.key});

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  bool _seeding = false;
  bool _uploading = false;
  String? _selectedMainId;

  @override
  void initState() {
    super.initState();
    _seedIfNeeded();
  }

  Future<void> _seedIfNeeded() async {
    setState(() => _seeding = true);
    try {
      await CategoryRepository.instance.ensureDefaults();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kategoriler yüklenemedi: $e')));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _editMain(AdminMainCategory? existing) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final id = TextEditingController(text: existing?.id ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    final isNew = existing == null;
    var uploading = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isNew ? 'Ana Kategori Ekle' : 'Ana Kategori Düzenle'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _categoryImageSized(
                        imageUrl.text,
                        fallback: title.text.trim().isEmpty
                            ? '?'
                            : title.text.trim().characters.first,
                        size: 92,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: imageUrl,
                              decoration: const InputDecoration(
                                labelText: 'Görsel URL',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: uploading
                                  ? null
                                  : () async {
                                      setDialogState(() => uploading = true);
                                      final url = await _pickAndUploadImage(
                                        'categories/main',
                                      );
                                      if (url != null) {
                                        imageUrl.text = url;
                                      }
                                      setDialogState(() => uploading = false);
                                    },
                              icon: const Icon(Icons.upload_rounded),
                              label: Text(
                                uploading ? 'Yükleniyor...' : 'Görsel Yükle',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: id,
                    enabled: isNew,
                    decoration: const InputDecoration(
                      labelText: 'Kod (ör. cat, dog, smart)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Başlık (ör. Kedi)',
                      border: OutlineInputBorder(),
                    ),
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
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    if (ok != true) {
      title.dispose();
      id.dispose();
      imageUrl.dispose();
      return;
    }

    final code = id.text.trim().toLowerCase().replaceAll(' ', '_');
    final name = title.text.trim();
    final image = imageUrl.text.trim();
    title.dispose();
    id.dispose();
    imageUrl.dispose();
    if (code.isEmpty || name.isEmpty) return;

    final category = AdminMainCategory(
      id: code,
      title: name,
      order: existing?.order ?? 99,
      active: existing?.active ?? true,
      imageUrl: image,
      subcategories: existing?.subcategories ?? const [],
    );
    await CategoryRepository.instance.saveMain(category);
    setState(() => _selectedMainId = code);
  }

  Future<void> _deleteMain(AdminMainCategory category) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ana kategoriyi sil'),
        content: Text(
          '"${category.title}" ve tüm alt kategorileri silinsin mi?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await CategoryRepository.instance.deleteMain(category.id);
    if (_selectedMainId == category.id) {
      setState(() => _selectedMainId = null);
    }
  }

  Future<void> _editSub(
    AdminMainCategory main,
    AdminSubCategory? existing,
  ) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final subtitle = TextEditingController(text: existing?.subtitle ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    final isNew = existing == null;
    var uploading = false;

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isNew ? 'Alt Kategori Ekle' : 'Alt Kategori Düzenle'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _categoryImageSized(
                        imageUrl.text,
                        fallback: title.text.trim().isEmpty
                            ? '?'
                            : title.text.trim().characters.first,
                        size: 92,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          children: [
                            TextField(
                              controller: imageUrl,
                              decoration: const InputDecoration(
                                labelText: 'Görsel URL',
                                border: OutlineInputBorder(),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: uploading
                                  ? null
                                  : () async {
                                      setDialogState(() => uploading = true);
                                      final url = await _pickAndUploadImage(
                                        'categories/sub',
                                      );
                                      if (url != null) {
                                        imageUrl.text = url;
                                      }
                                      setDialogState(() => uploading = false);
                                    },
                              icon: const Icon(Icons.upload_rounded),
                              label: Text(
                                uploading ? 'Yükleniyor...' : 'Görsel Yükle',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(
                      labelText: 'Başlık (ör. Mama)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: subtitle,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Açıklama',
                      border: OutlineInputBorder(),
                    ),
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
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );

    final name = title.text.trim();
    final desc = subtitle.text.trim();
    final image = imageUrl.text.trim();
    title.dispose();
    subtitle.dispose();
    imageUrl.dispose();
    if (ok != true || name.isEmpty) return;

    final subs = [...main.subcategories];
    if (isNew) {
      subs.add(
        AdminSubCategory(
          id: '${main.id}-${DateTime.now().millisecondsSinceEpoch}',
          title: name,
          subtitle: desc,
          imageUrl: image,
          order: subs.length,
        ),
      );
    } else {
      final i = subs.indexWhere((s) => s.id == existing.id);
      if (i >= 0) {
        subs[i] = existing.copyWith(
          title: name,
          subtitle: desc,
          imageUrl: image,
        );
      }
    }
    await CategoryRepository.instance.saveSubs(main.id, subs);
  }

  Future<void> _changeMainImage(AdminMainCategory category) async {
    final url = await _pickAndUploadImage('categories/main');
    if (url == null) return;
    await CategoryRepository.instance.saveMain(
      AdminMainCategory(
        id: category.id,
        title: category.title,
        imageUrl: url,
        order: category.order,
        active: category.active,
        subcategories: category.subcategories,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${category.title} görseli güncellendi.')),
    );
  }

  Future<void> _changeSubImage(
    AdminMainCategory main,
    AdminSubCategory sub,
  ) async {
    final url = await _pickAndUploadImage('categories/sub');
    if (url == null) return;
    final subs = [...main.subcategories];
    final index = subs.indexWhere((item) => item.id == sub.id);
    if (index < 0) return;
    subs[index] = sub.copyWith(imageUrl: url);
    await CategoryRepository.instance.saveSubs(main.id, subs);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${sub.title} görseli güncellendi.')),
    );
  }

  Future<String?> _pickAndUploadImage(String folder) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final ref = FirebaseStorage.instance.ref(
        '$folder/${DateTime.now().microsecondsSinceEpoch}_$safeName',
      );
      final metadata = SettableMetadata(
        contentType: _contentTypeFor(file.name),
      );
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Görsel yüklenemedi: $e')));
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _deleteSub(AdminMainCategory main, AdminSubCategory sub) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alt kategoriyi sil'),
        content: Text('"${sub.title}" silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    final subs = main.subcategories.where((s) => s.id != sub.id).toList();
    for (var i = 0; i < subs.length; i++) {
      subs[i] = subs[i].copyWith(order: i);
    }
    await CategoryRepository.instance.saveSubs(main.id, subs);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AdminMainCategory>>(
      stream: CategoryRepository.instance.watchAll(),
      builder: (context, snap) {
        if (_seeding || !snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError) {
          return Center(child: Text('Hata: ${snap.error}'));
        }

        final mains = snap.data!;
        final selectedId =
            _selectedMainId ?? (mains.isNotEmpty ? mains.first.id : null);
        final selected = mains.cast<AdminMainCategory?>().firstWhere(
          (c) => c?.id == selectedId,
          orElse: () => mains.isEmpty ? null : mains.first,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Kategoriler',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.text,
                    ),
                  ),
                ),
                FilledButton.icon(
                  onPressed: _uploading ? null : () => _editMain(null),
                  icon: const Icon(Icons.add),
                  label: const Text('Ana Kategori Ekle'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF17A2B8),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Uygulamadaki gibi 3 ana kategori ve alt kategoriler. '
              'Ekle, düzenle veya sil.',
              style: TextStyle(
                color: AppColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, c) {
                final wide = c.maxWidth >= 900;
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: wide ? 320 : c.maxWidth,
                      child: _buildMainList(mains, selectedId),
                    ),
                    if (wide) ...[
                      const SizedBox(width: 16),
                      Expanded(
                        child: selected == null
                            ? _emptyPanel('Ana kategori seçin')
                            : _buildSubPanel(selected),
                      ),
                    ],
                  ],
                );
              },
            ),
            if (MediaQuery.sizeOf(context).width < 900 && selected != null) ...[
              const SizedBox(height: 16),
              _buildSubPanel(selected),
            ],
          ],
        );
      },
    );
  }

  Widget _buildMainRow(AdminMainCategory main, {required bool selected}) {
    return Material(
      color: selected ? AppColors.selected : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedMainId = main.id),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
          child: Row(
            children: [
              InkWell(
                onTap: _uploading ? null : () => _changeMainImage(main),
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    _categoryImage(
                      main.imageUrl,
                      fallback: main.title.characters.first,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 18,
                        height: 18,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 11,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      main.title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      main.imageUrl.isEmpty
                          ? '${main.subcategories.length} alt kategori · görsel yok'
                          : '${main.subcategories.length} alt kategori · görsel var',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.subText,
                      ),
                    ),
                  ],
                ),
              ),
              FilledButton.tonalIcon(
                onPressed: _uploading ? null : () => _changeMainImage(main),
                icon: const Icon(Icons.image_outlined, size: 16),
                label: const Text('Görsel'),
                style: FilledButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                onSelected: (v) {
                  if (v == 'edit') _editMain(main);
                  if (v == 'image') _changeMainImage(main);
                  if (v == 'delete') _deleteMain(main);
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'image',
                    child: Text('Görsel Ekle / Değiştir'),
                  ),
                  PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                  PopupMenuItem(value: 'delete', child: Text('Sil')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubRow(AdminMainCategory main, AdminSubCategory sub) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: Row(
        children: [
          InkWell(
            onTap: _uploading ? null : () => _changeSubImage(main, sub),
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                _categoryImage(
                  sub.imageUrl,
                  fallback: sub.title.characters.first,
                ),
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 16,
                    height: 16,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.camera_alt_rounded,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sub.title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  sub.subtitle.isEmpty
                      ? (sub.imageUrl.isEmpty
                            ? 'Görsel yok'
                            : 'Görsel yüklendi')
                      : sub.subtitle,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.subText,
                  ),
                ),
              ],
            ),
          ),
          FilledButton.tonalIcon(
            onPressed: _uploading ? null : () => _changeSubImage(main, sub),
            icon: const Icon(Icons.image_outlined, size: 16),
            label: const Text('Görsel'),
            style: FilledButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 10),
            ),
          ),
          IconButton(
            tooltip: 'Düzenle',
            onPressed: () => _editSub(main, sub),
            icon: const Icon(Icons.edit_outlined, size: 18),
          ),
          IconButton(
            tooltip: 'Sil',
            onPressed: () => _deleteSub(main, sub),
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppColors.error,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainList(List<AdminMainCategory> mains, String? selectedId) {
    return Container(
      decoration: _panel,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Padding(
            padding: EdgeInsets.fromLTRB(14, 14, 14, 8),
            child: Text(
              'Ana Kategoriler',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
            ),
          ),
          if (mains.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text('Henüz ana kategori yok.'),
            ),
          for (final main in mains)
            _buildMainRow(main, selected: main.id == selectedId),
        ],
      ),
    );
  }

  Widget _buildSubPanel(AdminMainCategory main) {
    return Container(
      decoration: _panel,
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  '${main.title} · Alt Kategoriler',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: () => _editSub(main, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Alt Kategori Ekle'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (main.subcategories.isEmpty)
            _emptyPanel('Bu ana kategoride alt kategori yok.')
          else
            ...main.subcategories.map(
              (sub) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _buildSubRow(main, sub),
              ),
            ),
        ],
      ),
    );
  }

  Widget _emptyPanel(String text) {
    return Container(
      height: 140,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.subText,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _categoryImage(String url, {required String fallback}) {
    return _categoryImageSized(url, fallback: fallback, size: 46);
  }

  Widget _categoryImageSized(
    String url, {
    required String fallback,
    required double size,
  }) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(size >= 80 ? 20 : 16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.trim().isEmpty
          ? Text(
              fallback,
              style: const TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.w900,
              ),
            )
          : Image.network(
              url,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Text(
                fallback,
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
    );
  }

  BoxDecoration get _panel => BoxDecoration(
    color: AppColors.surface,
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: AppColors.border),
  );

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
