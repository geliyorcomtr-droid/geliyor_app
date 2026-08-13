import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/knowledge_disclaimer.dart';

class ArticleDetailScreen extends StatelessWidget {
  const ArticleDetailScreen({
    super.key,
    required this.title,
    required this.category,
    required this.imagePath,
    required this.minutes,
    this.summary,
  });

  final String title;
  final String category;
  final String imagePath;
  final int minutes;
  final String? summary;

  Color get _categoryColor {
    switch (category.toLowerCase()) {
      case 'beslenme':
        return AppColors.success;
      case 'sağlık':
        return const Color(0xFF9B4DCA);
      case 'bakım':
        return AppColors.warning;
      default:
        return AppColors.primary;
    }
  }

  List<String> get _keyPoints {
    switch (category.toLowerCase()) {
      case 'beslenme':
        return const [
          'Mama seçimini yaşa, kiloya ve sağlık durumuna göre yapın.',
          'Porsiyon miktarını günlük enerji ihtiyacına göre ayarlayın.',
          'Mama değişimini 5–7 güne yayarak kademeli gerçekleştirin.',
        ];
      case 'bakım':
        return const [
          'Bakım sıklığını tüy ve deri yapısına göre planlayın.',
          'Evcil hayvanınıza uygun, güvenli bakım ürünleri kullanın.',
          'Kızarıklık, yara veya hassasiyet fark ederseniz takip edin.',
        ];
      case 'aşı':
      case 'aşı & koruma':
        return const [
          'Aşı takvimini veteriner hekiminizle birlikte oluşturun.',
          'Uygulama tarihlerini ve hatırlatıcıları düzenli kaydedin.',
          'Aşı sonrası olağandışı belirtileri veterinerinize bildirin.',
        ];
      default:
        return const [
          'Dostunuzun günlük davranış ve iştah değişikliklerini izleyin.',
          'Belirtiler devam ederse profesyonel değerlendirme alın.',
          'Düzenli kontrollerle sağlık sorunlarını erken fark edin.',
        ];
    }
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
              _buildHero(),
              const SizedBox(height: 12),
              _buildTitle(),
              const SizedBox(height: 12),
              _buildIntroduction(),
              const SizedBox(height: 12),
              _buildKeyPoints(),
              const SizedBox(height: 12),
              _buildContentSection(),
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
                'Makale Ayrıntısı',
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

  Widget _buildHero() {
    return Container(
      width: double.infinity,
      height: 176,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            imagePath,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.selected,
                alignment: Alignment.center,
                child: const Icon(
                  Icons.article_outlined,
                  color: AppColors.primary,
                  size: 48,
                ),
              );
            },
          ),
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.transparent, Color(0xAA000000)],
                stops: [0.45, 1],
              ),
            ),
          ),
          Positioned(
            left: 12,
            bottom: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _categoryColor,
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                category,
                style: const TextStyle(
                  color: AppColors.surface,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.text,
            fontSize: 19,
            fontWeight: FontWeight.w900,
            height: 1.22,
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              color: AppColors.primary,
              size: 14,
            ),
            const SizedBox(width: 4),
            const Text(
              'Editör ekibi',
              style: TextStyle(
                color: AppColors.subText,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 12),
            const Icon(
              Icons.schedule_rounded,
              color: AppColors.subText,
              size: 14,
            ),
            const SizedBox(width: 4),
            Text(
              '$minutes dk okuma',
              style: const TextStyle(
                color: AppColors.subText,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.bookmark_border_rounded,
              color: AppColors.primary,
              size: 20,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildIntroduction() {
    return _sectionCard(
      icon: Icons.menu_book_rounded,
      title: 'Genel Bakış',
      child: Text(
        summary ??
            'Evcil dostunuzun sağlıklı ve mutlu bir yaşam sürmesi için '
                'günlük alışkanlıkları doğru planlamak önemlidir. Bu makalede '
                'konuyla ilgili temel bilgileri ve uygulanabilir önerileri bulabilirsiniz.',
        style: const TextStyle(
          color: AppColors.text,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.48,
        ),
      ),
    );
  }

  Widget _buildKeyPoints() {
    return _sectionCard(
      icon: Icons.checklist_rounded,
      title: 'Önemli Noktalar',
      child: Column(
        children: [
          for (int i = 0; i < _keyPoints.length; i++) ...[
            if (i > 0) const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 20,
                  height: 20,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Color.lerp(_categoryColor, Colors.white, 0.85),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.check_rounded,
                    color: _categoryColor,
                    size: 13,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _keyPoints[i],
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildContentSection() {
    return _sectionCard(
      icon: Icons.lightbulb_outline_rounded,
      title: 'Nelere Dikkat Etmelisiniz?',
      child: const Text(
        'Her evcil hayvanın yaşı, ırkı, yaşam biçimi ve sağlık geçmişi '
        'farklıdır. Önerileri uygularken dostunuzun bireysel ihtiyaçlarını '
        'göz önünde bulundurun. Ani davranış değişikliklerini, iştah kaybını '
        've devam eden belirtileri kayıt altına almanız veteriner '
        'değerlendirmesini kolaylaştırır.',
        style: TextStyle(
          color: AppColors.text,
          fontSize: 12,
          fontWeight: FontWeight.w500,
          height: 1.48,
        ),
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _categoryColor, size: 17),
              const SizedBox(width: 6),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.text,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          child,
        ],
      ),
    );
  }
}
