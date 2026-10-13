import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/health_product_groups.dart';
import 'package:geliyor_app/data/pet_life_stage.dart';
import 'package:geliyor_app/data/product_repository.dart';

class AdminSubCategory {
  const AdminSubCategory({
    required this.id,
    required this.title,
    this.subtitle = '',
    this.imageUrl = '',
    this.order = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final String imageUrl;
  final int order;

  factory AdminSubCategory.fromMap(Map<String, dynamic> map) {
    return AdminSubCategory(
      id: (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      subtitle: (map['subtitle'] as String?) ?? '',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      order: (map['order'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title.trim(),
    'subtitle': subtitle.trim(),
    'imageUrl': imageUrl.trim(),
    'order': order,
  };

  AdminSubCategory copyWith({
    String? id,
    String? title,
    String? subtitle,
    String? imageUrl,
    int? order,
  }) {
    return AdminSubCategory(
      id: id ?? this.id,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      imageUrl: imageUrl ?? this.imageUrl,
      order: order ?? this.order,
    );
  }
}

class AdminMainCategory {
  const AdminMainCategory({
    required this.id,
    required this.title,
    this.imageUrl = '',
    this.order = 0,
    this.active = true,
    this.subcategories = const [],
  });

  final String id;
  final String title;
  final String imageUrl;
  final int order;
  final bool active;
  final List<AdminSubCategory> subcategories;

  factory AdminMainCategory.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final d = doc.data() ?? {};
    final raw = d[CategoryFields.subcategories];
    final subs = <AdminSubCategory>[];
    if (raw is List) {
      for (final item in raw) {
        if (item is Map) {
          subs.add(AdminSubCategory.fromMap(Map<String, dynamic>.from(item)));
        }
      }
      subs.sort((a, b) => a.order.compareTo(b.order));
    }
    return AdminMainCategory(
      id: doc.id,
      title: (d[CategoryFields.title] as String?) ?? doc.id,
      imageUrl: (d[CategoryFields.imageUrl] as String?) ?? '',
      order: (d[CategoryFields.order] as num?)?.toInt() ?? 0,
      active: d[CategoryFields.active] as bool? ?? true,
      subcategories: subs,
    );
  }

  Map<String, dynamic> toMap() => {
    CategoryFields.id: id,
    CategoryFields.title: title.trim(),
    CategoryFields.imageUrl: imageUrl.trim(),
    CategoryFields.order: order,
    CategoryFields.active: active,
    CategoryFields.subcategories: subcategories.map((e) => e.toMap()).toList(),
    CategoryFields.updatedAt: FieldValue.serverTimestamp(),
  };
}

/// Uygulamadaki varsayılan 3 ana kategori + altlar.
const defaultAdminCategories = <AdminMainCategory>[
  AdminMainCategory(
    id: 'cat',
    title: 'Kedi',
    order: 0,
    subcategories: [
      AdminSubCategory(
        id: 'cat-mama',
        title: 'Yetişkin',
        subtitle: 'Yetişkin kedi mamaları ve ürünleri',
        order: 0,
      ),
      AdminSubCategory(
        id: 'cat-yavru',
        title: 'Yavru',
        subtitle: 'Yavru kedi mamaları ve ürünleri',
        order: 1,
      ),
      AdminSubCategory(
        id: 'cat-kum',
        title: 'Kum',
        subtitle: 'Topaklanan ve kokusuz kumlar',
        order: 2,
      ),
      AdminSubCategory(
        id: 'cat-odul',
        title: 'Ödül',
        subtitle: 'Eğitim ve ödül atıştırmalıkları',
        order: 3,
      ),
      AdminSubCategory(
        id: 'cat-bakim',
        title: 'Bakım',
        subtitle: 'Şampuan, temizlik ve hijyen',
        order: 4,
      ),
      AdminSubCategory(
        id: 'cat-oyuncak',
        title: 'Oyuncak',
        subtitle: 'Tüy, top ve interaktif oyuncaklar',
        order: 5,
      ),
      AdminSubCategory(
        id: 'cat-vitamin',
        title: HealthProductGroup.vitaminTitle,
        subtitle: 'Bağışıklık ve enerji desteği',
        order: 7,
      ),
      AdminSubCategory(
        id: 'cat-takviye',
        title: HealthProductGroup.supplementTitle,
        subtitle: 'Ek besin ve destek ürünleri',
        order: 8,
      ),
      AdminSubCategory(
        id: 'cat-malt',
        title: HealthProductGroup.maltTitle,
        subtitle: 'Tüy yumağı ve sindirim',
        order: 9,
      ),
      AdminSubCategory(
        id: 'cat-tasima',
        title: 'Taşıma',
        subtitle: 'Taşıma çantası ve ekipmanları',
        order: 10,
      ),
    ],
  ),
  AdminMainCategory(
    id: 'dog',
    title: 'Köpek',
    order: 1,
    subcategories: [
      AdminSubCategory(
        id: 'dog-mama',
        title: 'Yetişkin',
        subtitle: 'Yetişkin köpek mamaları ve ürünleri',
        order: 0,
      ),
      AdminSubCategory(
        id: 'dog-yavru',
        title: 'Yavru',
        subtitle: 'Yavru köpek mamaları ve ürünleri',
        order: 1,
      ),
      AdminSubCategory(
        id: 'dog-mini',
        title: 'Mini Irk',
        subtitle: 'Mini ırk yetişkin köpek ürünleri',
        order: 2,
      ),
      AdminSubCategory(
        id: 'dog-mini-yavru',
        title: 'Mini Irk Yavru',
        subtitle: 'Mini ırk yavru köpek mamaları ve ürünleri',
        order: 3,
      ),
      AdminSubCategory(
        id: 'dog-odul',
        title: 'Ödül',
        subtitle: 'Eğitim ve ödül atıştırmalıkları',
        order: 4,
      ),
      AdminSubCategory(
        id: 'dog-tasma',
        title: 'Tasma',
        subtitle: 'Tasma, kayış ve gezi ürünleri',
        order: 5,
      ),
      AdminSubCategory(
        id: 'dog-oyuncak',
        title: 'Oyuncak',
        subtitle: 'Çiğneme ve oyun ürünleri',
        order: 6,
      ),
      AdminSubCategory(
        id: 'dog-bakim',
        title: 'Bakım',
        subtitle: 'Şampuan ve bakım ürünleri',
        order: 7,
      ),
      AdminSubCategory(
        id: 'dog-yatak',
        title: 'Yatak',
        subtitle: 'Yatak ve dinlenme ürünleri',
        order: 8,
      ),
    ],
  ),
  AdminMainCategory(
    id: 'smart',
    title: 'Akıllı Pet',
    order: 2,
    subcategories: [
      AdminSubCategory(
        id: 'smart-mama',
        title: 'Mama Kabı',
        subtitle: 'Akıllı mama kapları',
        order: 0,
      ),
      AdminSubCategory(
        id: 'smart-su',
        title: 'Su Kabı',
        subtitle: 'Akıllı su kapları',
        order: 1,
      ),
      AdminSubCategory(
        id: 'smart-takip',
        title: 'Takip',
        subtitle: 'GPS ve takip cihazları',
        order: 2,
      ),
      AdminSubCategory(
        id: 'smart-kamera',
        title: 'Kamera',
        subtitle: 'Pet kameraları',
        order: 3,
      ),
      AdminSubCategory(
        id: 'smart-tuvalet',
        title: 'Tuvalet',
        subtitle: 'Akıllı tuvalet ürünleri',
        order: 4,
      ),
      AdminSubCategory(
        id: 'smart-bakim',
        title: 'Bakım',
        subtitle: 'Akıllı bakım cihazları',
        order: 5,
      ),
    ],
  ),
];

class CategoryRepository {
  CategoryRepository._();
  static final instance = CategoryRepository._();

  final _col = FirebaseFirestore.instance.collection(
    FirestoreCollections.categories,
  );

  List<AdminMainCategory> _cached = const [];
  bool _ready = false;
  StreamSubscription<List<AdminMainCategory>>? _watch;

  bool get ready => _ready;
  List<AdminMainCategory> get cached => _cached;

  /// Uygulama açılır açılmaz dinler; pet market eski ikona düşmeden güncel görseli kullanır.
  void startListening() {
    _watch ??= watchAll().listen((_) {});
  }

  Stream<List<AdminMainCategory>> watchAll() {
    return _col.orderBy(CategoryFields.order).snapshots().map((snap) {
      final items = snap.docs.map(AdminMainCategory.fromDoc).toList();
      _cached = List<AdminMainCategory>.unmodifiable(items);
      _ready = true;
      return _cached;
    });
  }

  Future<List<AdminMainCategory>> fetchAll() async {
    final snap = await _col.orderBy(CategoryFields.order).get();
    return snap.docs.map(AdminMainCategory.fromDoc).toList();
  }

  Future<void> ensureDefaults() async {
    final snap = await _col.get();
    if (snap.docs.isEmpty) {
      final batch = FirebaseFirestore.instance.batch();
      for (final cat in defaultAdminCategories) {
        batch.set(_col.doc(cat.id), cat.toMap());
      }
      await batch.commit();
      await ProductRepository.instance.migrateMamaCategoryToYetiskin();
      return;
    }

    final existing = {
      for (final doc in snap.docs) doc.id: AdminMainCategory.fromDoc(doc),
    };
    for (final cat in defaultAdminCategories) {
      final current = existing[cat.id];
      if (current == null) {
        await saveMain(cat);
        continue;
      }
      var subs = [...current.subcategories];
      var changed = false;

      if (cat.id == 'cat' || cat.id == 'dog') {
        for (var i = 0; i < subs.length; i++) {
          final title = PetLifeStage.normalizeTitle(subs[i].title);
          final isAdultSlot =
              subs[i].id == '${cat.id}-mama' || title == 'mama';
          if (isAdultSlot && subs[i].title.trim() != PetLifeStage.catAdult) {
            subs[i] = subs[i].copyWith(title: PetLifeStage.catAdult);
            changed = true;
          }
        }
      }

      final defaultOrderById = {
        for (final sub in cat.subcategories) sub.id: sub.order,
      };
      final defaultOrderByTitle = {
        for (final sub in cat.subcategories)
          PetLifeStage.normalizeTitle(sub.title): sub.order,
      };
      for (var i = 0; i < subs.length; i++) {
        final order = defaultOrderById[subs[i].id] ??
            defaultOrderByTitle[PetLifeStage.normalizeTitle(subs[i].title)];
        if (order != null && subs[i].order != order) {
          subs[i] = subs[i].copyWith(order: order);
          changed = true;
        }
      }
      subs.sort((a, b) => a.order.compareTo(b.order));

      final knownIds = subs.map((sub) => sub.id).toSet();
      final knownTitles = {
        for (final sub in subs) PetLifeStage.normalizeTitle(sub.title),
      };
      final missing = [
        for (final sub in cat.subcategories)
          if (!knownIds.contains(sub.id) &&
              !knownTitles.contains(PetLifeStage.normalizeTitle(sub.title)))
            sub,
      ];
      if (missing.isNotEmpty) {
        subs = [...subs, ...missing];
        changed = true;
      }
      if (changed) await saveSubs(cat.id, subs);
    }

    await ProductRepository.instance.migrateMamaCategoryToYetiskin();
  }

  Future<void> saveMain(AdminMainCategory category) async {
    await _col.doc(category.id).set(category.toMap(), SetOptions(merge: true));
  }

  Future<void> deleteMain(String id) async {
    await _col.doc(id).delete();
  }

  Future<void> saveSubs(String mainId, List<AdminSubCategory> subs) async {
    await _col.doc(mainId).set({
      CategoryFields.subcategories: subs.map((e) => e.toMap()).toList(),
      CategoryFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}
