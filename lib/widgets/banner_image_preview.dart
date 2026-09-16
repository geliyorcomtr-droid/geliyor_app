import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/knowledge_article_repository.dart';
import 'package:geliyor_app/screens/article_detail_screen.dart';
import 'package:geliyor_app/screens/articles_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_pressable_button.dart';
import 'package:geliyor_app/widgets/info_guide_sheet.dart';

class BannerImagePreview {
  BannerImagePreview._();

  static Future<void> show(BuildContext context, AppBanner banner) {
    final image = banner.displayImage;
    if (image.isEmpty) return Future.value();

    return InfoGuideSheet.showCentered(
      context,
      dismissOnContentTap: false,
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Column(
            children: [
              SizedBox(
                height: 32,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    onTap: () => Navigator.of(sheetContext).pop(),
                    behavior: HitTestBehavior.opaque,
                    child: const SizedBox(
                      width: 32,
                      height: 32,
                      child: Icon(
                        Icons.close_rounded,
                        color: AppColors.text,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: GestureDetector(
                  onTap: () => Navigator.of(sheetContext).pop(),
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: buildProductImage(
                      image,
                      fit: BoxFit.contain,
                      width: double.infinity,
                      height: double.infinity,
                      alignment: Alignment.center,
                      filterQuality: FilterQuality.high,
                      useHtmlElement: false,
                      cacheWidth: productPhotoCachePx,
                      errorWidget: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          size: 72,
                          color: AppColors.subText,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: IntrinsicWidth(
                  child: AppPressableButton.primary(
                    onTap: () => _openArticle(context, sheetContext, banner),
                    height: 28,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    child: const Text(
                      'Makaleye git',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
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

  static Future<void> _openArticle(
    BuildContext pageContext,
    BuildContext sheetContext,
    AppBanner banner,
  ) async {
    Navigator.of(sheetContext).pop();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!pageContext.mounted) return;

    final article = await KnowledgeArticleRepository.instance.getById(
      banner.linkId,
    );
    if (!pageContext.mounted) return;
    if (article != null) {
      await Navigator.of(pageContext).push(
        MaterialPageRoute(
          builder: (_) => ArticleDetailScreen.fromArticle(article),
        ),
      );
      return;
    }

    await Navigator.of(pageContext).push(
      MaterialPageRoute(builder: (_) => const ArticlesScreen()),
    );
  }
}
