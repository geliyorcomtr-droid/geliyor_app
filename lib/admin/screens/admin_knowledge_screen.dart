import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:geliyor_app/admin/admin_ui.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/knowledge_article_repository.dart';
import 'package:geliyor_app/data/knowledge_catalog.dart';
import 'package:geliyor_app/data/knowledge_content_repository.dart';
import 'package:geliyor_app/theme/app_colors.dart';
import 'package:geliyor_app/utils/compress_upload_image.dart';
import 'package:geliyor_app/utils/product_image.dart';

const _colorChoices = <(int, String)>[
  (0xFF1E90FF, 'Mavi'),
  (0xFFEC4899, 'Pembe'),
  (0xFFDB2777, 'Fuşya'),
  (0xFF9B4DCA, 'Mor'),
  (0xFF22C55E, 'Yeşil'),
  (0xFF0EA5E9, 'Açık mavi'),
  (0xFFFF6600, 'Turuncu'),
  (0xFFEF4444, 'Kırmızı'),
  (0xFF16A34A, 'Koyu yeşil'),
  (0xFFF59E0B, 'Amber'),
  (0xFF84CC16, 'Lime'),
  (0xFF14B8A6, 'Turkuaz'),
  (0xFF2563EB, 'İndigo'),
  (0xFF00A859, 'Zümrüt'),
  (0xFF8B5CF6, 'Violet'),
  (0xFFE60000, 'Acil kırmızı'),
  (0xFFDC2626, 'Koyu kırmızı'),
  (0xFFB91C1C, 'Bordo'),
  (0xFF65A30D, 'Zeytin'),
];

class AdminKnowledgeScreen extends StatefulWidget {
  const AdminKnowledgeScreen({super.key, this.initialGroup = 'topics'});

  final String initialGroup;

  @override
  State<AdminKnowledgeScreen> createState() => _AdminKnowledgeScreenState();
}

class _AdminKnowledgeScreenState extends State<AdminKnowledgeScreen> {
  bool _seeding = true;
  bool _uploading = false;
  late String _group = widget.initialGroup;
  String _allTopicId = 'sindirim';
  String _allTopicQuestionId = KnowledgeQuestionTopic.sindirim.id;
  String _questionTopicId = KnowledgeQuestionTopic.sindirim.id;
  String _articleCategoryId = KnowledgeArticleCategories.beslenme;

  @override
  void initState() {
    super.initState();
    _seed();
  }

  Future<void> _seed() async {
    try {
      await Future.wait([
        KnowledgeContentRepository.instance.ensureDefaults(),
        KnowledgeArticleRepository.instance.ensureDefaults(),
      ]);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Bilgi bankası yüklenemedi: $error')),
      );
    } finally {
      if (mounted) setState(() => _seeding = false);
    }
  }

  Future<String?> _upload(String folder) async {
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file == null) return null;
    setState(() => _uploading = true);
    try {
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        throw Exception('Dosya okunamadı, başka bir görsel dene.');
      }
      final prepared = prepareUploadImage(
        bytes,
        file.name,
        style: folder == 'knowledge_topics'
            ? UploadImageStyle.icon
            : UploadImageStyle.photo,
      );
      final reference = FirebaseStorage.instance.ref(
        '$folder/${DateTime.now().microsecondsSinceEpoch}_${prepared.fileName}',
      );
      await reference.putData(
        prepared.bytes,
        SettableMetadata(contentType: prepared.contentType),
      );
      return reference.getDownloadURL();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Görsel yüklenemedi: $error')),
        );
      }
      return null;
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  Future<void> _saveTopic(AppKnowledgeTopic topic) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.knowledgeTopics)
        .doc(topic.id)
        .set(topic.toMap(), SetOptions(merge: true));
  }

  Future<void> _saveQuestion(AppKnowledgeQuestion question) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.knowledgeQuestions)
        .doc(question.id)
        .set(question.toMap(), SetOptions(merge: true));
  }

  Future<void> _saveArticle(AppKnowledgeArticle article) async {
    await FirebaseFirestore.instance
        .collection(FirestoreCollections.knowledgeArticles)
        .doc(article.id)
        .set(article.toMap(), SetOptions(merge: true));
  }

  Future<bool> _confirmDelete(String title) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Sil'),
        content: Text('“$title” silinsin mi?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    return ok == true;
  }

  Future<void> _editTopic(AppKnowledgeTopic? existing, int nextOrder) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final subtitle = TextEditingController(text: existing?.subtitle ?? '');
    var questionTopicId =
        existing?.questionTopicId ?? KnowledgeQuestionTopic.sindirim.id;
    if (KnowledgeQuestionTopic.all.every((item) => item.id != questionTopicId)) {
      questionTopicId = KnowledgeQuestionTopic.sindirim.id;
    }
    var colorValue = existing?.colorValue ?? 0xFF1E90FF;
    var iconUrl = existing?.iconUrl ?? '';
    var active = existing?.active ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Konu ekle' : 'Konuyu düzenle'),
          content: SizedBox(
            width: 480,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                  ),
                  TextField(
                    controller: subtitle,
                    decoration: const InputDecoration(
                      labelText: 'Kısa açıklama',
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey('topic-q-$questionTopicId'),
                    initialValue: questionTopicId,
                    isExpanded: true,
                    decoration: const InputDecoration(
                      labelText: 'Bağlı soru konusu',
                    ),
                    items: [
                      for (final item in KnowledgeQuestionTopic.all)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(item.title),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialog(() => questionTopicId = value);
                    },
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<int>(
                    key: ValueKey('topic-c-$colorValue'),
                    initialValue: _colorChoices.any((item) => item.$1 == colorValue)
                        ? colorValue
                        : 0xFF1E90FF,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Renk'),
                    items: [
                      for (final item in _colorChoices)
                        DropdownMenuItem(
                          value: item.$1,
                          child: Text(item.$2),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialog(() => colorValue = value);
                    },
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _uploading
                          ? null
                          : () async {
                              final url = await _upload('knowledge_topics');
                              if (url == null) return;
                              setDialog(() => iconUrl = url);
                            },
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: Text(
                        iconUrl.isEmpty ? 'İkon yükle' : 'İkonu değiştir',
                      ),
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Uygulamada göster'),
                    value: active,
                    onChanged: (value) => setDialog(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    await _saveTopic(
      AppKnowledgeTopic(
        id:
            existing?.id ??
            FirebaseFirestore.instance
                .collection(FirestoreCollections.knowledgeTopics)
                .doc()
                .id,
        title: title.text.trim(),
        subtitle: subtitle.text.trim(),
        iconUrl: iconUrl.trim(),
        assetPath: existing?.assetPath ?? '',
        colorValue: colorValue,
        questionTopicId: questionTopicId,
        order: existing?.order ?? nextOrder,
        active: active,
      ),
    );
  }

  Future<void> _editQuestion(
    AppKnowledgeQuestion? existing,
    int nextOrder, {
    String? defaultTopicId,
  }) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final views = TextEditingController(text: existing?.views ?? '');
    final answer = TextEditingController(text: existing?.answer ?? '');
    final tips = TextEditingController(
      text: (existing?.tips ?? const []).join('\n'),
    );
    var topicId =
        existing?.topicId ??
        defaultTopicId ??
        (_group == 'topics' ? _allTopicQuestionId : _questionTopicId);
    if (KnowledgeQuestionTopic.all.every((item) => item.id != topicId)) {
      topicId = KnowledgeQuestionTopic.sindirim.id;
    }
    var featured = existing?.featured ?? false;
    var active = existing?.active ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Soru ekle' : 'Soruyu düzenle'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Soru'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey('q-topic-$topicId'),
                    initialValue: topicId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Konu'),
                    items: [
                      for (final item in KnowledgeQuestionTopic.all)
                        DropdownMenuItem(
                          value: item.id,
                          child: Text(item.title),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialog(() => topicId = value);
                    },
                  ),
                  TextField(
                    controller: views,
                    decoration: const InputDecoration(
                      labelText: 'Görüntülenme (ör. 9,8B)',
                    ),
                  ),
                  TextField(
                    controller: answer,
                    maxLines: 8,
                    decoration: const InputDecoration(
                      labelText: 'Yanıt',
                      hintText: 'Boş bırakılırsa uygulamadaki genel metin kullanılır',
                    ),
                  ),
                  TextField(
                    controller: tips,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'İpuçları',
                      hintText: 'Her satıra bir madde',
                    ),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Bilgi Bankası ana sayfasında öne çıkar'),
                    value: featured,
                    onChanged: (value) => setDialog(() => featured = value),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Uygulamada göster'),
                    value: active,
                    onChanged: (value) => setDialog(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    await _saveQuestion(
      AppKnowledgeQuestion(
        id:
            existing?.id ??
            FirebaseFirestore.instance
                .collection(FirestoreCollections.knowledgeQuestions)
                .doc()
                .id,
        topicId: topicId,
        title: title.text.trim(),
        views: views.text.trim(),
        answer: answer.text.trim(),
        tips: tips.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(),
        featured: featured,
        order: existing?.order ?? nextOrder,
        active: active,
      ),
    );
  }

  Future<void> _editArticle(
    AppKnowledgeArticle? existing,
    int nextOrder,
  ) async {
    final title = TextEditingController(text: existing?.title ?? '');
    final summary = TextEditingController(text: existing?.summary ?? '');
    final minutes = TextEditingController(text: '${existing?.minutes ?? 4}');
    final body = TextEditingController(text: existing?.body ?? '');
    final keyPoints = TextEditingController(
      text: (existing?.keyPoints ?? const []).join('\n'),
    );
    var categoryId = existing?.categoryId ?? _articleCategoryId;
    if (!KnowledgeArticleCategories.all.contains(categoryId)) {
      categoryId = KnowledgeArticleCategories.beslenme;
    }
    var imageUrl = existing?.imageUrl ?? '';
    var active = existing?.active ?? true;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(existing == null ? 'Makale ekle' : 'Makaleyi düzenle'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: title,
                    decoration: const InputDecoration(labelText: 'Başlık'),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    key: ValueKey('kb-cat-$categoryId'),
                    initialValue: categoryId,
                    isExpanded: true,
                    decoration: const InputDecoration(labelText: 'Kategori'),
                    items: [
                      for (final id in KnowledgeArticleCategories.all)
                        DropdownMenuItem(
                          value: id,
                          child: Text(KnowledgeArticleCategories.titleOf(id)),
                        ),
                    ],
                    onChanged: (value) {
                      if (value == null) return;
                      setDialog(() => categoryId = value);
                    },
                  ),
                  TextField(
                    controller: summary,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Kısa özet (Genel bakış)',
                    ),
                  ),
                  TextField(
                    controller: minutes,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Okuma süresi (dk)',
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      onPressed: _uploading
                          ? null
                          : () async {
                              final url = await _upload('knowledge_articles');
                              if (url == null) return;
                              setDialog(() => imageUrl = url);
                            },
                      icon: const Icon(Icons.upload_rounded, size: 18),
                      label: const Text('Kapak görseli yükle'),
                    ),
                  ),
                  TextField(
                    controller: keyPoints,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      labelText: 'Önemli noktalar',
                      hintText: 'Her satıra bir madde',
                    ),
                  ),
                  TextField(
                    controller: body,
                    maxLines: 8,
                    decoration: const InputDecoration(labelText: 'Makale metni'),
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Uygulamada göster'),
                    value: active,
                    onChanged: (value) => setDialog(() => active = value),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Vazgeç'),
            ),
            FilledButton(
              onPressed: () {
                if (title.text.trim().isEmpty) return;
                Navigator.pop(ctx, true);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
    if (saved != true) return;
    await _saveArticle(
      AppKnowledgeArticle(
        id:
            existing?.id ??
            FirebaseFirestore.instance
                .collection(FirestoreCollections.knowledgeArticles)
                .doc()
                .id,
        categoryId: categoryId,
        title: title.text.trim(),
        summary: summary.text.trim(),
        minutes: int.tryParse(minutes.text.trim()) ?? existing?.minutes ?? 4,
        imageUrl: imageUrl.trim(),
        assetPath: existing?.assetPath ?? '',
        body: body.text.trim(),
        keyPoints: keyPoints.text
            .split('\n')
            .map((line) => line.trim())
            .where((line) => line.isNotEmpty)
            .toList(),
        order: existing?.order ?? nextOrder,
        active: active,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_seeding) {
      return const Center(child: CircularProgressIndicator());
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        AdminPageHeader(
          title: switch (_group) {
            'questions' => 'Öne Çıkan Sorular',
            'articles' => 'Makaleler',
            _ => 'Tüm Konular',
          },
          subtitle: switch (_group) {
            'questions' =>
              'Sindirim, idrar yolu, alerji gibi konu başlıklarındaki soruları düzenleyin.',
            'articles' =>
              'Beslenme, sağlık, bakım ve aşı makalelerini düzenleyin.',
            _ =>
              'Sindirim, Böbrek gibi bir kart seçin; içindeki soru ve yanıtları düzenleyin.',
          },
          actions: [
            if (_group == 'topics')
              OutlinedButton.icon(
                onPressed: () => _editTopic(null, 0),
                icon: const Icon(Icons.grid_view_rounded, size: 18),
                label: const Text('Yeni konu kartı'),
              ),
            FilledButton.icon(
              onPressed: () {
                if (_group == 'articles') {
                  _editArticle(null, 0);
                } else if (_group == 'questions') {
                  _editQuestion(null, 0);
                } else {
                  _editQuestion(
                    null,
                    0,
                    defaultTopicId: _allTopicQuestionId,
                  );
                }
              },
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text(
                switch (_group) {
                  'articles' => 'Yeni makale',
                  _ => 'Yeni soru',
                },
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _groupChip('topics', 'Tüm Konular'),
            _groupChip('questions', 'Öne Çıkan Sorular'),
            _groupChip('articles', 'Makaleler'),
          ],
        ),
        const SizedBox(height: 16),
        if (_group == 'questions') _buildQuestions()
        else if (_group == 'articles') _buildArticles()
        else _buildTopics(),
      ],
    );
  }

  Widget _groupChip(String value, String label) {
    final selected = _group == value;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _group = value),
      selectedColor: AppColors.selected,
      checkmarkColor: AppColors.primary,
      labelStyle: TextStyle(
        color: selected ? AppColors.primary : AppColors.text,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  Widget _buildTopics() {
    return StreamBuilder<List<AppKnowledgeTopic>>(
      stream: KnowledgeContentRepository.instance.watchTopics(fallback: false),
      builder: (context, topicSnap) {
        final topics = topicSnap.data ?? const <AppKnowledgeTopic>[];
        if (!topicSnap.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (topics.isEmpty) {
          return const AdminPanel(
            padding: EdgeInsets.all(24),
            child: Text('Henüz konu yok.'),
          );
        }
        var selected = topics.first;
        for (final topic in topics) {
          if (topic.id == _allTopicId) {
            selected = topic;
            break;
          }
        }
        return StreamBuilder<List<AppKnowledgeQuestion>>(
          stream: KnowledgeContentRepository.instance.watchQuestions(
            fallback: false,
          ),
          builder: (context, questionSnap) {
            final all = questionSnap.data ?? const <AppKnowledgeQuestion>[];
            if (!questionSnap.hasData) {
              return const Padding(
                padding: EdgeInsets.all(24),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final visible = all
                .where((item) => item.topicId == selected.questionTopicId)
                .toList();
            final sharedTitles = topics
                .where(
                  (topic) =>
                      topic.id != selected.id &&
                      topic.questionTopicId == selected.questionTopicId,
                )
                .map((topic) => topic.title)
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final topic in topics)
                      FilterChip(
                        label: Text(topic.title),
                        selected: selected.id == topic.id,
                        onSelected: (_) => setState(() {
                          _allTopicId = topic.id;
                          _allTopicQuestionId = topic.questionTopicId;
                        }),
                        selectedColor: topic.color.withValues(alpha: 0.16),
                        checkmarkColor: topic.color,
                        labelStyle: TextStyle(
                          color: selected.id == topic.id
                              ? topic.color
                              : AppColors.text,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${selected.title} soruları',
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => _editTopic(selected, topics.length),
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      label: const Text('Kartı düzenle'),
                    ),
                  ],
                ),
                if (sharedTitles.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'Bu sorular ${[selected.title, ...sharedTitles].join(' ve ')} kartlarında ortak gösterilir.',
                      style: const TextStyle(
                        color: AppColors.subText,
                        fontSize: 13,
                      ),
                    ),
                  ),
                _questionsPanel(visible),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildQuestions() {
    return StreamBuilder<List<AppKnowledgeQuestion>>(
      stream: KnowledgeContentRepository.instance.watchQuestions(
        fallback: false,
      ),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <AppKnowledgeQuestion>[];
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final visible = all
            .where((item) => item.topicId == _questionTopicId)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final topic in KnowledgeQuestionTopic.all)
                  FilterChip(
                    label: Text(topic.title),
                    selected: _questionTopicId == topic.id,
                    onSelected: (_) =>
                        setState(() => _questionTopicId = topic.id),
                    selectedColor: topic.color.withValues(alpha: 0.16),
                    checkmarkColor: topic.color,
                    labelStyle: TextStyle(
                      color: _questionTopicId == topic.id
                          ? topic.color
                          : AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            _questionsPanel(visible),
          ],
        );
      },
    );
  }

  Widget _questionsPanel(List<AppKnowledgeQuestion> visible) {
    return AdminPanel(
      child: visible.isEmpty
          ? const Padding(
              padding: EdgeInsets.all(24),
              child: Text('Bu konuda henüz soru yok.'),
            )
          : Column(
              children: [
                for (int i = 0; i < visible.length; i++) ...[
                  if (i > 0)
                    const Divider(height: 1, color: AppColors.border),
                  ListTile(
                    onTap: () => _editQuestion(visible[i], visible.length),
                    title: Text(
                      visible[i].title,
                      style: const TextStyle(fontWeight: FontWeight.w800),
                    ),
                    subtitle: Text(
                      [
                        visible[i].answer.trim().isEmpty
                            ? 'Yanıt yok'
                            : visible[i].answer.trim(),
                        visible[i].views.isEmpty
                            ? 'görüntülenme yok'
                            : '${visible[i].views} görüntülenme',
                        if (visible[i].featured) 'Öne çıkan',
                      ].join(' · '),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AdminStatusChip(
                          label: visible[i].active ? 'Açık' : 'Kapalı',
                          color: visible[i].active
                              ? AppColors.success
                              : AppColors.subText,
                        ),
                        Switch(
                          value: visible[i].active,
                          onChanged: (value) => _saveQuestion(
                            visible[i].copyWith(active: value),
                          ),
                        ),
                        IconButton(
                          onPressed: () async {
                            if (!await _confirmDelete(visible[i].title)) {
                              return;
                            }
                            await FirebaseFirestore.instance
                                .collection(
                                  FirestoreCollections.knowledgeQuestions,
                                )
                                .doc(visible[i].id)
                                .delete();
                          },
                          icon: const Icon(Icons.delete_outline_rounded),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _buildArticles() {
    return StreamBuilder<List<AppKnowledgeArticle>>(
      stream: KnowledgeArticleRepository.instance.watchAll(fallback: false),
      builder: (context, snapshot) {
        final all = snapshot.data ?? const <AppKnowledgeArticle>[];
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final visible = all
            .where((item) => item.categoryId == _articleCategoryId)
            .toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in KnowledgeArticleCategories.all)
                  FilterChip(
                    label: Text(KnowledgeArticleCategories.titleOf(id)),
                    selected: _articleCategoryId == id,
                    onSelected: (_) =>
                        setState(() => _articleCategoryId = id),
                    selectedColor: KnowledgeArticleCategories.colorOf(
                      id,
                    ).withValues(alpha: 0.16),
                    checkmarkColor: KnowledgeArticleCategories.colorOf(id),
                    labelStyle: TextStyle(
                      color: _articleCategoryId == id
                          ? KnowledgeArticleCategories.colorOf(id)
                          : AppColors.text,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            AdminPanel(
              child: visible.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(24),
                      child: Text('Bu kategoride henüz makale yok.'),
                    )
                  : Column(
                      children: [
                        for (int i = 0; i < visible.length; i++) ...[
                          if (i > 0)
                            const Divider(height: 1, color: AppColors.border),
                          ListTile(
                            onTap: () =>
                                _editArticle(visible[i], visible.length),
                            leading: ClipRRect(
                              borderRadius: BorderRadius.circular(10),
                              child: SizedBox(
                                width: 44,
                                height: 44,
                                child: buildProductImage(
                                  visible[i].displayImage,
                                  fit: BoxFit.cover,
                                  errorWidget: ColoredBox(
                                    color: visible[i].categoryColor
                                        .withValues(alpha: 0.16),
                                    child: Icon(
                                      Icons.menu_book_rounded,
                                      color: visible[i].categoryColor,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            title: Text(
                              visible[i].title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            subtitle: Text('${visible[i].minutes} dk okuma'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AdminStatusChip(
                                  label: visible[i].active ? 'Açık' : 'Kapalı',
                                  color: visible[i].active
                                      ? AppColors.success
                                      : AppColors.subText,
                                ),
                                Switch(
                                  value: visible[i].active,
                                  onChanged: (value) => _saveArticle(
                                    visible[i].copyWith(active: value),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () async {
                                    if (!await _confirmDelete(
                                      visible[i].title,
                                    )) {
                                      return;
                                    }
                                    await FirebaseFirestore.instance
                                        .collection(
                                          FirestoreCollections
                                              .knowledgeArticles,
                                        )
                                        .doc(visible[i].id)
                                        .delete();
                                  },
                                  icon: const Icon(
                                    Icons.delete_outline_rounded,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
            ),
          ],
        );
      },
    );
  }
}
