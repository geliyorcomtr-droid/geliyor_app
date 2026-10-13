import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

/// Sahiplendirme ve İlan Ekle sayfalarındaki ilan türü kutusu.
/// Görsel aynı banner kaydından gelir; adminde değişince iki sayfa da güncellenir.
class AdoptionTypeBox extends StatelessWidget {
  const AdoptionTypeBox({
    super.key,
    required this.categoryId,
    required this.selected,
    required this.onTap,
    this.count,
    this.showCheck = false,
  });

  final String categoryId;
  final bool selected;
  final VoidCallback onTap;
  final int? count;
  final bool showCheck;

  static ({
    IconData icon,
    Color color,
    Color fill,
    BannerPlacement placement,
  }) styleFor(String id) {
    return switch (id) {
      AdoptionCategories.lost => (
          icon: Icons.search_rounded,
          color: AppColors.primary,
          fill: AppColors.selected,
          placement: BannerPlacement.adoptionBoxLost,
        ),
      AdoptionCategories.found => (
          icon: Icons.pets_rounded,
          color: Color(0xFF34D399),
          fill: Color(0xFFE6F9F0),
          placement: BannerPlacement.adoptionBoxFound,
        ),
      _ => (
          icon: Icons.home_rounded,
          color: AppColors.discount,
          fill: Color(0xFFFFF3E0),
          placement: BannerPlacement.adoptionBoxAdopt,
        ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final style = styleFor(categoryId);
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
            color: selected ? style.color : style.color.withValues(alpha: 0.22),
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
              final image = _imageFor(style.placement, snapshot.data?.docs);
              if (image == null) return _iconBody(style);
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
                    child: _badge(style.color),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _iconBody(
    ({IconData icon, Color color, Color fill, BannerPlacement placement})
    style,
  ) {
    return ColoredBox(
      color: style.fill,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 4, 4),
        child: Column(
          children: [
            Expanded(
              child: FittedBox(
                fit: BoxFit.contain,
                child: Icon(style.icon, color: style.color, size: 48),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                AdoptionCategories.label(categoryId),
                textAlign: TextAlign.center,
                maxLines: 1,
                style: TextStyle(
                  color: style.color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
            ),
            Text(
              AdoptionCategories.subtitle(categoryId),
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
            _badge(style.color),
          ],
        ),
      ),
    );
  }

  Widget _badge(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
      child: showCheck
          ? Icon(
              selected ? Icons.check_rounded : Icons.circle_outlined,
              size: 12,
              color: AppColors.surface,
            )
          : Text(
              '${count ?? 0}',
              style: const TextStyle(
                color: AppColors.surface,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
    );
  }

  String? _imageFor(
    BannerPlacement placement,
    List<QueryDocumentSnapshot<Map<String, dynamic>>>? docs,
  ) {
    final seeded = placement.id == BannerPlacement.adoptionBoxAdopt.id;
    const fallback = 'assets/images/sahiplendirme_kutu.jpg';
    const seededId = 'adoption-box-adopt';
    if (docs == null) return seeded ? fallback : null;
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
    if (seeded && deleted.contains(seededId)) return null;
    return seeded ? fallback : null;
  }
}
