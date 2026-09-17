import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/cat_feeding_table.dart';
import 'package:geliyor_app/widgets/knowledge_disclaimer.dart';

class QuestionDetailScreen extends StatelessWidget {
  const QuestionDetailScreen({
    super.key,
    required this.question,
    required this.views,
    required this.topicTitle,
    this.answer = '',
    this.tips = const [],
  });

  final String question;
  final String views;
  final String topicTitle;
  final String answer;
  final List<String> tips;

  bool get _showFeedingTable {
    final q = question.toLowerCase();
    final t = topicTitle.toLowerCase();
    return t.contains('kilo') ||
        q.contains('porsiyon') ||
        q.contains('kalori') ||
        q.contains('tüket') ||
        q.contains('tuket');
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
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildBanner(),
              const SizedBox(height: 10),
              _buildTopicChip(),
              const SizedBox(height: 10),
              _buildQuestionCard(),
              const SizedBox(height: 10),
              _buildAnswerCard(),
              if (_showFeedingTable) ...[
                const SizedBox(height: 10),
                const CatFeedingTableCard(accent: AppColors.warning),
              ],
              const SizedBox(height: 10),
              _buildTipsCard(),
              const SizedBox(height: 10),
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
                'Soru Detayı',
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

  /// Geçici banner — ileride özel görsel ile değiştirilecek.
  Widget _buildBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28), width: 1.2),
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            AppColors.warning.withValues(alpha: 0.16),
            AppColors.background,
            AppColors.warning.withValues(alpha: 0.16),
          ],
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            right: -10,
            bottom: -16,
            child: Icon(
              Icons.pets_rounded,
              size: 80,
              color: AppColors.warning.withValues(alpha: 0.07),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: const BoxDecoration(
                  color: AppColors.surface,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.info_outline_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Buradaki bilgiler genel bilgi amaçlıdır. Öneri ve tavsiye niteliğindedir. Uzman görüşü değildir. Ciddi durumlarda lütfen veteriner hekiminize başvurunuz.',
                  style: TextStyle(
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
      ),
    );
  }

  Widget _buildTopicChip() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.folder_open_rounded, color: AppColors.warning, size: 14),
          const SizedBox(width: 5),
          Text(
            topicTitle,
            style: const TextStyle(
              color: AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.warning, width: 1.4),
                ),
                child: const Icon(
                  Icons.help_outline_rounded,
                  color: AppColors.warning,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  question,
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(
                Icons.remove_red_eye_outlined,
                size: 13,
                color: AppColors.subText,
              ),
              const SizedBox(width: 4),
              Text(
                '$views görüntülenme',
                style: const TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 12),
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: AppColors.subText,
              ),
              const SizedBox(width: 4),
              const Text(
                '3 dk okuma',
                style: TextStyle(
                  color: AppColors.subText,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnswerCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.verified_rounded, color: AppColors.warning, size: 16),
              SizedBox(width: 6),
              Text(
                'Yanıt',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(
            _answerLead,
            style: const TextStyle(
              color: AppColors.text,
              fontSize: 12,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          if (_answerFollow.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              _answerFollow,
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 12,
                fontWeight: FontWeight.w500,
                height: 1.45,
              ),
            ),
          ],
        ],
      ),
    );
  }

  String get _answerLead {
    final custom = answer.trim();
    if (custom.isNotEmpty) return custom;
    if (_showFeedingTable) {
      return 'Yetişkin kedilerde günlük kuru mama ihtiyacı vücut ağırlığına göre değişir. '
          'Örneğin 3 kg bir kedi günde yaklaşık 50 g, 5 kg bir kedi 70 g, 8 kg bir kedi 100 g yer. '
          '30 günlük tüketim ve 10 kg paketin kaç gün yeteceği aşağıdaki tabloda yer alır.';
    }
    return 'Bu durum birçok evcil hayvanda stres, mama değişikliği, '
        'hafif mide rahatsızlığı veya çevresel faktörlerden kaynaklanabilir. '
        'Öncelikle iştah, su tüketimi, enerji seviyesi ve dışkı/kusma '
        'gibi belirtileri 24–48 saat izleyin.';
  }

  String get _answerFollow {
    if (answer.trim().isNotEmpty) return '';
    if (_showFeedingTable) {
      return 'Değerler ortalama rehberdir; mama kalorisi, kısırlık, aktivite ve '
          'yaş mama/ödül miktarına göre porsiyonu ayarlayın. Ani kilo değişiminde '
          'veteriner hekime danışın. Bu içerik bilgilendirme amaçlıdır.';
    }
    return 'Belirtiler şiddetlenirse, kan görülürse, hayvan halsiz düşerse '
        'veya hiç yemek/su almıyorsa gecikmeden veteriner hekime başvurun. '
        'Bu içerik bilgilendirme amaçlıdır; teşhis yerine geçmez.';
  }

  Widget _buildTipsCard() {
    final tips = this.tips.isNotEmpty
        ? this.tips
        : const <String>[
            'Temiz ve taze suya sürekli erişim sağlayın.',
            'Mama değişimini 5–7 günde kademeli yapın.',
            'Ani davranış değişikliklerini not edin.',
            'Şüphede kalırsanız veterinerinize danışın.',
          ];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.lightbulb_outline_rounded, color: AppColors.warning, size: 16),
              SizedBox(width: 6),
              Text(
                'Pratik öneriler',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (int i = 0; i < tips.length; i++) ...[
            if (i > 0) const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 18,
                  height: 18,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.10),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tips[i],
                    style: const TextStyle(
                      color: AppColors.text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      height: 1.3,
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
}
