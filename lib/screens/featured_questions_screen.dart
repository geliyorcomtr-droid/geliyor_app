import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/knowledge_catalog.dart';
import 'package:geliyor_app/data/knowledge_content_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/question_detail_screen.dart';
import 'package:geliyor_app/screens/topic_search_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/knowledge_disclaimer.dart';

class FeaturedQuestionsScreen extends StatefulWidget {
  const FeaturedQuestionsScreen({super.key, this.initialTopicId = 'sindirim'});

  final String initialTopicId;

  @override
  State<FeaturedQuestionsScreen> createState() =>
      _FeaturedQuestionsScreenState();
}

class _FeaturedQuestionsScreenState extends State<FeaturedQuestionsScreen> {
  late String _selectedTopicId;

  @override
  void initState() {
    super.initState();
    final exists = KnowledgeQuestionTopic.all.any(
      (t) => t.id == widget.initialTopicId,
    );
    _selectedTopicId = exists ? widget.initialTopicId : 'sindirim';
    unawaited(KnowledgeContentRepository.instance.ensureDefaults());
  }

  KnowledgeQuestionTopic get _selectedTopic =>
      KnowledgeQuestionTopic.byId(_selectedTopicId);

  Future<void> _openTopicSearch() async {
    final result = await Navigator.of(context).push<String>(
      MaterialPageRoute(
        builder: (_) => TopicSearchScreen(selectedTopicId: _selectedTopicId),
      ),
    );
    if (result != null && result.isNotEmpty && mounted) {
      setState(() => _selectedTopicId = result);
    }
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
              _buildTopicSelector(),
              const SizedBox(height: 12),
              _buildQuestionsHeader(),
              const SizedBox(height: 8),
              StreamBuilder<List<AppKnowledgeQuestion>>(
                stream: KnowledgeContentRepository.instance
                    .watchActiveQuestions(topicId: _selectedTopicId),
                builder: (context, snapshot) {
                  final questions =
                      snapshot.data ??
                      AppKnowledgeQuestion.defaults()
                          .where((item) => item.topicId == _selectedTopicId)
                          .toList();
                  if (questions.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 24),
                      child: Center(
                        child: Text(
                          'Bu konuda henüz soru yok.',
                          style: TextStyle(color: AppColors.subText),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: [
                      for (int i = 0; i < questions.length; i++) ...[
                        if (i > 0) const SizedBox(height: 6),
                        _buildQuestionCard(questions[i]),
                      ],
                    ],
                  );
                },
              ),
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
                'Öne Çıkan Sorular',
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
      placement: BannerPlacement.featuredQuestions,
      fallbackAssets: ['assets/images/one_cikan_sorular_banner.png'],
    );
  }

  Widget _buildTopicSelector() {
    return GestureDetector(
      onTap: _openTopicSearch,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.warning, width: 1.4),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.folder_open_rounded,
              color: AppColors.warning,
              size: 20,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Konu Seçin',
                    style: TextStyle(
                      color: AppColors.subText,
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    _selectedTopic.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.warning,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.warning,
              size: 24,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuestionsHeader() {
    return Row(
      children: [
        Expanded(
          child: Text(
            '${_selectedTopic.title} ile ilgili sorular',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.sectionHeader.copyWith(
              color: AppColors.warning,
            ),
          ),
        ),
        GestureDetector(
          onTap: _openTopicSearch,
          child: const Row(
            children: [
              Icon(Icons.sync_rounded, color: AppColors.warning, size: 15),
              SizedBox(width: 3),
              Text(
                'Konuyu Değiştir',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionCard(AppKnowledgeQuestion q) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(
              question: q.title,
              views: q.views,
              topicTitle: _selectedTopic.title,
              answer: q.answer,
              tips: q.tips,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.warning, width: 1.4),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.warning,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                q.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  height: 1.25,
                ),
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.remove_red_eye_outlined,
              size: 12,
              color: AppColors.subText,
            ),
            const SizedBox(width: 3),
            Text(
              q.views,
              style: const TextStyle(
                color: AppColors.subText,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 2),
            const Icon(
              Icons.chevron_right_rounded,
              color: AppColors.warning,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
