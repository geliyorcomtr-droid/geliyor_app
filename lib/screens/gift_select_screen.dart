import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class GiftSelectScreen extends StatefulWidget {
  const GiftSelectScreen({super.key, this.orderTotal = 4250});

  final double orderTotal;

  @override
  State<GiftSelectScreen> createState() => _GiftSelectScreenState();
}

class _GiftSelectScreenState extends State<GiftSelectScreen> {
  late int selectedTier;
  final Set<String> selectedGiftIds = {};

  final List<_GiftTier> tiers = const [
    _GiftTier(id: 0, label: '₺1.000–1.999', subtitle: '1 Hediye', maxSelect: 1),
    _GiftTier(id: 1, label: '₺2.000–3.999', subtitle: '2 Hediye', maxSelect: 2),
    _GiftTier(id: 2, label: '₺4.000+', subtitle: 'Premium 2', maxSelect: 2),
  ];

  final List<_GiftItem> normalGifts = const [
    _GiftItem(
      id: 'n1',
      title: 'Mama & Su Kabı',
      points: '900 Puan',
      imagePath: 'assets/images/mama_kabi.png',
    ),
    _GiftItem(
      id: 'n2',
      title: 'Somonlu Ödül',
      points: '850 Puan',
      imagePath: 'assets/images/app_ikonlar/somon.png',
    ),
    _GiftItem(
      id: 'n3',
      title: 'Doğal Bakım',
      points: '950 Puan',
      imagePath: 'assets/images/app_ikonlar/dogal_icerik.png',
    ),
    _GiftItem(
      id: 'n4',
      title: 'Yavru Kedi Seti',
      points: '1.100 Puan',
      imagePath: 'assets/images/icons/yavru_kedi.png',
    ),
    _GiftItem(
      id: 'n5',
      title: 'Tavuklu Mama',
      points: '1.000 Puan',
      imagePath: 'assets/images/app_ikonlar/tavuk.png',
    ),
    _GiftItem(
      id: 'n6',
      title: 'Kuzu Etli Mama',
      points: '1.050 Puan',
      imagePath: 'assets/images/app_ikonlar/kuzu.png',
    ),
  ];

  final List<_GiftItem> premiumGifts = const [
    _GiftItem(
      id: 'p1',
      title: 'Akıllı Mama Kabı',
      points: '1.800 Puan',
      imagePath: 'assets/images/market_akilli_pet.png',
    ),
    _GiftItem(
      id: 'p2',
      title: 'Premium Mama 2kg',
      points: '1.500 Puan',
      imagePath: 'assets/images/app_ikonlar/mama_kabi.png',
    ),
    _GiftItem(
      id: 'p3',
      title: 'Taşıma Çantası',
      points: '1.600 Puan',
      imagePath: 'assets/images/market_kedi.png',
    ),
    _GiftItem(
      id: 'p4',
      title: 'Tüy Bakım Seti',
      points: '1.400 Puan',
      imagePath: 'assets/images/app_ikonlar/tuy_deri.png',
    ),
    _GiftItem(
      id: 'p5',
      title: 'Omega Destek',
      points: '1.350 Puan',
      imagePath: 'assets/images/icons/omega.png',
    ),
    _GiftItem(
      id: 'p6',
      title: 'Sokaktakiler Paket',
      points: '1.700 Puan',
      imagePath: 'assets/images/app_ikonlar/sokak.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    selectedTier = _tierFromTotal(widget.orderTotal);
  }

  int _tierFromTotal(double total) {
    if (total >= 4000) return 2;
    if (total >= 2000) return 1;
    if (total >= 1000) return 0;
    return 0;
  }

  int get maxSelect => tiers[selectedTier].maxSelect;

  bool get canSelectPremium => selectedTier == 2;

  bool _isPremiumGift(String id) => id.startsWith('p');

  String get _statusMessage {
    if (selectedTier == 0) {
      return '1 hediye hakkın var. Sadece hediye seçeneklerinden seç.';
    }
    if (selectedTier == 1) {
      return '2 hediye hakkın var. Sadece hediye seçeneklerinden seç.';
    }
    return 'Premium 2 hediye hakkın var. Her iki listeden toplam 2 seç.';
  }

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

  void _toggleGift(String id) {
    setState(() {
      if (selectedGiftIds.contains(id)) {
        selectedGiftIds.remove(id);
        return;
      }
      if (_isPremiumGift(id) && !canSelectPremium) return;
      if (selectedGiftIds.length >= maxSelect) return;
      selectedGiftIds.add(id);
    });
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
              _buildHeroBanner(),
              const SizedBox(height: 12),
              _buildProgressSection(),
              const SizedBox(height: 12),
              _buildTierSection(),
              const SizedBox(height: 12),
              _buildGiftSection(
                number: '3',
                title: 'Hediye Seçenekleri',
                subtitle: selectedTier == 2
                    ? 'Normal hediyelerden de seçebilirsin'
                    : 'Bu kademede sadece buradan seçim yap',
                items: normalGifts,
                enabled: true,
              ),
              const SizedBox(height: 12),
              _buildGiftSection(
                number: '4',
                title: 'Premium Hediyeler',
                subtitle: canSelectPremium
                    ? 'Premium listedenden de seçebilirsin'
                    : 'Bu kademede premium hediye seçilemez',
                items: premiumGifts,
                enabled: canSelectPremium,
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
                  '${selectedGiftIds.length}/$maxSelect',
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

  Widget _buildHeroBanner() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.selected,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(
              Icons.card_giftcard_rounded,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dostun için hediye seç',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _statusMessage,
                  style: const TextStyle(
                    color: AppColors.subText,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = (widget.orderTotal / 4000).clamp(0.0, 1.0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('1', 'Sipariş Tutarı'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: _cardDecoration(),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.selected,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Icon(
                      Icons.pets_rounded,
                      color: AppColors.primary,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Toplam sipariş tutarın',
                      style: TextStyle(
                        color: AppColors.subText,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Text(
                    _formatPrice(widget.orderTotal),
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.selected,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '₺1.000',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₺2.000',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '₺4.000+',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTierSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('2', 'Hediye Kademesi'),
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

    return GestureDetector(
      onTap: () {
        setState(() {
          selectedTier = tier.id;
          selectedGiftIds.clear();
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
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
        SizedBox(
          height: 158,
          child: Opacity(
            opacity: enabled ? 1 : 0.45,
            child: LayoutBuilder(
              builder: (context, constraints) {
                const gap = 10.0;
                const visibleCount = 2.4;
                final cardWidth = (constraints.maxWidth - gap) / visibleCount;

                return ListView.separated(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  itemCount: items.length,
                  separatorBuilder: (context, index) =>
                      const SizedBox(width: gap),
                  itemBuilder: (context, index) => _buildGiftCard(
                    items[index],
                    enabled: enabled,
                    width: cardWidth,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGiftCard(
    _GiftItem gift, {
    required bool enabled,
    required double width,
  }) {
    final isSelected = selectedGiftIds.contains(gift.id);
    final canSelect =
        enabled && (isSelected || selectedGiftIds.length < maxSelect);

    return GestureDetector(
      onTap: canSelect ? () => _toggleGift(gift.id) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: width,
        padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
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
            Expanded(
              child: Center(
                child: Image.asset(
                  gift.imagePath,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.card_giftcard_rounded,
                      color: AppColors.primary,
                      size: 32,
                    );
                  },
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
            const SizedBox(height: 4),
            Text(
              gift.points,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
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
    final ready = selectedGiftIds.length == maxSelect;

    return AppPressableButton.primary(
      onTap: ready
          ? () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    '${selectedGiftIds.length} hediye seçimin onaylandı.',
                  ),
                  backgroundColor: AppColors.primary,
                ),
              );
              Navigator.of(context).maybePop();
            }
          : null,
      enabled: ready,
      height: 48,
      width: double.infinity,
      child: Text(
        'Seçimlerini Onayla (${selectedGiftIds.length}/$maxSelect)',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
      ),
    );
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

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: AppColors.border),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
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
