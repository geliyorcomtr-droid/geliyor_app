import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/knowledge_article_repository.dart';
import 'package:geliyor_app/data/knowledge_content_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/all_topics_screen.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/article_detail_screen.dart';
import 'package:geliyor_app/screens/articles_screen.dart';
import 'package:geliyor_app/screens/featured_questions_screen.dart';
import 'package:geliyor_app/screens/question_detail_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/knowledge_disclaimer.dart';

class KnowledgeBaseScreen extends StatefulWidget {
  const KnowledgeBaseScreen({super.key});

  @override
  State<KnowledgeBaseScreen> createState() => _KnowledgeBaseScreenState();
}

class _KnowledgeBaseScreenState extends State<KnowledgeBaseScreen> {
  /// null = öne çıkan sorular (varsayılan / Tümü veya tekrar tık)
  String? _selectedCategoryId;
  final _searchController = TextEditingController();

  static const _categories = <_KbCategory>[
    _KbCategory(
      id: 'sindirim',
      title: 'Sindirim\nSistemi',
      iconPath: 'assets/images/app_ikonlar/sindirim.png',
      color: AppColors.warning,
    ),
    _KbCategory(
      id: 'idrar',
      title: 'İdrar Yolu\nSağlığı',
      iconPath: 'assets/images/app_ikonlar/idrar.png',
      color: AppColors.warning,
    ),
    _KbCategory(
      id: 'alerji',
      title: 'Alerji\n& Deri',
      iconPath: 'assets/images/app_ikonlar/tuy_deri.png',
      color: AppColors.warning,
    ),
    _KbCategory(
      id: 'kilo',
      title: 'Kilo &\nBeslenme',
      iconPath: 'assets/images/app_ikonlar/kilo_kontrol.png',
      color: AppColors.warning,
    ),
    _KbCategory(
      id: 'genel',
      title: 'Genel\nSağlık',
      iconPath: 'assets/images/app_ikonlar/bagisiklik.png',
      color: AppColors.warning,
    ),
    _KbCategory(id: 'tumu', title: 'Tümü', color: AppColors.subText),
  ];

  List<AppKnowledgeQuestion> _visibleQuestions(
    List<AppKnowledgeQuestion> all,
  ) {
    final id = _selectedCategoryId;
    if (id == null || id == 'tumu') {
      final featured = all.where((item) => item.featured).toList();
      if (featured.isNotEmpty) return featured.take(4).toList();
      return all.take(4).toList();
    }
    return all.where((item) => item.topicId == id).take(4).toList();
  }

  String get _questionsTitle {
    final id = _selectedCategoryId;
    if (id == null || id == 'tumu') return 'Sizin İçin Öne Çıkan Sorular';
    switch (id) {
      case 'sindirim':
        return 'Sindirim Sistemi Soruları';
      case 'idrar':
        return 'İdrar Yolu Soruları';
      case 'alerji':
        return 'Alerji & Deri Soruları';
      case 'kilo':
        return 'Kilo & Beslenme Soruları';
      case 'genel':
        return 'Genel Sağlık Soruları';
      default:
        return 'Sizin İçin Öne Çıkan Sorular';
    }
  }

  void _onCategoryTap(String id) {
    if (id == 'tumu') {
      Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const AllTopicsScreen()));
      return;
    }
    setState(() {
      // Aynı kategoriye tekrar basınca öne çıkanlara dön
      if (_selectedCategoryId == id) {
        _selectedCategoryId = null;
      } else {
        _selectedCategoryId = id;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    unawaited(KnowledgeArticleRepository.instance.ensureDefaults());
    unawaited(KnowledgeContentRepository.instance.ensureDefaults());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const Text(
                'Evcil dostunuzla ilgili güvenilir bilgilere tek tıkla ulaşın.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 10),
              _buildHeroBanner(),
              const SizedBox(height: 12),
              _buildCategoryRow(),
              const SizedBox(height: 12),
              _buildQuestionsSection(),
              const SizedBox(height: 12),
              _buildArticlesSection(),
              const SizedBox(height: 12),
              const KnowledgeDisclaimer(),
            ],
          ),
        ),
        navbar: const AppBottomNavbar(homeColor: AppColors.warning),
      ),
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
                'Bilgi Bankası',
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

  Widget _buildSearchBar() {
    return Container(
      height: 40,
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
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Belirti, konu veya içerik ara...',
                hintStyle: TextStyle(
                  color: AppColors.subText,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner() {
    return const AppBannerSlot(
      placement: BannerPlacement.knowledge,
      fallbackAssets: ['assets/images/bilgi_bankasi_banner.png'],
    );
  }

  Widget _buildCategoryRow() {
    return SizedBox(
      height: 78,
      child: Row(
        children: [
          for (int i = 0; i < _categories.length; i++) ...[
            if (i > 0) const SizedBox(width: 5),
            Expanded(child: _buildCategoryItem(_categories[i])),
          ],
        ],
      ),
    );
  }

  Widget _buildCategoryItem(_KbCategory cat) {
    final selected = _selectedCategoryId == cat.id;

    return GestureDetector(
      onTap: () => _onCategoryTap(cat.id),
      child: Column(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: selected ? cat.color : AppColors.warning.withValues(alpha: 0.28),
                width: selected ? 2 : 1.2,
              ),
            ),
            child: cat.iconPath == null
                ? Icon(
                    Icons.more_horiz_rounded,
                    color: selected ? cat.color : AppColors.subText,
                    size: 20,
                  )
                : Padding(
                    padding: const EdgeInsets.all(5),
                    child: Image.asset(
                      cat.iconPath!,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(
                          Icons.health_and_safety_outlined,
                          color: AppColors.warning,
                          size: 20,
                        );
                      },
                    ),
                  ),
          ),
          const SizedBox(height: 4),
          Text(
            cat.title,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsSection() {
    return StreamBuilder<List<AppKnowledgeQuestion>>(
      stream: KnowledgeContentRepository.instance.watchActiveQuestions(),
      builder: (context, snapshot) {
        final questions = _visibleQuestions(
          snapshot.data ?? AppKnowledgeQuestion.defaults(),
        );
        return Column(
          children: [
            Row(
              children: [
                const Icon(Icons.pets_rounded, color: AppColors.warning, size: 15),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    _questionsTitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.sectionHeader.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => FeaturedQuestionsScreen(
                          initialTopicId: _selectedCategoryId ?? 'sindirim',
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Text(
                        'Tümünü Gör',
                        style: AppTextStyles.seeAllAction.copyWith(
                          color: AppColors.warning,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.warning,
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
              ),
              child: questions.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        'Bu konuda henüz soru yok.',
                        style: TextStyle(color: AppColors.subText),
                      ),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < questions.length; i++) ...[
                          _buildQuestionRow(questions[i]),
                          if (i != questions.length - 1)
                            Divider(height: 1, color: AppColors.warning.withValues(alpha: 0.28)),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildQuestionRow(AppKnowledgeQuestion q) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(
              question: q.title,
              views: q.views,
              topicTitle: q.topicTitle,
              answer: q.answer,
              tips: q.tips,
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 7, 6, 7),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.warning,
                size: 13,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.remove_red_eye_outlined,
                        size: 10,
                        color: AppColors.subText,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        q.views,
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.subText,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _openArticles([String? categoryId]) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ArticlesScreen(initialCategoryId: categoryId),
      ),
    );
  }

  Widget _buildArticlesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.pets_rounded, color: AppColors.warning, size: 15),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                'Makaleler',
                style: AppTextStyles.sectionHeader.copyWith(
                  color: AppColors.warning,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _openArticles(),
              child: Row(
                children: [
                  Text(
                    'Tüm Makaleler',
                    style: AppTextStyles.seeAllAction.copyWith(
                      color: AppColors.warning,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        StreamBuilder<List<AppKnowledgeArticle>>(
          stream: KnowledgeArticleRepository.instance.watchActive(),
          builder: (context, snapshot) {
            final articles = KnowledgeArticleRepository.hubArticles(
              snapshot.data ?? AppKnowledgeArticle.defaults(),
            );
            if (articles.isEmpty) return const SizedBox.shrink();
            return SizedBox(
              height: 120,
              child: Row(
                children: [
                  for (int i = 0; i < articles.length; i++) ...[
                    if (i > 0) const SizedBox(width: 7),
                    Expanded(child: _buildArticleCard(articles[i])),
                  ],
                ],
              ),
            );
          },
        ),
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
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: buildProductImage(
                      article.displayImage,
                      fit: BoxFit.cover,
                      alignment: Alignment.bottomCenter,
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
                  Positioned(
                    left: 5,
                    top: 5,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: article.categoryColor.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Text(
                        article.categoryTitle,
                        style: TextStyle(
                          color: article.categoryColor,
                          fontSize: 7,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 5, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 31,
                    child: Text(
                      article.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppColors.warning,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        size: 9,
                        color: AppColors.subText,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${article.minutes} dk',
                        style: const TextStyle(
                          color: AppColors.subText,
                          fontSize: 8,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _KbCategory {
  const _KbCategory({
    required this.id,
    required this.title,
    required this.color,
    this.iconPath,
  });

  final String id;
  final String title;
  final Color color;
  final String? iconPath;
}

