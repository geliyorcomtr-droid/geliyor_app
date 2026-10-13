import 'package:geliyor_app/data/product_advantage_repository.dart';

/// Bilgi bankası / tüm konular ikonları ürün faydalarından gelir.
class KnowledgeAdvantageIcons {
  KnowledgeAdvantageIcons._();

  /// `knowledge_topics/{id}` → ürün faydası id
  static const forAllTopicId = <String, String>{
    'sindirim': 'sindirim',
    'bobrek': 'bobrek',
    'idrar': 'idrar',
    'tuy-deri': 'tuy_deri',
    'alerji': 'hypoallergenic',
    'agiz-dis': 'dis',
    'kilo': 'kilo_kontrol',
    'kalp': 'kalp',
    'bagisiklik': 'bagisiklik',
    'diyabet': 'diyabet',
    'eklem': 'eklem',
    'karaciger': 'karaciger',
    'parazit': 'parazit',
    'asi-takibi': 'asi_takvimi',
    'ilac-tedavi': 'ilac_tedavi',
    'ozel-mama': 'mama_kabi',
    'acil': 'acil_durum',
    'zehirlenme': 'zehirlenme',
    'yaralanma': 'yaralanma',
    'dogal-icerik': 'dogal_icerik',
  };

  /// Bilgi bankası kategori şeridi / soru konuları → ürün faydası id
  static const forQuestionTopicId = <String, String>{
    'sindirim': 'sindirim',
    'idrar': 'idrar',
    'alerji': 'tuy_deri',
    'kilo': 'kilo_kontrol',
    'genel': 'bagisiklik',
    'dis': 'dis',
    'parazit': 'parazit',
  };

  static String defaultForTopicId(String topicId) =>
      forAllTopicId[topicId.trim()] ?? '';

  static String defaultForQuestionTopicId(String topicId) =>
      forQuestionTopicId[topicId.trim()] ?? '';

  static String pathForAdvantageId(
    String advantageId, {
    List<AppProductAdvantage> catalog = const [],
    String fallback = '',
  }) {
    final item = ProductAdvantageRepository.byId(
      advantageId,
      catalog: catalog,
    );
    if (item == null) return fallback;
    final path = ProductAdvantageRepository.displayPath(item);
    return path.isNotEmpty ? path : fallback;
  }

  static String forTopic({
    required String topicId,
    required String advantageId,
    String fallback = '',
    List<AppProductAdvantage> catalog = const [],
  }) {
    final linked = advantageId.trim();
    final id = linked.isNotEmpty ? linked : defaultForTopicId(topicId);
    return pathForAdvantageId(
      id,
      catalog: catalog,
      fallback: fallback,
    );
  }

  static String forQuestionTopic(
    String topicId, {
    List<AppProductAdvantage> catalog = const [],
    String fallback = '',
  }) {
    return pathForAdvantageId(
      defaultForQuestionTopicId(topicId),
      catalog: catalog,
      fallback: fallback,
    );
  }
}
