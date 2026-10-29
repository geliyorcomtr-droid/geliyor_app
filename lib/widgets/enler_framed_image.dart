import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/icon_dominant_color.dart';
import 'package:geliyor_app/utils/product_image.dart';

/// En'ler kutusu: görselin renginde çerçeve, görselle çerçeve arasında boşluk.
class EnlerFramedImage extends StatefulWidget {
  const EnlerFramedImage({
    super.key,
    required this.path,
    required this.fallbackPath,
    this.cacheWidth,
    this.maxDecodePx,
  });

  final String path;
  final String fallbackPath;
  final int? cacheWidth;
  final int? maxDecodePx;

  @override
  State<EnlerFramedImage> createState() => _EnlerFramedImageState();
}

class _EnlerFramedImageState extends State<EnlerFramedImage> {
  Color _color = AppColors.primary;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant EnlerFramedImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.path != widget.path) _load();
  }

  Future<void> _load() async {
    final color = await IconDominantColor.of(widget.path);
    if (!mounted) return;
    setState(() => _color = color);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: double.infinity,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _color),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: buildProductImage(
          widget.path,
          fit: BoxFit.cover,
          cacheWidth: widget.cacheWidth,
          maxDecodePx: widget.maxDecodePx,
          errorWidget: Image.asset(
            widget.fallbackPath,
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }
}
