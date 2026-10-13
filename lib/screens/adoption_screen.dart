import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/adoption_repository.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/screens/adoption_detail_screen.dart';
import 'package:geliyor_app/screens/adoption_submit_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/utils/login_gate.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class AdoptionScreen extends StatefulWidget {
  const AdoptionScreen({super.key, this.initialCategory});

  final String? initialCategory;

  @override
  State<AdoptionScreen> createState() => _AdoptionScreenState();
}

class _AdoptionScreenState extends State<AdoptionScreen> {
  static const _adoptFill = Color(0xFFFFF3E0);
  static const _foundColor = Color(0xFF34D399);
  static const _foundFill = Color(0xFFE6F9F0);

  static const _categories = <({
    String id,
    IconData icon,
    Color color,
    Color fill,
  })>[
    (
      id: AdoptionCategories.adopt,
      icon: Icons.home_rounded,
      color: AppColors.discount,
      fill: _adoptFill,
    ),
    (
      id: AdoptionCategories.lost,
      icon: Icons.search_rounded,
      color: AppColors.primary,
      fill: AppColors.selected,
    ),
    (
      id: AdoptionCategories.found,
      icon: Icons.pets_rounded,
      color: _foundColor,
      fill: _foundFill,
    ),
  ];

  final _searchController = TextEditingController();
  late String _category = widget.initialCategory ?? AdoptionCategories.adopt;
  String _species = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<AdoptionListing> _filter(List<AdoptionListing> listings) {
    final query = _searchController.text.trim().toLowerCase();
    return listings.where((item) {
      if (item.category != _category) return false;
      if (_species.isNotEmpty && item.species != _species) return false;
      if (query.isEmpty) return true;
      final haystack = [
        item.name,
        item.breed,
        item.city,
        item.description,
        item.species,
      ].join(' ').toLowerCase();
      return haystack.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        pawPrintColor: AppColors.warning,
        activeTab: AppNavTab.home,
        header: const AppPageHeader(
          title: 'Sahiplendirme',
          titleColor: AppColors.warning,
          leading: AppBackButton(color: AppColors.warning),
          trailing: AppNotificationButton(),
        ),
        content: StreamBuilder<List<AdoptionListing>>(
          stream: AdoptionRepository.instance.watchApproved(),
          builder: (context, snapshot) {
            final all = snapshot.data ?? const <AdoptionListing>[];
            final visible = _filter(all);
            return ListView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                AppPageFrame.contentHorizontalPadding,
                0,
                AppPageFrame.contentHorizontalPadding,
                12,
              ),
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.25),
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(21),
                    child: const AppBannerStrip(
                      placement: BannerPlacement.adoption,
                      fallbackAsset: 'assets/images/sahiplendirme_banner.jpg',
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                _buildCategoryRow(all),
                const SizedBox(height: 12),
                _buildFilterRow(),
                const SizedBox(height: 10),
                _buildSearchRow(),
                const SizedBox(height: 12),
                if (visible.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: const Text(
                      'Bu kategoride henüz onaylanmış ilan yok.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.subText,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  )
                else
                  for (final listing in visible) ...[
                    _ListingCard(
                      listing: listing,
                      onOpen: () => AdoptionDetailScreen.show(context, listing),
                    ),
                    const SizedBox(height: 10),
                  ],
              ],
            );
          },
        ),
        navbar: const AppBottomNavbar(
          activeTab: AppNavTab.home,
          homeColor: AppColors.warning,
        ),
      ),
    );
  }

  BannerPlacement _boxPlacement(String category) {
    return switch (category) {
      AdoptionCategories.lost => BannerPlacement.adoptionBoxLost,
      AdoptionCategories.found => BannerPlacement.adoptionBoxFound,
      _ => BannerPlacement.adoptionBoxAdopt,
    };
  }

  Widget _buildCategoryRow(List<AdoptionListing> all) {
    return SizedBox(
      height: 118,
      child: Row(
        children: [
          for (var i = 0; i < _categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: _CategoryCard(
                id: _categories[i].id,
                icon: _categories[i].icon,
                color: _categories[i].color,
                fill: _categories[i].fill,
                placement: _boxPlacement(_categories[i].id),
                count: all
                    .where((item) => item.category == _categories[i].id)
                    .length,
                selected: _category == _categories[i].id,
                onTap: () => setState(() => _category = _categories[i].id),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                hintText: 'Tür, ırk, şehir veya anahtar kelime ara...',
                hintStyle: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
                border: InputBorder.none,
                isDense: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openAddListing() async {
    final ok = await LoginGate.require(
      context: context,
      message: 'İlan eklemek için giriş yapmanız gerekir.',
    );
    if (!ok || !mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AdoptionSubmitScreen()),
    );
  }

  Widget _buildFilterRow() {
    const options = ['Tümü', 'Kedi', 'Köpek', 'Diğer'];
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: options.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final option = options[index];
                final selected = option == 'Tümü'
                    ? _species.isEmpty
                    : _species == option;
                return AppPressableButton(
                  onTap: () => setState(() {
                    _species = option == 'Tümü' ? '' : option;
                  }),
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  backgroundColor: selected
                      ? AppColors.warning
                      : AppColors.surface,
                  pressedBackgroundColor: AppColors.warning,
                  foregroundColor: selected
                      ? AppColors.surface
                      : AppColors.text,
                  pressedForegroundColor: AppColors.surface,
                  borderColor: selected
                      ? AppColors.warning
                      : AppColors.warning.withValues(alpha: 0.28),
                  pressedBorderColor: AppColors.warning,
                  builder: (pressed) => Text(
                    option,
                    style: TextStyle(
                      color: selected || pressed
                          ? AppColors.surface
                          : AppColors.text,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(width: 8),
          AppPressableButton(
            onTap: _openAddListing,
            height: 36,
            padding: const EdgeInsets.fromLTRB(12, 0, 10, 0),
            backgroundColor: AppColors.warning,
            pressedBackgroundColor: AppColors.warning.withValues(alpha: 0.82),
            foregroundColor: AppColors.surface,
            pressedForegroundColor: AppColors.surface,
            borderColor: AppColors.warning,
            pressedBorderColor: AppColors.warning,
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16, color: AppColors.surface),
                SizedBox(width: 4),
                Text(
                  'İlan Ekle',
                  style: TextStyle(
                    color: AppColors.surface,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.id,
    required this.icon,
    required this.color,
    required this.fill,
    required this.placement,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final IconData icon;
  final Color color;
  final Color fill;
  final BannerPlacement placement;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  String get _fallbackAsset => placement.id == BannerPlacement.adoptionBoxAdopt.id
      ? 'assets/images/sahiplendirme_kutu.jpg'
      : '';

  String get _seededId => placement.id == BannerPlacement.adoptionBoxAdopt.id
      ? 'adoption-box-adopt'
      : '';

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 118,
        padding: const EdgeInsets.all(3),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? color : color.withValues(alpha: 0.22),
            width: selected ? 1.6 : 1,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection(FirestoreCollections.banners)
                .snapshots(),
            builder: (context, snapshot) {
              final image = _boxImage(snapshot.data?.docs);
              if (image == null) return _iconBody();
              return Stack(
                fit: StackFit.expand,
                children: [
                  ColoredBox(
                    color: AppColors.surface,
                    child: buildProductImage(
                      image,
                      fit: BoxFit.contain,
                      cacheWidth: 512,
                    ),
                  ),
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  String? _boxImage(List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs) {
    final fallback = _fallbackAsset;
    if (docs == null) return fallback.isEmpty ? null : fallback;
    final deleted = <String>{};
    for (final doc in docs) {
      if (doc.id != BannerRepository.seededDocId) continue;
      final raw = doc.data()['deletedIds'];
      if (raw is Iterable) {
        deleted.addAll(raw.map((item) => item.toString()));
      }
    }
    final forSlot = [
      for (final doc in docs)
        if (!doc.id.startsWith('_')) AppBanner.fromDoc(doc),
    ].where((banner) => banner.placement == placement.id).toList();
    final visible = forSlot
        .where(
          (banner) => banner.active && banner.displayImage.trim().isNotEmpty,
        )
        .toList();
    final picked = AppBanner.latestLive(visible);
    if (picked != null && picked.displayImage.trim().isNotEmpty) {
      return picked.displayImage;
    }
    if (forSlot.isNotEmpty) return null;
    if (_seededId.isNotEmpty && deleted.contains(_seededId)) return null;
    return fallback.isEmpty ? null : fallback;
  }

  Widget _iconBody() {
    return ColoredBox(
      color: fill,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Column(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(icon, color: color, size: 48),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AdoptionCategories.label(id),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            Text(
              AdoptionCategories.subtitle(id),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: AppColors.subText,
                fontSize: 8.5,
                fontWeight: FontWeight.w600,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                '$count',
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListingCard extends StatelessWidget {
  const _ListingCard({required this.listing, required this.onOpen});

  final AdoptionListing listing;
  final VoidCallback onOpen;

  String get _speciesBreed {
    final parts = <String>[
      if (listing.species.trim().isNotEmpty) listing.species.trim(),
      if (listing.breed.trim().isNotEmpty) listing.breed.trim(),
    ];
    return parts.join(' • ');
  }

  String get _ageLabel {
    final value = listing.age
        .replaceAll(RegExp(r'ya[sş]', caseSensitive: false), '')
        .trim();
    if (value.isEmpty) return '';
    return 'Yaş $value';
  }

  String get _weightLabel {
    final value = listing.weight
        .replaceAll(RegExp(r'(kilo|kg)', caseSensitive: false), '')
        .trim();
    if (value.isEmpty) return '';
    return 'Kilo $value';
  }

  IconData get _genderIcon {
    final value = listing.gender.toLowerCase();
    if (value.contains('erkek')) return Icons.male_rounded;
    return Icons.female_rounded;
  }

  Color get _accent => switch (listing.category) {
    AdoptionCategories.lost => AppColors.primary,
    AdoptionCategories.found => AppColors.success,
    _ => AppColors.warning,
  };

  @override
  Widget build(BuildContext context) {
    final color = _accent;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onOpen,
      child: Container(
        height: 128,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: color),
        ),
        child: Row(
          children: [
            AspectRatio(
              aspectRatio: 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    listing.coverImage.isEmpty
                        ? ColoredBox(
                            color: AppColors.selected,
                            child: Center(
                              child: Icon(
                                listing.videoUrls.isNotEmpty
                                    ? Icons.play_circle_fill_rounded
                                    : Icons.pets_rounded,
                                color: color,
                              ),
                            ),
                          )
                        : buildProductImage(
                            listing.coverImage,
                            fit: BoxFit.cover,
                            cacheWidth: 400,
                          ),
                    Positioned(
                      left: 6,
                      top: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          listing.badgeLabel,
                          style: const TextStyle(
                            color: AppColors.surface,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 6,
                      bottom: 6,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 5,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.text.withValues(alpha: 0.55),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.photo_camera_outlined,
                              size: 10,
                              color: AppColors.surface,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              '${listing.mediaCount}',
                              style: const TextStyle(
                                color: AppColors.surface,
                                fontSize: 9,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: listing.name,
                                style: AppTextStyles.sectionHeader.copyWith(
                                  color: color,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  height: 1.1,
                                ),
                              ),
                              if (_speciesBreed.isNotEmpty) ...[
                                const WidgetSpan(
                                  alignment: PlaceholderAlignment.middle,
                                  child: SizedBox(width: 10),
                                ),
                                TextSpan(
                                  text: '($_speciesBreed)',
                                  style: TextStyle(
                                    color: color.withValues(alpha: 0.85),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    height: 1.15,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Icon(
                        Icons.favorite_border_rounded,
                        color: color,
                        size: 20,
                      ),
                    ],
                  ),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 2,
                          children: [
                            if (listing.gender.isNotEmpty)
                              _Meta(
                                icon: _genderIcon,
                                label: listing.gender,
                                color: color,
                              ),
                            if (_ageLabel.isNotEmpty)
                              _Meta(
                                icon: Icons.pets_rounded,
                                label: _ageLabel,
                                color: color,
                              ),
                            if (_weightLabel.isNotEmpty)
                              _Meta(
                                icon: Icons.monitor_weight_outlined,
                                label: _weightLabel,
                                color: color,
                              ),
                          ],
                        ),
                        if (listing.city.isNotEmpty)
                          _Meta(
                            icon: Icons.location_on_rounded,
                            label: listing.city,
                            color: color,
                          ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Expanded(
                              child: listing.description.isEmpty
                                  ? const SizedBox.shrink()
                                  : Text(
                                      listing.description,
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        color: color,
                                        fontSize: 12.5,
                                        height: 1.2,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 8),
                            AppPressableButton(
                              onTap: onOpen,
                              height: 28,
                              padding: const EdgeInsets.fromLTRB(10, 0, 6, 0),
                              backgroundColor: color,
                              pressedBackgroundColor: color.withValues(
                                alpha: 0.82,
                              ),
                              foregroundColor: AppColors.surface,
                              pressedForegroundColor: AppColors.surface,
                              borderColor: color,
                              pressedBorderColor: color,
                              builder: (pressed) => const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Detayı Gör',
                                    style: TextStyle(
                                      color: AppColors.surface,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    size: 16,
                                    color: AppColors.surface,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 3),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
