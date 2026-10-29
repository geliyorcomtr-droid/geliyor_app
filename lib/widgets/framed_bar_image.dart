import 'package:flutter/material.dart';
import 'package:geliyor_app/data/contact_bar_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/icon_dominant_color.dart';
import 'package:geliyor_app/utils/product_image.dart';

/// Sabit yükseklikli şerit: çerçeve ve görsel arasında 3 px boşluk.
class FramedBarImage extends StatefulWidget {
  const FramedBarImage({
    super.key,
    required this.path,
    required this.fallbackPath,
    required this.borderColor,
    this.tintFromImage = false,
    this.onTap,
  });

  final String path;
  final String fallbackPath;
  final Color borderColor;
  final bool tintFromImage;
  final VoidCallback? onTap;

  @override
  State<FramedBarImage> createState() => _FramedBarImageState();
}

class _FramedBarImageState extends State<FramedBarImage> {
  late Color _border = widget.borderColor;

  @override
  void initState() {
    super.initState();
    _loadTint();
  }

  @override
  void didUpdateWidget(covariant FramedBarImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path ||
        oldWidget.borderColor != widget.borderColor) {
      _border = widget.borderColor;
      _loadTint();
    }
  }

  Future<void> _loadTint() async {
    if (!widget.tintFromImage) return;
    final color = await IconDominantColor.of(widget.path);
    if (!mounted) return;
    setState(() => _border = color);
  }

  @override
  Widget build(BuildContext context) {
    final image = ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox.expand(
        child: buildProductImage(
          widget.path,
          fit: BoxFit.cover,
          cacheWidth: ContactBarRepository.uploadWidth,
          maxDecodePx: ContactBarRepository.uploadWidth,
          errorWidget: Image.asset(
            widget.fallbackPath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
    final framed = Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: _border.withValues(alpha: 0.25)),
      ),
      child: image,
    );
    if (widget.onTap == null) return framed;
    return GestureDetector(onTap: widget.onTap, child: framed);
  }
}
