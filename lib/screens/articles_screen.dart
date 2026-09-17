import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/knowledge_article_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/article_detail_screen.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/knowledge_disclaimer.dart';

class ArticlesScreen extends StatefulWidget {
  const ArticlesScreen({super.key, this.initialCategoryId});

  final String? initialCategoryId;

  @override
  State<ArticlesScreen> createState() => _ArticlesScreenState();
}

class _ArticlesScreenState extends State<ArticlesScreen> {
  final _searchController = TextEditingController();
  String _query = '';
  late String _selectedCategoryId;

  static const _categories = <_ArticleCategory>[
    _ArticleCategory(
      id: 'beslenme',
      title: 'Beslenme',
      color: AppColors.warning,
      imagePath: 'assets/images/bilgi_beslenme.png',
    ),
    _ArticleCategory(
      id: 'saglik',
      title: 'Sağlık',
      color: AppColors.warning,
      imagePath: 'assets/images/bilgi_saglik.png',
    ),
    _ArticleCategory(
      id: 'bakim',
      title: 'Bakım',
      color: AppColors.warning,
      imagePath: 'assets/images/bilgi_bakim.png',
    ),
    _ArticleCategory(
      id: 'asi',
      title: 'Aşı',
      color: AppColors.warning,
      imagePath: 'assets/images/bilgi_asi_koruma.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final valid = _categories.any((c) => c.id == widget.initialCategoryId);
    _selectedCategoryId =
        valid ? widget.initialCategoryId! : _categories.first.id;
    unawaited(KnowledgeArticleRepository.instance.ensureDefaults());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _ArticleCategory get _selectedCategory =>
      _categories.firstWhere((c) => c.id == _selectedCategoryId);

  List<AppKnowledgeArticle> _visibleFrom(List<AppKnowledgeArticle> all) {
    final q = _query.trim().toLowerCase();
    return all.where((a) {
      final inCategory = a.categoryId == _selectedCategoryId;
      final matchesQuery = q.isEmpty ||
          a.title.toLowerCase().contains(q) ||
          a.summary.toLowerCase().contains(q);
      return inCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AppKnowledgeArticle>>(
      stream: KnowledgeArticleRepository.instance.watchActive(),
      builder: (context, snapshot) {
        final visible = _visibleFrom(
          snapshot.data ?? AppKnowledgeArticle.defaults(),
        );
        return Scaffold(
          backgroundColor: AppColors.background,
          body: AppPageFrame.standard(
            backgroundColor: AppColors.background,
            pawPrintColor: AppColors.warning,
            header: _buildHeader(context),
            content: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildBanner(),
                  const SizedBox(height: 10),
                  _buildSearchBar(),
                  const SizedBox(height: 12),
                  _buildCategoryCards(),
                  const SizedBox(height: 14),
                  _buildArticlesHeader(visible.length),
                  const SizedBox(height: 8),
                  _buildArticlesList(visible),
                  const SizedBox(height: 12),
                  const KnowledgeDisclaimer(),
                ],
              ),
            ),
            navbar: const AppBottomNavbar(homeColor: AppColors.warning),
          ),
        );
      },
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(color: AppColors.warning),
          Expanded(
            child: IgnorePointer(
              child: Text(
                'Makaleler',
                textAlign: TextAlign.center,
                style: AppTextStyles.pageHeader.copyWith(color: AppColors.warning),
              ),
            ),
          ),
          const AppNotificationButton(badgeColor: AppColors.error),
        ],
      ),
    );
  }

  Widget _buildBanner() {
    return const AppBannerSlot(
      placement: BannerPlacement.articles,
      fallbackAssets: ['assets/images/bilgi_bankasi_banner.png'],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.warning, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Makale ara...',
                hintStyle: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          if (_query.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() => _query = '');
              },
              child: const Icon(
                Icons.close_rounded,
                color: AppColors.subText,
                size: 20,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCategoryCards() {
    return SizedBox(
      height: 96,
      child: Row(
        children: [
          for (int i = 0; i < _categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(child: _buildCategoryCard(_categories[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryCard(_ArticleCategory cat) {
    final selected = cat.id == _selectedCategoryId;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategoryId = cat.id),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? cat.color : AppColors.warning.withValues(alpha: 0.28),
            width: selected ? 2 : 1,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          children: [
            Expanded(
              child: Image.asset(
                cat.imagePath,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.image_outlined,
                      color: AppColors.subText,
                    ),
                  );
                },
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 5),
              color: selected ? cat.color : AppColors.surface,
              child: Text(
                cat.title,
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: selected ? AppColors.surface : AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArticlesHeader(int count) {
    return Row(
      children: [
        Icon(Icons.article_outlined, color: _selectedCategory.color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${_selectedCategory.title} Makaleleri',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionHeader.copyWith(
              color: AppColors.warning,
            ),
          ),
        ),
        Text(
          '$count makale',
          style: const TextStyle(
            color: AppColors.subText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildArticlesList(List<AppKnowledgeArticle> articles) {
    if (articles.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 32),
        alignment: Alignment.center,
        child: const Text(
          'Sonuç bulunamadı',
          style: TextStyle(
            color: AppColors.subText,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );
    }
    return Column(
      children: [
        for (int i = 0; i < articles.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          _buildArticleCard(articles[i]),
        ],
      ],
    );
  }

  Widget _buildArticleCard(AppKnowledgeArticle article) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen.fromArticle(article),
          ),
        );
      },
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
          SizedBox(
            width: 96,
            height: double.infinity,
            child: buildProductImage(
              article.displayImage,
              fit: BoxFit.cover,
              errorWidget: Container(
                color: AppColors.warning.withValues(alpha: 0.10),
                alignment: Alignment.center,
                child: const Icon(
                  Icons.image_outlined,
                  color: AppColors.subText,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    article.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    article.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.subText,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w500,
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 11,
                        color: AppColors.subText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '${article.minutes} dk okuma',
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.warning,
                        size: 18,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          ],
        ),
      ),
    );
  }
}

class _ArticleCategory {
  const _ArticleCategory({
    required this.id,
    required this.title,
    required this.color,
    required this.imagePath,
  });

  final String id;
  final String title;
  final Color color;
  final String imagePath;
}
