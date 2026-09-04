import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/icon_dominant_color.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

class InfoGuideSheet {
  InfoGuideSheet._();

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String guide,
    String subtitle = 'Bu özellik ne anlama gelir?',
    String iconPath = '',
    String imageUrl = '',
    IconData fallbackIcon = Icons.pets_rounded,
    Color fallbackIconColor = AppColors.primary,
    String buttonLabel = 'Bu etiketli ürünleri gör',
    VoidCallback? onSeeProducts,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      enableDrag: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final paragraphs = guide
            .split(RegExp(r'\n\s*\n'))
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
        final media = MediaQuery.of(sheetContext);
        final sheetHeight = _heightBelowProductImage(media);
        return Padding(
          padding: EdgeInsets.only(top: media.size.height - sheetHeight),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: AppPageFrame.width),
              child: Material(
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    8,
                    16,
                    16 + media.padding.bottom,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      SizedBox(
                        height: 32,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Container(
                              width: 36,
                              height: 4,
                              decoration: BoxDecoration(
                                color: AppColors.border,
                                borderRadius: BorderRadius.circular(999),
                              ),
                            ),
                            Align(
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
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          _GuideIconBox(
                            iconPath: iconPath,
                            imageUrl: imageUrl,
                            fallbackIcon: fallbackIcon,
                            fallbackIconColor: fallbackIconColor,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: const TextStyle(
                                    color: AppColors.text,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w900,
                                    height: 1.25,
                                  ),
                                ),
                                if (subtitle.trim().isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle,
                                    style: const TextStyle(
                                      color: AppColors.primary,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              for (int i = 0; i < paragraphs.length; i++) ...[
                                if (i > 0) const SizedBox(height: 12),
                                Text(
                                  paragraphs[i],
                                  style: const TextStyle(
                                    color: AppColors.subText,
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    height: 1.45,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      if (onSeeProducts != null) ...[
                        const SizedBox(height: 12),
                        AppPressableButton.primary(
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            if (onSeeProducts == null) return;
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              onSeeProducts();
                            });
                          },
                          width: double.infinity,
                          height: 44,
                          padding: EdgeInsets.zero,
                          child: Text(
                            buttonLabel,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Ürün detayında sheet üstü, orta karttaki ürün görselinin altına gelir.
  static double _heightBelowProductImage(MediaQueryData media) {
    const heroHeight = 488.0;
    const cardTopPad = 10.0;
    const cardBottomPad = 12.0;
    const belowGallery = 6 + 62 + 8 + 28 + 10 + 1 + 10 + 62;
    const gapUnderImage = 8.0;
    final galleryHeight =
        heroHeight - cardTopPad - cardBottomPad - belowGallery;
    final topInset = media.padding.top +
        AppPageFrame.headerHeight +
        AppPageFrame.headerGap +
        cardTopPad +
        galleryHeight +
        gapUnderImage;
    final available = media.size.height - topInset;
    return available.clamp(media.size.height * 0.48, media.size.height * 0.72);
  }
}

class _GuideIconBox extends StatefulWidget {
  const _GuideIconBox({
    required this.iconPath,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.fallbackIconColor,
  });

  final String iconPath;
  final String imageUrl;
  final IconData fallbackIcon;
  final Color fallbackIconColor;

  @override
  State<_GuideIconBox> createState() => _GuideIconBoxState();
}

class _GuideIconBoxState extends State<_GuideIconBox> {
  late Color _borderColor = widget.fallbackIconColor;

  @override
  void initState() {
    super.initState();
    _loadBorderColor();
  }

  @override
  void didUpdateWidget(covariant _GuideIconBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.iconPath != widget.iconPath) {
      _loadBorderColor();
    }
  }

  Future<void> _loadBorderColor() async {
    if (widget.iconPath.trim().isEmpty) {
      setState(() => _borderColor = widget.fallbackIconColor);
      return;
    }
    final color = await IconDominantColor.fromAsset(widget.iconPath);
    if (!mounted) return;
    setState(() => _borderColor = color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 48,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _borderColor, width: 1.5),
      ),
      child: _GuideIcon(
        iconPath: widget.iconPath,
        imageUrl: widget.imageUrl,
        fallbackIcon: widget.fallbackIcon,
        fallbackIconColor: widget.fallbackIconColor,
      ),
    );
  }
}

class _GuideIcon extends StatelessWidget {
  const _GuideIcon({
    required this.iconPath,
    required this.imageUrl,
    required this.fallbackIcon,
    required this.fallbackIconColor,
  });

  final String iconPath;
  final String imageUrl;
  final IconData fallbackIcon;
  final Color fallbackIconColor;

  @override
  Widget build(BuildContext context) {
    final fallback = Icon(fallbackIcon, color: fallbackIconColor, size: 22);
    if (imageUrl.trim().isNotEmpty) {
      return buildProductImage(
        imageUrl,
        fit: BoxFit.contain,
        errorWidget: iconPath.isEmpty
            ? fallback
            : buildProductImage(
                iconPath,
                fit: BoxFit.contain,
                errorWidget: fallback,
              ),
      );
    }
    if (iconPath.trim().isEmpty) return fallback;
    return buildProductImage(
      iconPath,
      fit: BoxFit.contain,
      errorWidget: fallback,
    );
  }
}
