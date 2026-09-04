import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/admin/admin_theme.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/admin/category_repository.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/data/trust_badge_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/utils/product_skt.dart';
import 'package:geliyor_app/widgets/preferred_rank_medal.dart';

class AdminProductFormScreen extends StatefulWidget {
  const AdminProductFormScreen({
    super.key,
    this.product,
    this.initialSection = 0,
    this.onClose,
  });

  final AdminProduct? product;
  final int initialSection;
  final VoidCallback? onClose;

  @override
  State<AdminProductFormScreen> createState() => _AdminProductFormScreenState();
}

class _AdminProductFormScreenState extends State<AdminProductFormScreen> {
  late final TextEditingController _title;
  late final TextEditingController _brand;
  late final TextEditingController _weight;
  late final TextEditingController _barcode;
  late final TextEditingController _skt;
  late int _vatRate;
  late final TextEditingController _unitPrice;
  late final TextEditingController _oldPrice;
  late final TextEditingController _discount;
  late final TextEditingController _imageUrl;
  late final TextEditingController _category;
  late String _mainCategory;
  late final TextEditingController _description;
  late final TextEditingController _stock;
  late final TextEditingController _proteinValue;
  late final TextEditingController _preferredRank;
  late final TextEditingController _repurchaseRate;
  late final TextEditingController _rating;
  late final TextEditingController _seoTitle;
  late final TextEditingController _metaDescription;
  late List<String> _selectedAdvantageIds;
  late List<String> _selectedTrustBadgeIds;
  late List<String> _gallery;
  late Set<String> _extraCategories;
  late bool _showAsGift;
  late bool _showAsPremiumGift;
  late bool _active;
  Uint8List? _mainImagePreviewBytes;
  bool _saving = false;
  bool _uploading = false;
  late int _section;
  final _brandSearch = TextEditingController();
  late final Future<List<AdminMainCategory>> _categoriesFuture;
  late final Future<List<AppBrand>> _brandsFuture;
  late final Future<List<AppProductAdvantage>> _advantagesFuture;

  bool get _isEdit => widget.product != null && widget.product!.id.isNotEmpty;
  bool get _isCopy => widget.product != null && widget.product!.id.isEmpty;

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection.clamp(0, 6);
    _categoriesFuture = _loadCategories();
    _brandsFuture = _loadBrands();
    _advantagesFuture = _loadAdvantages();
    TrustBadgeRepository.instance.ensureDefaults();
    final p = widget.product;
    _title = TextEditingController(text: p?.title ?? '');
    _brand = TextEditingController(text: p?.brand ?? '');
    _weight = TextEditingController(text: p?.weight ?? '');
    _barcode = TextEditingController(text: p?.barcode ?? '');
    final parsedVat = ProductFields.vatRateFrom(p?.vatRate);
    _vatRate = ProductFields.vatRates.contains(parsedVat) ? parsedVat : 20;
    _skt = TextEditingController(
      text: ProductSkt.display(p?.skt ?? ''),
    );
    _unitPrice = TextEditingController(
      text: p == null ? '' : p.unitPrice.toStringAsFixed(0),
    );
    _oldPrice = TextEditingController(
      text: p == null ? '' : p.oldPrice.toStringAsFixed(0),
    );
    _discount = TextEditingController(
      text: p == null ? '0' : '${p.discountPercent}',
    );
    _imageUrl = TextEditingController(text: p?.imageUrl ?? '');
    _category = TextEditingController(text: p?.category ?? '');
    _mainCategory = p?.mainCategory ?? 'cat';
    _description = TextEditingController(text: p?.description ?? '');
    _stock = TextEditingController(text: p == null ? '0' : '${p.stock}');
    _proteinValue = TextEditingController(
      text: (p?.proteinValue.trim().isNotEmpty ?? false)
          ? p!.proteinValue
          : '%42',
    );
    _preferredRank = TextEditingController(
      text: (p?.preferredRank.trim().isNotEmpty ?? false)
          ? p!.preferredRank
          : '2.',
    );
    _repurchaseRate = TextEditingController(
      text: (p?.repurchaseRate.trim().isNotEmpty ?? false)
          ? p!.repurchaseRate
          : '%78',
    );
    _rating = TextEditingController(
      text: p == null || p.rating <= 0 ? '' : p.rating.toStringAsFixed(1),
    );
    _seoTitle = TextEditingController(text: p?.seoTitle ?? '');
    _metaDescription = TextEditingController(text: p?.metaDescription ?? '');
    _selectedAdvantageIds = [...?p?.productAdvantageIds];
    if (!_selectedAdvantageIds.contains(
      ProductAdvantageRepository.proteinAdvantageId,
    )) {
      _selectedAdvantageIds.insert(
        0,
        ProductAdvantageRepository.proteinAdvantageId,
      );
    }
    _selectedTrustBadgeIds = [
      for (final id in [...?p?.trustBadgeIds])
        if (id != TrustBadgeRepository.proteinBadgeId) id,
    ];
    if (!_selectedTrustBadgeIds.contains(
      TrustBadgeRepository.repurchaseBadgeId,
    )) {
      _selectedTrustBadgeIds.add(TrustBadgeRepository.repurchaseBadgeId);
    }
    if (!_selectedTrustBadgeIds.contains(
      TrustBadgeRepository.affordableBadgeId,
    )) {
      _selectedTrustBadgeIds.add(TrustBadgeRepository.affordableBadgeId);
    }
    _gallery = [...?p?.gallery];
    _extraCategories = {...?p?.extraCategories};
    _showAsGift = p?.showAsGift ?? false;
    _showAsPremiumGift = p?.showAsPremiumGift ?? false;
    _active = p?.active ?? true;
    _title.addListener(_onTick);
    _unitPrice.addListener(_onTick);
    _imageUrl.addListener(_onTick);
  }

  void _onTick() {
    if (mounted) setState(() {});
  }

  Future<List<AdminMainCategory>> _loadCategories() async {
    await CategoryRepository.instance.ensureDefaults();
    return CategoryRepository.instance.fetchAll();
  }

  Future<List<AppBrand>> _loadBrands() async {
    await BrandRepository.instance.ensureDefaults();
    return BrandRepository.instance.fetchAll(activeOnly: true);
  }

  Future<List<AppProductAdvantage>> _loadAdvantages() async {
    await ProductAdvantageRepository.instance.ensureDefaults();
    return ProductAdvantageRepository.instance.fetchAll(activeOnly: true);
  }

  @override
  void dispose() {
    _title.removeListener(_onTick);
    _unitPrice.removeListener(_onTick);
    _imageUrl.removeListener(_onTick);
    _title.dispose();
    _brand.dispose();
    _weight.dispose();
    _barcode.dispose();
    _skt.dispose();
    _unitPrice.dispose();
    _oldPrice.dispose();
    _discount.dispose();
    _imageUrl.dispose();
    _category.dispose();
    _description.dispose();
    _stock.dispose();
    _proteinValue.dispose();
    _preferredRank.dispose();
    _repurchaseRate.dispose();
    _rating.dispose();
    _seoTitle.dispose();
    _metaDescription.dispose();
    _brandSearch.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final title = _title.text.trim();
    if (title.isEmpty) {
      setState(() => _section = 0);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ürün adı zorunlu.')));
      return;
    }

    setState(() => _saving = true);
    try {
      if (_category.text.trim().isEmpty) {
        final mains = await _loadCategories();
        if (mains.isNotEmpty) {
          final selectedMain = mains.firstWhere(
            (m) => m.id == _mainCategory,
            orElse: () => mains.first,
          );
          _mainCategory = selectedMain.id;
          if (selectedMain.subcategories.isNotEmpty) {
            _category.text = selectedMain.subcategories.first.title;
          }
        }
      }
      final trustBadges = await TrustBadgeRepository.instance.fetchAll(
        activeOnly: true,
      );
      final advantages = await _advantagesFuture;
      final selectedBadges = [
        for (final badge in trustBadges)
          if (_selectedTrustBadgeIds.contains(badge.id) &&
              !TrustBadgeRepository.isProteinBadge(badge))
            badge,
      ];
      final selectedAdvantages = [
        for (final id in _selectedAdvantageIds)
          ...advantages.where((item) => item.id == id),
      ];
      final proteinRaw = _proteinValue.text.trim();
      final proteinDisplay =
          ProductAdvantageRepository.formatProteinDisplay(proteinRaw);
      final preferredRankDisplay = TrustBadgeRepository.formatPreferredRank(
        _preferredRank.text,
      );
      final repurchaseDisplay = TrustBadgeRepository.formatRate(
        _repurchaseRate.text,
      );
      final product = AdminProduct(
        id: widget.product?.id ?? '',
        title: title,
        brand: _brand.text,
        weight: _weight.text,
        barcode: _barcode.text,
        vatRate: ProductFields.vatRateFrom(_vatRate),
        skt: ProductSkt.display(_skt.text),
        unitPrice: double.tryParse(_unitPrice.text.replaceAll(',', '.')) ?? 0,
        oldPrice: double.tryParse(_oldPrice.text.replaceAll(',', '.')) ?? 0,
        discountPercent: int.tryParse(_discount.text) ?? 0,
        imageUrl: _imageUrl.text,
        category: _category.text,
        extraCategories: [
          for (final title in _extraCategories)
            if (title.trim().isNotEmpty &&
                title.trim() != _category.text.trim())
              title.trim(),
        ],
        placements: [
          if (_showAsGift) ProductPlacements.gift,
          if (_showAsPremiumGift) ProductPlacements.giftPremium,
        ],
        mainCategory: _mainCategory,
        description: _description.text,
        active: _active,
        stock: int.tryParse(_stock.text) ?? 0,
        proteinValue: proteinDisplay,
        preferredRank: preferredRankDisplay,
        repurchaseRate: repurchaseDisplay,
        rating: double.tryParse(_rating.text.replaceAll(',', '.')) ?? 0,
        features: [
          for (final item in selectedAdvantages)
            AdminProductFeature(
              title: item.name,
              description: item.description,
              iconUrl: item.imageUrl.isNotEmpty
                  ? item.imageUrl
                  : item.assetPath,
            ),
        ],
        technicalFeatures: [
          for (final badge in selectedBadges)
            AdminProductFeature(
              title: badge.name,
              description: '',
              iconUrl: badge.imageUrl.isNotEmpty
                  ? badge.imageUrl
                  : badge.assetPath,
            ),
        ],
        trustBadgeIds: [for (final badge in selectedBadges) badge.id],
        productAdvantageIds: [for (final item in selectedAdvantages) item.id],
        productAdvantageValues:
            _selectedAdvantageIds.contains(
                  ProductAdvantageRepository.proteinAdvantageId,
                ) &&
                proteinDisplay.isNotEmpty
            ? {ProductAdvantageRepository.proteinAdvantageId: proteinDisplay}
            : const {},
        gallery: _gallery,
        seoTitle: _seoTitle.text,
        metaDescription: _metaDescription.text,
      );

      final col = FirebaseFirestore.instance.collection(
        FirestoreCollections.products,
      );
      final sktFields = ProductSkt.toFirestoreFields(_skt.text);
      final sktDisplay = ProductSkt.display(_skt.text);
      if (_isEdit) {
        await col.doc(widget.product!.id).set({
          ...product.toMap(),
          ...sktFields,
          ProductFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      } else {
        await col.add({
          ...product.toMap(isCreate: true),
          ...sktFields,
        });
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isCopy
                ? (sktDisplay.isEmpty
                      ? 'Yeni kopya ürün oluşturuldu (SKT boş). Orijinal değişmedi.'
                      : 'Yeni kopya ürün oluşturuldu. SKT: $sktDisplay — orijinal değişmedi.')
                : (sktDisplay.isEmpty
                      ? 'Ürün kaydedildi (SKT boş). Fiyat: ${product.unitPrice.toStringAsFixed(0)} ₺'
                      : 'Ürün kaydedildi. SKT: $sktDisplay · ${product.unitPrice.toStringAsFixed(0)} ₺'),
          ),
        ),
      );
      if (widget.onClose != null) {
        widget.onClose!();
      } else {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Kaydedilemedi: $e')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  static const _steps = <(String, String, IconData)>[
    ('Bilgi', 'Ad, fiyat, stok', Icons.edit_note_rounded),
    ('Kategori', 'Vitrin ve hediye', Icons.sell_outlined),
    ('Marka', 'Ürün markası', Icons.copyright_rounded),
    ('Görseller', 'Ana fotoğraf', Icons.photo_library_outlined),
    ('Özellikler', 'Sağ sütun', Icons.auto_awesome_outlined),
    ('Rozetler', 'Sol sütun', Icons.verified_outlined),
    ('SEO', 'İsteğe bağlı', Icons.search_rounded),
  ];

  bool _stepDone(int index) {
    return switch (index) {
      0 => _title.text.trim().isNotEmpty && _unitPrice.text.trim().isNotEmpty,
      1 => _category.text.trim().isNotEmpty,
      2 => _brand.text.trim().isNotEmpty,
      3 => _imageUrl.text.trim().isNotEmpty || _mainImagePreviewBytes != null,
      4 => _selectedAdvantageIds.length > 1,
      5 => _selectedTrustBadgeIds.isNotEmpty,
      _ =>
        _seoTitle.text.trim().isNotEmpty ||
            _metaDescription.text.trim().isNotEmpty,
    };
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AdminAccents.canvas,
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final wide = constraints.maxWidth >= 960;
                  if (!wide) {
                    return Column(
                      children: [
                        _buildCompactSteps(),
                        const SizedBox(height: 12),
                        Expanded(child: _buildScrollBody()),
                      ],
                    );
                  }
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        width: 228,
                        child: _buildStepRail(),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: _buildScrollBody()),
                    ],
                  );
                },
              ),
            ),
          ),
          _buildSaveBar(),
        ],
      ),
    );
  }

  Widget _buildScrollBody() {
    return ListView(
      padding: const EdgeInsets.only(bottom: 16),
      children: [
        _buildSummaryCard(),
        const SizedBox(height: 12),
        _buildSelectedSection(),
      ],
    );
  }

  Widget _buildSummaryCard() {
    final title = _title.text.trim().isEmpty ? 'İsimsiz ürün' : _title.text.trim();
    final price = double.tryParse(_unitPrice.text.replaceAll(',', '.'));
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Row(
        children: [
          _imagePreview(
            _imageUrl.text,
            size: 64,
            bytes: _mainImagePreviewBytes,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    if (_brand.text.trim().isNotEmpty) _brand.text.trim(),
                    if (_category.text.trim().isNotEmpty) _category.text.trim(),
                    if (_weight.text.trim().isNotEmpty) _weight.text.trim(),
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price == null ? 'Fiyat yok' : AdminUi.money(price),
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 4),
              AdminStatusChip(
                label: _active ? 'Vitrinde' : 'Gizli',
                color: _active ? AppColors.success : AppColors.subText,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStepRail() {
    final doneCount = [for (var i = 0; i < _steps.length; i++) i]
        .where(_stepDone)
        .length;
    return AdminPanel(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _isEdit
                ? 'Ürünü düzenle'
                : (_isCopy ? 'Ürüne kopyala' : 'Yeni ürün'),
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          if (_isCopy) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.selected,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Bu bir kopya. Kaydedince YENİ ürün oluşur; '
                'orijinal ürünün fiyatı/SKT’si değişmez. '
                'Uygulamada doğru ürünü açtığından emin ol.',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  height: 1.35,
                ),
              ),
            ),
          ],
          const SizedBox(height: 4),
          Text(
            '$doneCount / ${_steps.length} adım doldu',
            style: const TextStyle(
              color: AppColors.subText,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: ListView.separated(
              itemCount: _steps.length,
              separatorBuilder: (_, _) => const SizedBox(height: 6),
              itemBuilder: (context, i) => _stepTile(i),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactSteps() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (int i = 0; i < _steps.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _stepTile(i, compact: true),
          ],
        ],
      ),
    );
  }

  Widget _stepTile(int index, {bool compact = false}) {
    final selected = _section == index;
    final done = _stepDone(index);
    final color = selected
        ? AdminAccents.products
        : done
        ? AppColors.success
        : AppColors.subText;
    return Material(
      color: selected
          ? AdminAccents.products.withValues(alpha: 0.12)
          : Colors.transparent,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _section = index),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 8,
            vertical: compact ? 8 : 8,
          ),
          child: Row(
            mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: selected || done ? 1 : 0.12),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  done && !selected ? Icons.check_rounded : _steps[index].$3,
                  size: 15,
                  color: selected || done ? Colors.white : color,
                ),
              ),
              const SizedBox(width: 8),
              if (compact)
                Text(
                  _steps[index].$1,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: selected ? AdminAccents.products : AppColors.text,
                  ),
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _steps[index].$1,
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: selected
                              ? AdminAccents.products
                              : AppColors.text,
                        ),
                      ),
                      Text(
                        _steps[index].$2,
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  void _close() {
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  Widget _buildSelectedSection() {
    return switch (_section) {
      0 => _buildGeneralSection(),
      1 => _buildCategorySection(),
      2 => _buildBrandSection(),
      3 => _buildImagesSection(),
      4 => _buildAdvantagesSection(),
      5 => _buildTrustBadgesSection(),
      _ => _buildSeoSection(),
    };
  }

  Widget _buildAdvantagesSection() {
    return StreamBuilder<List<AppProductAdvantage>>(
      stream: ProductAdvantageRepository.instance.watchAll(activeOnly: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final items = snapshot.data!;
        if (items.isEmpty) {
          return _panel(
            title: 'Ürün Özellikleri',
            subtitle:
                'Önce Ürün Yönetimi → Ürün Özellikleri ekranından ekleyin.',
            child: const Text('Ürün özelliği bulunamadı.'),
          );
        }
        return _panel(
          title: 'Ürün Özellikleri',
          subtitle:
              'İlk 5 seçim ürün görselinin sağında kalır. Sonraki seçimler '
              'yalnızca altta Ürün Özellikleri listesinde görünür. En fazla '
              '${ProductAdvantageRepository.maxPerProduct} özellik seçilebilir. '
              'Protein her üründe zorunludur; değeri Ürün Bilgileri adımından girilir.',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final item in items)
                _AdvantageChoiceTile(
                  item: item,
                  selected: _selectedAdvantageIds.contains(item.id),
                  order: _selectedAdvantageIds.contains(item.id)
                      ? _selectedAdvantageIds.indexOf(item.id) + 1
                      : null,
                  onTap: () {
                    if (item.id ==
                        ProductAdvantageRepository.proteinAdvantageId) {
                      return;
                    }
                    setState(() {
                      if (_selectedAdvantageIds.contains(item.id)) {
                        _selectedAdvantageIds.remove(item.id);
                      } else if (_selectedAdvantageIds.length <
                          ProductAdvantageRepository.maxPerProduct) {
                        _selectedAdvantageIds.add(item.id);
                      }
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTrustBadgesSection() {
    return StreamBuilder<List<AppTrustBadge>>(
      stream: TrustBadgeRepository.instance.watchAll(activeOnly: true),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final badges = snapshot.data!
            .where((badge) => !TrustBadgeRepository.isSmartSuggestionBadge(badge))
            .where((badge) => !TrustBadgeRepository.isProteinBadge(badge))
            .toList();
        if (badges.isEmpty) {
          return _panel(
            title: 'Güven Rozetleri',
            subtitle:
                'Önce Ürün Yönetimi → Güven Rozetleri ekranından rozet ekleyin.',
            child: const Text('Güven rozeti bulunamadı.'),
          );
        }

        return _panel(
          title: 'Güven Rozetleri',
          subtitle:
              'Ürün detayında görselin solunda gösterilecek rozetleri seçin. '
              'Puan ikon + rakam + etiket olarak görünür (ör. 4.9 Puan). '
              'Çok Satan Ürün madalya ikonunun içinde sıra rakamı gösterir '
              '(ör. 1., 2.).',
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final badge in badges)
                _TrustBadgeChoiceTile(
                  badge: badge,
                  selected: _selectedTrustBadgeIds.contains(badge.id),
                  onTap: () {
                    setState(() {
                      if (_selectedTrustBadgeIds.contains(badge.id)) {
                        _selectedTrustBadgeIds.remove(badge.id);
                      } else {
                        _selectedTrustBadgeIds.add(badge.id);
                      }
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildCategorySection() {
    return FutureBuilder<List<AdminMainCategory>>(
      future: _categoriesFuture,
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }
        final mains = snap.data!;
        if (mains.isEmpty) {
          return _panel(
            title: 'Kategori Seçimi',
            subtitle:
                'Önce Ürün Yönetimi → Kategoriler ekranından kategori ekleyin.',
            child: const Text('Kategori bulunamadı.'),
          );
        }

        final selectedMain = mains.firstWhere(
          (m) => m.id == _mainCategory,
          orElse: () => mains.first,
        );
        if (_mainCategory != selectedMain.id) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            setState(() {
              _mainCategory = selectedMain.id;
              if (_category.text.isEmpty &&
                  selectedMain.subcategories.isNotEmpty) {
                _category.text = selectedMain.subcategories.first.title;
              }
            });
          });
        }

        final subs = selectedMain.subcategories;
        final currentSub = _category.text.trim();
        final subExists = subs.any((s) => s.title == currentSub);

        return _panel(
          title: 'Kategori Seçimi',
          subtitle:
              'Ana kategoriyi ve alt kategoriyi seçin. İsterseniz ürünü başka vitrinlerde ve hediye sayfasında da gösterebilirsiniz.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Ana Kategori',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final main in mains)
                    ChoiceChip(
                      label: Text(main.title),
                      selected: _mainCategory == main.id,
                      selectedColor: AppColors.selected,
                      onSelected: (_) {
                        setState(() {
                          _mainCategory = main.id;
                          _category.text = main.subcategories.isNotEmpty
                              ? main.subcategories.first.title
                              : '';
                          final allowed = {
                            for (final sub in main.subcategories) sub.title,
                          };
                          _extraCategories.removeWhere(
                            (title) =>
                                !allowed.contains(title) ||
                                title == _category.text,
                          );
                        });
                      },
                    ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Alt Kategori',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              if (subs.isEmpty)
                const Text(
                  'Bu ana kategoride alt kategori yok. Kategoriler ekranından ekleyin.',
                  style: TextStyle(color: AppColors.subText),
                )
              else
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final sub in subs)
                      FilterChip(
                        label: Text(sub.title),
                        selected: currentSub == sub.title,
                        selectedColor: AppColors.selected,
                        checkmarkColor: AppColors.primary,
                        onSelected: (_) {
                          setState(() {
                            _category.text = sub.title;
                            _extraCategories.remove(sub.title);
                          });
                        },
                      ),
                  ],
                ),
              if (!subExists && currentSub.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  'Seçili alt kategori listede yok: $currentSub',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
              const SizedBox(height: 8),
              Text(
                'Seçim: ${selectedMain.title}'
                '${currentSub.isEmpty ? '' : ' > $currentSub'}',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subs.where((s) => s.title != currentSub).isNotEmpty) ...[
                const SizedBox(height: 22),
                const Text(
                  'Ayrıca şu alt kategorilerde de göster',
                  style: TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Ürün ana kategorisinde kalır; seçilen vitrinlerde de listelenir. Aynı üründen kopya açılmaz.',
                  style: TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    for (final sub in subs)
                      if (sub.title != currentSub)
                        FilterChip(
                          label: Text(sub.title),
                          selected: _extraCategories.contains(sub.title),
                          selectedColor: AppColors.selected,
                          checkmarkColor: AppColors.primary,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _extraCategories.add(sub.title);
                              } else {
                                _extraCategories.remove(sub.title);
                              }
                            });
                          },
                        ),
                  ],
                ),
              ],
              const SizedBox(height: 22),
              const Text(
                'Hediye sayfasında göster',
                style: TextStyle(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              const Text(
                'Yaş mama, ödül veya başka bir ürünü Hediye Seç ekranına da koyabilirsiniz.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              _placementSwitch(
                title: 'Hediye Seçenekleri',
                subtitle: 'Sipariş hediyesi listesinde görünsün.',
                value: _showAsGift,
                onChanged: (value) => setState(() => _showAsGift = value),
              ),
              const SizedBox(height: 8),
              _placementSwitch(
                title: 'Premium Hediyeler',
                subtitle: '₺4.000+ kademesindeki premium listede görünsün.',
                value: _showAsPremiumGift,
                onChanged: (value) =>
                    setState(() => _showAsPremiumGift = value),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildGeneralSection() {
    return _panel(
      title: 'Ürün Bilgileri ve Fiyatlandırma',
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _field(_title, 'Ürün Adı')),
              const SizedBox(width: 12),
              Expanded(child: _field(_weight, 'Ağırlık (ör. 2 Kg)')),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _barcode,
                  'Barkod / Stok kodu',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: _field(_stock, 'Ana Stok')),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _field(
                  _oldPrice,
                  'Liste / Eski Fiyat',
                  keyboard: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _unitPrice,
                  'Satış Fiyatı',
                  keyboard: TextInputType.number,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _field(
                  _discount,
                  'İndirim Oranı (%)',
                  keyboard: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                ),
              ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 280),
              child: _vatRateField(),
            ),
          ),
          const Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Barkod ve stok kodu aynı numaradır. Satış fiyatı KDV dahildir.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Uygulama vitrin değerleri',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 4),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ürün detayındaki puan, protein, tercih sırası ve tekrar alım.',
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _sktField()),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(_proteinValue, 'Protein değeri (ör. %42 veya 42)'),
                    const Text(
                      'Protein İçerir seçiliyse detayda et ikonu, %42 ve etiket '
                      'Puan / Çok Satan Ürün ile aynı yapıda gösterilir.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      _rating,
                      'Puan (ör. 4.9)',
                      keyboard: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                    ),
                    const Text(
                      'Güven Rozetleri sekmesinde Puan / Değerlendirme seçiliyse '
                      'ikon ile "Puan" yazısının arasında görünür.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
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
                    _field(_preferredRank, 'Tercih sırası (ör. 1. veya 2.)'),
                    const Text(
                      'Çok Satan Ürün rozeti seçiliyse madalya içindeki rakam '
                      'olarak görünür.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(
                      _repurchaseRate,
                      'Tekrar alım oranı (ör. %78 veya 78)',
                    ),
                    const Text(
                      'Sol sütunda ikon + oran + Tekrar Alım olarak görünür. '
                      'Şimdilik geçici değer; müşteri alışkanlığına göre '
                      'güncellenecek.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(child: SizedBox.shrink()),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Aktif (satışta)',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Pasif ürünler mobil uygulamada gösterilmez.',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _active,
                activeThumbColor: AppColors.primary,
                onChanged: (v) => setState(() => _active = v),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          const SizedBox(height: 16),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Ürün Açıklaması',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 10),
          _field(_description, 'Ürünü kısaca anlatın…', maxLines: 8),
        ],
      ),
    );
  }

  Widget _buildBrandSection() {
    return FutureBuilder<List<AppBrand>>(
      future: _brandsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            ),
          );
        }

        final brands = snapshot.data!;
        final query = _brandSearch.text.trim().toLowerCase();
        final visible = query.isEmpty
            ? brands
            : brands
                .where((b) => b.name.toLowerCase().contains(query))
                .toList();
        final current = _brand.text.trim();
        if (brands.isEmpty) {
          return _panel(
            title: 'Marka Seçimi',
            subtitle: 'Önce Ürün Yönetimi → Markalar ekranından marka ekleyin.',
            child: const Text('Marka bulunamadı.'),
          );
        }

        return _panel(
          title: 'Marka Seçimi',
          subtitle:
              'Ürünün markasını listeden seçin. Marka ekleme ve görseller '
              'Ürün Yönetimi → Markalar sayfasından yönetilir.',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: _brandSearch,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: 'Marka ara',
                  prefixIcon: const Icon(Icons.search_rounded),
                  isDense: true,
                  filled: true,
                  fillColor: AppColors.background,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              if (current.isNotEmpty) ...[
                Text(
                  'Seçili: $current',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  for (final brand in visible)
                    _BrandChoiceTile(
                      brand: brand,
                      selected: current == brand.name,
                      onTap: () => setState(() => _brand.text = brand.name),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImagesSection() {
    return _panel(
      title: 'Ürün Resimleri',
      subtitle:
          'Ana ürün görselini ve galeri resimlerini yükleyin. PNG, JPG veya WEBP kullanabilirsiniz.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Ana Ürün Görseli',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imagePreview(
                _imageUrl.text,
                size: 150,
                bytes: _mainImagePreviewBytes,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _field(_imageUrl, 'Görsel URL'),
                    OutlinedButton.icon(
                      onPressed: _uploading ? null : () => _pickMainImage(),
                      icon: const Icon(Icons.upload_rounded),
                      label: const Text('Bilgisayardan Görsel Yükle'),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Galeri Görselleri',
                  style: TextStyle(
                    color: AppColors.text,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              FilledButton.icon(
                onPressed: _uploading ? null : _pickGalleryImages,
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: const Text('Galeriye Resim Ekle'),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (final url in _gallery)
                Stack(
                  children: [
                    _imagePreview(url, size: 112),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton.filled(
                        onPressed: () => setState(() => _gallery.remove(url)),
                        icon: const Icon(Icons.close, size: 15),
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.error,
                          minimumSize: const Size(28, 28),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              if (_gallery.isEmpty)
                const Text(
                  'Henüz galeri görseli eklenmedi.',
                  style: TextStyle(color: AppColors.subText),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Eski ürün kayıtlarının geriye dönük düzenlenmesi için tutuluyor.
  // ignore: unused_element
  Widget _buildFeaturesSection({
    required String title,
    required String explanation,
    required List<AdminProductFeature> items,
    required bool technical,
  }) {
    return _panel(
      title: title,
      subtitle: explanation,
      trailing: FilledButton.icon(
        onPressed: () =>
            _showFeatureDialog(target: items, technical: technical),
        icon: const Icon(Icons.add),
        label: const Text('Yeni İkon ve Özellik Ekle'),
      ),
      child: items.isEmpty
          ? Container(
              height: 180,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                'Henüz özellik eklenmedi.',
                style: TextStyle(
                  color: AppColors.subText,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          : GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 360,
                mainAxisExtent: 142,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      _imagePreview(item.iconUrl, size: 64),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              item.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.text,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            Text(
                              item.description,
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppColors.subText,
                                fontSize: 11,
                                height: 1.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        children: [
                          IconButton(
                            tooltip: 'Düzenle',
                            onPressed: () => _showFeatureDialog(
                              target: items,
                              technical: technical,
                              index: index,
                            ),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                          ),
                          IconButton(
                            tooltip: 'Sil',
                            onPressed: () =>
                                setState(() => items.removeAt(index)),
                            icon: const Icon(
                              Icons.delete_outline,
                              size: 18,
                              color: AppColors.error,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSeoSection() {
    return _panel(
      title: 'Arama Motoru Bilgileri',
      child: Column(
        children: [
          _field(_seoTitle, 'Sayfa Başlığı (Tarayıcı Başlığı)'),
          _field(
            _metaDescription,
            'Kısa Tanım (Meta Description)',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _placementSwitch({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
      decoration: BoxDecoration(
        color: value ? AppColors.selected : AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            activeThumbColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _panel({
    required String title,
    required Widget child,
    String? subtitle,
    Widget? trailing,
  }) {
    return Material(
      color: AppColors.surface,
      elevation: 0,
      shadowColor: AppColors.text.withValues(alpha: 0.04),
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.text.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            color: AppColors.subText,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                trailing ?? const SizedBox.shrink(),
              ],
            ),
            const Divider(height: 28, color: AppColors.border),
            child,
          ],
        ),
      ),
    );
  }

  Widget _buildSaveBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        children: [
          OutlinedButton(
            onPressed: _saving ? null : _close,
            child: const Text('Listeye dön'),
          ),
          const Spacer(),
          if (_section > 0)
            OutlinedButton.icon(
              onPressed: () => setState(() => _section -= 1),
              icon: const Icon(Icons.chevron_left_rounded),
              label: const Text('Geri'),
            ),
          if (_section > 0) const SizedBox(width: 8),
          if (_section < _steps.length - 1)
            FilledButton.tonalIcon(
              onPressed: () => setState(() => _section += 1),
              icon: const Icon(Icons.chevron_right_rounded),
              label: const Text('İleri'),
            ),
          if (_section < _steps.length - 1) const SizedBox(width: 8),
          FilledButton.icon(
            onPressed: _saving || _uploading ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 17,
                    height: 17,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppColors.surface,
                    ),
                  )
                : const Icon(Icons.save_outlined),
            label: Text(_isEdit ? 'Güncelle' : 'Ürünü kaydet'),
            style: FilledButton.styleFrom(
              backgroundColor: AdminAccents.products,
              minimumSize: const Size(140, 44),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickMainImage() async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return;

    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (mounted) setState(() => _mainImagePreviewBytes = bytes);

      final url = await _uploadBytes(bytes, file.name, 'products/main');
      if (!mounted) return;
      setState(() => _imageUrl.text = url);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Ürün görseli yüklendi.')));
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Görsel yüklenemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _pickGalleryImages() async {
    final files = await FilePicker.pickFiles(type: FileType.image);
    if (files.isEmpty) return;
    setState(() => _uploading = true);
    try {
      for (final file in files) {
        final bytes = await file.readAsBytes();
        final url = await _uploadBytes(bytes, file.name, 'products/gallery');
        _gallery.add(url);
      }
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Görsel yüklenemedi: $e')));
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<String?> _pickAndUploadImage(String folder) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      return await _uploadBytes(bytes, file.name, folder);
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

  Future<String> _uploadBytes(
    Uint8List bytes,
    String fileName,
    String folder,
  ) async {
    final safeName = fileName.replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
    final ref = FirebaseStorage.instance.ref(
      '$folder/${DateTime.now().microsecondsSinceEpoch}_$safeName',
    );
    await ref.putData(
      bytes,
      SettableMetadata(contentType: _contentTypeFor(fileName)),
    );
    return ref.getDownloadURL();
  }

  String _contentTypeFor(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    if (lower.endsWith('.svg')) return 'image/svg+xml';
    return 'image/jpeg';
  }

  Future<void> _showFeatureDialog({
    required List<AdminProductFeature> target,
    required bool technical,
    int? index,
  }) async {
    final existing = index == null ? null : target[index];
    final title = TextEditingController(text: existing?.title ?? '');
    final description = TextEditingController(
      text: existing?.description ?? '',
    );
    final iconUrl = TextEditingController(text: existing?.iconUrl ?? '');
    var uploading = false;

    final result = await showDialog<AdminProductFeature>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(
                index == null
                    ? (technical ? 'Güven Rozeti Ekle' : 'Ürün Özelliği Ekle')
                    : (technical
                          ? 'Güven Rozetini Düzenle'
                          : 'Ürün Özelliğini Düzenle'),
              ),
              content: SizedBox(
                width: 560,
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        technical
                            ? 'Güven rozeti — ürün görselinin sol yanında gösterilir.'
                            : 'Ürün özelliği — ilk 5 ürün görselinin sağında, fazlası alt listede gösterilir.',
                        style: const TextStyle(color: AppColors.subText),
                      ),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          _imagePreview(iconUrl.text, size: 92),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                TextField(
                                  controller: iconUrl,
                                  decoration: const InputDecoration(
                                    labelText: 'İkon Görsel URL',
                                    border: OutlineInputBorder(),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton.icon(
                                  onPressed: uploading
                                      ? null
                                      : () async {
                                          setDialogState(
                                            () => uploading = true,
                                          );
                                          final url = await _pickAndUploadImage(
                                            technical
                                                ? 'products/technical-icons'
                                                : 'products/feature-icons',
                                          );
                                          if (url != null) {
                                            iconUrl.text = url;
                                          }
                                          setDialogState(
                                            () => uploading = false,
                                          );
                                        },
                                  icon: const Icon(Icons.upload_rounded),
                                  label: Text(
                                    uploading
                                        ? 'Yükleniyor...'
                                        : 'İkon Görseli Yükle',
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: title,
                        decoration: const InputDecoration(
                          labelText: 'Özellik Başlığı',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: description,
                        maxLines: 4,
                        decoration: const InputDecoration(
                          labelText: 'Özellik Açıklaması',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: uploading
                      ? null
                      : () {
                          if (title.text.trim().isEmpty) return;
                          Navigator.pop(
                            dialogContext,
                            AdminProductFeature(
                              title: title.text,
                              description: description.text,
                              iconUrl: iconUrl.text,
                            ),
                          );
                        },
                  child: const Text('Ekle'),
                ),
              ],
            );
          },
        );
      },
    );

    title.dispose();
    description.dispose();
    iconUrl.dispose();
    if (result == null) return;
    setState(() {
      if (index == null) {
        target.add(result);
      } else {
        target[index] = result;
      }
    });
  }

  Widget _imagePreview(String url, {required double size, Uint8List? bytes}) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: bytes != null
          ? Image.memory(
              bytes,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const Icon(
                Icons.broken_image_outlined,
                color: AppColors.error,
              ),
            )
          : url.trim().isEmpty
          ? const Icon(Icons.image_outlined, color: AppColors.subText, size: 28)
          : buildProductImage(
              url,
              fit: BoxFit.contain,
              errorWidget: const Icon(
                Icons.broken_image_outlined,
                color: AppColors.error,
              ),
            ),
    );
  }

  Future<void> _pickSktMonthYear() async {
    final now = DateTime.now();
    final parsed = ProductSkt.parse(_skt.text);
    var month = parsed?.month ?? now.month;
    var year = parsed?.year ?? now.year + 1;
    final years = [for (var y = now.year; y <= now.year + 10; y++) y];
    if (!years.contains(year)) {
      year = years.last;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Son kullanma (ay / yıl)'),
              content: Row(
                children: [
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Ay',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: month,
                          isExpanded: true,
                          items: [
                            for (var i = 1; i <= 12; i++)
                              DropdownMenuItem(
                                value: i,
                                child: Text(ProductSkt.monthsTr[i - 1]),
                              ),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setDialogState(() => month = v);
                          },
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Yıl',
                        border: OutlineInputBorder(),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          value: year,
                          isExpanded: true,
                          items: [
                            for (final y in years)
                              DropdownMenuItem(value: y, child: Text('$y')),
                          ],
                          onChanged: (v) {
                            if (v == null) return;
                            setDialogState(() => year = v);
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Vazgeç'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  child: const Text('Seç'),
                ),
              ],
            );
          },
        );
      },
    );
    if (ok != true) return;
    setState(() {
      _skt.text = ProductSkt.format(month, year);
      _skt.selection = TextSelection.collapsed(offset: _skt.text.length);
    });
  }

  Widget _sktField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: _skt,
        readOnly: true,
        onTap: _pickSktMonthYear,
        decoration: InputDecoration(
          labelText: 'SKT (Ay / Yıl)',
          hintText: 'Örn. 11.2027',
          helperText: 'Takvimden ay ve yıl seç; uygulamada 11.2027 gibi görünür.',
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.surface,
          suffixIcon: IconButton(
            tooltip: 'Ay ve yıl seç',
            onPressed: _pickSktMonthYear,
            icon: const Icon(Icons.calendar_month_outlined),
          ),
        ),
      ),
    );
  }

  Widget _vatRateField() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'KDV oranı',
          hintText: 'Satış fiyatı KDV dahil',
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.selected,
        ),
        child: DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _vatRate,
            isExpanded: true,
            isDense: true,
            items: [
              for (final rate in ProductFields.vatRates)
                DropdownMenuItem(value: rate, child: Text('%$rate')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _vatRate = value);
            },
          ),
        ),
      ),
    );
  }

  Widget _field(
    TextEditingController c,
    String label, {
    TextInputType? keyboard,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: keyboard,
        maxLines: maxLines,
        inputFormatters: inputFormatters,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.surface,
        ),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: AppColors.background,
        ),
        child: Text(
          value,
          style: const TextStyle(
            color: AppColors.text,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _BrandChoiceTile extends StatelessWidget {
  const _BrandChoiceTile({
    required this.brand,
    required this.selected,
    required this.onTap,
  });

  final AppBrand brand;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        brand.name.isEmpty ? '?' : brand.name.characters.first,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final image = brand.imageUrl.isNotEmpty
        ? Image.network(
            brand.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => fallback,
          )
        : brand.assetPath.isNotEmpty
        ? Image.asset(
            brand.assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => fallback,
          )
        : fallback;

    return Material(
      color: selected ? AppColors.selected : AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 56, child: image),
              const SizedBox(height: 10),
              Text(
                brand.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? AppColors.primary : AppColors.subText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AdvantageChoiceTile extends StatelessWidget {
  const _AdvantageChoiceTile({
    required this.item,
    required this.selected,
    required this.onTap,
    this.order,
  });

  final AppProductAdvantage item;
  final bool selected;
  final VoidCallback onTap;
  final int? order;

  @override
  Widget build(BuildContext context) {
    final isStat = ProductAdvantageRepository.displaysAsStat(item);
    final fallback = Center(
      child: Text(
        item.name.isEmpty ? '?' : item.name.characters.first,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final imagePath = isStat
        ? ProductAdvantageRepository.proteinIconPath
        : (item.imageUrl.isNotEmpty ? item.imageUrl : item.assetPath);
    final image = imagePath.isNotEmpty
        ? buildProductImage(
            imagePath,
            fit: BoxFit.contain,
            filterQuality: FilterQuality.high,
            errorWidget: fallback,
          )
        : fallback;
    final isHeroSlot =
        order != null && order! <= ProductAdvantageRepository.heroSlotCount;
    return Material(
      color: selected ? AppColors.selected : AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 56,
                child: Stack(
                  children: [
                    Positioned.fill(child: image),
                    if (order != null)
                      Positioned(
                        left: 0,
                        top: 0,
                        child: Container(
                          width: 22,
                          height: 22,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$order',
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontSize: 11,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              Text(
                item.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (order != null) ...[
                const SizedBox(height: 4),
                Text(
                  isHeroSlot ? 'Sağ sütun' : 'Alt alan',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: selected ? AppColors.primary : AppColors.subText,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
              const SizedBox(height: 6),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? AppColors.primary : AppColors.subText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TrustBadgeChoiceTile extends StatelessWidget {
  const _TrustBadgeChoiceTile({
    required this.badge,
    required this.selected,
    required this.onTap,
  });

  final AppTrustBadge badge;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final fallback = Center(
      child: Text(
        badge.name.isEmpty ? '?' : badge.name.characters.first,
        style: const TextStyle(
          color: AppColors.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
    final isPreferred =
        badge.id == 'en-cok-tercih' ||
        badge.name.toLowerCase().contains('tercih');
    final isProtein = TrustBadgeRepository.isProteinBadge(badge);
    final isRepurchase = TrustBadgeRepository.isRepurchaseBadge(badge);
    final isAffordable = TrustBadgeRepository.isAffordableBadge(badge);
    final imagePath = isPreferred
        ? TrustBadgeRepository.preferredIconPath
        : isProtein
        ? TrustBadgeRepository.proteinIconPath
        : isRepurchase
        ? TrustBadgeRepository.repurchaseIconPath
        : isAffordable
        ? TrustBadgeRepository.affordableIconPath
        : (badge.imageUrl.isNotEmpty ? badge.imageUrl : badge.assetPath);
    final Widget image;
    if (isPreferred && imagePath.isNotEmpty) {
      image = PreferredRankMedal(rank: '2.', errorWidget: fallback);
    } else {
      image = imagePath.isNotEmpty
          ? buildProductImage(
              imagePath,
              fit: BoxFit.contain,
              filterQuality: FilterQuality.high,
              errorWidget: fallback,
            )
          : fallback;
    }

    return Material(
      color: selected ? AppColors.selected : AppColors.background,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          width: 170,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected ? AppColors.primary : AppColors.border,
              width: selected ? 1.6 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 56, child: image),
              const SizedBox(height: 10),
              Text(
                TrustBadgeRepository.displayName(badge),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                size: 18,
                color: selected ? AppColors.primary : AppColors.subText,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
