import 'package:flutter/material.dart';
import 'package:geliyor_app/app_navigator.dart';
import 'package:geliyor_app/services/user_profile_sync.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';

/// Kayıt / sipariş onayı gibi son adımda giriş zorunluluğu.
/// Sayfa gezintisi ve sepete ekleme giriş istemez.
class LoginGate {
  LoginGate._();

  /// `main` içinde LoginScreen'e bağlanır; döngüsel import olmasın.
  static Future<bool> Function(BuildContext context)? openLogin;

  static bool get isLoggedIn => AuthStore.instance.isLoggedIn;

  static Future<bool> require({
    BuildContext? context,
    String message = 'Bu işlem için giriş yapmanız gerekir.',
  }) async {
    if (isLoggedIn) return true;
    final nav = appNavigatorKey.currentState;
    final ctx = context ?? nav?.context;
    if (ctx == null || !ctx.mounted) return false;

    final goLogin = await showModalBottomSheet<bool>(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppPageFrame.width),
            child: Material(
              color: AppColors.surface,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(28),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Icon(
                      Icons.lock_outline_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Giriş yapmanız gerekir',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppPressableButton.primary(
                      onTap: () => Navigator.of(sheetContext).pop(true),
                      width: double.infinity,
                      height: 44,
                      padding: EdgeInsets.zero,
                      child: const Text(
                        'Giriş Yap',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    AppPressableButton(
                      onTap: () => Navigator.of(sheetContext).pop(false),
                      width: double.infinity,
                      height: 44,
                      padding: EdgeInsets.zero,
                      backgroundColor: AppColors.surface,
                      pressedBackgroundColor: AppColors.selected,
                      borderColor: AppColors.border,
                      pressedBorderColor: AppColors.primaryLight,
                      child: const Text(
                        'Vazgeç',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    if (goLogin != true) return false;
    final openCtx = context ?? appNavigatorKey.currentContext;
    if (openCtx == null || !openCtx.mounted) return false;
    final opener = openLogin;
    if (opener == null) return false;
    await opener(openCtx);
    if (isLoggedIn) {
      await UserProfileSync.sync();
    }
    return isLoggedIn;
  }
}
