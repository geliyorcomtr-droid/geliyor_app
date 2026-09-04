import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminProductsScreen extends StatefulWidget {
  const AdminProductsScreen({
    super.key,
    this.onAddProduct,
    this.onEditProduct,
    this.onCopyProduct,
  });

  final VoidCallback? onAddProduct;
  final ValueChanged<AdminProduct>? onEditProduct;
  final ValueChanged<AdminProduct>? onCopyProduct;

  @override
  State<AdminProductsScreen> createState() => _AdminProductsScreenState();
}

class _AdminProductsScreenState extends State<AdminProductsScreen> {
  final _search = TextEditingController();
  String _main = 'all';
  String _status = 'all';
  bool _lowStockOnly = false;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _deleteProduct(AdminProduct product) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ürünü sil'),
        content: Text('${product.title} silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.products)
        .doc(product.id)
        .delete();
  }

  Future<void> _toggleActive(AdminProduct product) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.products)
        .doc(product.id)
        .set({
          ProductFields.active: !product.active,
          ProductFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  List<AdminProduct> _filter(List<AdminProduct> products) {
    var list = products;
    final query = _search.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((p) {
        return p.title.toLowerCase().contains(query) ||
            p.brand.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query);
      }).toList();
    }
    if (_main != 'all') {
      list = list.where((p) => p.mainCategory == _main).toList();
    }
    if (_status == 'active') {
      list = list.where((p) => p.active).toList();
    } else if (_status == 'passive') {
      list = list.where((p) => !p.active).toList();
    }
    if (_lowStockOnly) {
      list = list.where((p) => p.stock <= 5).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance.collection(
      FirestoreCollections.products,
    );

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: query.snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Hata: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final all = snap.data!.docs.map(AdminProduct.fromDoc).toList()
          ..sort((a, b) => a.title.compareTo(b.title));
        final products = _filter(all);

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            AdminPageHeader(
              title: 'Ürünler',
              subtitle: 'Mama kataloğu, stok ve vitrin görünürlüğü.',
              actions: [
                FilledButton.icon(
                  onPressed: widget.onAddProduct,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Yeni Ürün'),
                ),
              ],
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Ürün, marka veya kategori ara',
                      prefixIcon: const Icon(Icons.search_rounded),
                      isDense: true,
                      filled: true,
                      fillColor: AppColors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _chip('Tümü', _main == 'all', () => setState(() => _main = 'all')),
                _chip('Kedi', _main == 'cat', () => setState(() => _main = 'cat')),
                _chip('Köpek', _main == 'dog', () => setState(() => _main = 'dog')),
                _chip(
                  'Akıllı',
                  _main == 'smart',
                  () => setState(() => _main = 'smart'),
                ),
                _chip(
                  'Aktif',
                  _status == 'active',
                  () => setState(
                    () => _status = _status == 'active' ? 'all' : 'active',
                  ),
                ),
                _chip(
                  'Pasif',
                  _status == 'passive',
                  () => setState(
                    () => _status = _status == 'passive' ? 'all' : 'passive',
                  ),
                ),
                _chip(
                  'Düşük stok',
                  _lowStockOnly,
                  () => setState(() => _lowStockOnly = !_lowStockOnly),
                ),
                Text(
                  '${products.length} ürün',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (products.isEmpty)
              const AdminPanel(
                padding: EdgeInsets.all(36),
                child: Center(
                  child: Text(
                    'Ürün yok. Yeni Ürün ile katalogı doldurun.',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              AdminPanel(
                child: Column(
                  children: [
                    for (int i = 0; i < products.length; i++) ...[
                      if (i > 0)
                        const Divider(height: 1, color: AppColors.border),
                      _row(products[i]),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _chip(String label, bool selected, VoidCallback onTap) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      showCheckmark: false,
      onSelected: (_) => onTap(),
      selectedColor: AppColors.selected,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.text,
        fontWeight: FontWeight.w700,
        fontSize: 12,
      ),
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      backgroundColor: AppColors.surface,
    );
  }

  Widget _row(AdminProduct product) {
    return InkWell(
      onTap: () => widget.onEditProduct?.call(product),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: SizedBox(
                width: 52,
                height: 52,
                child: ColoredBox(
                  color: AppColors.background,
                  child: buildProductImage(
                    product.imageUrl,
                    fit: BoxFit.contain,
                    errorWidget: const Icon(Icons.pets_rounded, size: 22),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    [
                      if (product.brand.isNotEmpty) product.brand,
                      if (product.weight.isNotEmpty) product.weight,
                      if (product.skt.isNotEmpty)
                        'SKT ${product.skt}'
                      else
                        'SKT yok',
                      if (product.category.isNotEmpty) product.category,
                      if (product.extraCategories.isNotEmpty)
                        '+ ${product.extraCategories.join(', ')}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 88,
              child: Text(
                AdminUi.money(product.unitPrice),
                textAlign: TextAlign.right,
                style: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),
            const SizedBox(width: 8),
            AdminStatusChip(
              label: 'KDV %${product.vatRate}',
              color: AppColors.primary,
            ),
            const SizedBox(width: 10),
            AdminStatusChip(
              label: 'Stok ${product.stock}',
              color: product.stock <= 0
                  ? AppColors.error
                  : product.stock <= 5
                  ? AppColors.warning
                  : AppColors.success,
            ),
            const SizedBox(width: 8),
            AdminStatusChip(
              label: product.active ? 'Vitrinde' : 'Gizli',
              color: product.active ? AppColors.success : AppColors.subText,
            ),
            if (product.showAsGift || product.showAsPremiumGift) ...[
              const SizedBox(width: 8),
              AdminStatusChip(
                label: product.showAsGift && product.showAsPremiumGift
                    ? 'Hediye + Premium'
                    : product.showAsPremiumGift
                    ? 'Premium hediye'
                    : 'Hediye',
                color: AppColors.primary,
              ),
            ],
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    widget.onEditProduct?.call(product);
                  case 'copy':
                    widget.onCopyProduct?.call(product);
                  case 'toggle':
                    _toggleActive(product);
                  case 'delete':
                    _deleteProduct(product);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'edit', child: Text('Düzenle')),
                const PopupMenuItem(
                  value: 'copy',
                  child: Text('Ürüne kopyala'),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(product.active ? 'Vitrinden kaldır' : 'Vitrine al'),
                ),
                const PopupMenuItem(value: 'delete', child: Text('Sil')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
