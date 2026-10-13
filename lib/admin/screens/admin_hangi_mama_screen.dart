import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/hangi_mama_repository.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

class AdminHangiMamaScreen extends StatefulWidget {
  const AdminHangiMamaScreen({super.key});

  @override
  State<AdminHangiMamaScreen> createState() => _AdminHangiMamaScreenState();
}

class _AdminHangiMamaScreenState extends State<AdminHangiMamaScreen> {
  final _search = TextEditingController();
  List<String> _selectedIds = [];
  var _loaded = false;
  var _saving = false;

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
      await HangiMamaRepository.instance.ensureDefaults();
      final ids = await HangiMamaRepository.instance.fetchAdvantageIds();
      if (!mounted) return;
      setState(() {
        _selectedIds = [...ids];
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _loaded = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hangi Mama yüklenemedi: $error')),
      );
    }
  }

  Future<void> _save(List<String> ids) async {
    setState(() {
      _selectedIds = ids;
      _saving = true;
    });
    try {
      await HangiMamaRepository.instance.saveAdvantageIds(ids);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Kaydedilemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggle(String id) {
    final next = [..._selectedIds];
    if (next.contains(id)) {
      next.remove(id);
    } else {
      next.add(id);
    }
    _save(next);
  }

  void _move(int from, int to) {
    if (from == to || from < 0 || to < 0) return;
    if (from >= _selectedIds.length || to >= _selectedIds.length) return;
    final next = [..._selectedIds];
    final id = next.removeAt(from);
    next.insert(to, id);
    _save(next);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) {
      return const Center(child: CircularProgressIndicator());
    }
    return StreamBuilder<List<AppProductAdvantage>>(
      stream: ProductAdvantageRepository.instance.watchAll(activeOnly: true),
      builder: (context, snapshot) {
        final catalog = snapshot.data ?? const <AppProductAdvantage>[];
        final byId = {for (final item in catalog) item.id: item};
        final selected = [
          for (final id in _selectedIds)
            if (byId[id] != null) byId[id]!,
        ];
        final query = ProductAdvantageRepository.foldSearch(_search.text);
        final available = [
          for (final item in catalog)
            if (!_selectedIds.contains(item.id) &&
                (query.isEmpty ||
                    ProductAdvantageRepository.foldSearch(
                      item.name,
                    ).contains(query) ||
                    ProductAdvantageRepository.foldSearch(
                      item.id,
                    ).contains(query)))
              item,
        ];
        final groupedAvailable = ProductAdvantageRepository.grouped(
          available,
          categories: ProductAdvantageRepository.instance.cachedCategories,
        );

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          children: [
            AdminPageHeader(
              title: 'Hangi Mama',
              subtitle:
                  'İhtiyacını Seç grid’i Öne Çıkan Özellikler ile aynı kaynaktır. '
                  'Burada seçilen ikonlar uygulamada görünür; görseller faydalardan gelir. '
                  'Uygulamada arama ile listede olmayan faydalar da seçilebilir.',
              actions: [
                if (_saving)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
              ],
            ),
            TextField(
              controller: _search,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: 'Fayda ara ve İhtiyacını Seç listesine ekle',
                prefixIcon: Icon(Icons.search_rounded),
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              'İhtiyacını Seç (${selected.length})',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sıra uygulamadaki grid sırasıdır. Tıklayınca çıkar; oklarla yer değiştir.',
              style: TextStyle(
                color: AppColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (selected.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  vertical: 28,
                  horizontal: 16,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: AppColors.border),
                ),
                child: const Text(
                  'Henüz fayda seçilmedi. Aşağıdan ekleyin.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              )
            else
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (var i = 0; i < selected.length; i++)
                    _HangiMamaAdvantageTile(
                      item: selected[i],
                      selected: true,
                      order: i + 1,
                      onTap: () => _toggle(selected[i].id),
                      onMoveUp: i == 0 ? null : () => _move(i, i - 1),
                      onMoveDown: i == selected.length - 1
                          ? null
                          : () => _move(i, i + 1),
                    ),
                ],
              ),
            const SizedBox(height: 22),
            const Text(
              'Tüm öne çıkan özellikler',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
            ),
            const SizedBox(height: 4),
            const Text(
              'Öne Çıkan Özellikler ekranındaki aktif ikonlar. Seçmek için tıklayın.',
              style: TextStyle(
                color: AppColors.subText,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 10),
            if (available.isEmpty)
              Text(
                catalog.isEmpty
                    ? 'Önce Ürünler → Öne Çıkan Özellikler ekranından özellik ekleyin.'
                    : 'Aramaya uyan seçilmemiş fayda yok.',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                ),
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final category
                      in ProductAdvantageRepository
                          .instance
                          .cachedCategories) ...[
                    if ((groupedAvailable[category.id] ??
                            const <AppProductAdvantage>[])
                        .isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 6, bottom: 8),
                        child: Text(
                          category.label,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 14,
                          ),
                        ),
                      ),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final item
                              in groupedAvailable[category.id] ??
                                  const <AppProductAdvantage>[])
                            _HangiMamaAdvantageTile(
                              item: item,
                              selected: false,
                              onTap: () => _toggle(item.id),
                            ),
                        ],
                      ),
                    ],
                  ],
                ],
              ),
          ],
        );
      },
    );
  }
}

class _HangiMamaAdvantageTile extends StatelessWidget {
  const _HangiMamaAdvantageTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.order,
    this.onMoveUp,
    this.onMoveDown,
  });

  final AppProductAdvantage item;
  final bool selected;
  final VoidCallback onTap;
  final int? order;
  final VoidCallback? onMoveUp;
  final VoidCallback? onMoveDown;

  @override
  Widget build(BuildContext context) {
    final path = ProductAdvantageRepository.displayPath(item);
    return SizedBox(
      width: 148,
      child: Material(
        color: selected ? AppColors.selected : AppColors.background,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            padding: const EdgeInsets.fromLTRB(10, 10, 10, 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Column(
              children: [
                SizedBox(
                  height: 64,
                  child: Stack(
                    children: [
                      Positioned.fill(
                        child: path.isEmpty
                            ? const Icon(
                                Icons.pets_rounded,
                                color: AppColors.primary,
                              )
                            : buildProductImage(
                                path,
                                fit: BoxFit.contain,
                                errorWidget: const Icon(
                                  Icons.pets_rounded,
                                  color: AppColors.primary,
                                ),
                              ),
                      ),
                      if (order != null)
                        Positioned(
                          left: 0,
                          top: 0,
                          child: Container(
                            width: 22,
                            height: 22,
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.all(
                                Radius.circular(999),
                              ),
                            ),
                            child: Text(
                              '$order',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.text,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                if (selected) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        tooltip: 'Yukarı',
                        visualDensity: VisualDensity.compact,
                        onPressed: onMoveUp,
                        icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                      ),
                      IconButton(
                        tooltip: 'Aşağı',
                        visualDensity: VisualDensity.compact,
                        onPressed: onMoveDown,
                        icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
