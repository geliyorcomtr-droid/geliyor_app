import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/article_detail_screen.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
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
      color: Color(0xFF00A859),
      imagePath: 'assets/images/bilgi_beslenme.png',
    ),
    _ArticleCategory(
      id: 'saglik',
      title: 'Sağlık',
      color: Color(0xFF9B4DCA),
      imagePath: 'assets/images/bilgi_saglik.png',
    ),
    _ArticleCategory(
      id: 'bakim',
      title: 'Bakım',
      color: Color(0xFFFF6600),
      imagePath: 'assets/images/bilgi_bakim.png',
    ),
    _ArticleCategory(
      id: 'asi',
      title: 'Aşı',
      color: Color(0xFF1E90FF),
      imagePath: 'assets/images/bilgi_asi_koruma.png',
    ),
  ];

  static const _articles = <_Article>[
    // Beslenme
    _Article(
      categoryId: 'beslenme',
      title: 'Kedilerde Doğru Beslenme Rehberi',
      summary: 'Yaşa ve ırka göre porsiyon, mama seçimi ve öğün düzeni.',
      minutes: 5,
      imagePath: 'assets/images/bilgi_beslenme.png',
    ),
    _Article(
      categoryId: 'beslenme',
      title: 'Yaş Mama mı Kuru Mama mı?',
      summary: 'İki mama türünün avantajları ve doğru kullanımı.',
      minutes: 4,
      imagePath: 'assets/images/bilgi_beslenme.png',
    ),
    _Article(
      categoryId: 'beslenme',
      title: 'Kilo Kontrolü İçin Beslenme İpuçları',
      summary: 'Fazla kilolu dostlar için pratik öneriler.',
      minutes: 6,
      imagePath: 'assets/images/bilgi_beslenme.png',
    ),
    // Sağlık
    _Article(
      categoryId: 'saglik',
      title: 'Kedilerde En Sık Görülen Hastalıklar',
      summary: 'Belirtiler, korunma yolları ve ne zaman veterinere gidilmeli.',
      minutes: 7,
      imagePath: 'assets/images/bilgi_saglik.png',
    ),
    _Article(
      categoryId: 'saglik',
      title: 'Düzenli Veteriner Kontrolünün Önemi',
      summary: 'Yıllık kontrol takvimi ve erken teşhisin faydaları.',
      minutes: 5,
      imagePath: 'assets/images/bilgi_saglik.png',
    ),
    _Article(
      categoryId: 'saglik',
      title: 'İdrar Yolu Sağlığına Dikkat',
      summary: 'Belirtiler ve günlük hayatta alınacak önlemler.',
      minutes: 6,
      imagePath: 'assets/images/bilgi_saglik.png',
    ),
    // Bakım
    _Article(
      categoryId: 'bakim',
      title: 'Tüy Bakımı Nasıl Yapılmalı?',
      summary: 'Fırçalama sıklığı, doğru araçlar ve tüy dökülmesi.',
      minutes: 4,
      imagePath: 'assets/images/bilgi_bakim.png',
    ),
    _Article(
      categoryId: 'bakim',
      title: 'Diş ve Ağız Bakımı',
      summary: 'Diş taşı önleme ve düzenli bakım alışkanlıkları.',
      minutes: 5,
      imagePath: 'assets/images/bilgi_bakim.png',
    ),
    _Article(
      categoryId: 'bakim',
      title: 'Tırnak ve Pati Bakımı',
      summary: 'Evde güvenli tırnak kesimi ve pati temizliği.',
      minutes: 3,
      imagePath: 'assets/images/bilgi_bakim.png',
    ),
    // Aşı
    _Article(
      categoryId: 'asi',
      title: 'Aşı Takvimi ve Koruyucu Hekimlik',
      summary: 'Hangi aşı ne zaman? Yavru ve yetişkin takvimi.',
      minutes: 6,
      imagePath: 'assets/images/bilgi_asi_koruma.png',
    ),
    _Article(
      categoryId: 'asi',
      title: 'İç ve Dış Parazit Koruması',
      summary: 'Düzenli koruma planı ve mevsimsel dikkat noktaları.',
      minutes: 5,
      imagePath: 'assets/images/bilgi_asi_koruma.png',
    ),
    _Article(
      categoryId: 'asi',
      title: 'Kuduz Aşısı Hakkında Bilinmesi Gerekenler',
      summary: 'Yasal zorunluluklar ve aşı sonrası bakım.',
      minutes: 4,
      imagePath: 'assets/images/bilgi_asi_koruma.png',
    ),
  ];

  @override
  void initState() {
    super.initState();
    final valid = _categories.any((c) => c.id == widget.initialCategoryId);
    _selectedCategoryId =
        valid ? widget.initialCategoryId! : _categories.first.id;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  _ArticleCategory get _selectedCategory =>
      _categories.firstWhere((c) => c.id == _selectedCategoryId);

  List<_Article> get _visibleArticles {
    final q = _query.trim().toLowerCase();
    return _articles.where((a) {
      final inCategory = a.categoryId == _selectedCategoryId;
      final matchesQuery = q.isEmpty ||
          a.title.toLowerCase().contains(q) ||
          a.summary.toLowerCase().contains(q);
      return inCategory && matchesQuery;
    }).toList();
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
              _buildBanner(),
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildCategoryCards(),
              const SizedBox(height: 14),
              _buildArticlesHeader(),
              const SizedBox(height: 8),
              _buildArticlesList(),
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
                'Makaleler',
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

  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border, width: 1.2),
      ),
      clipBehavior: Clip.antiAlias,
      child: Image.asset(
        'assets/images/bilgi_bankasi_banner.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 96,
            color: AppColors.selected,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Güvenilir bilgiye tek tıkla ulaşın',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 20),
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
            color: selected ? cat.color : AppColors.border,
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
                  color: selected ? AppColors.surface : AppColors.text,
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

  Widget _buildArticlesHeader() {
    return Row(
      children: [
        Icon(Icons.article_outlined, color: _selectedCategory.color, size: 16),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '${_selectedCategory.title} Makaleleri',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 14,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        Text(
          '${_visibleArticles.length} makale',
          style: const TextStyle(
            color: AppColors.subText,
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildArticlesList() {
    final articles = _visibleArticles;
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

  Widget _buildArticleCard(_Article article) {
    final category = _categories.firstWhere(
      (item) => item.id == article.categoryId,
    );
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ArticleDetailScreen(
              title: article.title,
              category: category.title,
              imagePath: article.imagePath,
              minutes: article.minutes,
              summary: article.summary,
            ),
          ),
        );
      },
      child: Container(
        height: 96,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Row(
          children: [
          SizedBox(
            width: 96,
            height: double.infinity,
            child: Image.asset(
              article.imagePath,
              fit: BoxFit.cover,
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
                      color: AppColors.text,
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
                        color: AppColors.primary,
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

class _Article {
  const _Article({
    required this.categoryId,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.imagePath,
  });

  final String categoryId;
  final String title;
  final String summary;
  final int minutes;
  final String imagePath;
}
