import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';
import 'package:geliyor_app/state/address_store.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/coupon_store.dart';
import 'package:geliyor_app/state/favorite_store.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/health_calendar_store.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/state/pet_store.dart';

/// Üye hesabındaki sepet, favori, adres, dost, mama ve tercihleri yükler.
class UserProfileSync {
  UserProfileSync._();

  static bool _started = false;
  static String? _hydratedUid;
  static String? _listeningUid;
  static Future<void>? _inFlight;
  static StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;

  static void start() {
    if (_started) return;
    _started = true;
    AuthStore.beforeLogout = flush;
    AuthStore.instance.addListener(() {
      unawaited(sync());
    });
    unawaited(sync());
  }

  /// Çıkıştan önce hesabı sunucuya yazar.
  static Future<void> flush() async {
    await Future.wait([
      PetStore.instance.persistNow(),
      FoodTrackingStore.instance.persistNow(),
      CartStore.instance.persistNow(),
      AddressStore.instance.persistNow(),
      FavoriteStore.instance.persistNow(),
      NotificationSettingsStore.instance.persistNow(),
      HealthCalendarStore.instance.sync(),
      OrderStore.instance.persistNow(),
    ]);
    await UserDocPersist.waitForServer();
  }

  static Future<void> _detach() async {
    await _sub?.cancel();
    _sub = null;
    _listeningUid = null;
  }

  static void _listen(String uid) {
    if (_listeningUid == uid && _sub != null) return;
    unawaited(_sub?.cancel());
    _listeningUid = uid;
    _sub = FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid)
        .snapshots()
        .listen((snap) {
          if (AuthStore.instance.uid != uid) return;
          if (_hydratedUid != uid) return;
          if (snap.metadata.isFromCache) return;
          unawaited(
            _applyDoc(
              uid,
              snap.data(),
              includeOrders: false,
              replaceMissing: !snap.metadata.hasPendingWrites,
            ),
          );
        }, onError: (_) {});
  }

  static Future<void> sync({bool force = false}) async {
    final previous = _inFlight;
    if (previous != null) {
      if (!force) return previous;
      await previous;
    }
    final run = _syncBody(force: force);
    _inFlight = run;
    try {
      await run;
    } finally {
      if (identical(_inFlight, run)) _inFlight = null;
    }
  }

  static Future<void> _syncBody({required bool force}) async {
    if (!AuthStore.instance.authReady && !force) return;

    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) {
      final wasLoggedIn = _hydratedUid != null;
      _hydratedUid = null;
      await _detach();
      if (!wasLoggedIn) return;
      PetStore.instance.showGuestPets();
      AddressStore.instance.showGuestAddresses();
      FoodTrackingStore.instance.clearLocal();
      CartStore.instance.clearLocal();
      FavoriteStore.instance.clearLocal();
      OrderStore.instance.clearLocal();
      NotificationSettingsStore.instance.resetLocal();
      HealthCalendarStore.instance.applyRemote(null);
      CouponStore.instance.clearLocal();
      return;
    }
    if (!force &&
        _hydratedUid == uid &&
        PetStore.instance.isBoundTo(uid)) {
      _listen(uid);
      return;
    }

    final mergeGuest = _hydratedUid != uid;
    final guestCart = mergeGuest && !CartStore.instance.hasRemote
        ? List<CartItem>.from(CartStore.instance.items)
        : const <CartItem>[];
    final guestFavorites = mergeGuest && !FavoriteStore.instance.hasRemote
        ? List<FavoriteItem>.from(FavoriteStore.instance.items)
        : const <FavoriteItem>[];

    final snap = await UserDocPersist.fetchUserDoc(uid);
    if (AuthStore.instance.uid != uid) return;
    if (snap == null) {
      _hydratedUid = uid;
      await _mergeGuestAndListen(
        uid: uid,
        guestCart: guestCart,
        guestFavorites: guestFavorites,
      );
      return;
    }

    await _applyDoc(
      uid,
      snap.data(),
      includeOrders: true,
      replaceMissing: true,
    );
    _hydratedUid = uid;
    await _mergeGuestAndListen(
      uid: uid,
      guestCart: guestCart,
      guestFavorites: guestFavorites,
    );
  }

  static Future<void> _mergeGuestAndListen({
    required String uid,
    required List<CartItem> guestCart,
    required List<FavoriteItem> guestFavorites,
  }) async {
    if (guestCart.isNotEmpty) {
      CartStore.instance.mergeGuestItems(guestCart);
      await CartStore.instance.persistNow();
    }
    if (guestFavorites.isNotEmpty) {
      FavoriteStore.instance.mergeGuestItems(guestFavorites);
      await FavoriteStore.instance.persistNow();
    }
    _listen(uid);
  }

  static Future<void> _applyDoc(
    String uid,
    Map<String, dynamic>? data, {
    required bool includeOrders,
    required bool replaceMissing,
  }) async {
    AuthStore.instance.applyProfileDoc(
      data,
      replaceMissing: replaceMissing,
    );
    scheduleMicrotask(AuthStore.instance.notifyProfileUpdated);

    if (replaceMissing || data?.containsKey(UserFields.pets) == true) {
      _applyPets(uid, data);
    }
    if (replaceMissing || data?.containsKey(UserFields.foodTracking) == true) {
      _applyTracking(data);
    }
    if (replaceMissing || data?.containsKey(UserFields.cart) == true) {
      CartStore.instance.applyRemote(
        UserDocPersist.asMapList(data?[UserFields.cart]),
      );
    }
    if (replaceMissing || data?.containsKey(UserFields.favorites) == true) {
      FavoriteStore.instance.applyRemote(
        UserDocPersist.asMapList(data?[UserFields.favorites]),
      );
    }
    if (replaceMissing || data?.containsKey(UserFields.addresses) == true) {
      AddressStore.instance.applyRemote(
        UserDocPersist.asMapList(data?[UserFields.addresses]),
      );
    }
    if (replaceMissing ||
        data?.containsKey(UserFields.notificationSettings) == true) {
      NotificationSettingsStore.instance.applyRemote(
        UserDocPersist.asStringMap(data?[UserFields.notificationSettings]),
      );
    }
    if (data?.containsKey(UserFields.healthCalendar) == true) {
      HealthCalendarStore.instance.applyRemote(
        UserDocPersist.asStringMap(data?[UserFields.healthCalendar]),
      );
    } else {
      HealthCalendarStore.instance.markReady();
    }
    if (replaceMissing ||
        data?.containsKey(UserFields.earnedCouponIds) == true) {
      CouponStore.instance.applyRemoteEarned(data?[UserFields.earnedCouponIds]);
    }
    if (includeOrders) {
      await _applyLastOrder(uid, data);
    }
  }

  static void _applyPets(String uid, Map<String, dynamic>? data) {
    final pets = <PetData>[];
    for (final item in UserDocPersist.asMapList(data?[UserFields.pets])) {
      final pet = PetData.fromMap(item);
      if (pet.name.isNotEmpty) pets.add(pet);
    }
    final index = (data?[UserFields.activePetIndex] as num?)?.toInt() ?? 0;
    PetStore.instance.applyRemote(uid: uid, pets: pets, activeIndex: index);
  }

  static void _applyTracking(Map<String, dynamic>? data) {
    FoodTrackingStore.instance.applyRemote(
      UserDocPersist.asStringMap(data?[UserFields.foodTracking]),
    );
  }

  static Future<void> _applyLastOrder(
    String uid,
    Map<String, dynamic>? data,
  ) async {
    final saved = UserDocPersist.asStringMap(data?[UserFields.lastOrder]);
    if (saved != null) {
      final items = UserDocPersist.asMapList(saved['items'])
          .map(LastOrderItem.fromMap)
          .where((item) => item.title.isNotEmpty)
          .toList();
      if (items.isNotEmpty) {
        OrderStore.instance.applyRemote(
          orderId: (saved['id'] as String?) ?? '',
          orderedAt: DateTime.tryParse((saved['orderedAt'] as String?) ?? '') ??
              DateTime.now(),
          items: items,
        );
        return;
      }
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirestoreCollections.orders)
          .where(OrderFields.userId, isEqualTo: uid)
          .orderBy(OrderFields.createdAt, descending: true)
          .limit(1)
          .get();
      if (snap.docs.isEmpty) {
        OrderStore.instance.clearLocal();
        return;
      }
      final order = snap.docs.first.data();
      final created = order[OrderFields.createdAt];
      final items = UserDocPersist.asMapList(order[OrderFields.items])
          .map(
            (item) => LastOrderItem(
              id: (item['productId'] as String?) ?? '',
              title: (item['title'] as String?) ?? '',
              subtitle: '',
              weight: (item['weight'] as String?) ?? '',
              price: (item['unitPrice'] as num?)?.toDouble() ?? 0,
              oldPrice: 0,
              imagePath: (item['imageUrl'] as String?) ?? '',
              quantity: (item['quantity'] as num?)?.toInt() ?? 1,
            ),
          )
          .where((item) => item.title.isNotEmpty)
          .toList();
      OrderStore.instance.applyRemote(
        orderId: snap.docs.first.id,
        orderedAt: created is Timestamp ? created.toDate() : DateTime.now(),
        items: items,
      );
    } catch (_) {
      OrderStore.instance.clearLocal();
    }
  }
}
