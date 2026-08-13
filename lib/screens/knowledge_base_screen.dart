import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/all_topics_screen.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/article_detail_screen.dart';
import 'package:geliyor_app/screens/articles_screen.dart';
import 'package:geliyor_app/screens/featured_questions_screen.dart';
import 'package:geliyor_app/screens/question_detail_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
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
      color: Color(0xFF22C55E),
    ),
    _KbCategory(
      id: 'idrar',
      title: 'İdrar Yolu\nSağlığı',
      iconPath: 'assets/images/app_ikonlar/idrar.png',
      color: Color(0xFFEC4899),
    ),
    _KbCategory(
      id: 'alerji',
      title: 'Alerji\n& Deri',
      iconPath: 'assets/images/app_ikonlar/tuy_deri.png',
      color: Color(0xFF9B4DCA),
    ),
    _KbCategory(
      id: 'kilo',
      title: 'Kilo &\nBeslenme',
      iconPath: 'assets/images/app_ikonlar/kilo_kontrol.png',
      color: Color(0xFFFF6600),
    ),
    _KbCategory(
      id: 'genel',
      title: 'Genel\nSağlık',
      iconPath: 'assets/images/app_ikonlar/bagisiklik.png',
      color: Color(0xFF00A859),
    ),
    _KbCategory(
      id: 'tumu',
      title: 'Tümü',
      color: AppColors.subText,
    ),
  ];

  static const _featuredQuestions = <_KbQuestion>[
    _KbQuestion(
      text: 'Kedimin iştahı azaldı, ne yapmalıyım?',
      views: '12,4B',
      categoryId: 'kilo',
    ),
    _KbQuestion(
      text: 'Kedilerde idrar yolu enfeksiyonunun belirtileri nelerdir?',
      views: '9,8B',
      categoryId: 'idrar',
    ),
    _KbQuestion(
      text: 'Kedimin tüyleri çok dökülüyor, normal mi?',
      views: '8,1B',
      categoryId: 'alerji',
    ),
    _KbQuestion(
      text: 'Kedime hangi aşıları yaptırmalıyım?',
      views: '15,2B',
      categoryId: 'genel',
    ),
  ];

  static const _questionsByCategory = <String, List<_KbQuestion>>{
    'sindirim': [
      _KbQuestion(
        text: 'Kedimde ishal olursa ne yapmalıyım?',
        views: '7,2B',
        categoryId: 'sindirim',
      ),
      _KbQuestion(
        text: 'Kusma ne zaman acil sayılır?',
        views: '6,5B',
        categoryId: 'sindirim',
      ),
      _KbQuestion(
        text: 'Hassas mideli kediler için mama önerisi nedir?',
        views: '5,9B',
        categoryId: 'sindirim',
      ),
      _KbQuestion(
        text: 'Gaz ve şişkinlik için ne yapılmalı?',
        views: '4,3B',
        categoryId: 'sindirim',
      ),
    ],
    'idrar': [
      _KbQuestion(
        text: 'Kedilerde idrar yolu enfeksiyonunun belirtileri nelerdir?',
        views: '9,8B',
        categoryId: 'idrar',
      ),
      _KbQuestion(
        text: 'Kum kabı dışında idrar yapıyorsa ne anlama gelir?',
        views: '6,1B',
        categoryId: 'idrar',
      ),
      _KbQuestion(
        text: 'İdrar yolu sağlığı için mama seçimi nasıl olmalı?',
        views: '5,4B',
        categoryId: 'idrar',
      ),
      _KbQuestion(
        text: 'Su tüketimi nasıl artırılır?',
        views: '4,8B',
        categoryId: 'idrar',
      ),
    ],
    'alerji': [
      _KbQuestion(
        text: 'Kedimin tüyleri çok dökülüyor, normal mi?',
        views: '8,1B',
        categoryId: 'alerji',
      ),
      _KbQuestion(
        text: 'Kaşıntı ve kızarıklık alerji belirtisi midir?',
        views: '7,0B',
        categoryId: 'alerji',
      ),
      _KbQuestion(
        text: 'Alerjik deri sorunlarında mama değişimi gerekir mi?',
        views: '5,6B',
        categoryId: 'alerji',
      ),
      _KbQuestion(
        text: 'Tüy bakımı alerjiyi nasıl etkiler?',
        views: '3,9B',
        categoryId: 'alerji',
      ),
    ],
    'kilo': [
      _KbQuestion(
        text: 'Kedimin iştahı azaldı, ne yapmalıyım?',
        views: '12,4B',
        categoryId: 'kilo',
      ),
      _KbQuestion(
        text: 'Fazla kilolu kediler için porsiyon nasıl ayarlanır?',
        views: '6,8B',
        categoryId: 'kilo',
      ),
      _KbQuestion(
        text: 'Günlük kalori ihtiyacı nasıl hesaplanır?',
        views: '5,1B',
        categoryId: 'kilo',
      ),
      _KbQuestion(
        text: 'Ödül mamaları kilo alımına yol açar mı?',
        views: '4,0B',
        categoryId: 'kilo',
      ),
    ],
    'genel': [
      _KbQuestion(
        text: 'Kedime hangi aşıları yaptırmalıyım?',
        views: '15,2B',
        categoryId: 'genel',
      ),
      _KbQuestion(
        text: 'Yıllık veteriner kontrolü ne zaman yapılmalı?',
        views: '8,7B',
        categoryId: 'genel',
      ),
      _KbQuestion(
        text: 'İç ve dış parazit koruması nasıl planlanır?',
        views: '7,3B',
        categoryId: 'genel',
      ),
      _KbQuestion(
        text: 'Evde sağlık takibi için nelere dikkat etmeliyim?',
        views: '5,5B',
        categoryId: 'genel',
      ),
    ],
  };

  static const _articles = <_KbArticle>[
    _KbArticle(
      tag: 'Beslenme',
      tagColor: Color(0xFF00A859),
      title: 'Kedilerde Doğru Beslenme Rehberi',
      minutes: 5,
      imagePath: 'assets/images/bilgi_beslenme.png',
    ),
    _KbArticle(
      tag: 'Sağlık',
      tagColor: Color(0xFF9B4DCA),
      title: 'Kedilerde En Sık Görülen Hastalıklar',
      minutes: 7,
      imagePath: 'assets/images/bilgi_saglik.png',
    ),
    _KbArticle(
      tag: 'Bakım',
      tagColor: Color(0xFFFF6600),
      title: 'Tüy Bakımı Nasıl Yapılmalı?',
      minutes: 4,
      imagePath: 'assets/images/bilgi_bakim.png',
    ),
    _KbArticle(
      tag: 'Aşı',
      tagColor: Color(0xFF1E90FF),
      title: 'Aşı Takvimi ve Koruyucu Hekimlik',
      minutes: 6,
      imagePath: 'assets/images/bilgi_asi_koruma.png',
    ),
  ];

  List<_KbQuestion> get _visibleQuestions {
    final id = _selectedCategoryId;
    if (id == null || id == 'tumu') return _featuredQuestions;
    return _questionsByCategory[id] ?? _featuredQuestions;
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
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AllTopicsScreen()),
      );
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
        navbar: const AppBottomNavbar(),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Row(
        children: [
          const AppBackButton(),
          Expanded(
            child: IgnorePointer(
              child: Text(
                'Bilgi Bankası',
                textAlign: TextAlign.center,
                style: AppTextStyles.pageHeader,
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
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.subText, size: 20),
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
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.3),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/bilgi_bankasi_banner.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 110,
            color: AppColors.selected,
            alignment: Alignment.center,
            child: const Icon(
              Icons.menu_book_rounded,
              color: AppColors.primary,
              size: 36,
            ),
          );
        },
      ),
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
                color: selected ? cat.color : AppColors.border,
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
                          color: AppColors.primary,
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
              color: selected ? cat.color : AppColors.text,
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
    final questions = _visibleQuestions;
    return Column(
      children: [
        Row(
          children: [
            const Icon(Icons.pets_rounded, color: AppColors.primary, size: 15),
            const SizedBox(width: 4),
            Expanded(
              child: Text(
                _questionsTitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const FeaturedQuestionsScreen(),
                  ),
                );
              },
              child: const Row(
                children: [
                  Text(
                    'Tümünü Gör',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 16,
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
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              for (int i = 0; i < questions.length; i++) ...[
                _buildQuestionRow(questions[i]),
                if (i != questions.length - 1)
                  const Divider(height: 1, color: AppColors.border),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionRow(_KbQuestion q) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(
              question: q.text,
              views: q.views,
              topicTitle: _questionsTitle,
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
              decoration: const BoxDecoration(
                color: AppColors.selected,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.primary,
                size: 13,
              ),
            ),
            const SizedBox(width: 7),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    q.text,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.text,
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
            const Icon(Icons.pets_rounded, color: AppColors.primary, size: 15),
            const SizedBox(width: 4),
            const Expanded(
              child: Text(
                'Makaleler',
                style: TextStyle(
                  color: AppColors.text,
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            GestureDetector(
              onTap: () => _openArticles(),
              child: const Row(
                children: [
                  Text(
                    'Tüm Makaleler',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 120,
          child: Row(
            children: [
              for (int i = 0; i < _articles.length; i++) ...[
                if (i > 0) const SizedBox(width: 7),
                Expanded(child: _buildArticleCard(_articles[i])),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildArticleCard(_KbArticle article) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(
              title: article.title,
              category: article.tag,
              imagePath: article.imagePath,
              minutes: article.minutes,
            ),
          ),
        );
      },
      child: Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: Image.asset(
                    article.imagePath,
                    fit: BoxFit.cover,
                    // Görselin içindeki hazır etiket kırpılsın, pill kod ile çizilir
                    alignment: Alignment.bottomCenter,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.selected,
                        alignment: Alignment.center,
                        child: const Icon(
                          Icons.image_outlined,
                          color: AppColors.subText,
                        ),
                      );
                    },
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
                        color: article.tagColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Text(
                      article.tag,
                      style: TextStyle(
                        color: article.tagColor,
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
                      color: AppColors.text,
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

class _KbQuestion {
  const _KbQuestion({
    required this.text,
    required this.views,
    required this.categoryId,
  });

  final String text;
  final String views;
  final String categoryId;
}

class _KbArticle {
  const _KbArticle({
    required this.tag,
    required this.tagColor,
    required this.title,
    required this.minutes,
    required this.imagePath,
  });

  final String tag;
  final Color tagColor;
  final String title;
  final int minutes;
  final String imagePath;
}
