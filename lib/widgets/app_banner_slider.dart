import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/banner_image_preview.dart';

/// Ortak kaydırmalı banner yapısı; yükseklik sayfanın kendi ölçüsüne göre.
class AppBannerSlot extends StatelessWidget {
  const AppBannerSlot({
    super.key,
    required this.placement,
    this.fallbackAssets = const [],
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.openOnTap = true,
  });

  final BannerPlacement placement;
  final List<String> fallbackAssets;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool openOnTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppBanner>>(
      stream: BannerRepository.instance.watchActive(placement: placement.id),
      builder: (context, snapshot) {
        final remote = snapshot.data;
        final banners = remote ?? const <AppBanner>[];
        final items = banners.isNotEmpty
            ? banners
            : [
                if (!snapshot.hasData)
                  for (var i = 0; i < fallbackAssets.length; i++)
                    AppBanner(
                      id: 'fallback-$i',
                      title: '',
                      assetPath: fallbackAssets[i],
                      placement: placement.id,
                      order: i,
                    ),
              ];
        if (items.isEmpty) return const SizedBox.shrink();
        return AppBannerSlider(
          banners: items,
          height: placement.height,
          autoPlay: autoPlay,
          autoPlayInterval: autoPlayInterval,
          openOnTap: openOnTap,
        );
      },
    );
  }
}

class AppBannerSlider extends StatefulWidget {
  const AppBannerSlider({
    super.key,
    required this.banners,
    this.height = 132,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.openOnTap = true,
  });

  final List<AppBanner> banners;
  final double height;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool openOnTap;

  @override
  State<AppBannerSlider> createState() => _AppBannerSliderState();
}

class _AppBannerSliderState extends State<AppBannerSlider> {
  late final PageController _controller;
  Timer? _autoPlayTimer;
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController();
    _startAutoPlay();
  }

  @override
  void didUpdateWidget(covariant AppBannerSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.banners.length != widget.banners.length) {
      _index = _index.clamp(
        0,
        widget.banners.isEmpty ? 0 : widget.banners.length - 1,
      );
    }
    if (oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.autoPlayInterval != widget.autoPlayInterval ||
        oldWidget.banners.length != widget.banners.length) {
      _startAutoPlay();
    }
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    _autoPlayTimer?.cancel();
    if (!widget.autoPlay || widget.banners.length <= 1) return;
    _autoPlayTimer = Timer.periodic(widget.autoPlayInterval, (_) {
      if (!mounted || !_controller.hasClients || widget.banners.length <= 1) {
        return;
      }
      final next = (_index + 1) % widget.banners.length;
      _controller.animateToPage(
        next,
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    });
  }

  void _goTo(int page) {
    if (!_controller.hasClients) return;
    _controller.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
    _startAutoPlay();
  }

  @override
  Widget build(BuildContext context) {
    final banners = widget.banners;
    if (banners.isEmpty) return const SizedBox.shrink();
    final index = _index.clamp(0, banners.length - 1);

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
                  itemCount: banners.length,
                  onPageChanged: (i) {
                    setState(() => _index = i);
                    _startAutoPlay();
                  },
                  itemBuilder: (context, pageIndex) {
                    final banner = banners[pageIndex];
                    final path = banner.displayImage;
                    final useContain = path.contains('banner_geliyor');
                    final isNetwork = path.startsWith('http');
                    final dpr = MediaQuery.devicePixelRatioOf(context);
                    final decodeW =
                        (BannerPlacement.width * dpr).round().clamp(720, 1080);
                    final image = ColoredBox(
                      color: AppColors.selected,
                      child: isNetwork
                          ? Image.network(
                              path,
                              fit: useContain ? BoxFit.contain : BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              cacheWidth: decodeW,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) =>
                                  _fallback(),
                            )
                          : Image.asset(
                              path,
                              fit: useContain ? BoxFit.contain : BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              cacheWidth: decodeW,
                              filterQuality: FilterQuality.medium,
                              errorBuilder: (context, error, stackTrace) =>
                                  _fallback(),
                            ),
                    );
                    if (!widget.openOnTap) return image;
                    return GestureDetector(
                      onTap: () => BannerImagePreview.show(context, banner),
                      child: image,
                    );
                  },
                ),
              ),
              if (banners.length > 1) ...[
                Positioned(
                  left: 8,
                  child: _arrow(Icons.chevron_left_rounded, () {
                    _goTo((index - 1 + banners.length) % banners.length);
                  }),
                ),
                Positioned(
                  right: 8,
                  child: _arrow(Icons.chevron_right_rounded, () {
                    _goTo((index + 1) % banners.length);
                  }),
                ),
              ],
            ],
          ),
        ),
        if (banners.length > 1) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(banners.length, (dotIndex) {
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
