import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/app_bootstrap.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/brand_repository.dart';
import 'package:geliyor_app/data/product_repository.dart';
import 'package:geliyor_app/data/welcome_splash_repository.dart';
import 'package:geliyor_app/screens/home_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/local_image_cache.dart';
import 'package:geliyor_app/utils/product_image.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  static const _autoNavigateDelay = Duration(seconds: 4);
  static const _tapEnabledAfter = Duration(seconds: 1);

  Timer? _autoNavigateTimer;
  Timer? _tapEnableTimer;
  StreamSubscription<String>? _splashSub;
  bool _canTapNavigate = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _tapEnableTimer = Timer(_tapEnabledAfter, () {
      if (!mounted) return;
      setState(() => _canTapNavigate = true);
    });
    _autoNavigateTimer = Timer(_autoNavigateDelay, _goHome);
    unawaited(_loadSplash());
    WidgetsBinding.instance.addPostFrameCallback((_) => _warmupImages());
  }

  Future<void> _loadSplash() async {
    try {
      await AppBootstrap.whenFirebaseReady;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    _splashSub = WelcomeSplashRepository.instance.watchImageUrl().listen((url) {
      unawaited(
        LocalImageCache.instance.rememberNamed(LocalImageCache.splashName, url),
      );
    });
  }

  Future<void> _warmupImages() async {
    try {
      await AppBootstrap.whenFirebaseReady;
    } catch (_) {
      return;
    }
    if (!mounted) return;
    unawaited(_warmupBrands());
    unawaited(_warmupBanners());
    unawaited(_warmupProducts());
    unawaited(_warmupSplash());
  }

  Future<void> _warmupBrands() async {
    try {
      final brands = await BrandRepository.instance.fetchAll(activeOnly: true);
      final urls = [
        for (final brand in brands)
          if (brand.imageUrl.trim().isNotEmpty) brand.imageUrl.trim(),
      ];
      await LocalImageCache.instance.prefetch(urls);
      if (!mounted) return;
      ImageWarmup.precache(
        context,
        brands.map((brand) => brand.displayImage),
        cacheWidth: brandLogoCachePx,
      );
    } catch (_) {}
  }

  Future<void> _warmupBanners() async {
    try {
      final banners = await BannerRepository.instance.fetchActiveFromServer();
      if (!mounted) return;
      ImageWarmup.precache(
        context,
        [
          for (final banner in banners) ...[
            banner.displayImage,
            AppBanner.liveNetworkPath([banner]),
          ],
        ],
        cacheWidth: bannerCachePx,
      );
    } catch (_) {}
  }

  Future<void> _warmupProducts() async {
    try {
      ProductRepository.instance.ensureWarm();
      var products = ProductRepository.instance.cachedMarketProducts();
      if (products.isEmpty) {
        products = await ProductRepository.instance
            .watchMarketProducts()
            .first
            .timeout(const Duration(seconds: 3), onTimeout: () => const []);
      }
      if (!mounted) return;
      ImageWarmup.precache(
        context,
        products.take(16).map((product) => product.imagePath),
        cacheWidth: productThumbCachePx,
      );
    } catch (_) {}
  }

  Future<void> _warmupSplash() async {
    try {
      final splashUrl = WelcomeSplashRepository.instance.imageUrl.isNotEmpty
          ? WelcomeSplashRepository.instance.imageUrl
          : await WelcomeSplashRepository.instance.fetchImageUrl();
      await LocalImageCache.instance.rememberNamed(
        LocalImageCache.splashName,
        splashUrl,
      );
      if (!mounted) return;
      ImageWarmup.precache(context, [splashUrl], cacheWidth: splashCachePx);
    } catch (_) {}
  }

  @override
  void dispose() {
    _autoNavigateTimer?.cancel();
    _tapEnableTimer?.cancel();
    unawaited(_splashSub?.cancel());
    super.dispose();
  }

  Future<void> _goHome() async {
    if (_navigated || !mounted) return;
    _navigated = true;
    _autoNavigateTimer?.cancel();
    _tapEnableTimer?.cancel();
    try {
      await AppBootstrap.whenFirebaseReady.timeout(const Duration(seconds: 8));
    } catch (_) {}
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const HomeScreen()),
    );
  }

  void _onTapAnywhere() {
    if (!_canTapNavigate) return;
    unawaited(_goHome());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: GestureDetector(
        onTap: _onTapAnywhere,
        behavior: HitTestBehavior.opaque,
        child: ListenableBuilder(
          listenable: Listenable.merge([
            WelcomeSplashRepository.instance,
            LocalImageCache.instance,
          ]),
          builder: (context, _) {
            final bytes = WelcomeSplashRepository.instance.localBytes;
            if (bytes != null && bytes.isNotEmpty) {
              return SizedBox.expand(
                child: Image.memory(
                  bytes,
                  fit: BoxFit.cover,
                  alignment: Alignment.center,
                  filterQuality: FilterQuality.high,
                  gaplessPlayback: true,
                  errorBuilder: (_, _, _) => const SizedBox.expand(),
                ),
              );
            }
            final imageUrl = WelcomeSplashRepository.instance.imageUrl;
            if (imageUrl.isEmpty) return const SizedBox.expand();
            return SizedBox.expand(
              child: buildProductImage(
                imageUrl,
                fit: BoxFit.cover,
                width: double.infinity,
                height: double.infinity,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
                cacheWidth: splashCachePx,
                maxDecodePx: splashCachePx,
                errorWidget: const SizedBox.expand(),
              ),
            );
          },
        ),
      ),
    );
  }
}
