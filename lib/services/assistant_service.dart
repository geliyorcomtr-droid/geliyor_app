import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geliyor_app/data/cat_feeding_guide.dart';
import 'package:geliyor_app/state/pet_store.dart';
import 'package:http/http.dart' as http;

class AssistantProduct {
  const AssistantProduct({
    required this.name,
    required this.subtitle,
    required this.rating,
    required this.imagePath,
  });

  final String name;
  final String subtitle;
  final double rating;
  final String imagePath;
}

class AssistantAction {
  const AssistantAction({required this.label, required this.prompt});

  final String label;
  final String prompt;
}

class AssistantReply {
  const AssistantReply({
    required this.text,
    this.products = const [],
    this.actions = const [],
    this.fromAi = false,
  });

  final String text;
  final List<AssistantProduct> products;
  final List<AssistantAction> actions;
  final bool fromAi;
}

class AssistantService {
  AssistantService._();

  static final AssistantService instance = AssistantService._();

  static const _envApiKey = String.fromEnvironment('GEMINI_API_KEY');
  static const _model = 'gemini-2.0-flash';
  static const _configAsset = 'assets/config/gemini_api_key.txt';

  String? _cachedApiKey;
  bool _configLoaded = false;

  Future<void> _ensureApiKeyLoaded() async {
    if (_configLoaded) return;
    _configLoaded = true;

    if (_envApiKey.isNotEmpty) {
      _cachedApiKey = _envApiKey.trim();
      return;
    }

    try {
      final raw = await rootBundle.loadString(_configAsset);
      final key = raw.trim();
      if (key.isNotEmpty && !key.startsWith('YOUR_') && !key.startsWith('#')) {
        _cachedApiKey = key;
      }
    } catch (_) {
      // Config asset missing or empty — offline mode.
    }
  }

  Future<bool> get hasLiveApi async {
    await _ensureApiKeyLoaded();
    return (_cachedApiKey ?? '').isNotEmpty;
  }

  Future<AssistantReply> ask(
    String question, {
    List<({String role, String text})> history = const [],
  }) async {
    final trimmed = question.trim();
    if (trimmed.isEmpty) {
      return const AssistantReply(
        text: 'Lütfen dostunuzla ilgili bir soru yazın.',
      );
    }

    if (await hasLiveApi) {
      try {
        return await _askGemini(trimmed, history: history);
      } catch (error) {
        debugPrint('Assistant API error: $error');
      }
    }

    return _smartLocalReply(trimmed);
  }

  Future<AssistantReply> _askGemini(
    String question, {
    required List<({String role, String text})> history,
  }) async {
    final apiKey = _cachedApiKey!;
    final pets = PetStore.instance.pets;
    final petContext = pets.isEmpty
        ? 'Kullanıcının kayıtlı dostu yok.'
        : pets
            .map(
              (p) =>
                  '${p.name} (${p.species}, yaş: ${p.shortAge}, kilo: ${p.weight ?? '-'}, '
                  'vücut: ${p.bodyType ?? '-'}, kısır: ${p.neutered ?? '-'}, '
                  'aktivite: ${p.activityLevel ?? '-'}, ekstra besin: ${p.extraFood ?? '-'}, '
                  'alerji: ${p.allergies.isEmpty ? 'yok' : p.allergies.join(', ')})',
            )
            .join('; ');

    final systemPrompt = '''
Sen Geliyor.tr uygulamasının Türkçe konuşan yapay zeka pet asistanısın.
Kurallar:
- Her soruya özel, farklı ve somut cevap ver; kalıp cümle tekrarlama.
- Kısa tut (2-5 cümle), sıcak ve pratik ol.
- Veteriner teşhisi koyma; ciddi belirtilerde veterinere yönlendir.
- Mümkünse kayıtlı dost bilgilerini kullanarak kişiselleştir.
- Mama, aşı, bakım, kum, tüy, kilo, davranış konularında uygulama içi öneri ver.

Kayıtlı dost bilgileri: $petContext
''';

    final contents = <Map<String, dynamic>>[
      {
        'role': 'user',
        'parts': [
          {'text': systemPrompt},
        ],
      },
      {
        'role': 'model',
        'parts': [
          {
            'text':
                'Anladım. Geliyor.tr pet asistanıyım; kayıtlı dost bilgilerinize göre özel cevap vereceğim.',
          },
        ],
      },
    ];

    for (final turn in history.take(8)) {
      contents.add({
        'role': turn.role == 'user' ? 'user' : 'model',
        'parts': [
          {'text': turn.text},
        ],
      });
    }

    contents.add({
      'role': 'user',
      'parts': [
        {'text': question},
      ],
    });

    final uri = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_model:generateContent?key=$apiKey',
    );

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'contents': contents,
        'generationConfig': {
          'temperature': 0.85,
          'maxOutputTokens': 800,
          'topP': 0.95,
        },
      }),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Gemini HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final text = _extractGeminiText(decoded);
    if (text == null || text.trim().isEmpty) {
      throw Exception('Empty Gemini response');
    }

    final enriched = _enrichReply(text.trim(), question);
    return AssistantReply(
      text: enriched.text,
      products: enriched.products,
      actions: enriched.actions,
      fromAi: true,
    );
  }

  String? _extractGeminiText(Map<String, dynamic> decoded) {
    final candidates = decoded['candidates'];
    if (candidates is! List || candidates.isEmpty) return null;

    final content = (candidates.first as Map<String, dynamic>)['content'];
    if (content is! Map<String, dynamic>) return null;

    final parts = content['parts'];
    if (parts is! List || parts.isEmpty) return null;

    final firstPart = parts.first;
    if (firstPart is! Map<String, dynamic>) return null;

    final text = firstPart['text'];
    return text is String ? text : null;
  }

  AssistantReply _smartLocalReply(String question) {
    final lower = _normalize(question);
    final pets = PetStore.instance.pets;
    final primary = pets.isNotEmpty ? pets.first : null;
    final name = primary?.name ?? 'dostunuz';
    final species = primary?.species ?? 'dostunuz';
    final age = primary?.shortAge ?? 'bilinmeyen yaş';
    final weight = primary?.weight ?? 'bilinmeyen kilo';
    final body = primary?.bodyType;
    final activity = primary?.activityLevel;
    final neutered = primary?.neutered;
    final extraFood = primary?.extraFood;
    final isCat = (primary?.species ?? '').toLowerCase().contains('kedi');
    final isDog = (primary?.species ?? '').toLowerCase().contains('köpek') ||
        (primary?.species ?? '').toLowerCase().contains('kopek');

    // Greeting / thanks
    if (_containsAny(lower, ['merhaba', 'selam', 'iyi gun', 'iyi gün', 'hey'])) {
      return AssistantReply(
        text: pets.isEmpty
            ? 'Merhaba! Ben Geliyor.tr asistanıyım. Mama, aşı, bakım veya ürün konularında yardımcı olurum. Önce Dost Ekle’den dostunu kaydedersen önerilerim daha isabetli olur.'
            : 'Merhaba! $name için buradayım. Mama, aşı, kilo, tüy bakımı veya ürün önerisi sorabilirsin.',
      );
    }
    if (_containsAny(lower, ['tesekkur', 'teşekkür', 'sagol', 'sağol'])) {
      return const AssistantReply(
        text: 'Rica ederim! Başka bir konuda da yardımcı olabilirim.',
      );
    }

    // Vaccine / calendar
    if (_containsAny(lower, ['asi', 'aşı', 'takvim', 'hatirlat', 'hatırlat'])) {
      final speciesTip = isDog
          ? 'Köpeklerde karma, kuduz ve gerektiğinde kennel cough aşıları planlanır.'
          : isCat
              ? 'Kedilerde karma (FVRCP) ve kuduz temel takvimdedir; yaşam tarzına göre lösemi aşısı eklenebilir.'
              : 'Türüne göre temel aşı takvimi değişir.';
      return AssistantReply(
        text:
            '$name ($age) için aşı takvimini Sağlık > Aşı Takvimi’nden takip edebilirsin. $speciesTip '
            'Hatırlatıcı açmamı ister misin?',
        actions: const [
          AssistantAction(
            label: 'Evet, hatırlatıcıyı aç',
            prompt: 'Aşı hatırlatıcısını açmak istiyorum.',
          ),
          AssistantAction(
            label: 'Takvimi göster',
            prompt: 'Aşı takvimini nasıl görürüm?',
          ),
          AssistantAction(
            label: 'Şimdilik gerek yok',
            prompt: 'Şimdilik aşı hatırlatıcısı istemiyorum.',
          ),
        ],
      );
    }

    // Daily portion / consumption table
    if (_containsAny(lower, [
      'porsiyon',
      'gunluk',
      'günlük',
      'tuket',
      'tüket',
      'kac gram',
      'kaç gram',
      'ne kadar mama',
    ])) {
      PetData? cat;
      for (final pet in pets) {
        if (pet.species.toLowerCase().contains('kedi')) {
          cat = pet;
          break;
        }
      }
      cat ??= isCat ? primary : null;
      final row = CatFeedingGuide.fromWeightLabel(cat?.weight);
      if (row != null && cat != null) {
        final daily = row.gramsFor(
          bodyType: cat.bodyType,
          activityLevel: cat.activityLevel,
        );
        final profile = CatFeedingGuide.profileLabel(
          bodyType: cat.bodyType,
          activityLevel: cat.activityLevel,
        );
        return AssistantReply(
          text:
              '${cat.name} (${cat.weight}, $profile) için günlük yaklaşık $daily g kuru mama önerilir. '
              '30 günde ${row.monthlyFor(daily)}; 10 kg mama yaklaşık ${row.daysForBagKg(10, daily: daily)} gün yeter. '
              '${(extraFood != null && extraFood != 'Hayır') ? 'Düzenli $extraFood verdiğiniz için kuru mamayı biraz düşürün. ' : ''}'
              'Bu değerler kilo, vücut tipi ve aktivite tablosuna göredir.',
          actions: const [
            AssistantAction(
              label: 'Hangi mama uygun?',
              prompt: 'Dostuma hangi mama uygun?',
            ),
            AssistantAction(
              label: 'Kilo ideal mi?',
              prompt: 'Dostumun kilosu ideal mi?',
            ),
          ],
        );
      }
      return const AssistantReply(
        text:
            'Yetişkin kedilerde günlük kuru mama kilosuna göre değişir: 3 kg ≈ 50 g, 4 kg ≈ 60 g, 5 kg ≈ 70 g. '
            '10 kg mama 4 kg’lık bir kediye yaklaşık 167 gün yeter. Dost Ekle’den kedi kilosunu kaydedersen porsiyonu netleştiririm.',
      );
    }

    // Food / diet
    if (_containsAny(lower, [
      'mama',
      'beslen',
      'yem',
      'diyet',
      'acikti',
      'açıktı',
      'yemek',
    ])) {
      final bodyTip = switch (body) {
        'Kilolu' =>
          'Vücut yapısı kilolu göründüğü için düşük kalorili / light formüller ve ölçülü porsiyon öneririm.',
        'Zayıf' =>
          'Vücut yapısı zayıf olduğu için kalori ve protein açısından daha zengin bir mama dengesi düşünülebilir.',
        'İdeal' =>
          'Vücut yapısı ideal; mevcut ihtiyacı koruyan dengeli bir formül yeterli olur.',
        _ => 'Vücut yapısına göre porsiyonu ayarlamak önemli.',
      };
      final activityTip = switch (activity) {
        'Yüksek' || 'Çok aktif' =>
          'Aktivitesi yüksek; enerji ihtiyacı artabilir.',
        'Düşük' => 'Aktivitesi düşük; fazla kaloriden kaçının.',
        _ => '',
      };
      final neuteredTip = neutered == 'Evet'
          ? ' Kısır olduğu için steril/sterilised formüller kilo kontrolünde işe yarar.'
          : '';
      final extraTip = (extraFood != null && extraFood != 'Hayır')
          ? ' Ayrıca düzenli $extraFood tükettiği için kuru mama porsiyonunu buna göre biraz düşürmek iyi olur.'
          : '';

      return AssistantReply(
        text:
            '$name için ($species, $age, $weight): $bodyTip $activityTip$neuteredTip$extraTip '
            'Aşağıdaki seçeneklere bakabilirsin; Hangi Mama ekranından da kişiselleştirilmiş listeye gidebilirsin.',
        products: _defaultProducts(isDog: isDog),
        actions: const [
          AssistantAction(
            label: 'Hangi mama uygun?',
            prompt: 'Dostuma hangi mama uygun?',
          ),
          AssistantAction(
            label: 'Porsiyon ne kadar olmalı?',
            prompt: 'Günlük mama porsiyonu ne kadar olmalı?',
          ),
        ],
      );
    }

    // Weight / body
    if (_containsAny(lower, ['kilo', 'obez', 'zayif', 'zayıf', 'sisman', 'şişman', 'vucut'])) {
      final tip = body == 'Kilolu'
          ? 'Kilolu görünüyorsa porsiyonu %10-15 azaltmak, ödül mamasını sınırlamak ve kısa yürüyüş/oyun eklemek yardımcı olur.'
          : body == 'Zayıf'
              ? 'Zayıfsa öğün sayısını artırmak ve yüksek kaliteli proteinli mama denemek düşünülebilir; ani kilo kaybında veterinere danışın.'
              : 'Kilosunu düzenli tartarak takip etmek en sağlıklısı; ani değişimde veteriner kontrolü iyi olur.';
      return AssistantReply(
        text: '$name şu an $weight aralığında kayıtlı${body != null ? ', vücut yapısı: $body' : ''}. $tip',
      );
    }

    // Neutered
    if (_containsAny(lower, ['kisir', 'kısır', 'steril'])) {
      return AssistantReply(
        text: neutered == 'Evet'
            ? '$name kısır kayıtlı. Metabolizma yavaşlayabildiği için protein oranı iyi, yağ oranı dengeli steril mamalar ve ölçülü porsiyon önerilir. Su kabını her zaman dolu tutun.'
            : '$name için kısırlık durumu ${neutered ?? 'belirtilmemiş'}. Kısırlaştırma kararı yaş, sağlık ve yaşam tarzına göre veterinerle verilmelidir. Operasyon sonrası mama formülünü steril seriye geçirmek yaygın bir yaklaşımdır.',
      );
    }

    // Allergy / skin
    if (_containsAny(lower, [
      'alerji',
      'kasinti',
      'kaşınt',
      'deri',
      'tuyo',
      'kızarıklık',
      'kizariklik',
      'egzama',
    ])) {
      return AssistantReply(
        text:
            'Kaşıntı ve deri sorunları mama, parazit veya çevresel alerjiden kaynaklanabilir. '
            '${primary != null && primary.allergies.isNotEmpty ? 'Kayıtlarda alerji notu: ${primary.allergies.join(', ')}. ' : ''}'
            'Kısa süreli hafif belirtilerde mama/çevre değişimi denenebilir; 3-5 günden uzun sürerse veteriner öneririm. Hipoprotein veya hipoalerjenik formüller seçenek olabilir.',
        products: _defaultProducts(isDog: isDog).take(2).toList(),
      );
    }

    // Hair / shedding
    if (_containsAny(lower, ['tuy', 'tüy', 'dokul', 'dökül', 'tuybakim', 'fırça', 'firca'])) {
      return AssistantReply(
        text: isDog
            ? '$name için düzenli tarama, omega-3 destekli mama ve yeterince su tüy dökülmesini azaltmaya yardımcı olur. Mevsim geçişlerinde tarama sıklığını artırın.'
            : '$name için günlük kısa tarama, malt macunu/tüy topu önleyici ürünler ve kaliteli proteinli mama tüy sağlığını destekler. Aşırı dökülmede deri ve tiroid kontrolü gerekebilir.',
      );
    }

    // Litter / toilet (cats)
    if (_containsAny(lower, ['kum', 'tuvalet', 'kutu', 'idrar', 'cismar', 'çiş'])) {
      return AssistantReply(
        text: isCat || !isDog
            ? 'Kedi kumunda topaklanan, tozsuz bentonit veya silika tercih edilebilir. Kum kabı sayısı idealde kedi sayısı + 1 olmalıdır; kabı sessiz bir yerde tutun. İdrar sorununda gecikmeden veterinere gidin.'
            : 'Köpeklerde tuvalet eğitimi için sabit saat, ödül ve sabır önemli. Ani idrar kaçırma veya zorlanmada sağlık kontrolü gerekir.',
      );
    }

    // Behavior
    if (_containsAny(lower, [
      'havla',
      'isir',
      'ısır',
      'saldir',
      'saldır',
      'korku',
      'stres',
      'huzursuz',
      'miyav',
      'davranis',
      'davranış',
    ])) {
      return AssistantReply(
        text:
            'Davranış değişiklikleri sıkılma, ağrı veya stres kaynaklı olabilir. $name için (${activity ?? 'aktivite bilinmiyor'}) günlük oyun/egzersiz rutini, tutarlı kurallar ve sakin ödüllendirme işe yarar. Ani saldırganlık veya aşırı seslenmede önce sağlık kontrolü öneririm.',
      );
    }

    // Delivery / order / market
    if (_containsAny(lower, [
      'siparis',
      'sipariş',
      'kargo',
      'teslimat',
      'sepet',
      'market',
      'kampanya',
      'indirim',
    ])) {
      return AssistantReply(
        text:
            'Pet Market’ten sipariş verebilir, Sepetim’den ödeme adımlarını tamamlayabilirsin. Kampanyalar sekmesinde güncel indirimler var. Teslimat ve adres için Hesabım > Adreslerim bölümünü güncel tutman yeterli.',
        actions: const [
          AssistantAction(
            label: 'Mama öner',
            prompt: 'Dostuma mama önerir misin?',
          ),
          AssistantAction(
            label: 'Kampanyalar neler?',
            prompt: 'Güncel kampanyalar neler?',
          ),
        ],
      );
    }

    // Health / medicine / vet
    if (_containsAny(lower, [
      'hast',
      'ates',
      'ateş',
      'kus',
      'ishal',
      'ilac',
      'ilaç',
      'veteriner',
      'tedavi',
      'vitamin',
      'parazit',
    ])) {
      return AssistantReply(
        text:
            'Ciddi veya ani sağlık belirtilerinde (kusma, ishal, ateş, iştahsızlık) en yakın veterinere başvurmanı öneririm. '
            'Rutin takip için uygulamada Sağlık ekranından aşı, ilaç-tedavi ve hatırlatıcıları kullanabilirsin. $name için kayıtlı bilgiler: $age, $weight.',
        actions: const [
          AssistantAction(
            label: 'Aşı takvimini sor',
            prompt: 'Aşı takvimi nasıl olmalı?',
          ),
          AssistantAction(
            label: 'Parazit koruması',
            prompt: 'Parazit koruması ne sıklıkla yapılmalı?',
          ),
        ],
      );
    }

    // Parasite specifically
    if (_containsAny(lower, ['pire', 'kene', 'kurt', 'iç parazit', 'ic parazit'])) {
      return AssistantReply(
        text:
            'Pire-kene ve iç parazit koruması genellikle aylık veya veterinerin önerdiği aralıklarla yapılır. $species için yaşa uygun ürün seçmek önemli; yavru ve yetişkin dozları farklıdır. Ürün seçiminde Sağlık / İlaç ve Tedavi bölümüne bakabilirsin.',
      );
    }

    // Walk / exercise (dogs)
    if (_containsAny(lower, ['yuruyus', 'yürüyüş', 'egzersiz', 'oyun', 'gezdir'])) {
      return AssistantReply(
        text: isDog
            ? '$name için aktivite seviyesi ${activity ?? 'belirtilmemiş'}. Orta-yüksek aktivitede günde 2 yürüyüş + kısa oyun iyi bir başlangıçtır. Sıcak havalarda öğlen gezilerinden kaçının, suyu unutmayın.'
            : '$name için kapalı alanda tırmanma/oyun alanı ve günde birkaç kısa etkileşimli oyun stresi azaltır. Zorla egzersiz yerine merakını uyandıran oyuncaklar daha etkilidir.',
      );
    }

    // Wet food / treats
    if (_containsAny(lower, ['yas mama', 'yaş mama', 'odul', 'ödül', 'treat', 'konserve'])) {
      return AssistantReply(
        text: extraFood != null && extraFood != 'Hayır'
            ? '$name düzenli olarak "$extraFood" tüketiyor kayıtlı. Yaş mama/ödül kalorisini günlük ihtiyaçtan düşerek kuru mama porsiyonunu ayarla; ödülü eğitim için küçük parçalar halinde kullan.'
            : 'Yaş mama ve ödüller ek kalori getirir. Günlük ihtiyacın yaklaşık %10’unu aşmamaya çalışın. Diş sağlığı için ödül sonrası su ve gerektiğinde diş bakımı iyi olur.',
      );
    }

    // App help
    if (_containsAny(lower, [
      'nasil',
      'nasıl',
      'nerede',
      'uygulama',
      'ayar',
      'hesap',
      'adres',
      'plan',
    ])) {
      return const AssistantReply(
        text:
            'Hızlı yönlendirme: Ana sayfadan Pet Market, Akıllı Planım, Sağlık ve Dost Ekle’ye ulaşabilirsin. '
            'Hesap menüsünden adres, kişisel bilgi ve güvenlik ayarlarını yönetebilirsin. Net bir işlem söyle, adım adım anlatayım.',
      );
    }

    // Personalized default when we know the pet
    if (primary != null) {
      return AssistantReply(
        text:
            '$name için sorunuzu aldım ($species, $age, $weight'
            '${body != null ? ', $body' : ''}'
            '${activity != null ? ', aktivite: $activity' : ''}). '
            'Daha net yardımcı olmam için mama, aşı, tüy, kilo veya davranış gibi konuyu belirtir misin? '
            'Acil bir belirti varsa veterinere başvurmanı öneririm.',
        actions: const [
          AssistantAction(label: 'Mama öner', prompt: 'Mama önerir misin?'),
          AssistantAction(label: 'Aşı takvimi', prompt: 'Aşı takvimi nasıl olmalı?'),
          AssistantAction(label: 'Tüy bakımı', prompt: 'Tüy dökülmesi için ne yapmalıyım?'),
        ],
      );
    }

    return const AssistantReply(
      text:
          'Size daha iyi yardımcı olmam için dostunuzun türünü (kedi/köpek) ve konuyu (mama, aşı, kilo, tüy, davranış) yazın. '
          'Dost Ekle’den profil oluşturursanız cevaplarım kişiselleşir. Acil durumlarda en yakın veterinere başvurun.',
      actions: [
        AssistantAction(label: 'Mama sor', prompt: 'Kedi mama önerisi isterim'),
        AssistantAction(label: 'Aşı sor', prompt: 'Aşı takvimi nasıl olmalı?'),
        AssistantAction(label: 'Kilo sor', prompt: 'Dostumun kilosu ideal mi?'),
      ],
    );
  }

  AssistantReply _enrichReply(String text, String question) {
    final lower = _normalize('$text $question');
    final pets = PetStore.instance.pets;
    final isDog = pets.isNotEmpty &&
        (pets.first.species.toLowerCase().contains('köpek') ||
            pets.first.species.toLowerCase().contains('kopek'));

    final products = _containsAny(lower, [
      'mama',
      'beslen',
      'pro plan',
      'royal',
      'hill',
      'diyet',
      'porsiyon',
    ])
        ? _defaultProducts(isDog: isDog)
        : <AssistantProduct>[];

    final actions = _containsAny(lower, ['asi', 'aşı', 'hatirlat', 'hatırlat'])
        ? const [
            AssistantAction(
              label: 'Evet, hatırlatıcıyı aç',
              prompt: 'Aşı hatırlatıcısını açmak istiyorum.',
            ),
            AssistantAction(
              label: 'Daha sonra hatırlat',
              prompt: 'Aşı hatırlatmasını daha sonra istiyorum.',
            ),
            AssistantAction(
              label: 'Hayır, teşekkürler',
              prompt: 'Şimdilik aşı hatırlatıcısı istemiyorum.',
            ),
          ]
        : <AssistantAction>[];

    return AssistantReply(text: text, products: products, actions: actions);
  }

  List<AssistantProduct> _defaultProducts({bool isDog = false}) {
    if (isDog) {
      return const [
        AssistantProduct(
          name: 'Pro Plan',
          subtitle: 'Adult Medium Tavuklu',
          rating: 4.8,
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
        ),
        AssistantProduct(
          name: 'Royal Canin',
          subtitle: 'Medium Adult',
          rating: 4.7,
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
        ),
        AssistantProduct(
          name: "Hill's",
          subtitle: 'Science Plan Adult',
          rating: 4.6,
          imagePath: 'assets/images/nd_kuzu_kisir.jpg',
        ),
      ];
    }

    return const [
      AssistantProduct(
        name: 'Pro Plan',
        subtitle: 'Sterilised Somonlu',
        rating: 4.8,
        imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      ),
      AssistantProduct(
        name: 'Royal Canin',
        subtitle: 'Indoor 27',
        rating: 4.7,
        imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      ),
      AssistantProduct(
        name: "Hill's",
        subtitle: 'Science Plan',
        rating: 4.6,
        imagePath: 'assets/images/nd_kuzu_kisir.jpg',
      ),
    ];
  }

  String _normalize(String text) {
    return text
        .toLowerCase()
        .replaceAll('İ', 'i')
        .replaceAll('I', 'i')
        .replaceAll('ı', 'i')
        .replaceAll('ş', 's')
        .replaceAll('ğ', 'g')
        .replaceAll('ü', 'u')
        .replaceAll('ö', 'o')
        .replaceAll('ç', 'c');
  }

  bool _containsAny(String text, List<String> words) {
    for (final word in words) {
      if (text.contains(_normalize(word))) return true;
    }
    return false;
  }
}
