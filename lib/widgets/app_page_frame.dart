import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/paw_print_background.dart';

/// Sayfa çerçevesi.
///
/// Tasarım referansı (Figma): 393×852.
/// Gerçek telefonda ekranı doldurur; safe area cihazdan alınır.
/// Sabit tuval + Center kullanma — üst/alt boşluk ve gereksiz kaydırmaya yol açar.
class AppPageFrame extends StatelessWidget {
  const AppPageFrame({
    super.key,
    required this.child,
    this.backgroundColor = AppColors.background,
    this.showPawPrints = true,
    this.pawPrintStyle = PawPrintStyle.page,
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
    bool showPawPrints = true,
    PawPrintStyle pawPrintStyle = PawPrintStyle.page,
  }) {
    return AppPageFrame(
      key: key,
      backgroundColor: backgroundColor,
      showPawPrints: showPawPrints,
      pawPrintStyle: pawPrintStyle,
      child: Builder(
        builder: (context) {
          final padding = MediaQuery.paddingOf(context);
          return Padding(
            // Üst: durum çubuğu. Alt boşluk navbar içine alınır —
            // aksi halde navbar altında ekstra beyaz şerit oluşur.
            padding: EdgeInsets.only(top: padding.top),
            child: Column(
              children: [
                SizedBox(
                  height: headerHeight,
                  child: Padding(
                    // Başlık metninin üstündeki ve içerikle arasındaki
                    // görünen boşluğu eşitler.
                    padding: const EdgeInsets.only(top: headerGap),
                    child: header,
                  ),
                ),
                const SizedBox(height: headerGap),
                Expanded(child: content),
                SizedBox(
                  height: bottomNavHeight + padding.bottom,
                  child: showNavbar
                      ? Padding(
                          padding: EdgeInsets.only(bottom: padding.bottom),
                          child: OverflowBox(
                            maxHeight: bottomNavHeight + 22,
                            alignment: Alignment.bottomCenter,
                            child: navbar ??
                                AppBottomNavbar(activeTab: activeTab),
                          ),
                        )
                      : SizedBox(height: padding.bottom),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Tasarım referans genişliği (dialog / maxWidth için).
  static const double width = 393;

  /// Tasarım referans yüksekliği.
  static const double height = 852;

  /// Sayfa içeriğinin standart yatay boşluğu.
  static const double contentHorizontalPadding = 16;

  static const double safeAreaTop = 59;
  static const double headerHeight = 56;
  /// Başlık metninin üstü ve altı (içerikle arası) için ortak boşluk.
  static const double headerGap = 8;
  static const double contentHeight = 560;
  static const double bottomNavHeight = 62;
  static const double safeAreaBottom = 69;

  final Widget child;
  final Color backgroundColor;
  final bool showPawPrints;
  final PawPrintStyle pawPrintStyle;

  @override
  Widget build(BuildContext context) {
    Widget body = SizedBox.expand(child: child);
    if (showPawPrints) {
      body = PawPrintBackground(style: pawPrintStyle, child: body);
    }
    return ColoredBox(color: backgroundColor, child: body);
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
            child:
                leading ??
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
