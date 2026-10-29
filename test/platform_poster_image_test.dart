import 'package:flutter_test/flutter_test.dart';
import 'package:geliyor_app/data/banner_repository.dart';

void main() {
  const fallback = 'assets/images/platform_poster.jpg';

  String resolve({
    List<AppBanner> banners = const [],
    Set<String> deletedIds = const {},
  }) {
    return BannerRepository.resolvePlacementImage(
      banners: banners,
      deletedIds: deletedIds,
      placement: BannerPlacement.platformPoster.id,
      seededId: 'platform-poster',
      fallbackAsset: fallback,
    );
  }

  test('kayıt yokken paketteki platform görseli açılır', () {
    expect(resolve(), fallback);
  });

  test('yayındaki görsel adresi pakettekinin önüne geçer', () {
    expect(
      resolve(
        banners: const [
          AppBanner(
            id: 'platform-poster',
            title: 'Platform',
            assetPath: fallback,
            imageUrl: 'https://cdn.example/platform.jpg',
            placement: 'platform_poster',
          ),
        ],
      ),
      'https://cdn.example/platform.jpg',
    );
  });

  test('silinen veya gizlenen görsel açılmaz', () {
    expect(resolve(deletedIds: {'platform-poster'}), isEmpty);
    expect(
      resolve(
        banners: const [
          AppBanner(
            id: 'platform-poster',
            title: 'Platform',
            assetPath: fallback,
            placement: 'platform_poster',
            active: false,
          ),
        ],
      ),
      isEmpty,
    );
  });
}
