import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminBrandsScreen extends StatefulWidget {
  const AdminBrandsScreen({super.key});

  @override
  State<AdminBrandsScreen> createState() => _AdminBrandsScreenState();
}

class _AdminBrandsScreenState extends State<AdminBrandsScreen> {
  bool _seeding = true;
  bool _uploading = false;
  final _search = TextEditingController();
  int _pageSize = 100;

  @override
  void initState() {
    super.initState();
    _seedBrands();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _seedBrands() async {
    try {
      await BrandRepository.instance.ensureDefaults();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Markalar yüklenemedi: $error')));
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<void> _editBrand(AppBrand? existing, int nextOrder) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final imageUrl = TextEditingController(text: existing?.imageUrl ?? '');
    final order = TextEditingController(
      text: '${existing?.order ?? nextOrder}',
    );
    var active = existing?.active ?? true;
    var dialogUploading = false;

    final save = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(existing == null ? 'Marka Ekle' : 'Markayı Düzenle'),
          content: SizedBox(
            width: 520,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _brandImage(
                  imageUrl: imageUrl.text,
                  assetPath: existing?.assetPath ?? '',
                  name: name.text,
                  size: 110,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Marka adı',
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
                          if (url != null) imageUrl.text = url;
                          setDialogState(() => dialogUploading = false);
                        },
                  icon: const Icon(Icons.upload_rounded),
                  label: Text(
                    dialogUploading ? 'Yükleniyor...' : 'Görsel Ekle',
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

    final brandName = name.text.trim();
    final uploadedImage = imageUrl.text.trim();
    final brandOrder = int.tryParse(order.text.trim()) ?? nextOrder;
    name.dispose();
    imageUrl.dispose();
    order.dispose();
    if (save != true || brandName.isEmpty) return;

    final id = existing?.id ?? _brandId(brandName);
    await BrandRepository.instance.save(
      AppBrand(
        id: id,
        name: brandName,
        imageUrl: uploadedImage,
        assetPath: existing?.assetPath ?? '',
        order: brandOrder,
        active: active,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('$brandName kaydedildi.')));
  }

  Future<void> _toggleActive(AppBrand brand) async {
    await BrandRepository.instance.save(brand.copyWith(active: !brand.active));
  }

  Future<void> _changeImage(AppBrand brand) async {
    final url = await _pickAndUploadImage();
    if (url == null) return;
    await BrandRepository.instance.save(brand.copyWith(imageUrl: url));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${brand.name} görseli güncellendi.')),
    );
  }

  Future<void> _deleteBrand(AppBrand brand) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Markayı kaldır'),
        content: Text('"${brand.name}" marka listesinden kaldırılsın mı?'),
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
    await BrandRepository.instance.delete(brand.id);
  }

  Future<String?> _pickAndUploadImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      final safeName = file.name.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final reference = FirebaseStorage.instance.ref(
        'brands/${DateTime.now().microsecondsSinceEpoch}_$safeName',
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
    return StreamBuilder<List<AppBrand>>(
      stream: BrandRepository.instance.watchAll(),
      builder: (context, snapshot) {
        if (_seeding || !snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Hata: ${snapshot.error}'));
        }

        final brands = snapshot.data!;
        final query = _search.text.trim().toLowerCase();
        final filtered = query.isEmpty
            ? brands
            : brands
                  .where((brand) => brand.name.toLowerCase().contains(query))
                  .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Markalar',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            _buildToolbar(brands.length),
            const SizedBox(height: 14),
            if (brands.isEmpty)
              _emptyPanel()
            else
              _buildTable(filtered, brands.length),
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
          onPressed: _uploading ? null : () => _editBrand(null, total),
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

  Widget _buildTable(List<AppBrand> brands, int nextOrder) {
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
                  DataColumn(label: Text('Marka Adı')),
                  DataColumn(label: Text('Sıra No')),
                  DataColumn(label: Text('Yayın Durumu')),
                  DataColumn(label: Text('İşlem')),
                ],
                rows: [
                  for (final brand in brands.take(_pageSize))
                    DataRow(
                      cells: [
                        DataCell(
                          InkWell(
                            onTap: _uploading
                                ? null
                                : () => _changeImage(brand),
                            borderRadius: BorderRadius.circular(16),
                            child: SizedBox(
                              width: 68,
                              height: 52,
                              child: _brandImage(
                                imageUrl: brand.imageUrl,
                                assetPath: brand.assetPath,
                                name: brand.name,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          SizedBox(
                            width: 250,
                            child: Text(
                              brand.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text('${brand.order}')),
                        DataCell(
                          TextButton(
                            onPressed: () => _toggleActive(brand),
                            child: Text(
                              brand.active ? 'Aktif' : 'Pasif',
                              style: TextStyle(
                                color: brand.active
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
                                    : () => _changeImage(brand),
                                icon: const Icon(
                                  Icons.image_outlined,
                                  size: 19,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Düzenle',
                                onPressed: () => _editBrand(brand, nextOrder),
                                icon: const Icon(Icons.edit_outlined, size: 19),
                              ),
                              IconButton(
                                tooltip: 'Sil',
                                onPressed: () => _deleteBrand(brand),
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

  Widget _brandImage({
    required String imageUrl,
    required String assetPath,
    required String name,
    double? size,
  }) {
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
    final image = imageUrl.isNotEmpty
        ? Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => fallback,
          )
        : assetPath.isNotEmpty
        ? Image.asset(
            assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => fallback,
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
        'Henüz marka yok. “Marka Ekle” ile başlayın.',
        style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w600),
      ),
    );
  }

  String _brandId(String name) {
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
    final base = slug.isEmpty ? 'marka' : slug;
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
