const productAdvantageGuides = <String, String>{
  'kisir_kedi':
      'Kısırlaştırılmış kedilerin metabolizması genellikle yavaşlar; aynı '
      'miktarda mama daha kolay kilo aldırabilir. “Kısır Kediler İçin” etiketli '
      'mamalar, enerjiyi daha kontrollü tutar, tokluk hissini destekler ve idrar '
      'yolu sağlığını da gözeten mineral dengesiyle hazırlanır.\n\n'
      'Bu mama kimler için uygundur? Kısırlaştırılmış, evde yaşayan, hareketi '
      'azalmış veya kilo almaya yatkın kediler. Yavru ve hamile kediler için '
      'steril seri genelde önerilmez.\n\n'
      'Nasıl kullanmalısınız? Paket üzerindeki günlük gramajı kilonuza göre '
      'uygulayın, serbest yedirmeyin. 4–6 haftada tartı kontrolü yapın. İdrar '
      'sorunu, iştahsızlık veya ani kilo değişiminde veterinere danışın.',
  'kisir_kopek':
      'Kısırlaştırılmış köpeklerde enerji ihtiyacı genelde düşer; aynı mama '
      'miktarı kolay kilo aldırabilir. “Kısır Köpekler İçin” etiketli mamalar '
      'kaloriyi dengeler, tokluğu destekler ve ideal kilonun korunmasına '
      'yardımcı olur.\n\n'
      'Bu mama kimler için uygundur? Kısırlaştırılmış, evde yaşayan veya '
      'hareketi azalmış köpekler. Büyüme dönemindeki yavrular için yavru '
      'formülü daha doğrudur.\n\n'
      'Nasıl kullanmalısınız? Günlük porsiyonu tartın, ödülü kaloriye dahil '
      'edin ve haftalık tartı tutun. Eklem yükü artmasın diye kilo ile yürüyüş '
      'süresini birlikte ayarlayın.',
  'kilo_kontrol':
      'Kilo kontrolü, dostunuzun ideal vücut ağırlığını korumasına yardımcı '
      'olmak için kalorisi dengelenmiş, doyurucu formülleri ifade eder. Amaç '
      'aç bırakmak değil; daha az enerjiyle tok tutmaktır.\n\n'
      'Fazla kilo eklemleri zorlar, şeker ve kalp riskini artırır. Bu etiketli '
      'ürünler genellikle daha yüksek protein/lif, daha düşük yağ-enerji '
      'dengesiyle hazırlanır.\n\n'
      'Ne yapmalısınız? Günlük porsiyonu tartarak verin, ödül mamasını günlük '
      'kaloriye dahil edin, oyun ve yürüyüşü artırın. Hedef, ani zayıflama '
      'değil haftalık kontrollü kayıptır. Diyabet, tiroid veya eklem sorunu '
      'varsa mama değişimini veterinerle planlayın.',
  'bobrek':
      'Böbrek sağlığını destekleyen mamalar, böbreklerin süzme yükünü '
      'hafifletmek için fosfor, sodyum ve protein kalitesini dengeler. Amaç '
      'böbreği “tedavi etmek” değil, günlük beslenmeyi daha nazik hale '
      'getirmektir.\n\n'
      'Bol su tüketimi kritiktir. Yaş mama, çeşme veya birden fazla su kabı '
      'yardımcı olur. Kusma, bol su içme, kilo kaybı veya iştahsızlık varsa '
      'bu mama tek başına yeterli olmaz; veteriner kontrolü gerekir.\n\n'
      'Bu etiketi, böbrek hassasiyeti olan veya veterinerin renal destekli '
      'beslenme önerdiği dostlar için kullanın. Kendi başınıza ağır protein '
      'kısıtlaması yapmayın.',
  'sindirim':
      'Sindirim desteği, mide-bağırsak hassasiyeti olan dostlar için daha kolay '
      'sindirilen protein, dengeli lif ve bazen prebiyotik içeren formülleri '
      'ifade eder.\n\n'
      'Gaz, yumuşak dışkı, kusma veya mama değişiminde huzursuzluk varsa bu '
      'etiket yönlendiricidir. Yeni mamaya 7–10 günde yavaş geçin; ani '
      'değişim ishali artırabilir.\n\n'
      'Kanlı dışkı, üst üste kusma veya halsizlikte mamayı denemek yerine '
      'veterinere gidin. Parazit ve gıda intoleransı da benzer belirti verir.',
  'tuy_deri':
      'Tüy ve deri sağlığı etiketli ürünler, tüy parlaklığı ve deri bariyerini '
      'desteklemek için omega yağ asitleri, çinko ve vitaminlerle güçlendirilir.\n\n'
      'Kepek, mat tüy, kaşıntı veya tüy dökülmesinde beslenme katkısı olabilir; '
      'ancak alerji, parazit veya mantar da aynı tabloyu yaratır. Mama tek başına '
      'teşhis değildir.\n\n'
      'Sonuç genelde 6–8 haftada görülür. Şiddetli kaşıntı, yaralar veya kulak '
      'akıntısında veteriner muayenesi şarttır.',
  'bagisiklik':
      'Bağışıklık desteği, antioksidan, vitamin ve mineral dengesiyle vücudun '
      'savunma sistemini günlük olarak desteklemeyi amaçlar. Aşı veya ilaç '
      'yerine geçmez.\n\n'
      'Yavru, yaşlı, stresli veya sık hastalanan dostlarda tam ve dengeli mama '
      'önemlidir. Bu etiket, bağışıklığı “güçlendiren mucize” değil, eksiksiz '
      'beslenmenin parçasıdır.\n\n'
      'Ateş, iştahsızlık veya tekrarlayan enfeksiyonda mama değişiminden önce '
      'sağlık kontrolü yaptırın.',
  'idrar':
      'İdrar yolu sağlığı etiketli mamalar, idrarın mineral dengesini ve su '
      'tüketimini destekleyerek kristal ve sistit riskini azaltmaya yardımcı '
      'olur.\n\n'
      'Kediler az su içer; idrar yoğunlaşınca taş riski artar. Yaş mama, taze '
      'su ve temiz tuvalet kabı bu formülle birlikte düşünülmelidir.\n\n'
      'Kumda kan, sık idrara çıkma, ıkınma veya hiç idrar yapamama acil '
      'durumdur. Özellikle erkek kedilerde tıkanıklık hayati risk taşır.',
  'dis':
      'Diş sağlığı etiketli ürünler, çiğneme dokusu veya diş dostu formülle '
      'plak birikimini azaltmaya yardımcı olur. Diş fırçalamanın yerini tutmaz.\n\n'
      'Ağız kokusu, sarı tartar, yemek yerken çekinme diş eti hastalığı '
      'habercisi olabilir. Mama desteği günlük bakımın yanındadır.\n\n'
      'Yılda en az bir ağız kontrolü önerilir. Şiddetli tartar ve ağrıda '
      'veteriner diş bakımı gerekir.',
  'eklem':
      'Eklem desteği, hareket kabiliyetini korumaya yardımcı glukozamin, '
      'kondroitin veya benzeri besin ögeleri içeren formülleri ifade eder.\n\n'
      'Yaşlı, iri ırk, fazla kilolu veya topallayan dostlarda eklem yükü '
      'artar. Mama, kilo kontrolü ve kontrollü egzersizle birlikte işe yarar.\n\n'
      'Ani topallama, şişlik veya ayağını hiç basmama durumunda mamayı '
      'beklemeden veterinere başvurun.',
  'kalp':
      'Kalp sağlığı etiketli mamalar, taurin ve uygun mineral dengesi gibi '
      'kalp-dolaşım için önemli ögeleri gözeten formüllerdir. Kalp ilacı '
      'değildir.\n\n'
      'Nefes darlığı, çabuk yorulma, öksürük veya bayılma kardiyak belirti '
      'olabilir. Bu durumda etiketli mama tek tedavi olamaz.\n\n'
      'Teşhis konmuş kalp hastalarında mama seçimini mutlaka veterinerinizle '
      'yapın.',
  'karaciger':
      'Karaciğer desteği, karaciğerin işini kolaylaştırmak için protein ve '
      'bakır gibi ögeleri daha dikkatli dengeleyen formülleri anlatır.\n\n'
      'Sarılık, kusma, halsizlik veya iştahsızlık karaciğer belirtisi olabilir. '
      'Bu mamalar veteriner diyeti yerine geçmez.\n\n'
      'Laboratuvar sonucu olmadan ağır karaciğer diyeti uygulamayın.',
  'diyabet':
      'Diyabet destekli mamalar, kan şekerinin daha dengeli seyretmesi için '
      'kontrollü karbonhidrat ve yüksek kaliteli proteinle hazırlanır.\n\n'
      'Aşırı su içme, kilo kaybı ve sık idrara çıkma uyarıdır. İnsülin '
      'kullanan dostlarda mama ve öğün saati tedavi planının parçasıdır.\n\n'
      'Bu etiketi gördüğünüzde ürünü kendi başınıza “şeker ilacı” sanmayın; '
      'veteriner protokolüne göre kullanın.',
  'hypoallergenic':
      'Hipoalerjenik formüller, alerjiye yatkın dostlar için daha sınırlı veya '
      'yeni protein kaynağı kullanır. Kaşıntı, kulak iltihabı ve ishal gıda '
      'hassasiyetiyle ilişkili olabilir.\n\n'
      'Gerçek eleme diyeti 6–8 hafta boyunca yalnızca o mamayla yapılır; arada '
      'ödül ve sofra artığı verilmez.\n\n'
      'Deri testi veya kan testi olmadan her kaşıntı alerji değildir. Parazit '
      've enfeksiyon da ekarte edilmelidir.',
  'tahilsiz':
      'Tahılsız formül, buğday, mısır, pirinç gibi tahıl içermez; enerjiyi '
      'daha çok et ve sebzeden alır. Hassas sindirim veya tahıl intoleransı '
      'düşünülen dostlar için bir seçenektir.\n\n'
      'Tahılsız olmak “daha sağlıklı” demek değildir. Her kedi ve köpek tahılsız '
      'mama zorunda değildir.\n\n'
      'Veterineriniz tahıl içeren bir diyeti öneriyorsa, moda diye değiştirmeyin.',
  'dogal_icerik':
      'Doğal içerik etiketi, gereksiz katkılardan uzak, tanınabilir hammaddelerle '
      'hazırlanmış formülü vurgular. “Doğal” ifadesi ilaç etkisi vaat etmez.\n\n'
      'Etiket, katkı maddesi hassasiyeti olan veya sade içerik arayan sahipler '
      'için yönlendiricidir.\n\n'
      'İçerik listesini yine de okuyun; her doğal ürün her dost için uygun '
      'olmayabilir.',
  'somon':
      'Somonlu formül, somon proteinini ve omega yağlarını lezzet ile tüy-deri '
      'desteği için kullanır. Balık seven dostlar ve tüy kalitesi arayanlar '
      'için sık tercih edilir.\n\n'
      'Balık alerjisi nadir de olsa vardır. Kaşıntı veya kusma olursa protein '
      'kaynağını değiştirin.\n\n'
      'Tek proteinli diyet arıyorsanız etiket ve içerik listesini birlikte '
      'kontrol edin.',
  'tavuk':
      'Tavuklu formül, yüksek sindirilebilir tavuk proteiniyle günlük enerji ve '
      'kas ihtiyacını karşılamayı hedefler. Birçok kedi ve köpek için ilk '
      'tercih protein kaynağıdır.\n\n'
      'Tavuk hassasiyeti olan dostlarda kaşıntı veya sindirim sorunu '
      'görülebilir. Bu durumda kuzu, hindi veya hipoalerjenik seriye geçilir.\n\n'
      'İçerikte tavuk yağı veya tavuk unu da alerjeni tetikleyebilir.',
  'kuzu':
      'Kuzulu formül, tavuğa alternatif bir protein kaynağı arayan hassas '
      'damaklar ve bazı gıda intoleransları için kullanılır.\n\n'
      'Yeni protein diyeti deniyorsanız birkaç hafta yalnızca bu kaynağı '
      'verin ki sonucu net görebilesiniz.\n\n'
      'Her kuzulu mama hipoalerjenik değildir; içeriğindeki diğer hayvansal '
      'ürünleri de kontrol edin.',
  'hindi':
      'Hindili formül, daha hafif ve sindirimi kolay bir beyaz et proteinidir. '
      'Tavuk yerine geçiş yapmak isteyenler için yumuşak bir alternatiftir.\n\n'
      'Hassas mide ve kilo kontrolü planlarında sıklıkla tercih edilir.\n\n'
      'Geçişi kademeli yapın; ani mama değişimi ishale yol açabilir.',
  'inek':
      'Sığır etli formül, yüksek palatabilite (lezzet) arayan dostlar için '
      'doyurucu kırmızı et proteinidir.\n\n'
      'Bazı köpeklerde sığır eti hassasiyeti görülebilir. Kaşıntı veya kulak '
      'sorunu olursa proteini değiştirin.\n\n'
      'Yağ oranı ürüne göre değişir; kilo kontrolündeki dostlarda etiket ve '
      'analiz değerine bakın.',
  'ordek':
      'Ördekli formül, yeni veya sınırlı protein kaynağı arayan, tahılsız veya '
      'hassas diyetlerde kullanılan bir alternatiftir.\n\n'
      'Daha önce tavuk-kuzu denenen ama uyum sağlanamayan dostlarda denenebilir.\n\n'
      'Tek protein iddiası varsa içeriğin gerçekten yalnızca ördek içerdiğini '
      'doğrulayın.',
  'tavsan':
      'Tavşanlı formül, alerjiye yatkın evcil dostlar için daha az karşılaşılmış '
      'bir protein kaynağı sunar.\n\n'
      'Eleme diyetlerinde “yeni protein” olarak seçilebilir. Bu süreçte başka '
      'hayvansal ödül vermeyin.\n\n'
      'Uzun süreli kullanım kararı veteriner diyetisyeniyle daha sağlıklıdır.',
  'ton_baligi':
      'Ton balıklı formül, kedilerin sık sevdiği lezzetli bir balık proteinidir. '
      'Günlük tam mama olarak dengeli içeriğe sahip olmalıdır.\n\n'
      'Sadece ton balığıyla beslemek eksiklik yaratır; etiketli ürün tam ve '
      'dengeli mama standardında olmalıdır.\n\n'
      'Sık idrar sorunu olan kedilerde su tüketimini ayrıca destekleyin.',
  'normal_kedi':
      'Yetişkin kedi formülü, 1 yaş civarı ve üzerindeki sağlıklı kedilerin '
      'günlük protein, yağ ve vitamin ihtiyacına göre dengelenmiş tam mamadır.\n\n'
      'Yavru, kısır, böbrek veya kilo problemi olan kedilerde özel seri daha '
      'doğru olabilir.\n\n'
      'Porsiyonu aktiviteye göre ayarlayın; ev kedileri daha az enerji yakar.',
  'kopek':
      'Köpekler için etiketli ürünler, köpeğin sindirim fizyolojisine ve '
      'protein-enerji ihtiyacına göre hazırlanır. Kedi maması köpeğe uzun süre '
      'verilmemelidir.\n\n'
      'Yaş, ırk ve aktivite porsiyonu değiştirir. Mini ırk ile büyük ırk aynı '
      'kalori ihtiyacına sahip değildir.\n\n'
      'Yavru, kısır veya eklem destekli ihtiyaç varsa o özel etiketi tercih edin.',
  'protein':
      'Protein oranı, kas gelişimi, tokluk ve doku onarımı için temel göstergedir. '
      'Yüzde değeri, mamadaki ham protein miktarını özetler.\n\n'
      'Yüksek protein her dost için şart değildir; böbrek veya karaciğer '
      'hastalarında protein kalitesi ve miktarı veteriner kararıdır.\n\n'
      'Etiket, formülün kas ve enerji ihtiyacını karşılamaya odaklandığını '
      'gösterir. Aktiviteye göre porsiyonu ayarlayın.',
  'parazit':
      'Parazit koruması, iç-dış parazit ürünlerini ve koruma programını '
      'tamamlayan bakımı ifade eder. Mama, parazit ilacı yerine geçmez.\n\n'
      'Pire, kene ve iç parazit mevsimsel risk taşır. Düzenli koruma, tarama '
      've çevre temizliği birlikte yürür.\n\n'
      'Kaşıntı, tüy dökülmesi veya ishalde parazit kontrolünü veterinere sorun.',
  'asi_takvimi':
      'Aşı takvimi etiketi, koruyucu hekimlik ürün ve hatırlatmalarını '
      'yönlendirir. Aşı, bağışıklık kazandırır; mama aşı yerine geçmez.\n\n'
      'Yavru döneminde çekirdek aşılar, sonrasında rapeller veteriner '
      'protokolüne göredir.\n\n'
      'Aşı gecikmesinde kendi başınıza program uydurmayın; klinikle güncelleyin.',
  'ilac_tedavi':
      'İlaç ve tedavi etiketi, tedavi sürecinde ihtiyaç duyulan ürünlere hızlı '
      'erişimi kolaylaştırır. Reçeteli ilaçlar veteriner onayı olmadan '
      'kullanılmamalıdır.\n\n'
      'Doğru doz, süre ve mama etkileşimi tedavinin parçasıdır.\n\n'
      'Belirtiler kötüleşirse mamayı değil, hekiminizi arayın.',
  'acil_durum':
      'Acil durum etiketi, ilk müdahale ve hızlı yönlendirme içindir. Kusma, '
      'nefes darlığı, zehirlenme şüphesi veya travmada dakika önemlidir.\n\n'
      'Bu ürünler muayene yerine geçmez. Önce hayati bulguları kontrol edin, '
      'sonra en yakın kliniğe gidin.\n\n'
      'Evde acil çantası (gazlı bez, tasma, klinik telefonu) bulundurun.',
  'zehirlenme':
      'Zehirlenme şüphesinde çikolata, soğan, üzüm, ksilol, ilaç ve temizlik '
      'ürünleri sık nedendir. Mama seçimi tedavi değildir.\n\n'
      'Ne yediğini, ne zaman ve ne kadar olduğunu not edin. Kusmayı kendi '
      'başınıza zorlamayın.\n\n'
      'Hemen veteriner veya zehir danışma hattına başvurun.',
  'yaralanma':
      'Yaralanma etiketli ürünler küçük kesik ve sıyrıklarda ilk bakıma '
      'yardımcı olabilir. Derin, kanayan veya ezilmeli yaralar acil bakımdır.\n\n'
      'Yarayı temiz suyla nazikçe durulayın, kirli malzemeyle ovuşturmayın.\n\n'
      'Aşırı kanama, kırık şüphesi veya göz yaralanmasında vakit kaybetmeyin.',
  'sokak':
      'Sokak dostları etiketi, sahipsiz hayvanların temel beslenme ihtiyacına '
      'uygun, pratik ve ekonomik seçenekleri işaret eder.\n\n'
      'Temiz su, düzenli mama noktası ve kısırlaştırma desteği uzun vadede '
      'daha etkilidir.\n\n'
      'Hasta görünen hayvanı zorla beslemek yerine yerel belediye veya '
      'veteriner desteği alın.',
  'mama_kabi':
      'Mama kabı, hijyenik ve doğru porsiyon için temel ekipmandır. Dar, '
      'kirli veya kaygan kaplar yemek stresini artırabilir.\n\n'
      'Günlük yıkayın, su kabını ayrı tutun. Kedilerde bıyık stresini azaltan '
      'geniş kaplar tercih edilebilir.\n\n'
      'Otomatik kaplar pratiktir ama porsiyonu yine sizin ayarlamanız gerekir.',
  'tl':
      'Fiyat avantajı, kaliteden ödün vermeden bütçe dostu seçenekleri '
      'gösterir. Ucuz mama her zaman yetersiz demek değildir; analize bakın.\n\n'
      'Tam ve dengeli mama standardı, protein kaynağı ve sizin dostunuzun '
      'ihtiyacı asıl ölçüttür.\n\n'
      'Sürekli mama değiştirmek yerine ihtiyaca uygun ekonomik seride kalmak '
      'sindirim için daha iyidir.',
};
