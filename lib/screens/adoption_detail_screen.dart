import 'package:flutter/material.dart';
import 'package:geliyor_app/data/adoption_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/info_guide_sheet.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:video_player/video_player.dart';

class AdoptionDetailScreen {
  AdoptionDetailScreen._();

  static Color accentFor(String category) => switch (category) {
    AdoptionCategories.lost => AppColors.primary,
    AdoptionCategories.found => AppColors.success,
    _ => AppColors.warning,
  };

  static Future<void> show(BuildContext context, AdoptionListing listing) {
    final color = accentFor(listing.category);
    return InfoGuideSheet.showCentered(
      context,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 32,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.text,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      listing.imageUrls.isEmpty && listing.videoUrls.isEmpty
                          ? ColoredBox(
                              color: AppColors.selected,
                              child: Center(
                                child: Icon(
                                  Icons.pets_rounded,
                                  color: color,
                                  size: 48,
                                ),
                              ),
                            )
                          : PageView(
                              children: [
                                for (final url in listing.imageUrls)
                                  SizedBox.expand(
                                    child: buildProductImage(
                                      url,
                                      fit: BoxFit.cover,
                                      cacheWidth: 1080,
                                    ),
                                  ),
                                for (final url in listing.videoUrls)
                                  _ListingNetworkVideo(url: url),
                              ],
                            ),
                      Positioned(
                        left: 10,
                        top: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            listing.badgeLabel,
                            style: const TextStyle(
                              color: AppColors.surface,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: listing.name,
                      style: TextStyle(
                        color: color,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1.1,
                      ),
                    ),
                    if (_speciesBreed(listing).isNotEmpty) ...[
                      const WidgetSpan(
                        alignment: PlaceholderAlignment.middle,
                        child: SizedBox(width: 10),
                      ),
                      TextSpan(
                        text: '(${_speciesBreed(listing)})',
                        style: TextStyle(
                          color: color.withValues(alpha: 0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (listing.gender.isNotEmpty)
                    _chip(_genderIcon(listing.gender), listing.gender, color),
                  if (_ageLabel(listing.age).isNotEmpty)
                    _chip(
                      Icons.pets_rounded,
                      _ageLabel(listing.age),
                      color,
                    ),
                  if (_weightLabel(listing.weight).isNotEmpty)
                    _chip(
                      Icons.monitor_weight_outlined,
                      _weightLabel(listing.weight),
                      color,
                    ),
                  if (listing.city.isNotEmpty)
                    _chip(Icons.location_on_outlined, listing.city, color),
                ],
              ),
              if (listing.description.isNotEmpty) ...[
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 72),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Text(
                      listing.description,
                      style: TextStyle(
                        color: color,
                        height: 1.4,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
              if (listing.phone.isNotEmpty) ...[
                const SizedBox(height: 12),
                AppPressableButton(
                  onTap: () => _call(sheetContext, listing.phone),
                  height: 44,
                  backgroundColor: color,
                  pressedBackgroundColor: color.withValues(alpha: 0.82),
                  foregroundColor: AppColors.surface,
                  pressedForegroundColor: AppColors.surface,
                  borderColor: color,
                  pressedBorderColor: color,
                  builder: (pressed) => Text(
                    listing.phone,
                    style: const TextStyle(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  static String _ageLabel(String age) {
    final value = age
        .replaceAll(RegExp(r'ya[sş]', caseSensitive: false), '')
        .trim();
    if (value.isEmpty) return '';
    return 'Yaş $value';
  }

  static String _weightLabel(String weight) {
    final value = weight
        .replaceAll(RegExp(r'(kilo|kg)', caseSensitive: false), '')
        .trim();
    if (value.isEmpty) return '';
    return 'Kilo $value';
  }

  static String _speciesBreed(AdoptionListing listing) {
    final parts = <String>[
      if (listing.species.trim().isNotEmpty) listing.species.trim(),
      if (listing.breed.trim().isNotEmpty) listing.breed.trim(),
    ];
    return parts.join(' • ');
  }

  static IconData _genderIcon(String gender) {
    if (gender.toLowerCase().contains('erkek')) return Icons.male_rounded;
    return Icons.female_rounded;
  }

  static Future<void> _call(BuildContext context, String phone) async {
    final number = phone.replaceAll(RegExp(r'[^\d+]'), '');
    if (number.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: number);
    try {
      final launched = await launchUrl(uri);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Arama başlatılamadı.')),
        );
      }
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Arama başlatılamadı.')),
      );
    }
  }

  static Widget _chip(IconData icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListingNetworkVideo extends StatefulWidget {
  const _ListingNetworkVideo({required this.url});

  final String url;

  @override
  State<_ListingNetworkVideo> createState() => _ListingNetworkVideoState();
}

class _ListingNetworkVideoState extends State<_ListingNetworkVideo> {
  late final VideoPlayerController _controller;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
      ..initialize().then((_) {
        if (!mounted) return;
        _controller
          ..setLooping(true)
          ..setVolume(1)
          ..play();
        setState(() => _ready = true);
      });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const ColoredBox(
        color: AppColors.selected,
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    }
    return GestureDetector(
      onTap: () {
        setState(() {
          if (_controller.value.isPlaying) {
            _controller.pause();
          } else {
            _controller.play();
          }
        });
      },
      child: Stack(
        fit: StackFit.expand,
        children: [
          FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              width: _controller.value.size.width,
              height: _controller.value.size.height,
              child: VideoPlayer(_controller),
            ),
          ),
          if (!_controller.value.isPlaying)
            const Center(
              child: Icon(
                Icons.play_circle_fill_rounded,
                color: AppColors.surface,
                size: 56,
              ),
            ),
        ],
      ),
    );
  }
}
