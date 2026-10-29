import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

class EnlerCard {
  const EnlerCard({
    required this.id,
    required this.title,
    required this.imageUrl,
    required this.iconUrl,
    required this.assetPath,
  });

  final String id;
  final String title;
  final String imageUrl;

  /// Ürünler sayfasındaki yuvarlak ikon. Boşsa [assetPath] kullanılır.
  final String iconUrl;
  final String assetPath;

  List<String> get lines {
    final raw = title.trim();
    if (raw.contains('\n')) {
      final parts = raw.split('\n').map((line) => line.trim()).toList();
      final first = parts.isEmpty ? '' : parts.first;
      final rest = parts.skip(1).where((line) => line.isNotEmpty).join(' ');
      return [first, rest];
    }
    final space = raw.indexOf(' ');
    if (space <= 0) return [raw, ''];
    return [raw.substring(0, space).trim(), raw.substring(space + 1).trim()];
  }

  String get singleLine => lines.where((line) => line.isNotEmpty).join(' ');

  EnlerCard copyWith({String? title, String? imageUrl, String? iconUrl}) {
    return EnlerCard(
      id: id,
      title: title ?? this.title,
      imageUrl: imageUrl ?? this.imageUrl,
      iconUrl: iconUrl ?? this.iconUrl,
      assetPath: assetPath,
    );
  }
}

class EnlerRepository extends ChangeNotifier {
  EnlerRepository._();
  static final EnlerRepository instance = EnlerRepository._();

  static const sevilenler = 'sevilenler';
  static const lezzetli = 'lezzetli';
  static const saglikli = 'saglikli';

  /// Ana sayfa kutusu. Boy × en.
  static const boxHeight = 132.0;
  static const boxWidth = 120.0;

  /// Yüklenen dosya, kutunun 3 katı. Boy × en.
  static const uploadHeight = 396;
  static const uploadWidth = 360;

  /// Ürünler sayfasındaki yuvarlak ikon.
  static const iconSize = 48.0;

  static const defaults = <EnlerCard>[
    EnlerCard(
      id: sevilenler,
      title: 'En\nSevilenler',
      imageUrl: '',
      iconUrl: '',
      assetPath: 'assets/images/en_sevilenler.jpg',
    ),
    EnlerCard(
      id: lezzetli,
      title: 'En\nLezzetli',
      imageUrl: '',
      iconUrl: '',
      assetPath: 'assets/images/en_lezzetli.jpg',
    ),
    EnlerCard(
      id: saglikli,
      title: 'En\nSağlıklı',
      imageUrl: '',
      iconUrl: '',
      assetPath: 'assets/images/en_saglikli.jpg',
    ),
  ];

  bool _started = false;
  List<EnlerCard> _cards = defaults;

  List<EnlerCard> get cards => _cards;

  DocumentReference<Map<String, dynamic>> get _doc => FirebaseFirestore.instance
      .collection(FirestoreCollections.settings)
      .doc(SettingsDocs.enler);

  void startListening() {
    if (_started) return;
    _started = true;
    _doc.snapshots().listen(
      (snap) {
        _cards = _fromMap(snap.data());
        notifyListeners();
      },
      onError: (Object error, StackTrace stack) {
        debugPrint('Enler okunamadı: $error\n$stack');
      },
    );
  }

  Future<void> save(List<EnlerCard> cards) {
    final byId = {for (final card in cards) card.id: card};
    return _doc.set({
      EnlerFields.items: [
        for (final base in defaults)
          {
            EnlerFields.id: base.id,
            EnlerFields.title: (byId[base.id]?.title ?? base.title).trim(),
            EnlerFields.imageUrl: (byId[base.id]?.imageUrl ?? '').trim(),
            EnlerFields.iconUrl: (byId[base.id]?.iconUrl ?? '').trim(),
          },
      ],
      EnlerFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  List<EnlerCard> _fromMap(Map<String, dynamic>? data) {
    final raw = data?[EnlerFields.items];
    final saved = <String, Map<String, dynamic>>{};
    if (raw is List) {
      for (final item in raw.whereType<Map>()) {
        final map = Map<String, dynamic>.from(item);
        final id = (map[EnlerFields.id] as String?)?.trim() ?? '';
        if (id.isNotEmpty) saved[id] = map;
      }
    }
    return [
      for (final base in defaults)
        EnlerCard(
          id: base.id,
          title: ((saved[base.id]?[EnlerFields.title] as String?) ?? '')
                  .trim()
                  .isEmpty
              ? base.title
              : (saved[base.id]![EnlerFields.title] as String).trim(),
          imageUrl:
              ((saved[base.id]?[EnlerFields.imageUrl] as String?) ?? '').trim(),
          iconUrl:
              ((saved[base.id]?[EnlerFields.iconUrl] as String?) ?? '').trim(),
          assetPath: base.assetPath,
        ),
    ];
  }
}
