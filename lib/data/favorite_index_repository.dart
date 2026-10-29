import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/state/auth_store.dart';

/// Üyelerin favorilediği ürünlerin herkese açık dizini.
class FavoriteIndexRepository extends ChangeNotifier {
  FavoriteIndexRepository._();
  static final FavoriteIndexRepository instance = FavoriteIndexRepository._();

  bool _started = false;
  Set<String> _productIds = const {};

  Set<String> get productIds => _productIds;

  void startListening() {
    if (_started) return;
    _started = true;
    FirebaseFirestore.instance
        .collectionGroup('fav_users')
        .snapshots()
        .listen(
          (snap) {
            final counts = <String, int>{};
            for (final doc in snap.docs) {
              final productId = doc.reference.parent.parent?.id.trim() ?? '';
              if (productId.isEmpty) continue;
              counts[productId] = (counts[productId] ?? 0) + 1;
            }
            _productIds = counts.keys.toSet();
            notifyListeners();
          },
          onError: (Object error, StackTrace stack) {
            debugPrint('Favori dizini okunamadı: $error\n$stack');
          },
        );
  }

  static Future<void> syncUser({
    required Set<String> before,
    required Set<String> after,
  }) async {
    final uid = AuthStore.instance.uid?.trim() ?? '';
    if (uid.isEmpty) return;
    final added = after.difference(before);
    final removed = before.difference(after);
    if (added.isEmpty && removed.isEmpty) return;
    final root = FirebaseFirestore.instance.collection(
      FirestoreCollections.favoriteMembers,
    );
    try {
      for (final id in added) {
        await root.doc(id).collection('fav_users').doc(uid).set({
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }
      for (final id in removed) {
        await root.doc(id).collection('fav_users').doc(uid).delete();
      }
    } catch (error) {
      debugPrint('Favori dizini yazılamadı: $error');
    }
  }
}
