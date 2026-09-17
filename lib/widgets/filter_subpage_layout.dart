import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';

class FilterSubpageItem {
  const FilterSubpageItem({
    required this.title,
    required this.subtitle,
    this.imagePath,
    this.icon,
    this.iconColor,
    this.badgeIcon = Icons.pets_rounded,
    this.badgeIconColor,
    this.leadingColor,
    this.leadingLabel,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String? imagePath;
  final IconData? icon;
  final Color? iconColor;
  final IconData badgeIcon;
  final Color? badgeIconColor;
  final Color? leadingColor;
  final String? leadingLabel;
  final VoidCallback? onTap;
}

class FilterSubpageLayout extends StatelessWidget {
  const FilterSubpageLayout({
    super.key,
    required this.title,
    this.items,
    this.content,
    this.defaultOnTap,
    this.accent = AppColors.primary,
  }) : assert(items != null || content != null);

  final String title;
  final List<FilterSubpageItem>? items;
  final Widget? content;
  final VoidCallback? defaultOnTap;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        pawPrintColor: accent,
        header: _buildHeader(context),
        content: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildSearchRow(),
              const SizedBox(height: 14),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: accent.withValues(alpha: 0.28)),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: content ??
                      ListView.separated(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        itemCount: items!.length,
                        separatorBuilder: (context, index) => Divider(
                          height: 1,
                          thickness: 1,
                          indent: 76,
                          endIndent: 16,
                          color: accent.withValues(alpha: 0.28),
                        ),
                        itemBuilder: (context, index) {
                          return _buildCategoryRow(context, items![index]);
                        },
                      ),
                ),
              ),
            ],
          ),
        ),
        navbar: AppBottomNavbar(homeColor: accent),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          AppBackButton(color: accent),
          Expanded(
            child: IgnorePointer(
              child: Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.pageHeader.copyWith(color: accent),
              ),
            ),
          ),
          const AppNotificationButton(),
        ],
      ),
    );
  }

  Widget _buildSearchRow() {
    return Row(
      children: [
        Expanded(
          child: Container(
            height: 44,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(color: accent.withValues(alpha: 0.28)),
            ),
            child: Row(
              children: [
                Icon(Icons.search_rounded, color: accent, size: 22),
                SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    decoration: InputDecoration(
                      hintText: 'Ürün, marka veya kategori ara...',
                      hintStyle: TextStyle(
                        color: AppColors.subText,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 8),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: accent.withValues(alpha: 0.28)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, color: accent, size: 18),
              const SizedBox(width: 4),
              Text(
                'Filtrele',
                style: TextStyle(
                  color: accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryRow(BuildContext context, FilterSubpageItem item) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: item.onTap ?? defaultOnTap,
        borderRadius: BorderRadius.circular(18),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Row(
            children: [
              _buildLeading(item),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: accent,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          item.badgeIcon,
                          size: 14,
                          color: item.badgeIconColor ?? accent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: accent,
                size: 22,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeading(FilterSubpageItem item) {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: AppColors.surface,
        shape: BoxShape.circle,
        border: Border.all(color: accent.withValues(alpha: 0.28), width: 1.2),
      ),
      child: item.leadingLabel != null
          ? Center(
              child: Text(
                item.leadingLabel!,
                style: TextStyle(
                  color: item.leadingColor ?? accent,
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : Padding(
              padding: const EdgeInsets.all(7),
              child: item.imagePath != null
                  ? Image.asset(
                      item.imagePath!,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          item.icon ?? Icons.pets_rounded,
                          color: item.iconColor ?? accent,
                          size: 24,
                        );
                      },
                    )
                  : Icon(
                      item.icon ?? Icons.pets_rounded,
                      color: item.iconColor ?? accent,
                      size: 24,
                    ),
            ),
    );
  }
}
