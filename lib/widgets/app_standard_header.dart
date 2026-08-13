import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';

/// Standart sayfa üst başlığı: geri + ortalanmış başlık + bildirim.
class AppStandardHeader extends StatelessWidget {
  const AppStandardHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing = const AppNotificationButton(),
    this.leading,
    this.titleSuffix,
    this.horizontalPadding = 8,
    this.showNotification = true,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? leading;
  final Widget? titleSuffix;
  final double horizontalPadding;
  final bool showNotification;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
      child: Row(
        children: [
          leading ?? const AppBackButton(),
          Expanded(
            child: IgnorePointer(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      title,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.pageHeader,
                    ),
                  ),
                  if (titleSuffix != null) ...[
                    const SizedBox(width: 4),
                    titleSuffix!,
                  ],
                ],
              ),
            ),
          ),
          if (showNotification)
            trailing ?? const AppNotificationButton()
          else
            const SizedBox(width: 44),
        ],
      ),
    );
  }
}
