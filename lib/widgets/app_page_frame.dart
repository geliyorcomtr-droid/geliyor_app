import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
/// Sabit sayfa tuvali ve dikey standart:
/// 59 Safe Area + 64 Header + 16 Boşluk + 560 İçerik + 84 Navbar + 69 Alt = 852
class AppPageFrame extends StatelessWidget {
  const AppPageFrame({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.background,
  });

  /// Standart dikey yerleşimli sayfa.
  factory AppPageFrame.standard({
    Key? key,
    required Widget header,
    required Widget content,
    Color backgroundColor = AppColors.background,
    AppNavTab activeTab = AppNavTab.home,
    bool showNavbar = true,
    Widget? navbar,
  }) {
    return AppPageFrame(
      key: key,
      backgroundColor: backgroundColor,
      child: Column(
        children: [
          const SizedBox(height: safeAreaTop),
          SizedBox(height: headerHeight, child: header),
          const SizedBox(height: headerGap),
          SizedBox(height: contentHeight, child: content),
          SizedBox(
            height: bottomNavHeight,
            child: showNavbar
                ? OverflowBox(
                    maxHeight: bottomNavHeight + 22,
                    alignment: Alignment.bottomCenter,
                    child: navbar ?? AppBottomNavbar(activeTab: activeTab),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: safeAreaBottom),
        ],
      ),
    );
  }

  static const double width = 393;
  static const double height = 852;

  static const double safeAreaTop = 59;
  static const double headerHeight = 64;
  static const double headerGap = 16;
  static const double contentHeight = 560;
  static const double bottomNavHeight = 84;
  static const double safeAreaBottom = 69;

  final Widget child;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: backgroundColor,
      child: Center(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: SizedBox(
              width: width,
              height: height,
              child: ColoredBox(
                color: backgroundColor,
                child: child,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Standart header: geri + başlık (ortada).
class AppPageHeader extends StatelessWidget {
  const AppPageHeader({
    super.key,
    required this.title,
    this.onBack,
    this.trailing,
    this.titleColor = AppColors.primary,
    this.leading,
  });

  final String title;
  final VoidCallback? onBack;
  final Widget? trailing;
  final Widget? leading;
  final Color titleColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: leading ??
                (onBack != null || Navigator.of(context).canPop()
                    ? AppBackButton(onPressed: onBack)
                    : const SizedBox.shrink()),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.pageHeader.copyWith(color: titleColor),
            ),
          ),
          SizedBox(width: 44, child: trailing),
        ],
      ),
    );
  }
}
