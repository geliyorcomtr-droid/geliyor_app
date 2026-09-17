import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/knowledge_catalog.dart';

class AppKnowledgeTopic {
  const AppKnowledgeTopic({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.iconUrl = '',
    this.assetPath = '',
    this.colorValue = 0xFFF59E0B,
    this.questionTopicId = 'sindirim',
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String title;
  final String subtitle;
  final String iconUrl;
  final String assetPath;
  final int colorValue;
  final String questionTopicId;
  final int order;
  final bool active;

  Color get color => knowledgeColor(colorValue);

  String get displayIcon {
    final url = iconUrl.trim();
    if (url.isNotEmpty) return url;
    return assetPath.trim();
  }

  factory AppKnowledgeTopic.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    return AppKnowledgeTopic(
      id: doc.id,
      title: (data[KnowledgeTopicFields.title] as String?) ?? '',
      subtitle: (data[KnowledgeTopicFields.subtitle] as String?) ?? '',
      iconUrl: (data[KnowledgeTopicFields.iconUrl] as String?) ?? '',
      assetPath: (data[KnowledgeTopicFields.assetPath] as String?) ?? '',
      colorValue:
          (data[KnowledgeTopicFields.colorValue] as num?)?.toInt() ??
          0xFFF59E0B,
      questionTopicId:
          (data[KnowledgeTopicFields.questionTopicId] as String?) ??
          'sindirim',
      order: (data[KnowledgeTopicFields.order] as num?)?.toInt() ?? 0,
      active: data[KnowledgeTopicFields.active] as bool? ?? true,
    );
  }

  factory AppKnowledgeTopic.fromDefault(DefaultKnowledgeTopic item) {
    return AppKnowledgeTopic(
      id: item.id,
      title: item.title,
      subtitle: item.subtitle,
      assetPath: item.assetPath,
      colorValue: item.colorValue,
      questionTopicId: item.questionTopicId,
      order: item.order,
    );
  }

  static List<AppKnowledgeTopic> defaults() => [
    for (final item in defaultKnowledgeTopics)
      AppKnowledgeTopic.fromDefault(item),
  ];

  Map<String, dynamic> toMap() => {
    KnowledgeTopicFields.title: title.trim(),
    KnowledgeTopicFields.subtitle: subtitle.trim(),
    KnowledgeTopicFields.iconUrl: iconUrl.trim(),
    KnowledgeTopicFields.assetPath: assetPath.trim(),
    KnowledgeTopicFields.colorValue: colorValue,
    KnowledgeTopicFields.questionTopicId: questionTopicId.trim(),
    KnowledgeTopicFields.order: order,
    KnowledgeTopicFields.active: active,
    KnowledgeTopicFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppKnowledgeTopic copyWith({
    String? title,
    String? subtitle,
    String? iconUrl,
    String? assetPath,
    int? colorValue,
    String? questionTopicId,
    int? order,
    bool? active,
  }) {
    return AppKnowledgeTopic(
      id: id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      iconUrl: iconUrl ?? this.iconUrl,
      assetPath: assetPath ?? this.assetPath,
      colorValue: colorValue ?? this.colorValue,
      questionTopicId: questionTopicId ?? this.questionTopicId,
      order: order ?? this.order,
      active: active ?? this.active,
    );
  }
}

class AppKnowledgeQuestion {
  const AppKnowledgeQuestion({
    required this.id,
    required this.topicId,
    required this.title,
    this.views = '',
    this.answer = '',
    this.tips = const [],
    this.featured = false,
    this.order = 0,
    this.active = true,
  });

  final String id;
  final String topicId;
  final String title;
  final String views;
  final String answer;
  final List<String> tips;
  final bool featured;
  final int order;
  final bool active;

  String get topicTitle => KnowledgeQuestionTopic.titleOf(topicId);

  factory AppKnowledgeQuestion.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final rawTips = data[KnowledgeQuestionFields.tips];
    return AppKnowledgeQuestion(
      id: doc.id,
      topicId: (data[KnowledgeQuestionFields.topicId] as String?) ?? '',
      title: (data[KnowledgeQuestionFields.title] as String?) ?? '',
      views: (data[KnowledgeQuestionFields.views] as String?) ?? '',
      answer: (data[KnowledgeQuestionFields.answer] as String?) ?? '',
      tips: rawTips is List
          ? rawTips
                .map((item) => '$item'.trim())
                .where((item) => item.isNotEmpty)
                .toList()
          : const [],
      featured: data[KnowledgeQuestionFields.featured] as bool? ?? false,
      order: (data[KnowledgeQuestionFields.order] as num?)?.toInt() ?? 0,
      active: data[KnowledgeQuestionFields.active] as bool? ?? true,
    );
  }

  factory AppKnowledgeQuestion.fromDefault(DefaultKnowledgeQuestion item) {
    return AppKnowledgeQuestion(
      id: item.id,
      topicId: item.topicId,
      title: item.title,
      views: item.views,
      featured: item.featured,
      order: item.order,
    );
  }

  static List<AppKnowledgeQuestion> defaults() => [
    for (final item in defaultKnowledgeQuestions)
      AppKnowledgeQuestion.fromDefault(item),
  ];

  Map<String, dynamic> toMap() => {
    KnowledgeQuestionFields.title: title.trim(),
    KnowledgeQuestionFields.topicId: topicId.trim(),
    KnowledgeQuestionFields.views: views.trim(),
    KnowledgeQuestionFields.answer: answer.trim(),
    KnowledgeQuestionFields.tips: tips
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList(),
    KnowledgeQuestionFields.featured: featured,
    KnowledgeQuestionFields.order: order,
    KnowledgeQuestionFields.active: active,
    KnowledgeQuestionFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppKnowledgeQuestion copyWith({
    String? topicId,
    String? title,
    String? views,
    String? answer,
    List<String>? tips,
    bool? featured,
    int? order,
    bool? active,
  }) {
    return AppKnowledgeQuestion(
      id: id,
      topicId: topicId ?? this.topicId,
      title: title ?? this.title,
      views: views ?? this.views,
      answer: answer ?? this.answer,
      tips: tips ?? this.tips,
      featured: featured ?? this.featured,
      order: order ?? this.order,
      active: active ?? this.active,
    );
  }
}

class KnowledgeContentRepository {
  KnowledgeContentRepository._();
  static final KnowledgeContentRepository instance =
      KnowledgeContentRepository._();

  CollectionReference<Map<String, dynamic>> get _topics => FirebaseFirestore
      .instance
      .collection(FirestoreCollections.knowledgeTopics);

  CollectionReference<Map<String, dynamic>> get _questions => FirebaseFirestore
      .instance
      .collection(FirestoreCollections.knowledgeQuestions);

  Future<void> ensureDefaults() async {
    try {
      final topicSnap = await _topics.limit(1).get();
      if (topicSnap.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final topic in AppKnowledgeTopic.defaults()) {
          batch.set(_topics.doc(topic.id), topic.toMap());
        }
        await batch.commit();
      }
    } catch (_) {}

    try {
      final questionSnap = await _questions.limit(1).get();
      if (questionSnap.docs.isEmpty) {
        final items = AppKnowledgeQuestion.defaults();
        for (var i = 0; i < items.length; i += 400) {
          final batch = FirebaseFirestore.instance.batch();
          for (final question in items.skip(i).take(400)) {
            batch.set(_questions.doc(question.id), question.toMap());
          }
          await batch.commit();
        }
      }
    } catch (_) {}
  }

  Stream<List<AppKnowledgeTopic>> watchTopics({bool fallback = true}) {
    return _topics.snapshots().map((snap) {
      if (snap.docs.isEmpty && fallback) return AppKnowledgeTopic.defaults();
      final list = snap.docs.map(AppKnowledgeTopic.fromDoc).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Stream<List<AppKnowledgeTopic>> watchActiveTopics() {
    return watchTopics().map(
      (list) => list.where((item) => item.active).toList(),
    );
  }

  Stream<List<AppKnowledgeQuestion>> watchQuestions({bool fallback = true}) {
    return _questions.snapshots().map((snap) {
      if (snap.docs.isEmpty && fallback) {
        return AppKnowledgeQuestion.defaults();
      }
      final list = snap.docs.map(AppKnowledgeQuestion.fromDoc).toList()
        ..sort((a, b) {
          final byTopic = a.topicId.compareTo(b.topicId);
          if (byTopic != 0) return byTopic;
          return a.order.compareTo(b.order);
        });
      return list;
    });
  }

  Stream<List<AppKnowledgeQuestion>> watchActiveQuestions({String? topicId}) {
    return watchQuestions().map((list) {
      return list
          .where(
            (item) =>
                item.active && (topicId == null || item.topicId == topicId),
          )
          .toList();
    });
  }
}
