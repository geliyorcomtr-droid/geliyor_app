class KnowledgeArticle {
  const KnowledgeArticle({
    required this.id,
    required this.categoryId,
    required this.title,
    required this.summary,
    required this.minutes,
    required this.imagePath,
  });

  final String id;
  final String categoryId;
  final String title;
  final String summary;
  final int minutes;
  final String imagePath;

  String get categoryTitle => switch (categoryId) {
    'beslenme' => 'Beslenme',
    'saglik' => 'Sağlık',
    'bakim' => 'Bakım',
    'asi' => 'Aşı',
    _ => 'Makale',
  };

  static const values = <KnowledgeArticle>[
    KnowledgeArticle(
      id: 'kedilerde-dogru-beslenme',
      categoryId: 'beslenme',
      title: 'Kedilerde Doğru Beslenme Rehberi',
      summary: 'Yaşa ve ırka göre porsiyon, mama seçimi ve öğün düzeni.',
      minutes: 5,
      imagePath: 'assets/images/bilgi_beslenme.png',
    ),
    KnowledgeArticle(
      id: 'yas-mi-kuru-mama',
      categoryId: 'beslenme',
      title: 'Yaş Mama mı Kuru Mama mı?',
      summary: 'İki mama türünün avantajları ve doğru kullanımı.',
      minutes: 4,
      imagePath: 'assets/images/bilgi_beslenme.png',
    ),
    KnowledgeArticle(
      id: 'kilo-kontrolu-beslenme',
      categoryId: 'beslenme',
      title: 'Kilo Kontrolü İçin Beslenme İpuçları',
      summary: 'Fazla kilolu dostlar için pratik öneriler.',
      minutes: 6,
      imagePath: 'assets/images/bilgi_beslenme.png',
    ),
    KnowledgeArticle(
      id: 'kedilerde-sik-hastaliklar',
      categoryId: 'saglik',
      title: 'Kedilerde En Sık Görülen Hastalıklar',
      summary: 'Belirtiler, korunma yolları ve ne zaman veterinere gidilmeli.',
      minutes: 7,
      imagePath: 'assets/images/bilgi_saglik.png',
    ),
    KnowledgeArticle(
      id: 'veteriner-kontrolu',
      categoryId: 'saglik',
      title: 'Düzenli Veteriner Kontrolünün Önemi',
      summary: 'Yıllık kontrol takvimi ve erken teşhisin faydaları.',
      minutes: 5,
      imagePath: 'assets/images/bilgi_saglik.png',
    ),
    KnowledgeArticle(
      id: 'idrar-yolu-sagligi',
      categoryId: 'saglik',
      title: 'İdrar Yolu Sağlığına Dikkat',
      summary: 'Belirtiler ve günlük hayatta alınacak önlemler.',
      minutes: 6,
      imagePath: 'assets/images/bilgi_saglik.png',
    ),
    KnowledgeArticle(
      id: 'tuy-bakimi',
      categoryId: 'bakim',
      title: 'Tüy Bakımı Nasıl Yapılmalı?',
      summary: 'Fırçalama sıklığı, doğru araçlar ve tüy dökülmesi.',
      minutes: 4,
      imagePath: 'assets/images/bilgi_bakim.png',
    ),
    KnowledgeArticle(
      id: 'dis-agiz-bakimi',
      categoryId: 'bakim',
      title: 'Diş ve Ağız Bakımı',
      summary: 'Diş taşı önleme ve düzenli bakım alışkanlıkları.',
      minutes: 5,
      imagePath: 'assets/images/bilgi_bakim.png',
    ),
    KnowledgeArticle(
      id: 'tirnak-pati-bakimi',
      categoryId: 'bakim',
      title: 'Tırnak ve Pati Bakımı',
      summary: 'Evde güvenli tırnak kesimi ve pati temizliği.',
      minutes: 3,
      imagePath: 'assets/images/bilgi_bakim.png',
    ),
    KnowledgeArticle(
      id: 'asi-takvimi',
      categoryId: 'asi',
      title: 'Aşı Takvimi ve Koruyucu Hekimlik',
      summary: 'Hangi aşı ne zaman? Yavru ve yetişkin takvimi.',
      minutes: 6,
      imagePath: 'assets/images/bilgi_asi_koruma.png',
    ),
    KnowledgeArticle(
      id: 'parazit-korumasi',
      categoryId: 'asi',
      title: 'İç ve Dış Parazit Koruması',
      summary: 'Düzenli koruma planı ve mevsimsel dikkat noktaları.',
      minutes: 5,
      imagePath: 'assets/images/bilgi_asi_koruma.png',
    ),
    KnowledgeArticle(
      id: 'kuduz-asisi',
      categoryId: 'asi',
      title: 'Kuduz Aşısı Hakkında Bilinmesi Gerekenler',
      summary: 'Yasal zorunluluklar ve aşı sonrası bakım.',
      minutes: 4,
      imagePath: 'assets/images/bilgi_asi_koruma.png',
    ),
  ];

  static KnowledgeArticle? byId(String id) {
    final key = id.trim();
    if (key.isEmpty) return null;
    for (final item in values) {
      if (item.id == key) return item;
    }
    return null;
  }
}
