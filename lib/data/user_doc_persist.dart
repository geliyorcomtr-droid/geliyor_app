import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/state/auth_store.dart';

/// `users/{uid}` üzerine merge yazar.
class UserDocPersist {
  UserDocPersist._();

  static DocumentReference<Map<String, dynamic>>? _userRef([String? uid]) {
    final id = uid ?? AuthStore.instance.uid;
    if (id == null || id.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(id);
  }

  static Future<void> merge(Map<String, dynamic> fields) async {
    final ref = _userRef();
    if (ref == null) return;
    try {
      await ref.set({
        ...fields,
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (_) {
      // Offline: local state remains until next save.
    }
  }

  /// Çıkıştan önce kuyruktaki yazıların sunucuya gitmesini bekler.
  static Future<void> waitForServer({
    Duration timeout = const Duration(seconds: 8),
  }) async {
    try {
      await FirebaseFirestore.instance
          .waitForPendingWrites()
          .timeout(timeout);
    } catch (_) {}
  }

  /// Önce sunucudan okur; çevrimdışıysa önbelleğe düşer.
  static Future<DocumentSnapshot<Map<String, dynamic>>?> fetchUserDoc(
    String uid,
  ) async {
    final ref = _userRef(uid);
    if (ref == null) return null;
    try {
      return await ref.get(const GetOptions(source: Source.server));
    } catch (_) {
      try {
        return await ref.get();
      } catch (_) {
        return null;
      }
    }
  }

  static Map<String, dynamic>? asStringMap(dynamic raw) {
    if (raw is Map<String, dynamic>) return raw;
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  static List<Map<String, dynamic>> asMapList(dynamic raw) {
    if (raw is! List) return const [];
    final list = <Map<String, dynamic>>[];
    for (final item in raw) {
      final map = asStringMap(item);
      if (map != null) list.add(map);
    }
    return list;
  }
}
