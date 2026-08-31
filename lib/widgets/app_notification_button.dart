import 'package:flutter/material.dart';
import 'package:geliyor_app/screens/notifications_screen.dart';
import 'package:geliyor_app/state/notifications_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';

/// Header bildirim zili — tüm alan tıklanabilir (badge tıklamayı yemez).
class AppNotificationButton extends StatelessWidget {
  const AppNotificationButton({
    super.key,
    this.count,
    this.onPressed,
    this.iconSize = 26,
    this.size = 44,
    this.badgeColor = AppColors.primary,
  });

  final int? count;
  final VoidCallback? onPressed;
  final double iconSize;
  final double size;
  final Color badgeColor;

  void _open(BuildContext context) {
    if (onPressed != null) {
      onPressed!();
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const NotificationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: NotificationsStore.instance,
      builder: (context, _) {
        final badge = count ?? NotificationsStore.instance.unreadCount;
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _open(context),
                  child: Center(
                    child: Icon(
                      Icons.notifications_none_rounded,
                      color: AppColors.primary,
                      size: iconSize,
                    ),
                  ),
                ),
              ),
              if (badge > 0)
                Positioned(
                  right: 4,
                  top: 4,
                  child: IgnorePointer(
                    child: Container(
                      width: 16,
                      height: 16,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: badgeColor,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        badge > 9 ? '9+' : '$badge',
                        style: const TextStyle(
                          color: AppColors.surface,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          height: 1,
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
}
