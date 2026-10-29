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
    return showCentered(
      context,
      builder: (sheetContext) {
        final paragraphs = guide
            .split(RegExp(r'\n\s*\n'))
            .map((part) => part.trim())
            .where((part) => part.isNotEmpty)
            .toList();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
        );
      },
    );
  }

  /// Akıllı Plan otomatik sipariş görseliyle aynı kutu: görsel, sağ üst çarpı,
  /// altta beyaz “Bu etiketli ürünleri gör”. Görsele dokununca kapanır.
  static Future<void> showImageOverlay(
    BuildContext context, {
    required String imagePath,
    String buttonLabel = 'Bu etiketli ürünleri gör',
    VoidCallback? onSeeProducts,
    IconData fallbackIcon = Icons.pets_rounded,
    Color fallbackIconColor = AppColors.primary,
    double height = 280,
    double width = 361,
  }) {
    final media = MediaQuery.of(context);
    final available = media.size.height - 48;
    final panelHeight = height > available && available > 0 ? available : height;
    final panelWidth = width;
    final path = imagePath.trim();
    return showCentered(
      context,
      dismissOnContentTap: false,
      height: panelHeight,
      maxWidth: panelWidth,
      builder: (sheetContext) {
        void close() {
          if (Navigator.of(sheetContext).canPop()) {
            Navigator.of(sheetContext).pop();
          }
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: close,
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(
                  color: AppColors.surface,
                  child: path.isEmpty
                      ? Center(
                          child: Icon(
                            fallbackIcon,
                            color: fallbackIconColor,
                            size: 72,
                          ),
                        )
                      : buildProductImage(
                          path,
                          fit: BoxFit.contain,
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.center,
                          filterQuality: FilterQuality.high,
                          cacheWidth: 1083,
                          errorWidget: Center(
                            child: Icon(
                              fallbackIcon,
                              color: fallbackIconColor,
                              size: 72,
                            ),
                          ),
                        ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: close,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.text,
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (onSeeProducts != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Center(
                    child: IntrinsicWidth(
                      child: AppPressableButton(
                        onTap: () {
                          close();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            onSeeProducts();
                          });
                        },
                        backgroundColor: AppColors.surface,
                        pressedBackgroundColor: AppColors.selected,
                        foregroundColor: AppColors.text,
                        pressedForegroundColor: AppColors.primary,
                        borderColor: AppColors.border,
                        pressedBorderColor: AppColors.primary,
                        height: 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          buttonLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Ürün özelliği kalıp görseli: sabit arka plan, değişen başlık ve açıklama.
  static Future<void> showAdvantageOverlay(
    BuildContext context, {
    required String templatePath,
    required String title,
    required String description,
    String buttonLabel = 'Bu etiketli ürünleri gör',
    VoidCallback? onSeeProducts,
  }) {
    const panelHeight = 280.0;
    const panelWidth = 361.0;
    final template = templatePath.trim();
    final paragraphs = description
        .split(RegExp(r'\n+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    final heading = title.trim();

    return showCentered(
      context,
      dismissOnContentTap: false,
      height: panelHeight,
      maxWidth: panelWidth,
      builder: (sheetContext) {
        void close() {
          if (Navigator.of(sheetContext).canPop()) {
            Navigator.of(sheetContext).pop();
          }
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: Stack(
            fit: StackFit.expand,
            children: [
              GestureDetector(
                onTap: close,
                behavior: HitTestBehavior.opaque,
                child: ColoredBox(
                  color: AppColors.surface,
                  child: template.isEmpty
                      ? const SizedBox.expand()
                      : buildProductImage(
                          template,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          alignment: Alignment.centerRight,
                          filterQuality: FilterQuality.high,
                          cacheWidth: 1083,
                        ),
                ),
              ),
              Positioned(
                left: 16,
                top: 14,
                width: 168,
                bottom: 40,
                child: IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (heading.isNotEmpty)
                        Text(
                          heading,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            height: 1.15,
                          ),
                        ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListView(
                          padding: EdgeInsets.zero,
                          physics: const BouncingScrollPhysics(),
                          children: [
                            for (int i = 0; i < paragraphs.length; i++) ...[
                              if (i > 0) const SizedBox(height: 8),
                              Text(
                                paragraphs[i],
                                style: const TextStyle(
                                  color: AppColors.text,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 8,
                right: 8,
                child: GestureDetector(
                  onTap: close,
                  behavior: HitTestBehavior.opaque,
                  child: Container(
                    width: 32,
                    height: 32,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.close_rounded,
                      color: AppColors.text,
                      size: 20,
                    ),
                  ),
                ),
              ),
              if (onSeeProducts != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 6,
                  child: Center(
                    child: IntrinsicWidth(
                      child: AppPressableButton(
                        onTap: () {
                          close();
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            onSeeProducts();
                          });
                        },
                        backgroundColor: AppColors.surface,
                        pressedBackgroundColor: AppColors.selected,
                        foregroundColor: AppColors.text,
                        pressedForegroundColor: AppColors.primary,
                        borderColor: AppColors.border,
                        pressedBorderColor: AppColors.primary,
                        height: 28,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          buttonLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: AppColors.text,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  static Future<void> showCentered(
    BuildContext context, {
    required Widget Function(BuildContext sheetContext) builder,
    bool dismissOnContentTap = true,
    double? height,
    double? maxWidth,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Kapat',
      barrierColor: const Color(0x59000000),
      pageBuilder: (sheetContext, animation, secondaryAnimation) {
        final media = MediaQuery.of(sheetContext);
        final panelH = height ?? panelHeight(media);
        final panelW = (maxWidth ?? AppPageFrame.width).clamp(
          0.0,
          media.size.width,
        );
        final verticalGap = ((media.size.height - panelH) / 2).clamp(
          24.0,
          media.size.height,
        );
        Widget panel = builder(sheetContext);
        if (dismissOnContentTap) {
          panel = GestureDetector(
            onTap: () => Navigator.of(sheetContext).pop(),
            behavior: HitTestBehavior.opaque,
            child: panel,
          );
        }
        return Padding(
          padding: EdgeInsets.symmetric(vertical: verticalGap),
          child: Align(
            alignment: Alignment.center,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: panelW),
              child: Material(
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                borderRadius: BorderRadius.circular(28),
                child: SizedBox(
                  height: panelH,
                  width: panelW,
                  child: panel,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// Ortalanmış bilgi paneli yüksekliği (üst-alt eşit boşluk).
  static double panelHeight(MediaQueryData media) {
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
