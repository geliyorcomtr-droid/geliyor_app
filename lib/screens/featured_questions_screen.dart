import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_text_styles.dart';
import 'package:geliyor_app/widgets/app_notification_button.dart';
import 'package:geliyor_app/screens/question_detail_screen.dart';
import 'package:geliyor_app/screens/topic_search_screen.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/widgets/app_back_button.dart';
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
    final exists = TopicSearchScreen.topics.any(
      (t) => t.id == widget.initialTopicId,
    );
    _selectedTopicId = exists ? widget.initialTopicId : 'sindirim';
  }

  static const _questionsByTopic = <String, List<_FqQuestion>>{
    'sindirim': [
      _FqQuestion('Kedimin iştahı azaldı, ne yapmalıyım?', '12,4B'),
      _FqQuestion('Kedimin kusması normal mi?', '9,8B'),
      _FqQuestion('Kedimin ishal olması ne anlama gelir?', '8,1B'),
      _FqQuestion('Kedimde tüy yeme (kıl yutma) neden olur?', '7,4B'),
      _FqQuestion('Kedimin dışkısı sert, ne yapmalıyım?', '6,9B'),
      _FqQuestion('Kedi mama değişikliğine nasıl alıştırılır?', '6,9B'),
      _FqQuestion('Kedimin gazı var, nasıl geçer?', '5,7B'),
      _FqQuestion('Kedimin bağırsak parazit belirtileri nelerdir?', '5,3B'),
    ],
    'idrar': [
      _FqQuestion('Kedilerde idrar yolu enfeksiyonu belirtileri nelerdir?', '9,8B'),
      _FqQuestion('Kum kabı dışında idrar yapıyorsa ne anlama gelir?', '7,6B'),
      _FqQuestion('Kedimin idrarı kanlıysa ne yapmalıyım?', '6,4B'),
      _FqQuestion('Su tüketimini nasıl artırabilirim?', '5,9B'),
      _FqQuestion('İdrar yolu sağlığı için mama seçimi nasıl olmalı?', '5,2B'),
      _FqQuestion('Kedilerde böbrek yetmezliği erken belirtileri neler?', '4,8B'),
      _FqQuestion('Erkek kedilerde idrar tıkanıklığı acil midir?', '4,5B'),
      _FqQuestion('Kum tipi idrar sağlığını etkiler mi?', '3,9B'),
    ],
    'alerji': [
      _FqQuestion('Kedimin tüyleri çok dökülüyor, normal mi?', '8,1B'),
      _FqQuestion('Kaşıntı ve kızarıklık alerji belirtisi midir?', '7,0B'),
      _FqQuestion('Alerjik deri sorunlarında mama değişimi gerekir mi?', '5,6B'),
      _FqQuestion('Tüy bakımı alerjiyi nasıl etkiler?', '4,9B'),
      _FqQuestion('Kedilerde yiyecek alerjisi nasıl anlaşılır?', '4,4B'),
      _FqQuestion('Pire alerjisi ile gıda alerjisi nasıl ayırt edilir?', '4,1B'),
      _FqQuestion('Deri yaraları için evde ne yapabilirim?', '3,7B'),
      _FqQuestion('Hiperalerjenik mama ne zaman tercih edilmeli?', '3,3B'),
    ],
    'kilo': [
      _FqQuestion('Kedimin iştahı azaldı, ne yapmalıyım?', '12,4B'),
      _FqQuestion('Fazla kilolu kediler için porsiyon nasıl ayarlanır?', '6,8B'),
      _FqQuestion('Günlük kalori ihtiyacı nasıl hesaplanır?', '5,1B'),
      _FqQuestion('Ödül mamaları kilo alımına yol açar mı?', '4,0B'),
      _FqQuestion('Kedi ideal kilosu nasıl ölçülür?', '3,8B'),
      _FqQuestion('Zayıflama mamaları ne kadar süre verilmeli?', '3,5B'),
      _FqQuestion('İştahsızlık ile kilo kaybı ne zaman acildir?', '3,2B'),
      _FqQuestion('Serbest mama bırakmak kilo yapar mı?', '2,9B'),
    ],
    'genel': [
      _FqQuestion('Kedime hangi aşıları yaptırmalıyım?', '15,2B'),
      _FqQuestion('Yıllık veteriner kontrolü ne zaman yapılmalı?', '8,7B'),
      _FqQuestion('İç ve dış parazit koruması nasıl planlanır?', '7,3B'),
      _FqQuestion('Evde sağlık takibi için nelere dikkat etmeliyim?', '5,5B'),
      _FqQuestion('Kedimin ateşi olup olmadığını nasıl anlarım?', '5,0B'),
      _FqQuestion('Halsizlik ne zaman ciddiye alınmalı?', '4,6B'),
      _FqQuestion('Yaşlı kedilerde kontrol sıklığı nasıl olmalı?', '4,2B'),
      _FqQuestion('Acil veteriner durumları nelerdir?', '3,9B'),
    ],
    'dis': [
      _FqQuestion('Kedilerde diş taşı nasıl önlenir?', '6,2B'),
      _FqQuestion('Ağız kokusu hastalık belirtisi midir?', '5,4B'),
      _FqQuestion('Diş fırçalama ne sıklıkla yapılmalı?', '4,8B'),
      _FqQuestion('Kediler kuru mama ile diş temizler mi?', '4,1B'),
      _FqQuestion('Diş eti kanaması ne anlama gelir?', '3,7B'),
      _FqQuestion('Yemek yemeyi reddetmek diş ağrısı olabilir mi?', '3,4B'),
      _FqQuestion('Dental mama ne zaman önerilir?', '3,0B'),
      _FqQuestion('Diş çekimi sonrası bakım nasıl olmalı?', '2,7B'),
    ],
    'goz': [
      _FqQuestion('Kedimin gözü sulanıyorsa ne yapmalıyım?', '5,8B'),
      _FqQuestion('Gözde akıntı enfeksiyon belirtisi midir?', '4,9B'),
      _FqQuestion('Üçüncü göz kapağı görünürse ne olur?', '4,3B'),
      _FqQuestion('Kedilerde göz rengi değişimi normal midir?', '3,8B'),
      _FqQuestion('Göz kapağı şişmesi neden olur?', '3,4B'),
      _FqQuestion('Kornea çizilmesi belirtileri nelerdir?', '3,1B'),
      _FqQuestion('Göz damlası evde kullanılabilir mi?', '2,8B'),
      _FqQuestion('Işığa hassasiyet ne zaman acildir?', '2,5B'),
    ],
    'kulak': [
      _FqQuestion('Kedimin kulağı kaşınıyorsa ne yapmalıyım?', '5,5B'),
      _FqQuestion('Kulak akıntısı enfeksiyon mudur?', '4,7B'),
      _FqQuestion('Kulak temizliği nasıl yapılır?', '4,2B'),
      _FqQuestion('Kulak akarları belirtileri nelerdir?', '3,9B'),
      _FqQuestion('Kafa sallama neden olur?', '3,5B'),
      _FqQuestion('Kulak kokusu hastalık belirtisi midir?', '3,2B'),
      _FqQuestion('Dış kulak yolu enfeksiyonu nasıl anlaşılır?', '2,9B'),
      _FqQuestion('Kulak temizleyici seçerken nelere dikkat?', '2,6B'),
    ],
    'solunum': [
      _FqQuestion('Kedimin öksürmesi normal mi?', '6,0B'),
      _FqQuestion('Hapşırma ne zaman ciddiye alınmalı?', '5,1B'),
      _FqQuestion('Burun akıntısı neden olur?', '4,6B'),
      _FqQuestion('Nefes darlığı acil midir?', '4,3B'),
      _FqQuestion('Üst solunum yolu enfeksiyonu belirtileri?', '3,9B'),
      _FqQuestion('Horlama hastalık belirtisi olabilir mi?', '3,4B'),
      _FqQuestion('Ağızdan nefes alma ne anlama gelir?', '3,1B'),
      _FqQuestion('Astım şüphesinde ne yapılmalı?', '2,8B'),
    ],
    'parazit': [
      _FqQuestion('İç parazit belirtileri nelerdir?', '7,1B'),
      _FqQuestion('Dış parazit koruması ne sıklıkla yapılmalı?', '6,3B'),
      _FqQuestion('Pire tedavisi nasıl uygulanır?', '5,5B'),
      _FqQuestion('Kene ısırığında ne yapmalıyım?', '4,9B'),
      _FqQuestion('Solucan ilaçları güvenli midir?', '4,4B'),
      _FqQuestion('Yavru kedilerde parazit koruması nasıl?', '4,0B'),
      _FqQuestion('Evde parazit temizliği yeterli midir?', '3,6B'),
      _FqQuestion('Doğal parazit önleme yöntemleri işe yarar mı?', '3,1B'),
    ],
  };

  TopicSearchItem get _selectedTopic => TopicSearchScreen.topics.firstWhere(
    (t) => t.id == _selectedTopicId,
  );

  List<_FqQuestion> get _questions =>
      _questionsByTopic[_selectedTopicId] ?? const [];

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
              _buildQuestionsList(),
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
                'Öne Çıkan Sorular',
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
        'assets/images/one_cikan_sorular_banner.png',
        width: double.infinity,
        fit: BoxFit.fitWidth,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            height: 96,
            color: AppColors.selected,
            alignment: Alignment.center,
            padding: const EdgeInsets.all(12),
            child: const Text(
              'Merak ettikleriniz burada!',
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

  Widget _buildTopicSelector() {
    return GestureDetector(
      onTap: _openTopicSearch,
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.primary, width: 1.4),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.folder_open_rounded,
              color: AppColors.primary,
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
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: AppColors.primary,
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
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 13,
              fontWeight: FontWeight.w900,
            ),
          ),
        ),
        GestureDetector(
          onTap: _openTopicSearch,
          child: const Row(
            children: [
              Icon(Icons.sync_rounded, color: AppColors.primary, size: 15),
              SizedBox(width: 3),
              Text(
                'Konuyu Değiştir',
                style: TextStyle(
                  color: AppColors.primary,
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

  Widget _buildQuestionsList() {
    return Column(
      children: [
        for (int i = 0; i < _questions.length; i++) ...[
          if (i > 0) const SizedBox(height: 6),
          _buildQuestionCard(_questions[i]),
        ],
      ],
    );
  }

  Widget _buildQuestionCard(_FqQuestion q) {
    return GestureDetector(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => QuestionDetailScreen(
              question: q.text,
              views: q.views,
              topicTitle: _selectedTopic.title,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.primary, width: 1.4),
              ),
              child: const Icon(
                Icons.help_outline_rounded,
                color: AppColors.primary,
                size: 14,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                q.text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.text,
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
              color: AppColors.primary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _FqQuestion {
  const _FqQuestion(this.text, this.views);

  final String text;
  final String views;
}
