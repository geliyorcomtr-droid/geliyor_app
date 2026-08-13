import 'package:flutter/material.dart';
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

  static const topics = <TopicSearchItem>[
    TopicSearchItem(
      id: 'sindirim',
      title: 'Sindirim Sistemi',
      count: 64,
      color: Color(0xFF1E90FF),
      iconPath: 'assets/images/app_ikonlar/sindirim.png',
      icon: Icons.restaurant_rounded,
    ),
    TopicSearchItem(
      id: 'idrar',
      title: 'İdrar Yolu Sağlığı',
      count: 48,
      color: Color(0xFFEC4899),
      iconPath: 'assets/images/app_ikonlar/bobrek.png',
      icon: Icons.water_drop_outlined,
    ),
    TopicSearchItem(
      id: 'alerji',
      title: 'Alerji & Deri',
      count: 52,
      color: Color(0xFF9B4DCA),
      iconPath: 'assets/images/app_ikonlar/tuy_deri.png',
      icon: Icons.spa_outlined,
    ),
    TopicSearchItem(
      id: 'kilo',
      title: 'Kilo & Beslenme',
      count: 41,
      color: Color(0xFFFF6600),
      iconPath: 'assets/images/app_ikonlar/kilo_kontrol.png',
      icon: Icons.monitor_weight_outlined,
    ),
    TopicSearchItem(
      id: 'genel',
      title: 'Genel Sağlık',
      count: 73,
      color: Color(0xFF22C55E),
      iconPath: 'assets/images/app_ikonlar/bagisiklik.png',
      icon: Icons.favorite_outline_rounded,
    ),
    TopicSearchItem(
      id: 'dis',
      title: 'Ağız & Diş Sağlığı',
      count: 36,
      color: Color(0xFF0EA5E9),
      iconPath: 'assets/images/app_ikonlar/dis.png',
      icon: Icons.sentiment_satisfied_alt_outlined,
    ),
    TopicSearchItem(
      id: 'goz',
      title: 'Göz Hastalıkları',
      count: 29,
      color: Color(0xFF16A34A),
      icon: Icons.visibility_outlined,
    ),
    TopicSearchItem(
      id: 'kulak',
      title: 'Kulak Hastalıkları',
      count: 27,
      color: Color(0xFF8B5CF6),
      icon: Icons.hearing_outlined,
    ),
    TopicSearchItem(
      id: 'solunum',
      title: 'Solunum Sistemi',
      count: 33,
      color: Color(0xFFF97316),
      icon: Icons.air_rounded,
    ),
    TopicSearchItem(
      id: 'parazit',
      title: 'Parazitler',
      count: 45,
      color: Color(0xFF2563EB),
      icon: Icons.bug_report_outlined,
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
                  color: AppColors.text,
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
                    border: Border.all(color: AppColors.border),
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
                          separatorBuilder: (_, _) => const Divider(
                            height: 1,
                            color: AppColors.border,
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
                'Konu Seçin',
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
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColors.primary, width: 1.3),
      ),
      child: Row(
        children: [
          const Icon(Icons.search_rounded, color: AppColors.primary, size: 22),
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
                style: TextStyle(
                  color: selected ? AppColors.primary : AppColors.text,
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ),
            Text(
              '${topic.count} soru',
              style: const TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (selected) ...[
              const SizedBox(width: 6),
              const Icon(
                Icons.check_circle_rounded,
                color: AppColors.primary,
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
            return Icon(topic.icon, color: topic.color, size: 24);
          },
        ),
      );
    }
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: Color.lerp(topic.color, Colors.white, 0.85),
        shape: BoxShape.circle,
      ),
      child: Icon(topic.icon, color: topic.color, size: 18),
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
