import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

/// Chrome / web'de uygulamayı 393×852 mobil tuvalde gösterir.
class MobileWebShell extends StatelessWidget {
  const MobileWebShell({super.key, required this.child});

  final Widget child;

  static const Color _backdrop = Color(0xFF111827);

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) return child;

    final media = MediaQuery.of(context);
    const phoneW = AppPageFrame.width;
    const phoneH = AppPageFrame.height;

    final phonePadding = media.padding.copyWith(
      top: math.max(media.padding.top, AppPageFrame.safeAreaTop),
      bottom: math.max(media.padding.bottom, 34),
    );

    return ColoredBox(
      color: _backdrop,
      child: Center(
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: phoneW,
            height: phoneH,
            child: MediaQuery(
              data: media.copyWith(
                size: const Size(phoneW, phoneH),
                padding: phonePadding,
                viewPadding: phonePadding,
                viewInsets: EdgeInsets.zero,
              ),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.45),
                      blurRadius: 32,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(28),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
