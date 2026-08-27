import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Ortak kaydırmalı banner yapısı; yükseklik sayfanın kendi ölçüsüne göre.
class AppBannerSlot extends StatelessWidget {
  const AppBannerSlot({
    super.key,
    required this.placement,
    this.fallbackAssets = const [],
  });

  final BannerPlacement placement;
  final List<String> fallbackAssets;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppBanner>>(
      stream: BannerRepository.instance.watchActive(placement: placement.id),
      builder: (context, snapshot) {
        final banners = snapshot.data ?? const <AppBanner>[];
        final images = banners.isEmpty
            ? fallbackAssets
            : banners.map((item) => item.displayImage).toList();
        return AppBannerSlider(
          images: images,
          height: placement.height,
        );
      },
    );
  }
}

class AppBannerSlider extends StatefulWidget {
  const AppBannerSlider({
    super.key,
    required this.images,
    this.height = 132,
  });

  final List<String> images;
  final double height;

  @override
  State<AppBannerSlider> createState() => _AppBannerSliderState();
}

class _AppBannerSliderState extends State<AppBannerSlider> {
  late final PageController _controller;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
  }

  @override
  void didUpdateWidget(covariant AppBannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.images.length != widget.images.length) {
      _index = _index.clamp(
        0,
        widget.images.isEmpty ? 0 : widget.images.length - 1,
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.images;
    if (images.isEmpty) return const SizedBox.shrink();
    final index = _index.clamp(0, images.length - 1);

    return Column(
      children: [
        SizedBox(
          height: widget.height,
          child: Stack(
            alignment: Alignment.center,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(BannerPlacement.radius),
                child: PageView.builder(
                  controller: _controller,
                  itemCount: images.length,
                  onPageChanged: (i) => setState(() => _index = i),
                  itemBuilder: (context, pageIndex) {
                    final path = images[pageIndex];
                    final useContain = path.contains('banner_geliyor');
                    final isNetwork = path.startsWith('http');
                    return ColoredBox(
                      color: AppColors.selected,
                      child: isNetwork
                          ? Image.network(
                              path,
                              fit: useContain ? BoxFit.contain : BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _fallback(),
                            )
                          : Image.asset(
                              path,
                              fit: useContain ? BoxFit.contain : BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              errorBuilder: (context, error, stackTrace) =>
                                  _fallback(),
                            ),
                    );
                  },
                ),
              ),
              if (images.length > 1) ...[
                Positioned(
                  left: 8,
                  child: _arrow(Icons.chevron_left_rounded, () {
                    final prev = (index - 1 + images.length) % images.length;
                    _controller.animateToPage(
                      prev,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                    );
                  }),
                ),
                Positioned(
                  right: 8,
                  child: _arrow(Icons.chevron_right_rounded, () {
                    final next = (index + 1) % images.length;
                    _controller.animateToPage(
                      next,
                      duration: const Duration(milliseconds: 240),
                      curve: Curves.easeOut,
                    );
                  }),
                ),
              ],
            ],
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (dotIndex) {
              final active = dotIndex == index;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: 7,
                height: 7,
                decoration: BoxDecoration(
                  color: active ? AppColors.primary : AppColors.border,
                  shape: BoxShape.circle,
                ),
              );
            }),
          ),
        ],
      ],
    );
  }

  Widget _fallback() {
    return Container(
      color: AppColors.primaryLight,
      alignment: Alignment.center,
      child: const Text(
        'geliyor.tr',
        style: TextStyle(
          color: AppColors.surface,
          fontSize: 24,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }

  Widget _arrow(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
    );
  }
}
