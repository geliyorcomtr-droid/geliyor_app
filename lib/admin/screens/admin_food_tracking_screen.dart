import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/screens/admin_brand_feeding_dialog.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminFoodTrackingScreen extends StatefulWidget {
  const AdminFoodTrackingScreen({super.key});

  @override
  State<AdminFoodTrackingScreen> createState() =>
      _AdminFoodTrackingScreenState();
}

class _AdminFoodTrackingScreenState extends State<AdminFoodTrackingScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppBrand>>(
      stream: BrandRepository.instance.watchAll(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
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
        final ready = brands.where((brand) => !brand.feeding.isEmpty).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            const Text(
              'Mama Tüketim Takibi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.text,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Marka bazında günlük tüketim (gram) buradan yönetilir. '
              'Yetişkin kedi kilo, yavru kedi ay; köpekte yetişkin beden, '
              'yavru ay + mini ırk ayrımı kullanılır. Gramaj girilen marka '
              'uygulamada Mama Takibi Başlat seçiminde görünür.',
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 13,
                fontWeight: FontWeight.w600,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            const Divider(height: 1, color: AppColors.border),
            const SizedBox(height: 14),
            Wrap(
              spacing: 14,
              runSpacing: 10,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  '$ready / ${brands.length} markada gramaj var',
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: TextField(
                    controller: _search,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      hintText: 'Marka ara',
                      suffixIcon: Icon(Icons.search_rounded),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            if (brands.isEmpty)
              _emptyPanel()
            else
              _buildTable(filtered),
          ],
        );
      },
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
        'Önce Ürünler → Markalar ekranından marka ekleyin.',
        style: TextStyle(color: AppColors.subText, fontWeight: FontWeight.w600),
      ),
    );
  }

  Widget _buildTable(List<AppBrand> brands) {
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
                columnSpacing: 28,
                horizontalMargin: 14,
                columns: const [
                  DataColumn(label: Text('Marka')),
                  DataColumn(label: Text('Kedi')),
                  DataColumn(label: Text('Köpek')),
                  DataColumn(label: Text('Uygulama')),
                  DataColumn(label: Text('İşlem')),
                ],
                rows: [
                  for (final brand in brands)
                    DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              _miniImage(brand),
                              const SizedBox(width: 10),
                              SizedBox(
                                width: 180,
                                child: Text(
                                  brand.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Text(
                            brand.feeding.hasCat || brand.feeding.hasCatKitten
                                ? '${brand.feeding.filledCatCount()} yetişkin / ${brand.feeding.filledCatKittenCount()} yavru'
                                : '—',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: brand.feeding.hasCat ||
                                      brand.feeding.hasCatKitten
                                  ? AppColors.text
                                  : AppColors.subText,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            brand.feeding.hasDog ||
                                    brand.feeding.hasDogPuppy ||
                                    brand.feeding.hasDogMiniPuppy
                                ? '${brand.feeding.filledDogCount()} yetişkin / ${brand.feeding.filledDogPuppyCount()} yavru'
                                : '—',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: brand.feeding.hasDog ||
                                      brand.feeding.hasDogPuppy ||
                                      brand.feeding.hasDogMiniPuppy
                                  ? AppColors.text
                                  : AppColors.subText,
                            ),
                          ),
                        ),
                        DataCell(
                          Text(
                            brand.feeding.isEmpty
                                ? 'Gizli'
                                : (brand.active ? 'Görünür' : 'Pasif marka'),
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: !brand.feeding.isEmpty && brand.active
                                  ? AppColors.success
                                  : AppColors.subText,
                            ),
                          ),
                        ),
                        DataCell(
                          FilledButton.icon(
                            onPressed: () =>
                                showAdminBrandFeedingDialog(context, brand),
                            icon: const Icon(Icons.scale_outlined, size: 18),
                            label: const Text('Tüketimi düzenle'),
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

  Widget _miniImage(AppBrand brand) {
    final path = brand.displayImage;
    return Container(
      width: 44,
      height: 44,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: path.isEmpty
          ? const Icon(Icons.pets_rounded, color: AppColors.subText, size: 20)
          : buildProductImage(
              path,
              fit: BoxFit.contain,
              width: 36,
              height: 36,
              cacheWidth: uiIconAssetPx,
              errorWidget: const Icon(
                Icons.pets_rounded,
                color: AppColors.subText,
                size: 20,
              ),
            ),
    );
  }
}
