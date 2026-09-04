import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/coupon_repository.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';
import 'package:geliyor_app/utils/courier_fee.dart';

class CouponStore extends ChangeNotifier {
  CouponStore._();
  static final CouponStore instance = CouponStore._();

  final List<AppCoupon> _catalog = [];
  final List<String> _earnedIds = [];
  AppCoupon? _selected;
  StreamSubscription<List<AppCoupon>>? _sub;
  bool _started = false;

  AppCoupon? get selected => _selected;
  List<String> get earnedIds => List.unmodifiable(_earnedIds);

  List<AppCoupon> get usableCoupons {
    final list = _catalog.where((coupon) {
      if (!coupon.active) return false;
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

  double discountFor(double subtotal) =>
      _selected?.discountFor(subtotal) ?? 0;

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
    if (!coupon.publicCoupon && !_earnedIds.contains(coupon.id)) {
      return 'Bu kupon hesabınıza tanımlı değil.';
    }
    final error = coupon.eligibilityError(subtotal);
    if (error != null) return error;
    _selected = coupon;
    notifyListeners();
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
    if (used != null &&
        used.singleUse &&
        _earnedIds.contains(used.id)) {
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
