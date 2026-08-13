import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/featured_questions_screen.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/knowledge_disclaimer.dart';

class AllTopicsScreen extends StatefulWidget {
  const AllTopicsScreen({super.key});

  @override
  State<AllTopicsScreen> createState() => _AllTopicsScreenState();
}

class _AllTopicsScreenState extends State<AllTopicsScreen> {
  final _searchController = TextEditingController();

  static const _topics = <_TopicItem>[
    _TopicItem(
      title: 'Sindirim',
      subtitle: 'İshal & kusma',
      iconPath: 'assets/images/app_ikonlar/sindirim.png',
      color: Color(0xFF1E90FF),
      featuredTopicId: 'sindirim',
    ),
    _TopicItem(
      title: 'Böbrek',
      subtitle: 'Böbrek sağlığı',
      iconPath: 'assets/images/app_ikonlar/bobrek.png',
      color: Color(0xFFEC4899),
      featuredTopicId: 'idrar',
    ),
    _TopicItem(
      title: 'İdrar Yolu',
      subtitle: 'İdrar sağlığı',
      iconPath: 'assets/images/app_ikonlar/idrar.png',
      color: Color(0xFFDB2777),
      featuredTopicId: 'idrar',
    ),
    _TopicItem(
      title: 'Tüy & Deri',
      subtitle: 'Tüy bakımı',
      iconPath: 'assets/images/app_ikonlar/tuy_deri.png',
      color: Color(0xFF9B4DCA),
      featuredTopicId: 'alerji',
    ),
    _TopicItem(
      title: 'Alerji',
      subtitle: 'Hassas cilt',
      iconPath: 'assets/images/app_ikonlar/hypoallergenic.png',
      color: Color(0xFF22C55E),
      featuredTopicId: 'alerji',
    ),
    _TopicItem(
      title: 'Ağız & Diş',
      subtitle: 'Diş bakımı',
      iconPath: 'assets/images/app_ikonlar/dis.png',
      color: Color(0xFF0EA5E9),
      featuredTopicId: 'dis',
    ),
    _TopicItem(
      title: 'Kilo Kontrolü',
      subtitle: 'İdeal kilo',
      iconPath: 'assets/images/app_ikonlar/kilo_kontrol.png',
      color: Color(0xFFFF6600),
      featuredTopicId: 'kilo',
    ),
    _TopicItem(
      title: 'Kalp Sağlığı',
      subtitle: 'Kalp desteği',
      iconPath: 'assets/images/app_ikonlar/kalp.png',
      color: Color(0xFFEF4444),
      featuredTopicId: 'genel',
    ),
    _TopicItem(
      title: 'Bağışıklık',
      subtitle: 'Bağışıklık',
      iconPath: 'assets/images/app_ikonlar/bagisiklik.png',
      color: Color(0xFF16A34A),
      featuredTopicId: 'genel',
    ),
    _TopicItem(
      title: 'Diyabet',
      subtitle: 'Kan şekeri',
      iconPath: 'assets/images/app_ikonlar/diyabet.png',
      color: Color(0xFFF59E0B),
      featuredTopicId: 'kilo',
    ),
    _TopicItem(
      title: 'Eklem',
      subtitle: 'Hareket desteği',
      iconPath: 'assets/images/app_ikonlar/eklem.png',
      color: Color(0xFF84CC16),
      featuredTopicId: 'genel',
    ),
    _TopicItem(
      title: 'Karaciğer',
      subtitle: 'Karaciğer',
      iconPath: 'assets/images/app_ikonlar/karaciger.png',
      color: Color(0xFF14B8A6),
      featuredTopicId: 'genel',
    ),
    _TopicItem(
      title: 'Parazit',
      subtitle: 'İç & dış',
      iconPath: 'assets/images/app_ikonlar/parazit.png',
      color: Color(0xFF2563EB),
      featuredTopicId: 'parazit',
    ),
    _TopicItem(
      title: 'Aşı Takibi',
      subtitle: 'Aşı takvimi',
      iconPath: 'assets/images/app_ikonlar/asi_takvimi.png',
      color: Color(0xFFFF6600),
      featuredTopicId: 'genel',
    ),
    _TopicItem(
      title: 'İlaç & Tedavi',
      subtitle: 'Tedavi planı',
      iconPath: 'assets/images/app_ikonlar/ilac_tedavi.png',
      color: Color(0xFF00A859),
      featuredTopicId: 'genel',
    ),
    _TopicItem(
      title: 'Özel Mama',
      subtitle: 'Özel formül',
      iconPath: 'assets/images/app_ikonlar/mama_kabi.png',
      color: Color(0xFF8B5CF6),
      featuredTopicId: 'kilo',
    ),
    _TopicItem(
      title: 'Acil Durum',
      subtitle: 'Acil yardım',
      iconPath: 'assets/images/app_ikonlar/acil_durum.png',
      color: Color(0xFFE60000),
      featuredTopicId: 'genel',
    ),
    _TopicItem(
      title: 'Zehirlenme',
      subtitle: 'Toksik risk',
      iconPath: 'assets/images/app_ikonlar/zehirlenme.png',
      color: Color(0xFFDC2626),
      featuredTopicId: 'genel',
    ),
    _TopicItem(
      title: 'Yaralanma',
      subtitle: 'İlk yardım',
      iconPath: 'assets/images/app_ikonlar/yaralanma.png',
      color: Color(0xFFB91C1C),
      featuredTopicId: 'genel',
    ),
    _TopicItem(
      title: 'Doğal İçerik',
      subtitle: 'Doğal formül',
      iconPath: 'assets/images/app_ikonlar/dogal_icerik.png',
      color: Color(0xFF65A30D),
      featuredTopicId: 'kilo',
    ),
  ];

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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 10),
              _buildSearchBar(),
              const SizedBox(height: 12),
              _buildTopicsGrid(),
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
                'Tüm Konular',
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
        'assets/images/tum_konular_banner.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        alignment: Alignment.center,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 100,
            color: AppColors.selected,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Dostunuzun sağlığı bizim önceliğimiz',
              textAlign: TextAlign.center,
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
      height: 40,
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
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Sağlık konusu ara...',
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

  Widget _buildTopicsGrid() {
    const columns = 4;
    const rows = 5;
    return Column(
      children: [
        for (int row = 0; row < rows; row++) ...[
          if (row > 0) const SizedBox(height: 10),
          SizedBox(
            height: 92,
            child: Row(
              children: [
                for (int col = 0; col < columns; col++) ...[
                  if (col > 0) const SizedBox(width: 8),
                  Expanded(
                    child: _buildTopicItem(_topics[row * columns + col]),
                  ),
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildTopicItem(_TopicItem topic) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FeaturedQuestionsScreen(
              initialTopicId: topic.featuredTopicId,
            ),
          ),
        );
      },
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              shape: BoxShape.circle,
              border: Border.all(
                color: Color.lerp(topic.color, Colors.white, 0.45) ??
                    AppColors.border,
                width: 1.4,
              ),
            ),
            child: ClipOval(
              child: Image.asset(
                topic.iconPath,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.health_and_safety_outlined,
                    color: topic.color,
                    size: 24,
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            topic.title,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 9,
              fontWeight: FontWeight.w800,
              height: 1.1,
            ),
          ),
          Text(
            topic.subtitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.subText,
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              height: 1.15,
            ),
          ),
        ],
      ),
    );
  }

}

class _TopicItem {
  const _TopicItem({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.color,
    required this.featuredTopicId,
  });

  final String title;
  final String subtitle;
  final String iconPath;
  final Color color;
  final String featuredTopicId;
}
