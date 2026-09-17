import 'package:flutter/material.dart';
import 'package:geliyor_app/data/knowledge_catalog.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
import 'package:geliyor_app/widgets/app_bottom_navbar.dart';
import 'package:geliyor_app/widgets/app_page_frame.dart';
import 'package:geliyor_app/widgets/knowledge_disclaimer.dart';

/// Konu seçimi arama sayfası — seçilen konu id'sini geri döndürür.
class TopicSearchScreen extends StatefulWidget {
  const TopicSearchScreen({super.key, this.selectedTopicId = 'sindirim'});

  final String selectedTopicId;

  static List<TopicSearchItem> get topics => [
    for (final topic in KnowledgeQuestionTopic.all)
      TopicSearchItem(
        id: topic.id,
        title: topic.title,
        count: defaultKnowledgeQuestions
            .where((item) => item.topicId == topic.id)
            .length,
        color: AppColors.warning,
        iconPath: topic.iconPath,
        icon: topic.icon,
      ),
  ];

  @override
  State<TopicSearchScreen> createState() => _TopicSearchScreenState();
}

class _TopicSearchScreenState extends State<TopicSearchScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<TopicSearchItem> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return TopicSearchScreen.topics;
    return TopicSearchScreen.topics
        .where((t) => t.title.toLowerCase().contains(q))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final items = _filtered;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: AppPageFrame.standard(
        backgroundColor: AppColors.background,
        pawPrintColor: AppColors.warning,
        header: _buildHeader(context),
        content: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSearchBar(),
              const SizedBox(height: 12),
              const Text(
                'Sağlık Konuları',
                style: TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.warning.withValues(alpha: 0.28)),
                  ),
                  child: items.isEmpty
                      ? const Center(
                          child: Text(
                            'Sonuç bulunamadı',
                            style: TextStyle(
                              color: AppColors.subText,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : ListView.separated(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          itemCount: items.length,
                          separatorBuilder: (_, _) => Divider(
                            height: 1,
                            color: AppColors.warning.withValues(alpha: 0.28),
                          ),
                          itemBuilder: (context, index) {
                            return _buildTopicRow(items[index]);
                          },
                        ),
                ),
              ),
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
                'Konu Seçin',
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
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.warning, width: 1.3),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.warning, size: 22),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _searchController,
              autofocus: true,
              onChanged: (v) => setState(() => _query = v),
              style: const TextStyle(
                color: AppColors.text,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: 'Sağlık konusu ara...',
                hintStyle: TextStyle(
                  color: AppColors.subText,
                  fontSize: 13,
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

  Widget _buildTopicRow(TopicSearchItem topic) {
    final selected = topic.id == widget.selectedTopicId;
    return InkWell(
      onTap: () => Navigator.of(context).pop(topic.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        child: Row(
          children: [
            _buildIcon(topic),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                topic.title,
                style: const TextStyle(
                  color: AppColors.warning,
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            Text(
              '${topic.count} soru',
              style: const TextStyle(
                color: AppColors.warning,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.warning,
                size: 18,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildIcon(TopicSearchItem topic) {
    if (topic.iconPath != null) {
      return SizedBox(
        width: 32,
        height: 32,
        child: Image.asset(
          topic.iconPath!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return Icon(topic.icon, color: AppColors.warning, size: 24);
          },
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        shape: BoxShape.circle,
      ),
      child: Icon(topic.icon, color: AppColors.warning, size: 18),
    );
  }
}

class TopicSearchItem {
  const TopicSearchItem({
    required this.id,
    required this.title,
    required this.count,
    required this.color,
    required this.icon,
    this.iconPath,
  });

  final String id;
  final String title;
  final int count;
  final Color color;
  final IconData icon;
  final String? iconPath;
}
