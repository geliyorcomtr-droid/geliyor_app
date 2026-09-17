import 'package:flutter/material.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class KnowledgeQuestionTopic {
  const KnowledgeQuestionTopic({
    required this.id,
    required this.title,
    required this.color,
    this.iconPath = '',
    this.icon = Icons.folder_open_rounded,
  });

  final String id;
  final String title;
  final Color color;
  final String iconPath;
  final IconData icon;

  static const sindirim = KnowledgeQuestionTopic(
    id: 'sindirim',
    title: 'Sindirim Sistemi',
    color: AppColors.warning,
    iconPath: 'assets/images/app_ikonlar/sindirim.png',
    icon: Icons.restaurant_rounded,
  );
  static const idrar = KnowledgeQuestionTopic(
    id: 'idrar',
    title: 'İdrar Yolu Sağlığı',
    color: AppColors.warning,
    iconPath: 'assets/images/app_ikonlar/bobrek.png',
    icon: Icons.water_drop_outlined,
  );
  static const alerji = KnowledgeQuestionTopic(
    id: 'alerji',
    title: 'Alerji & Deri',
    color: AppColors.warning,
    iconPath: 'assets/images/app_ikonlar/tuy_deri.png',
    icon: Icons.spa_outlined,
  );
  static const kilo = KnowledgeQuestionTopic(
    id: 'kilo',
    title: 'Kilo & Beslenme',
    color: AppColors.warning,
    iconPath: 'assets/images/app_ikonlar/kilo_kontrol.png',
    icon: Icons.monitor_weight_outlined,
  );
  static const genel = KnowledgeQuestionTopic(
    id: 'genel',
    title: 'Genel Sağlık',
    color: AppColors.warning,
    iconPath: 'assets/images/app_ikonlar/bagisiklik.png',
    icon: Icons.favorite_outline_rounded,
  );
  static const dis = KnowledgeQuestionTopic(
    id: 'dis',
    title: 'Ağız & Diş Sağlığı',
    color: AppColors.warning,
    iconPath: 'assets/images/app_ikonlar/dis.png',
    icon: Icons.sentiment_satisfied_alt_outlined,
  );
  static const goz = KnowledgeQuestionTopic(
    id: 'goz',
    title: 'Göz Hastalıkları',
    color: AppColors.warning,
    icon: Icons.visibility_outlined,
  );
  static const kulak = KnowledgeQuestionTopic(
    id: 'kulak',
    title: 'Kulak Hastalıkları',
    color: AppColors.warning,
    icon: Icons.hearing_outlined,
  );
  static const solunum = KnowledgeQuestionTopic(
    id: 'solunum',
    title: 'Solunum Sistemi',
    color: AppColors.warning,
    icon: Icons.air_rounded,
  );
  static const parazit = KnowledgeQuestionTopic(
    id: 'parazit',
    title: 'Parazitler',
    color: AppColors.warning,
    icon: Icons.bug_report_outlined,
  );

  static const all = <KnowledgeQuestionTopic>[
    sindirim,
    idrar,
    alerji,
    kilo,
    genel,
    dis,
    goz,
    kulak,
    solunum,
    parazit,
  ];

  static KnowledgeQuestionTopic byId(String id) {
    for (final item in all) {
      if (item.id == id) return item;
    }
    return sindirim;
  }

  static String titleOf(String id) => byId(id).title;
}

class DefaultKnowledgeTopic {
  const DefaultKnowledgeTopic({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.assetPath,
    required this.colorValue,
    required this.questionTopicId,
    required this.order,
  });

  final String id;
  final String title;
  final String subtitle;
  final String assetPath;
  final int colorValue;
  final String questionTopicId;
  final int order;
}

class DefaultKnowledgeQuestion {
  const DefaultKnowledgeQuestion({
    required this.id,
    required this.topicId,
    required this.title,
    required this.views,
    this.featured = false,
    required this.order,
  });

  final String id;
  final String topicId;
  final String title;
  final String views;
  final bool featured;
  final int order;
}

const defaultKnowledgeTopics = <DefaultKnowledgeTopic>[
  DefaultKnowledgeTopic(
    id: 'sindirim',
    title: 'Sindirim',
    subtitle: 'İshal & kusma',
    assetPath: 'assets/images/app_ikonlar/sindirim.png',
    colorValue: 0xFF1E90FF,
    questionTopicId: 'sindirim',
    order: 0,
  ),
  DefaultKnowledgeTopic(
    id: 'bobrek',
    title: 'Böbrek',
    subtitle: 'Böbrek sağlığı',
    assetPath: 'assets/images/app_ikonlar/bobrek.png',
    colorValue: 0xFFEC4899,
    questionTopicId: 'idrar',
    order: 1,
  ),
  DefaultKnowledgeTopic(
    id: 'idrar',
    title: 'İdrar Yolu',
    subtitle: 'İdrar sağlığı',
    assetPath: 'assets/images/app_ikonlar/idrar.png',
    colorValue: 0xFFDB2777,
    questionTopicId: 'idrar',
    order: 2,
  ),
  DefaultKnowledgeTopic(
    id: 'tuy-deri',
    title: 'Tüy & Deri',
    subtitle: 'Tüy bakımı',
    assetPath: 'assets/images/app_ikonlar/tuy_deri.png',
    colorValue: 0xFF9B4DCA,
    questionTopicId: 'alerji',
    order: 3,
  ),
  DefaultKnowledgeTopic(
    id: 'alerji',
    title: 'Alerji',
    subtitle: 'Hassas cilt',
    assetPath: 'assets/images/app_ikonlar/hypoallergenic.png',
    colorValue: 0xFF22C55E,
    questionTopicId: 'alerji',
    order: 4,
  ),
  DefaultKnowledgeTopic(
    id: 'agiz-dis',
    title: 'Ağız & Diş',
    subtitle: 'Diş bakımı',
    assetPath: 'assets/images/app_ikonlar/dis.png',
    colorValue: 0xFF0EA5E9,
    questionTopicId: 'dis',
    order: 5,
  ),
  DefaultKnowledgeTopic(
    id: 'kilo',
    title: 'Kilo Kontrolü',
    subtitle: 'İdeal kilo',
    assetPath: 'assets/images/app_ikonlar/kilo_kontrol.png',
    colorValue: 0xFFFF6600,
    questionTopicId: 'kilo',
    order: 6,
  ),
  DefaultKnowledgeTopic(
    id: 'kalp',
    title: 'Kalp Sağlığı',
    subtitle: 'Kalp desteği',
    assetPath: 'assets/images/app_ikonlar/kalp.png',
    colorValue: 0xFFEF4444,
    questionTopicId: 'genel',
    order: 7,
  ),
  DefaultKnowledgeTopic(
    id: 'bagisiklik',
    title: 'Bağışıklık',
    subtitle: 'Bağışıklık',
    assetPath: 'assets/images/app_ikonlar/bagisiklik.png',
    colorValue: 0xFF16A34A,
    questionTopicId: 'genel',
    order: 8,
  ),
  DefaultKnowledgeTopic(
    id: 'diyabet',
    title: 'Diyabet',
    subtitle: 'Kan şekeri',
    assetPath: 'assets/images/app_ikonlar/diyabet.png',
    colorValue: 0xFFF59E0B,
    questionTopicId: 'kilo',
    order: 9,
  ),
  DefaultKnowledgeTopic(
    id: 'eklem',
    title: 'Eklem',
    subtitle: 'Hareket desteği',
    assetPath: 'assets/images/app_ikonlar/eklem.png',
    colorValue: 0xFF84CC16,
    questionTopicId: 'genel',
    order: 10,
  ),
  DefaultKnowledgeTopic(
    id: 'karaciger',
    title: 'Karaciğer',
    subtitle: 'Karaciğer',
    assetPath: 'assets/images/app_ikonlar/karaciger.png',
    colorValue: 0xFF14B8A6,
    questionTopicId: 'genel',
    order: 11,
  ),
  DefaultKnowledgeTopic(
    id: 'parazit',
    title: 'Parazit',
    subtitle: 'İç & dış',
    assetPath: 'assets/images/app_ikonlar/parazit.png',
    colorValue: 0xFF2563EB,
    questionTopicId: 'parazit',
    order: 12,
  ),
  DefaultKnowledgeTopic(
    id: 'asi-takibi',
    title: 'Aşı Takibi',
    subtitle: 'Aşı takvimi',
    assetPath: 'assets/images/app_ikonlar/asi_takvimi.png',
    colorValue: 0xFFFF6600,
    questionTopicId: 'genel',
    order: 13,
  ),
  DefaultKnowledgeTopic(
    id: 'ilac-tedavi',
    title: 'İlaç & Tedavi',
    subtitle: 'Tedavi planı',
    assetPath: 'assets/images/app_ikonlar/ilac_tedavi.png',
    colorValue: 0xFF00A859,
    questionTopicId: 'genel',
    order: 14,
  ),
  DefaultKnowledgeTopic(
    id: 'ozel-mama',
    title: 'Özel Mama',
    subtitle: 'Özel formül',
    assetPath: 'assets/images/app_ikonlar/mama_kabi.png',
    colorValue: 0xFF8B5CF6,
    questionTopicId: 'kilo',
    order: 15,
  ),
  DefaultKnowledgeTopic(
    id: 'acil',
    title: 'Acil Durum',
    subtitle: 'Acil yardım',
    assetPath: 'assets/images/app_ikonlar/acil_durum.png',
    colorValue: 0xFFE60000,
    questionTopicId: 'genel',
    order: 16,
  ),
  DefaultKnowledgeTopic(
    id: 'zehirlenme',
    title: 'Zehirlenme',
    subtitle: 'Toksik risk',
    assetPath: 'assets/images/app_ikonlar/zehirlenme.png',
    colorValue: 0xFFDC2626,
    questionTopicId: 'genel',
    order: 17,
  ),
  DefaultKnowledgeTopic(
    id: 'yaralanma',
    title: 'Yaralanma',
    subtitle: 'İlk yardım',
    assetPath: 'assets/images/app_ikonlar/yaralanma.png',
    colorValue: 0xFFB91C1C,
    questionTopicId: 'genel',
    order: 18,
  ),
  DefaultKnowledgeTopic(
    id: 'dogal-icerik',
    title: 'Doğal İçerik',
    subtitle: 'Doğal formül',
    assetPath: 'assets/images/app_ikonlar/dogal_icerik.png',
    colorValue: 0xFF65A30D,
    questionTopicId: 'kilo',
    order: 19,
  ),
];

const defaultKnowledgeQuestions = <DefaultKnowledgeQuestion>[
  DefaultKnowledgeQuestion(id: 'sindirim-1', topicId: 'sindirim', title: 'Kedimin iştahı azaldı, ne yapmalıyım?', views: '12,4B', order: 0),
  DefaultKnowledgeQuestion(id: 'sindirim-2', topicId: 'sindirim', title: 'Kedimin kusması normal mi?', views: '9,8B', order: 1),
  DefaultKnowledgeQuestion(id: 'sindirim-3', topicId: 'sindirim', title: 'Kedimin ishal olması ne anlama gelir?', views: '8,1B', order: 2),
  DefaultKnowledgeQuestion(id: 'sindirim-4', topicId: 'sindirim', title: 'Kedimde tüy yeme (kıl yutma) neden olur?', views: '7,4B', order: 3),
  DefaultKnowledgeQuestion(id: 'sindirim-5', topicId: 'sindirim', title: 'Kedimin dışkısı sert, ne yapmalıyım?', views: '6,9B', order: 4),
  DefaultKnowledgeQuestion(id: 'sindirim-6', topicId: 'sindirim', title: 'Kedi mama değişikliğine nasıl alıştırılır?', views: '6,9B', order: 5),
  DefaultKnowledgeQuestion(id: 'sindirim-7', topicId: 'sindirim', title: 'Kedimin gazı var, nasıl geçer?', views: '5,7B', order: 6),
  DefaultKnowledgeQuestion(id: 'sindirim-8', topicId: 'sindirim', title: 'Kedimin bağırsak parazit belirtileri nelerdir?', views: '5,3B', order: 7),
  DefaultKnowledgeQuestion(id: 'idrar-1', topicId: 'idrar', title: 'Kedilerde idrar yolu enfeksiyonu belirtileri nelerdir?', views: '9,8B', featured: true, order: 0),
  DefaultKnowledgeQuestion(id: 'idrar-2', topicId: 'idrar', title: 'Kum kabı dışında idrar yapıyorsa ne anlama gelir?', views: '7,6B', order: 1),
  DefaultKnowledgeQuestion(id: 'idrar-3', topicId: 'idrar', title: 'Kedimin idrarı kanlıysa ne yapmalıyım?', views: '6,4B', order: 2),
  DefaultKnowledgeQuestion(id: 'idrar-4', topicId: 'idrar', title: 'Su tüketimini nasıl artırabilirim?', views: '5,9B', order: 3),
  DefaultKnowledgeQuestion(id: 'idrar-5', topicId: 'idrar', title: 'İdrar yolu sağlığı için mama seçimi nasıl olmalı?', views: '5,2B', order: 4),
  DefaultKnowledgeQuestion(id: 'idrar-6', topicId: 'idrar', title: 'Kedilerde böbrek yetmezliği erken belirtileri neler?', views: '4,8B', order: 5),
  DefaultKnowledgeQuestion(id: 'idrar-7', topicId: 'idrar', title: 'Erkek kedilerde idrar tıkanıklığı acil midir?', views: '4,5B', order: 6),
  DefaultKnowledgeQuestion(id: 'idrar-8', topicId: 'idrar', title: 'Kum tipi idrar sağlığını etkiler mi?', views: '3,9B', order: 7),
  DefaultKnowledgeQuestion(id: 'alerji-1', topicId: 'alerji', title: 'Kedimin tüyleri çok dökülüyor, normal mi?', views: '8,1B', featured: true, order: 0),
  DefaultKnowledgeQuestion(id: 'alerji-2', topicId: 'alerji', title: 'Kaşıntı ve kızarıklık alerji belirtisi midir?', views: '7,0B', order: 1),
  DefaultKnowledgeQuestion(id: 'alerji-3', topicId: 'alerji', title: 'Alerjik deri sorunlarında mama değişimi gerekir mi?', views: '5,6B', order: 2),
  DefaultKnowledgeQuestion(id: 'alerji-4', topicId: 'alerji', title: 'Tüy bakımı alerjiyi nasıl etkiler?', views: '4,9B', order: 3),
  DefaultKnowledgeQuestion(id: 'alerji-5', topicId: 'alerji', title: 'Kedilerde yiyecek alerjisi nasıl anlaşılır?', views: '4,4B', order: 4),
  DefaultKnowledgeQuestion(id: 'alerji-6', topicId: 'alerji', title: 'Pire alerjisi ile gıda alerjisi nasıl ayırt edilir?', views: '4,1B', order: 5),
  DefaultKnowledgeQuestion(id: 'alerji-7', topicId: 'alerji', title: 'Deri yaraları için evde ne yapabilirim?', views: '3,7B', order: 6),
  DefaultKnowledgeQuestion(id: 'alerji-8', topicId: 'alerji', title: 'Hiperalerjenik mama ne zaman tercih edilmeli?', views: '3,3B', order: 7),
  DefaultKnowledgeQuestion(id: 'kilo-1', topicId: 'kilo', title: 'Kedimin iştahı azaldı, ne yapmalıyım?', views: '12,4B', featured: true, order: 0),
  DefaultKnowledgeQuestion(id: 'kilo-2', topicId: 'kilo', title: 'Fazla kilolu kediler için porsiyon nasıl ayarlanır?', views: '6,8B', order: 1),
  DefaultKnowledgeQuestion(id: 'kilo-3', topicId: 'kilo', title: 'Günlük kalori ihtiyacı nasıl hesaplanır?', views: '5,1B', order: 2),
  DefaultKnowledgeQuestion(id: 'kilo-4', topicId: 'kilo', title: 'Ödül mamaları kilo alımına yol açar mı?', views: '4,0B', order: 3),
  DefaultKnowledgeQuestion(id: 'kilo-5', topicId: 'kilo', title: 'Kedi ideal kilosu nasıl ölçülür?', views: '3,8B', order: 4),
  DefaultKnowledgeQuestion(id: 'kilo-6', topicId: 'kilo', title: 'Zayıflama mamaları ne kadar süre verilmeli?', views: '3,5B', order: 5),
  DefaultKnowledgeQuestion(id: 'kilo-7', topicId: 'kilo', title: 'İştahsızlık ile kilo kaybı ne zaman acildir?', views: '3,2B', order: 6),
  DefaultKnowledgeQuestion(id: 'kilo-8', topicId: 'kilo', title: 'Serbest mama bırakmak kilo yapar mı?', views: '2,9B', order: 7),
  DefaultKnowledgeQuestion(id: 'genel-1', topicId: 'genel', title: 'Kedime hangi aşıları yaptırmalıyım?', views: '15,2B', featured: true, order: 0),
  DefaultKnowledgeQuestion(id: 'genel-2', topicId: 'genel', title: 'Yıllık veteriner kontrolü ne zaman yapılmalı?', views: '8,7B', order: 1),
  DefaultKnowledgeQuestion(id: 'genel-3', topicId: 'genel', title: 'İç ve dış parazit koruması nasıl planlanır?', views: '7,3B', order: 2),
  DefaultKnowledgeQuestion(id: 'genel-4', topicId: 'genel', title: 'Evde sağlık takibi için nelere dikkat etmeliyim?', views: '5,5B', order: 3),
  DefaultKnowledgeQuestion(id: 'genel-5', topicId: 'genel', title: 'Kedimin ateşi olup olmadığını nasıl anlarım?', views: '5,0B', order: 4),
  DefaultKnowledgeQuestion(id: 'genel-6', topicId: 'genel', title: 'Halsizlik ne zaman ciddiye alınmalı?', views: '4,6B', order: 5),
  DefaultKnowledgeQuestion(id: 'genel-7', topicId: 'genel', title: 'Yaşlı kedilerde kontrol sıklığı nasıl olmalı?', views: '4,2B', order: 6),
  DefaultKnowledgeQuestion(id: 'genel-8', topicId: 'genel', title: 'Acil veteriner durumları nelerdir?', views: '3,9B', order: 7),
  DefaultKnowledgeQuestion(id: 'dis-1', topicId: 'dis', title: 'Kedilerde diş taşı nasıl önlenir?', views: '6,2B', order: 0),
  DefaultKnowledgeQuestion(id: 'dis-2', topicId: 'dis', title: 'Ağız kokusu hastalık belirtisi midir?', views: '5,4B', order: 1),
  DefaultKnowledgeQuestion(id: 'dis-3', topicId: 'dis', title: 'Diş fırçalama ne sıklıkla yapılmalı?', views: '4,8B', order: 2),
  DefaultKnowledgeQuestion(id: 'dis-4', topicId: 'dis', title: 'Kediler kuru mama ile diş temizler mi?', views: '4,1B', order: 3),
  DefaultKnowledgeQuestion(id: 'dis-5', topicId: 'dis', title: 'Diş eti kanaması ne anlama gelir?', views: '3,7B', order: 4),
  DefaultKnowledgeQuestion(id: 'dis-6', topicId: 'dis', title: 'Yemek yemeyi reddetmek diş ağrısı olabilir mi?', views: '3,4B', order: 5),
  DefaultKnowledgeQuestion(id: 'dis-7', topicId: 'dis', title: 'Dental mama ne zaman önerilir?', views: '3,0B', order: 6),
  DefaultKnowledgeQuestion(id: 'dis-8', topicId: 'dis', title: 'Diş çekimi sonrası bakım nasıl olmalı?', views: '2,7B', order: 7),
  DefaultKnowledgeQuestion(id: 'goz-1', topicId: 'goz', title: 'Kedimin gözü sulanıyorsa ne yapmalıyım?', views: '5,8B', order: 0),
  DefaultKnowledgeQuestion(id: 'goz-2', topicId: 'goz', title: 'Gözde akıntı enfeksiyon belirtisi midir?', views: '4,9B', order: 1),
  DefaultKnowledgeQuestion(id: 'goz-3', topicId: 'goz', title: 'Üçüncü göz kapağı görünürse ne olur?', views: '4,3B', order: 2),
  DefaultKnowledgeQuestion(id: 'goz-4', topicId: 'goz', title: 'Kedilerde göz rengi değişimi normal midir?', views: '3,8B', order: 3),
  DefaultKnowledgeQuestion(id: 'goz-5', topicId: 'goz', title: 'Göz kapağı şişmesi neden olur?', views: '3,4B', order: 4),
  DefaultKnowledgeQuestion(id: 'goz-6', topicId: 'goz', title: 'Kornea çizilmesi belirtileri nelerdir?', views: '3,1B', order: 5),
  DefaultKnowledgeQuestion(id: 'goz-7', topicId: 'goz', title: 'Göz damlası evde kullanılabilir mi?', views: '2,8B', order: 6),
  DefaultKnowledgeQuestion(id: 'goz-8', topicId: 'goz', title: 'Işığa hassasiyet ne zaman acildir?', views: '2,5B', order: 7),
  DefaultKnowledgeQuestion(id: 'kulak-1', topicId: 'kulak', title: 'Kedimin kulağı kaşınıyorsa ne yapmalıyım?', views: '5,5B', order: 0),
  DefaultKnowledgeQuestion(id: 'kulak-2', topicId: 'kulak', title: 'Kulak akıntısı enfeksiyon mudur?', views: '4,7B', order: 1),
  DefaultKnowledgeQuestion(id: 'kulak-3', topicId: 'kulak', title: 'Kulak temizliği nasıl yapılır?', views: '4,2B', order: 2),
  DefaultKnowledgeQuestion(id: 'kulak-4', topicId: 'kulak', title: 'Kulak akarları belirtileri nelerdir?', views: '3,9B', order: 3),
  DefaultKnowledgeQuestion(id: 'kulak-5', topicId: 'kulak', title: 'Kafa sallama neden olur?', views: '3,5B', order: 4),
  DefaultKnowledgeQuestion(id: 'kulak-6', topicId: 'kulak', title: 'Kulak kokusu hastalık belirtisi midir?', views: '3,2B', order: 5),
  DefaultKnowledgeQuestion(id: 'kulak-7', topicId: 'kulak', title: 'Dış kulak yolu enfeksiyonu nasıl anlaşılır?', views: '2,9B', order: 6),
  DefaultKnowledgeQuestion(id: 'kulak-8', topicId: 'kulak', title: 'Kulak temizleyici seçerken nelere dikkat?', views: '2,6B', order: 7),
  DefaultKnowledgeQuestion(id: 'solunum-1', topicId: 'solunum', title: 'Kedimin öksürmesi normal mi?', views: '6,0B', order: 0),
  DefaultKnowledgeQuestion(id: 'solunum-2', topicId: 'solunum', title: 'Hapşırma ne zaman ciddiye alınmalı?', views: '5,1B', order: 1),
  DefaultKnowledgeQuestion(id: 'solunum-3', topicId: 'solunum', title: 'Burun akıntısı neden olur?', views: '4,6B', order: 2),
  DefaultKnowledgeQuestion(id: 'solunum-4', topicId: 'solunum', title: 'Nefes darlığı acil midir?', views: '4,3B', order: 3),
  DefaultKnowledgeQuestion(id: 'solunum-5', topicId: 'solunum', title: 'Üst solunum yolu enfeksiyonu belirtileri?', views: '3,9B', order: 4),
  DefaultKnowledgeQuestion(id: 'solunum-6', topicId: 'solunum', title: 'Horlama hastalık belirtisi olabilir mi?', views: '3,4B', order: 5),
  DefaultKnowledgeQuestion(id: 'solunum-7', topicId: 'solunum', title: 'Ağızdan nefes alma ne anlama gelir?', views: '3,1B', order: 6),
  DefaultKnowledgeQuestion(id: 'solunum-8', topicId: 'solunum', title: 'Astım şüphesinde ne yapılmalı?', views: '2,8B', order: 7),
  DefaultKnowledgeQuestion(id: 'parazit-1', topicId: 'parazit', title: 'İç parazit belirtileri nelerdir?', views: '7,1B', order: 0),
  DefaultKnowledgeQuestion(id: 'parazit-2', topicId: 'parazit', title: 'Dış parazit koruması ne sıklıkla yapılmalı?', views: '6,3B', order: 1),
  DefaultKnowledgeQuestion(id: 'parazit-3', topicId: 'parazit', title: 'Pire tedavisi nasıl uygulanır?', views: '5,5B', order: 2),
  DefaultKnowledgeQuestion(id: 'parazit-4', topicId: 'parazit', title: 'Kene ısırığında ne yapmalıyım?', views: '4,9B', order: 3),
  DefaultKnowledgeQuestion(id: 'parazit-5', topicId: 'parazit', title: 'Solucan ilaçları güvenli midir?', views: '4,4B', order: 4),
  DefaultKnowledgeQuestion(id: 'parazit-6', topicId: 'parazit', title: 'Yavru kedilerde parazit koruması nasıl?', views: '4,0B', order: 5),
  DefaultKnowledgeQuestion(id: 'parazit-7', topicId: 'parazit', title: 'Evde parazit temizliği yeterli midir?', views: '3,6B', order: 6),
  DefaultKnowledgeQuestion(id: 'parazit-8', topicId: 'parazit', title: 'Doğal parazit önleme yöntemleri işe yarar mı?', views: '3,1B', order: 7),
];

Color knowledgeColor(int value) {
  if (value == 0) return AppColors.warning;
  return Color(value);
}
