import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_models.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/order_repository.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class GiftSelectScreen extends StatefulWidget {
  const GiftSelectScreen({
    super.key,
    this.orderTotal = 4250,
    this.orderId = '',
  });

  final double orderTotal;
  final String orderId;

  @override
  State<GiftSelectScreen> createState() => _GiftSelectScreenState();
}

class _GiftSelectScreenState extends State<GiftSelectScreen> {
  late int selectedTier;
  final Map<String, _GiftItem> selectedGifts = {};
  bool _saving = false;
  bool _locked = false;
  bool _loadingOrder = true;
  String _boundOrderId = '';

  final List<_GiftTier> tiers = const [
    _GiftTier(id: 0, label: '₺1.000–1.999', subtitle: 'Bronz', maxSelect: 1),
    _GiftTier(id: 1, label: '₺2.000–3.999', subtitle: 'Altın', maxSelect: 1),
    _GiftTier(id: 2, label: '₺4.000+', subtitle: 'Premium', maxSelect: 1),
  ];


  @override
  void initState() {
    super.initState();
    selectedTier = widget.orderId.trim().isEmpty
        ? -1
        : _tierFromTotal(widget.orderTotal);
    _loadOrderChoice();
  }

  Future<void> _loadOrderChoice() async {
    final orderId = await _resolveOrderId();
    if (!mounted) return;
    if (orderId.isEmpty) {
      setState(() {
        _loadingOrder = false;
        _locked = true;
        selectedTier = -1;
      });
      return;
    }
    final choice = await OrderRepository.instance.giftChoice(orderId);
    if (!mounted) return;
    final saved = choice?.gifts ?? const <Map<String, dynamic>>[];
    setState(() {
      _boundOrderId = orderId;
      _loadingOrder = false;
      if (choice != null) {
        selectedTier = _tierFromTotal(choice.total);
      }
      _locked = saved.isNotEmpty;
      if (_locked) {
        selectedGifts
          ..clear()
          ..addEntries(
            saved.map((item) {
              final gift = _giftFromSaved(item);
              return MapEntry(gift.id, gift);
            }),
          );
      }
    });
  }

  _GiftItem _giftFromSaved(Map<String, dynamic> item) {
    final id = '${item['productId'] ?? item['id'] ?? ''}'.trim();
    final title = '${item['title'] ?? ''}'.trim();
    return _GiftItem(
      id: id.isEmpty ? title : id,
      title: title.isEmpty ? 'Hediye' : title,
      points: '',
      imagePath: '${item['imageUrl'] ?? item['imagePath'] ?? ''}'.trim(),
    );
  }

  int _tierFromTotal(double total) {
    if (total >= 4000) return 2;
    if (total >= 2000) return 1;
    if (total >= 1000) return 0;
    return -1;
  }

  int get maxSelect => selectedTier < 0 ? 0 : tiers[selectedTier].maxSelect;

  String _formatPrice(double price) {
    final whole = price.round().toString();
    final buffer = StringBuffer();
    for (int i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return '${buffer.toString()} TL';
  }

  void _toggleGift(_GiftItem gift) {
    if (_locked || _loadingOrder || selectedTier < 0) return;
    setState(() {
      if (selectedGifts.containsKey(gift.id)) {
        selectedGifts.remove(gift.id);
        return;
      }
      selectedGifts
        ..clear()
        ..[gift.id] = gift;
    });
  }

  _GiftItem _giftFromProduct(AdminProduct product) {
    final title = product.title.trim().isEmpty
        ? 'Hediye'
        : product.title.trim();
    final strike = product.oldPrice > 0 ? product.oldPrice : product.unitPrice;
    return _GiftItem(
      id: product.id,
      title: title,
      points: strike > 0 ? _formatPrice(strike) : '',
      imagePath: product.imageUrl.trim(),
    );
  }

  List<_GiftItem> _resolveGifts(List<AdminProduct> products) {
    if (selectedTier < 0) return const [];
    return [
      for (final product in products)
        if (product.giftTier == selectedTier) _giftFromProduct(product),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        header: _buildHeader(),
        content: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 12),
              _buildTierSection(),
              const SizedBox(height: 12),
              StreamBuilder<List<AdminProduct>>(
                stream: ProductRepository.instance.watchAll(
                  activeOnly: true,
                  inStockOnly: true,
                ),
                builder: (context, snapshot) {
                  final products = snapshot.data ?? const <AdminProduct>[];
                  return _buildGiftSection(
                    number: '2',
                    title: 'Hediye Seçenekleri',
                    subtitle: _locked
                        ? 'Hediye seçimin tamamlandı.'
                        : selectedTier < 0
                        ? 'Bu sipariş tutarında hediye hakkı yok.'
                        : 'Bu kademeden ${tiers[selectedTier].maxSelect} hediye seçebilirsin.',
                    items: _resolveGifts(products),
                    enabled: !_locked && !_loadingOrder && selectedTier >= 0,
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildInfoBanner(),
              const SizedBox(height: 10),
              _buildConfirmButton(),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(activeTab: AppNavTab.home),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          const Expanded(
            child: Text(
              'Hediye Seç',
              textAlign: TextAlign.center,
              style: AppTextStyles.pageHeader,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.selected,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.primary,
                  size: 13,
                ),
                const SizedBox(width: 4),
                Text(
                  '${selectedGifts.length}/$maxSelect',
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    const fallback = 'assets/images/hediye_sec_banner.jpg';
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(FirestoreCollections.banners)
          .snapshots(),
      builder: (context, snapshot) {
        var path = fallback;
        var hidden = false;
        final docs = snapshot.data?.docs;
        if (docs != null) {
          final deleted = <String>{};
          for (final doc in docs) {
            if (doc.id != BannerRepository.seededDocId) continue;
            final raw = doc.data()['deletedIds'];
            if (raw is Iterable) {
              deleted.addAll(raw.map((item) => item.toString()));
            }
          }
          final live = [
            for (final doc in docs)
              if (!doc.id.startsWith('_')) AppBanner.fromDoc(doc),
          ].where((banner) {
            return banner.active &&
                banner.placement == BannerPlacement.giftSelect.id &&
                banner.displayImage.trim().isNotEmpty;
          }).toList();
          final picked = AppBanner.latestLive(live);
          if (picked != null) {
            path = picked.displayImage;
          } else if (deleted.contains('hediye-sec')) {
            hidden = true;
          }
        }
        if (hidden) return const SizedBox.shrink();
        return LayoutBuilder(
          builder: (context, constraints) {
            const framePad = 3.0;
            final width = constraints.maxWidth - framePad * 2;
            final height = width * 140 / 361;
            return Container(
              padding: const EdgeInsets.all(framePad),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.25),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(21),
                child: SizedBox(
                  width: width,
                  height: height,
                  child: buildProductImage(
                    path,
                    fit: BoxFit.fill,
                    width: width,
                    height: height,
                    cacheWidth: 1024,
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildTierSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('1', 'Hediye Kademesi'),
        const SizedBox(height: 8),
        Row(
          children: [
            for (int i = 0; i < tiers.length; i++) ...[
              Expanded(child: _buildTierTab(tiers[i])),
              if (i != tiers.length - 1) const SizedBox(width: 8),
            ],
          ],
        ),
      ],
    );
  }

  Widget _buildTierTab(_GiftTier tier) {
    final isSelected = selectedTier == tier.id;

    return Opacity(
      opacity: isSelected ? 1 : 0.4,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
          ),
        ),
        child: Column(
          children: [
            Text(
              tier.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? AppColors.surface : AppColors.text,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tier.subtitle,
              style: TextStyle(
                color: isSelected ? AppColors.surface : AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGiftSection({
    required String number,
    required String title,
    required String subtitle,
    required List<_GiftItem> items,
    required bool enabled,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(number, title),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: AppColors.subText,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        if (items.isEmpty)
          Container(
            height: 80,
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(
              enabled
                  ? 'Bu kademe için henüz hediye işaretlenmedi.'
                  : 'Bu sipariş tutarında hediye hakkı yok.',
              style: const TextStyle(
                color: AppColors.subText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        else
          Opacity(
            opacity: enabled ? 1 : 0.45,
            child: _buildGiftGrid(items, enabled: enabled),
          ),
      ],
    );
  }

  Widget _buildGiftGrid(List<_GiftItem> items, {required bool enabled}) {
    const columns = 3;
    const gap = 8.0;
    final rows = <Widget>[];
    for (var start = 0; start < items.length; start += columns) {
      rows.add(
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var column = 0; column < columns; column++) ...[
              if (column > 0) const SizedBox(width: gap),
              Expanded(
                child: start + column < items.length
                    ? _buildGiftCard(items[start + column], enabled: enabled)
                    : const SizedBox.shrink(),
              ),
            ],
          ],
        ),
      );
      if (start + columns < items.length) {
        rows.add(const SizedBox(height: gap));
      }
    }
    return Column(children: rows);
  }

  Widget _buildGiftCard(_GiftItem gift, {required bool enabled}) {
    final isSelected = selectedGifts.containsKey(gift.id);
    final canSelect = enabled;

    return GestureDetector(
      onTap: canSelect ? () => _toggleGift(gift) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.border,
            width: isSelected ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Spacer(),
                Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : AppColors.surface,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.primary, width: 1.3),
                  ),
                  child: isSelected
                      ? const Icon(
                          Icons.check_rounded,
                          color: AppColors.surface,
                          size: 14,
                        )
                      : null,
                ),
              ],
            ),
            SizedBox(
              height: 64,
              width: double.infinity,
              child: buildProductImage(
                gift.imagePath,
                fit: BoxFit.contain,
                errorWidget: const Icon(
                  Icons.card_giftcard_rounded,
                  color: AppColors.primary,
                  size: 32,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              gift.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 11,
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
            if (gift.points.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                gift.points,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.subText,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoBanner() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline_rounded, color: AppColors.primary, size: 18),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Hediyeler siparişiniz ile birlikte teslim edilir.',
              style: TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfirmButton() {
    if (_locked) {
      return AppPressableButton.primary(
        onTap: null,
        enabled: false,
        height: 48,
        width: double.infinity,
        child: const Text(
          'İşlem tamam',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
      );
    }
    final ready = !_loadingOrder &&
        maxSelect > 0 &&
        selectedGifts.length == maxSelect &&
        !_saving;

    return AppPressableButton.primary(
      onTap: ready ? _confirmSelection : null,
      enabled: ready,
      height: 48,
      width: double.infinity,
      child: Text(
        _saving
            ? 'Kaydediliyor…'
            : 'Seçimlerini Onayla (${selectedGifts.length}/$maxSelect)',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
  }

  Future<void> _confirmSelection() async {
    if (_locked ||
        _loadingOrder ||
        _saving ||
        maxSelect <= 0 ||
        selectedGifts.length != maxSelect) {
      return;
    }
    setState(() => _saving = true);
    try {
      final orderId = _boundOrderId.isNotEmpty
          ? _boundOrderId
          : await _resolveOrderId();
      if (orderId.isEmpty) {
        throw StateError('Sipariş bulunamadı.');
      }
      await OrderRepository.instance.saveGifts(
        orderId: orderId,
        gifts: [
          for (final gift in selectedGifts.values)
            {
              'productId': gift.id,
              'title': gift.title,
              'imageUrl': gift.imagePath,
              'premium': false,
            },
        ],
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _locked = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('İşlem tamam.'),
          backgroundColor: AppColors.primary,
        ),
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_giftSaveError(error)),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<String> _resolveOrderId() async {
    final fromWidget = widget.orderId.trim();
    if (fromWidget.isNotEmpty) return fromWidget;
    final lastId = OrderStore.instance.lastOrderId.trim();
    if (lastId.isNotEmpty && !lastId.toUpperCase().startsWith('GL-')) {
      return lastId;
    }
    return OrderRepository.instance.latestOrderId();
  }

  String _giftSaveError(Object error) {
    if (error is FirebaseFunctionsException) {
      final message = error.message?.trim() ?? '';
      if (message.isNotEmpty) return message;
    }
    return 'Hediye kaydedilemedi. Lütfen tekrar deneyin.';
  }

  Widget _sectionHeader(String number, String title) {
    return Row(
      children: [
        Container(
          width: 22,
          height: 22,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            number,
            style: const TextStyle(
              color: AppColors.surface,
              fontSize: 11,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(child: Text(title, style: AppTextStyles.sectionHeader)),
      ],
    );
  }

}

class _GiftTier {
  const _GiftTier({
    required this.id,
    required this.label,
    required this.subtitle,
    required this.maxSelect,
  });

  final int id;
  final String label;
  final String subtitle;
  final int maxSelect;
}

class _GiftItem {
  const _GiftItem({
    required this.id,
    required this.title,
    required this.points,
    required this.imagePath,
  });

  final String id;
  final String title;
  final String points;
  final String imagePath;
}
