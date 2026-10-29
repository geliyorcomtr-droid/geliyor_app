import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';

/// Ana sayfadaki platform şeridine tıklanınca açılan 361×600 görsel.
class PlatformPosterOverlay {
  PlatformPosterOverlay._();

  static const width = 361.0;
  static const height = 600.0;

  static Future<void> show(BuildContext context, {required String imagePath}) {
    final path = imagePath.trim();
    if (path.isEmpty) return Future.value();
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Kapat',
      barrierColor: const Color(0xB3000000),
      transitionDuration: const Duration(milliseconds: 180),
      pageBuilder: (sheetContext, animation, secondaryAnimation) {
        return _PlatformPosterPage(imagePath: path);
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(opacity: animation, child: child);
      },
    );
  }
}

class _PlatformPosterPage extends StatelessWidget {
  const _PlatformPosterPage({required this.imagePath});

  final String imagePath;

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: GestureDetector(
        onTap: () => Navigator.of(context).pop(),
        behavior: HitTestBehavior.opaque,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final scale = math.min(
                  1.0,
                  math.min(
                    constraints.maxWidth / PlatformPosterOverlay.width,
                    constraints.maxHeight / PlatformPosterOverlay.height,
                  ),
                );
                final width = PlatformPosterOverlay.width * scale;
                final height = PlatformPosterOverlay.height * scale;
                return Center(
                  child: SizedBox(
                    width: width,
                    height: height,
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: buildProductImage(
                            imagePath,
                            fit: BoxFit.cover,
                            width: width,
                            height: height,
                            alignment: Alignment.center,
                            filterQuality: FilterQuality.high,
                            cacheWidth: (width * 3).round(),
                          ),
                        ),
                        Positioned(
                          top: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => Navigator.of(context).pop(),
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
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
