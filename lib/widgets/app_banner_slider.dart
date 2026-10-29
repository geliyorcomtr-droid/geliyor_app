import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';
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
    this.onTap,
  });

  final BannerPlacement placement;
  // ignore: unused_field
  final List<String> fallbackAssets;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool openOnTap;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppBanner>>(
      stream: BannerRepository.instance.watchActive(placement: placement.id),
      builder: (context, snapshot) {
        final remote = snapshot.data;
        if (remote == null) {
          return SizedBox(height: placement.height);
        }
        if (remote.isEmpty) return const SizedBox.shrink();
        final ordered = [...remote]
          ..sort((a, b) => a.order.compareTo(b.order));
        ImageWarmup.precache(
          context,
          [
            for (final banner in ordered) ...[
              banner.displayImage,
              banner.imageUrl,
            ],
          ],
          cacheWidth: bannerCachePx,
        );
        return AppBannerSlider(
          banners: ordered,
          height: placement.height,
          radius: placement.boxRadius,
          autoPlay: autoPlay,
          autoPlayInterval: autoPlayInterval,
          openOnTap: openOnTap,
          onTap: onTap,
        );
      },
    );
  }
}

/// Tek görsellik şerit. İlk kare yalnızca sunucudaki en yeni `imageUrl`.
class AppBannerStrip extends StatefulWidget {
  const AppBannerStrip({
    super.key,
    required this.placement,
    this.fallbackAsset = '',
    this.onTap,
  });

  final BannerPlacement placement;
  final String fallbackAsset;
  final VoidCallback? onTap;

  @override
  State<AppBannerStrip> createState() => _AppBannerStripState();
}

class _AppBannerStripState extends State<AppBannerStrip> {
  static final Map<String, String> _remembered = {};

  StreamSubscription<({List<AppBanner> banners, bool fromCache})>? _sub;
  String? _path;
  var _ready = false;
  var _stamp = 0;

  @override
  void initState() {
    super.initState();
    _start();
  }

  @override
  void didUpdateWidget(covariant AppBannerStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.placement.id != widget.placement.id ||
        oldWidget.fallbackAsset != widget.fallbackAsset) {
      _start();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _start() async {
    await _sub?.cancel();
    _sub = null;
    final remembered = _remembered[widget.placement.id];
    if (mounted && remembered != null && remembered.isNotEmpty) {
      setState(() {
        _ready = true;
        _path = remembered;
      });
    }
    try {
      final cached = await BannerRepository.instance.fetchActiveFromCache(
        placement: widget.placement.id,
      );
      _apply(cached, fromServer: false);
    } catch (_) {}
    try {
      final banners = await BannerRepository.instance.fetchActiveFromServer(
        placement: widget.placement.id,
      );
      _apply(banners, fromServer: true);
    } catch (_) {}
    if (!mounted) return;
    _sub = BannerRepository.instance
        .watchActiveMeta(placement: widget.placement.id)
        .listen((meta) {
          _apply(meta.banners, fromServer: !meta.fromCache);
        });
  }

  void _apply(List<AppBanner> banners, {required bool fromServer}) {
    if (!mounted) return;
    var list = banners;
    if (widget.placement.id == BannerPlacement.homeDostEkle.id) {
      list = banners
          .where((banner) {
            final asset = banner.assetPath.toLowerCase();
            if (asset.contains('dostunu_taniyalim')) return false;
            final title = banner.title.toLowerCase();
            if (title.contains('tanıyalım') || title.contains('taniyalim')) {
              return false;
            }
            return true;
          })
          .toList();
    }
    final live = AppBanner.latestLive(list);
    final next = AppBanner.liveNetworkPath(list);
    final nextStamp = live == null
        ? 0
        : AppBanner.storageUploadStamp(live.imageUrl);
    if (_stamp > 0 && nextStamp > 0 && nextStamp < _stamp) {
      return;
    }
    final asset = live != null && live.assetPath.trim().isNotEmpty
        ? live.assetPath.trim()
        : widget.fallbackAsset.trim();
    final path = next.isNotEmpty ? next : asset;
    if (path.isEmpty) {
      if (_path != null) {
        if (!_ready) setState(() => _ready = true);
        return;
      }
      if (!fromServer && !_ready) return;
      setState(() => _ready = true);
      return;
    }
    if (_path == path && _ready) return;
    if (path.isNotEmpty) {
      ImageWarmup.precache(context, [path], cacheWidth: bannerCachePx);
    }
    setState(() {
      _ready = true;
      _path = path;
      if (nextStamp > 0) _stamp = nextStamp;
      _remembered[widget.placement.id] = path;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready || _path == null) {
      return SizedBox(height: widget.placement.height);
    }
    final strip = SizedBox(
      width: double.infinity,
      height: widget.placement.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.placement.boxRadius),
          child: SizedBox.expand(
            child: buildProductImage(
              _path!,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              filterQuality: FilterQuality.high,
              cacheWidth: bannerCachePx,
            ),
          ),
      ),
    );
    if (widget.onTap == null) return strip;
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: strip,
    );
  }
}

class AppBannerSlider extends StatefulWidget {
  const AppBannerSlider({
    super.key,
    required this.banners,
    this.height = 132,
    this.radius = BannerPlacement.radius,
    this.autoPlay = false,
    this.autoPlayInterval = const Duration(seconds: 3),
    this.openOnTap = true,
    this.onTap,
  });

  final List<AppBanner> banners;
  final double height;
  final double radius;
  final bool autoPlay;
  final Duration autoPlayInterval;
  final bool openOnTap;
  final VoidCallback? onTap;

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
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmup());
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
    _warmup();
  }

  void _warmup() {
    ImageWarmup.precache(
      context,
      widget.banners.map((banner) => banner.displayImage),
      cacheWidth: bannerCachePx,
    );
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

    return SizedBox(
      height: widget.height,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.radius),
        child: Stack(
          alignment: Alignment.center,
          children: [
            PageView.builder(
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
                final image = buildProductImage(
                  path,
                  fit: useContain ? BoxFit.contain : BoxFit.cover,
                  width: double.infinity,
                  height: double.infinity,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.medium,
                  cacheWidth: bannerCachePx,
                  errorWidget: _fallback(),
                );
                if (widget.onTap != null) {
                  return GestureDetector(
                    onTap: widget.onTap,
                    behavior: HitTestBehavior.opaque,
                    child: image,
                  );
                }
                if (!widget.openOnTap) return image;
                return GestureDetector(
                  onTap: () => BannerImagePreview.show(context, banner),
                  child: image,
                );
              },
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
              Positioned(
                left: 0,
                right: 0,
                bottom: 8,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(banners.length, (dotIndex) {
                    final active = dotIndex == index;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active
                            ? AppColors.surface
                            : AppColors.surface.withValues(alpha: 0.5),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                ),
              ),
            ],
          ],
        ),
      ),
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
