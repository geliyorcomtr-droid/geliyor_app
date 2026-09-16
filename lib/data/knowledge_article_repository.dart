import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/knowledge_articles.dart';
import 'package:geliyor_app/theme/app_colors.dart';

class KnowledgeArticleCategories {
  KnowledgeArticleCategories._();

  static const beslenme = 'beslenme';
  static const saglik = 'saglik';
  static const bakim = 'bakim';
  static const asi = 'asi';

  static const all = <String>[beslenme, saglik, bakim, asi];

  static String titleOf(String id) => switch (id) {
    beslenme => 'Beslenme',
    saglik => 'Sağlık',
    bakim => 'Bakım',
    asi => 'Aşı',
    _ => 'Makale',
  };

  static Color colorOf(String id) => switch (id) {
    beslenme => const Color(0xFF00A859),
    saglik => const Color(0xFF9B4DCA),
    bakim => const Color(0xFFFF6600),
    asi => const Color(0xFF1E90FF),
    _ => AppColors.primary,
  };
}

class AppKnowledgeArticle {
  const AppKnowledgeArticle({
    required this.id,
    required this.categoryId,
    required this.title,
    this.summary = '',
    this.minutes = 4,
    this.imageUrl = '',
    this.assetPath = '',
    this.body = '',
    this.keyPoints = const [],
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String categoryId;
  final String title;
  final String summary;
  final int minutes;
  final String imageUrl;
  final String assetPath;
  final String body;
  final List<String> keyPoints;
  final int order;
  final bool active;

  String get displayImage {
    final url = imageUrl.trim();
    if (url.isNotEmpty) return url;
    return assetPath.trim();
  }

  String get categoryTitle => KnowledgeArticleCategories.titleOf(categoryId);

  Color get categoryColor => KnowledgeArticleCategories.colorOf(categoryId);

  factory AppKnowledgeArticle.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AppKnowledgeArticle(
      id: doc.id,
      categoryId: (data[KnowledgeArticleFields.categoryId] as String?) ?? '',
      title: (data[KnowledgeArticleFields.title] as String?) ?? '',
      summary: (data[KnowledgeArticleFields.summary] as String?) ?? '',
      minutes: (data[KnowledgeArticleFields.minutes] as num?)?.toInt() ?? 4,
      imageUrl: (data[KnowledgeArticleFields.imageUrl] as String?) ?? '',
      assetPath: (data[KnowledgeArticleFields.assetPath] as String?) ?? '',
      body: (data[KnowledgeArticleFields.body] as String?) ?? '',
      keyPoints: _stringList(data[KnowledgeArticleFields.keyPoints]),
      order: (data[KnowledgeArticleFields.order] as num?)?.toInt() ?? 0,
      active: data[KnowledgeArticleFields.active] as bool? ?? true,
    );
  }

  factory AppKnowledgeArticle.fromCatalog(KnowledgeArticle item, int order) {
    return AppKnowledgeArticle(
      id: item.id,
      categoryId: item.categoryId,
      title: item.title,
      summary: item.summary,
      minutes: item.minutes,
      assetPath: item.imagePath,
      order: order,
    );
  }

  static List<AppKnowledgeArticle> defaults() {
    final catalog = KnowledgeArticle.values;
    return [
      for (var i = 0; i < catalog.length; i++)
        AppKnowledgeArticle.fromCatalog(catalog[i], i),
    ];
  }

  Map<String, dynamic> toMap() => {
    KnowledgeArticleFields.title: title.trim(),
    KnowledgeArticleFields.categoryId: categoryId.trim(),
    KnowledgeArticleFields.summary: summary.trim(),
    KnowledgeArticleFields.minutes: minutes < 1 ? 1 : minutes,
    KnowledgeArticleFields.imageUrl: imageUrl.trim(),
    KnowledgeArticleFields.assetPath: assetPath.trim(),
    KnowledgeArticleFields.body: body.trim(),
    KnowledgeArticleFields.keyPoints: keyPoints
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(),
    KnowledgeArticleFields.order: order,
    KnowledgeArticleFields.active: active,
    KnowledgeArticleFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppKnowledgeArticle copyWith({
    String? categoryId,
    String? title,
    String? summary,
    int? minutes,
    String? imageUrl,
    String? assetPath,
    String? body,
    List<String>? keyPoints,
    int? order,
    bool? active,
  }) {
    return AppKnowledgeArticle(
      id: id,
      categoryId: categoryId ?? this.categoryId,
      title: title ?? this.title,
      summary: summary ?? this.summary,
      minutes: minutes ?? this.minutes,
      imageUrl: imageUrl ?? this.imageUrl,
      assetPath: assetPath ?? this.assetPath,
      body: body ?? this.body,
      keyPoints: keyPoints ?? this.keyPoints,
      order: order ?? this.order,
      active: active ?? this.active,
    );
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .map((item) => '$item'.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class KnowledgeArticleRepository {
  KnowledgeArticleRepository._();
  static final KnowledgeArticleRepository instance =
      KnowledgeArticleRepository._();

  CollectionReference<Map<String, dynamic>> get _col => FirebaseFirestore
      .instance
      .collection(FirestoreCollections.knowledgeArticles);

  Future<void> ensureDefaults() async {
    try {
      final existing = await _col.limit(1).get();
      if (existing.docs.isNotEmpty) return;
      final batch = FirebaseFirestore.instance.batch();
      for (final article in AppKnowledgeArticle.defaults()) {
        batch.set(_col.doc(article.id), article.toMap());
      }
      await batch.commit();
    } catch (_) {
      // İstemcide yazma yetkisi olmayabilir.
    }
  }

  Stream<List<AppKnowledgeArticle>> watchAll({bool fallback = true}) {
    return _col.snapshots().map((snap) {
      if (snap.docs.isEmpty && fallback) {
        return AppKnowledgeArticle.defaults();
      }
      final list = snap.docs.map(AppKnowledgeArticle.fromDoc).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Stream<List<AppKnowledgeArticle>> watchActive() {
    return watchAll().map(
      (list) => list.where((article) => article.active).toList(),
    );
  }

  Future<AppKnowledgeArticle?> getById(String id) async {
    final key = id.trim();
    if (key.isEmpty) return null;
    try {
      final doc = await _col.doc(key).get();
      if (doc.exists) return AppKnowledgeArticle.fromDoc(doc);
    } catch (_) {}
    for (final article in AppKnowledgeArticle.defaults()) {
      if (article.id == key) return article;
    }
    return null;
  }

  static List<AppKnowledgeArticle> hubArticles(
    List<AppKnowledgeArticle> all,
  ) {
    final picked = <AppKnowledgeArticle>[];
    for (final categoryId in KnowledgeArticleCategories.all) {
      for (final article in all) {
        if (article.categoryId == categoryId) {
          picked.add(article);
          break;
        }
      }
    }
    if (picked.length >= 4) return picked.take(4).toList();
    for (final article in all) {
      if (picked.length >= 4) break;
      if (picked.any((item) => item.id == article.id)) continue;
      picked.add(article);
    }
    return picked.take(4).toList();
  }
}
