import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/admin/admin_theme.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/product_margin.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class AdminReportingScreen extends StatefulWidget {
  const AdminReportingScreen({super.key});

  @override
  State<AdminReportingScreen> createState() => _AdminReportingScreenState();
}

class _AdminReportingScreenState extends State<AdminReportingScreen> {
  final _search = TextEditingController();
  String? _savingId;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _setVat(AdminProduct product, int vatRate) async {
    if (product.vatRate == vatRate) return;
    setState(() => _savingId = product.id);
    try {
      await FirebaseFirestore.instance
          .collection(FirestoreCollections.products)
          .doc(product.id)
          .set({ProductFields.vatRate: vatRate}, SetOptions(merge: true));
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('KDV kaydedilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _savingId = null);
    }
  }

  List<AdminProduct> _filter(List<AdminProduct> products) {
    final q = _search.text.trim().toLowerCase();
    final filtered = [
      for (final product in products)
        if (q.isEmpty ||
            product.title.toLowerCase().contains(q) ||
            product.brand.toLowerCase().contains(q) ||
            product.barcode.toLowerCase().contains(q))
          product,
    ];
    filtered.sort((a, b) => a.title.compareTo(b.title));
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.products)
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('Rapor yüklenemedi: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final products = _filter([
          for (final doc in snap.data!.docs) AdminProduct.fromDoc(doc),
        ]);
        final margins = [
          for (final product in products)
            ProductMargin.percent(
              purchasePrice: product.purchasePrice,
              discountedPrice: product.unitPrice,
              vatRate: product.vatRate,
            ),
        ].whereType<double>().toList();
        final avg = margins.isEmpty
            ? null
            : margins.reduce((a, b) => a + b) / margins.length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const AdminPageHeader(
              title: 'Raporlama',
              subtitle:
                  'Alış KDV hariç, indirimli fiyat KDV dahil. Kâr marjı = '
                  '(net satış − alış) / net satış. KDV varsayılan %20, değiştirilebilir.',
            ),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth >= 720;
                final cards = [
                  AdminStatCard(
                    value: '${products.length}',
                    label: 'Ürün',
                    icon: Icons.inventory_2_rounded,
                    color: AdminAccents.products,
                  ),
                  AdminStatCard(
                    value: ProductMargin.percentLabel(avg),
                    label: 'Ortalama kâr marjı',
                    icon: Icons.percent_rounded,
                    color: AdminAccents.reporting,
                  ),
                ];
                if (wide) {
                  return Row(
                    children: [
                      for (var i = 0; i < cards.length; i++) ...[
                        if (i > 0) const SizedBox(width: 12),
                        Expanded(child: cards[i]),
                      ],
                    ],
                  );
                }
                return Column(
                  children: [
                    for (var i = 0; i < cards.length; i++) ...[
                      if (i > 0) const SizedBox(height: 10),
                      cards[i],
                    ],
                  ],
                );
              },
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Ürün, marka veya barkod ara',
                prefixIcon: const Icon(Icons.search_rounded),
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
            const SizedBox(height: 14),
            if (products.isEmpty)
              const AdminPanel(
                padding: EdgeInsets.all(36),
                child: Center(
                  child: Text(
                    'Gösterilecek ürün yok.',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              )
            else
              AdminPanel(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(minWidth: 980),
                    child: Column(
                      children: [
                        _header(),
                        const Divider(height: 1, color: AppColors.border),
                        for (int i = 0; i < products.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          _row(products[i]),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: const [
          SizedBox(
            width: 280,
            child: Text(
              'Ürün',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              'Alış fiyatı',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              'İndirimli fiyat',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              'KDV',
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              'Kâr marjı',
              textAlign: TextAlign.right,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }

  Widget _row(AdminProduct product) {
    final margin = ProductMargin.percent(
      purchasePrice: product.purchasePrice,
      discountedPrice: product.unitPrice,
      vatRate: product.vatRate,
    );
    final saving = _savingId == product.id;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
      child: Row(
        children: [
          SizedBox(
            width: 280,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                if (product.barcode.isNotEmpty)
                  Text(
                    product.barcode,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              AdminUi.money(product.purchasePrice),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
          SizedBox(
            width: 150,
            child: Text(
              AdminUi.money(product.unitPrice),
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
          SizedBox(
            width: 120,
            child: Center(
              child: saving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<int>(
                        value: ProductFields.vatRates.contains(product.vatRate)
                            ? product.vatRate
                            : 20,
                        isDense: true,
                        items: [
                          for (final rate in ProductFields.vatRates)
                            DropdownMenuItem(
                              value: rate,
                              child: Text('%$rate'),
                            ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          _setVat(product, value);
                        },
                      ),
                    ),
            ),
          ),
          SizedBox(
            width: 130,
            child: Text(
              ProductMargin.percentLabel(margin),
              textAlign: TextAlign.right,
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: margin == null
                    ? AppColors.subText
                    : margin >= 0
                    ? AppColors.success
                    : AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
