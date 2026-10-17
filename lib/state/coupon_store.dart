import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/coupon_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/order_store.dart';
import 'package:geliyor_app/utils/courier_fee.dart';

class CouponStore extends ChangeNotifier {
  CouponStore._();
  static final CouponStore instance = CouponStore._();

  final List<AppCoupon> _catalog = [];
  final List<String> _earnedIds = [];
  final Set<String> _usedIds = {};
  AppCoupon? _selected;
  StreamSubscription<List<AppCoupon>>? _sub;
  bool _started = false;

  AppCoupon? get selected => _selected;
  List<String> get earnedIds => List.unmodifiable(_earnedIds);

  bool get _hasPriorOrder =>
      OrderStore.instance.lastOrderId.trim().isNotEmpty;

  bool _isWelcome(AppCoupon coupon) =>
      coupon.id == CouponRepository.welcomeCouponId;

  List<AppCoupon> get usableCoupons {
    final list = _catalog.where((coupon) {
      if (!coupon.active) return false;
      if (coupon.singleUse && _usedIds.contains(coupon.id)) return false;
      if (_isWelcome(coupon) && _hasPriorOrder) return false;
      if (coupon.publicCoupon) return true;
      return _earnedIds.contains(coupon.id);
    }).toList();
    list.sort((a, b) {
      final earnedA = _earnedIds.contains(a.id);
      final earnedB = _earnedIds.contains(b.id);
      if (earnedA != earnedB) return earnedA ? -1 : 1;
      return a.order.compareTo(b.order);
    });
    return list;
  }

  double discountFor(double subtotal) {
    final selected = _selected;
    if (selected == null) return 0;
    if (selected.singleUse && _usedIds.contains(selected.id)) return 0;
    return selected.discountFor(subtotal);
  }

  double payableTotal(double subtotal) {
    final courier = CourierFee.forSubtotal(subtotal);
    final discount = discountFor(subtotal);
    final products = subtotal - discount;
    return (products < 0 ? 0 : products) + courier;
  }

  Future<void> ensureLoaded() async {
    if (_started) return;
    _started = true;
    await CouponRepository.instance.ensureDefaults();
    _sub = CouponRepository.instance.watchActive().listen((list) {
      _catalog
        ..clear()
        ..addAll(list);
      _syncSelected();
      notifyListeners();
    });
    unawaited(refreshUsed());
  }

  /// Tek kullanımlık kupon, bu müşterinin iptal edilmemiş siparişinde varsa kapanır.
  Future<void> refreshUsed() async {
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirestoreCollections.orders)
          .where(OrderFields.userId, isEqualTo: uid)
          .get();
      final ids = <String>{};
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data[OrderFields.status] == OrderStatuses.cancelled) continue;
        final id = (data[OrderFields.couponId] as String?)?.trim() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
      _usedIds
        ..clear()
        ..addAll(ids);
      _syncSelected();
      notifyListeners();
    } catch (_) {}
  }

  /// `true` kullanılmış, `false` kullanılmamış, `null` kontrol edilemedi.
  Future<bool?> redeemedSingleUse(String couponId) async {
    final id = couponId.trim();
    if (id.isEmpty) return false;
    if (_usedIds.contains(id)) return true;
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return null;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(FirestoreCollections.orders)
          .where(OrderFields.userId, isEqualTo: uid)
          .get();
      for (final doc in snap.docs) {
        final data = doc.data();
        if (data[OrderFields.status] == OrderStatuses.cancelled) continue;
        final used = (data[OrderFields.couponId] as String?)?.trim() ?? '';
        if (used.isNotEmpty) _usedIds.add(used);
      }
      _syncSelected();
      notifyListeners();
      return _usedIds.contains(id);
    } catch (_) {
      return null;
    }
  }

  void applyRemoteEarned(List<dynamic>? raw) {
    final ids = <String>[];
    if (raw is List) {
      for (final item in raw) {
        final id = item?.toString().trim() ?? '';
        if (id.isNotEmpty && !ids.contains(id)) ids.add(id);
      }
    }
    final same = ids.length == _earnedIds.length &&
        ids.every(_earnedIds.contains);
    if (same) return;
    _earnedIds
      ..clear()
      ..addAll(ids);
    _syncSelected();
    notifyListeners();
  }

  void clearLocal() {
    _earnedIds.clear();
    _usedIds.clear();
    _selected = null;
    notifyListeners();
  }

  void select(AppCoupon? coupon) {
    _selected = coupon;
    notifyListeners();
  }

  void clearSelected() {
    if (_selected == null) return;
    _selected = null;
    notifyListeners();
  }

  String? applyCode(String rawCode, double subtotal) {
    final code = rawCode.trim().toUpperCase();
    if (code.isEmpty) return 'Kupon kodu girin.';
    AppCoupon? match;
    for (final coupon in _catalog) {
      if (coupon.code == code) {
        match = coupon;
        break;
      }
    }
    if (match == null || !match.active) {
      return 'Kupon bulunamadı.';
    }
    if (_isWelcome(match) && _hasPriorOrder) {
      return 'Hoş geldin kuponu yalnızca ilk siparişte geçerlidir.';
    }
    if (match.singleUse && _usedIds.contains(match.id)) {
      return 'Bu kupon daha önce kullanıldı.';
    }
    if (!match.publicCoupon && !_earnedIds.contains(match.id)) {
      return 'Bu kupon hesabınıza tanımlı değil.';
    }
    final error = match.eligibilityError(subtotal);
    if (error != null) return error;
    _selected = match;
    notifyListeners();
    return null;
  }

  String? applyCoupon(AppCoupon coupon, double subtotal) {
    if (_isWelcome(coupon) && _hasPriorOrder) {
      return 'Hoş geldin kuponu yalnızca ilk siparişte geçerlidir.';
    }
    if (coupon.singleUse && _usedIds.contains(coupon.id)) {
      return 'Bu kupon daha önce kullanıldı.';
    }
    if (!coupon.publicCoupon && !_earnedIds.contains(coupon.id)) {
      return 'Bu kupon hesabınıza tanımlı değil.';
    }
    final error = coupon.eligibilityError(subtotal);
    if (error != null) return error;
    _selected = coupon;
    notifyListeners();
    return null;
  }

  /// İlk siparişte Hoşgeldin 50 kuponunu uygular. Sonraki siparişlerde kaldırır.
  void syncWelcome(double subtotal) {
    final welcome = _welcomeCoupon();
    if (_hasPriorOrder) {
      if (_selected != null && _isWelcome(_selected!)) {
        _selected = null;
        notifyListeners();
      }
      return;
    }
    if (welcome != null &&
        welcome.singleUse &&
        _usedIds.contains(welcome.id)) {
      if (_selected != null && _isWelcome(_selected!)) {
        _selected = null;
        notifyListeners();
      }
      return;
    }
    if (welcome == null || !welcome.active) return;
    if (_selected != null && !_isWelcome(_selected!)) return;
    if (welcome.eligibilityError(subtotal) != null) {
      if (_selected != null && _isWelcome(_selected!)) {
        _selected = null;
        notifyListeners();
      }
      return;
    }
    if (_selected?.id == welcome.id) return;
    _selected = welcome;
    notifyListeners();
  }

  AppCoupon? _welcomeCoupon() {
    for (final coupon in _catalog) {
      if (_isWelcome(coupon)) return coupon;
    }
    for (final coupon in defaultCoupons) {
      if (_isWelcome(coupon)) return coupon;
    }
    return null;
  }

  Future<bool> earnReward() async {
    await ensureLoaded();
    const id = CouponRepository.earnedRewardId;
    if (_earnedIds.contains(id)) return false;
    _earnedIds.add(id);
    notifyListeners();
    await UserDocPersist.merge({
      UserFields.earnedCouponIds: _earnedIds,
    });
    return true;
  }

  Future<void> onOrderPlaced() async {
    final used = _selected;
    _selected = null;
    if (used != null && used.singleUse) {
      _usedIds.add(used.id);
      _earnedIds.remove(used.id);
      await UserDocPersist.merge({
        UserFields.earnedCouponIds: _earnedIds,
      });
    }
    notifyListeners();
  }

  void _syncSelected() {
    final current = _selected;
    if (current == null) return;
    if (current.singleUse && _usedIds.contains(current.id)) {
      _selected = null;
      return;
    }
    AppCoupon? fresh;
    for (final coupon in usableCoupons) {
      if (coupon.id == current.id) {
        fresh = coupon;
        break;
      }
    }
    _selected = fresh;
  }
}
