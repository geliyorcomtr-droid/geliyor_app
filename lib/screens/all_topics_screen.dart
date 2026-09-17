import 'dart:async';

import 'package:flutter/material.dart';
import 'package:geliyor_app/data/banner_repository.dart';
import 'package:geliyor_app/data/knowledge_content_repository.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/screens/featured_questions_screen.dart';
import 'package:geliyor_app/utils/product_image.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_banner_slider.dart';
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
  String _query = '';

  @override
  void initState() {
    super.initState();
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
                'Tüm Konular',
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
      placement: BannerPlacement.allTopics,
      fallbackAssets: ['assets/images/tum_konular_banner.png'],
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
              onChanged: (value) => setState(() => _query = value),
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
    return StreamBuilder<List<AppKnowledgeTopic>>(
      stream: KnowledgeContentRepository.instance.watchActiveTopics(),
      builder: (context, snapshot) {
        final q = _query.trim().toLowerCase();
        final topics = (snapshot.data ?? AppKnowledgeTopic.defaults()).where((
          item,
        ) {
          if (q.isEmpty) return true;
          return item.title.toLowerCase().contains(q) ||
              item.subtitle.toLowerCase().contains(q);
        }).toList();
        if (topics.isEmpty) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'Konu bulunamadı',
                style: TextStyle(color: AppColors.subText),
              ),
            ),
          );
        }
        const columns = 4;
        final rows = (topics.length / columns).ceil();
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
                        child: () {
                          final index = row * columns + col;
                          if (index >= topics.length) {
                            return const SizedBox.shrink();
                          }
                          return _buildTopicItem(topics[index]);
                        }(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        );
      },
    );
  }

  Widget _buildTopicItem(AppKnowledgeTopic topic) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => FeaturedQuestionsScreen(
              initialTopicId: topic.questionTopicId,
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
                color: AppColors.warning.withValues(alpha: 0.45),
                width: 1.4,
              ),
            ),
            child: ClipOval(
              child: buildProductImage(
                topic.displayIcon,
                fit: BoxFit.contain,
                filterQuality: FilterQuality.high,
                errorWidget: Icon(
                  Icons.health_and_safety_outlined,
                  color: AppColors.warning,
                  size: 24,
                ),
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
              color: AppColors.warning,
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

