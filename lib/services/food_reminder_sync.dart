import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/services/food_remaining_estimator.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/food_tracking_store.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/state/pet_store.dart';

/// Mama bitiş tarihini Firestore’a yazar; günlük Cloud Function buna bakarak bildirir.
class FoodReminderSync {
  FoodReminderSync._();

  static bool _started = false;
  static bool _loading = false;
  static String? _hydratedUid;
  static Timer? _debounce;

  static void start() {
    if (_started) return;
    _started = true;
    void schedule() {
      if (_loading) return;
      _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 700), sync);
    }

    AuthStore.instance.addListener(schedule);
    FoodTrackingStore.instance.addListener(schedule);
    NotificationSettingsStore.instance.addListener(schedule);
    PetStore.instance.addListener(schedule);
    unawaited(sync());
  }

  static DocumentReference<Map<String, dynamic>>? _doc(String? uid) {
    if (uid == null || uid.isEmpty) return null;
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(uid);
  }

  static const _map = 'food_reminder';

  static String _ymd(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static Future<void> sync() async {
    if (_loading) return;
    final uid = AuthStore.instance.uid;
    final ref = _doc(uid);
    if (ref == null) {
      _hydratedUid = null;
      return;
    }
    if (!PetStore.instance.isBoundTo(uid)) return;
    if (_hydratedUid != uid) {
      await _hydratePrefs(ref);
      _hydratedUid = uid;
    }

    final settings = NotificationSettingsStore.instance;
    final estimate = FoodRemainingEstimator.compute();
    if (!settings.canSendFoodReminder || estimate == null) {
      await ref.set({
        _map: {
          FoodReminderFields.enabled: false,
          FoodReminderFields.prefsEnabled: settings.smartFoodReminderEnabled,
          FoodReminderFields.daysBefore: settings.effectiveSmartFoodReminderDays,
          FoodReminderFields.autoOrderEnabled: false,
        },
        UserFields.updatedAt: FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      return;
    }

    final today = _dateOnly(DateTime.now());
    final end = today.add(Duration(days: estimate.remainingDays));
    var notifyAt = end.subtract(
      Duration(days: settings.effectiveSmartFoodReminderDays),
    );
    if (notifyAt.isAfter(end)) {
      notifyAt = end;
    }
    if (notifyAt.isBefore(today)) {
      notifyAt = today;
    }
    final reminderDate = _ymd(notifyAt);

    var autoNotifyAt = end.subtract(
      Duration(days: settings.autoOrderDaysBefore.clamp(1, 30)),
    );
    if (autoNotifyAt.isAfter(end)) autoNotifyAt = end;
    if (autoNotifyAt.isBefore(today)) autoNotifyAt = today;
    final autoOrderDate = _ymd(autoNotifyAt);
    final autoOrderEnabled =
        settings.canSendOrderNotifications && estimate.remainingDays >= 0;

    final existing = await ref.get();
    final prev = existing.data()?[_map] as Map<String, dynamic>?;
    final prevDate = prev?[FoodReminderFields.reminderDate] as String?;
    final prevSent = prev?[FoodReminderFields.sentFor] as String?;
    final sentFor = prevDate == reminderDate ? (prevSent ?? '') : '';
    final prevAutoDate = prev?[FoodReminderFields.autoOrderDate] as String?;
    final prevAutoSent = prev?[FoodReminderFields.autoOrderSentFor] as String?;
    final autoOrderSentFor =
        prevAutoDate == autoOrderDate ? (prevAutoSent ?? '') : '';

    await ref.set({
      _map: {
        FoodReminderFields.enabled: true,
        FoodReminderFields.prefsEnabled: settings.smartFoodReminderEnabled,
        FoodReminderFields.daysBefore: settings.effectiveSmartFoodReminderDays,
        FoodReminderFields.reminderDate: reminderDate,
        FoodReminderFields.estimatedEndDate: _ymd(end),
        FoodReminderFields.remainingDays: estimate.remainingDays,
        FoodReminderFields.petName: estimate.shareLabel,
        FoodReminderFields.foodTitle: estimate.foodTitle,
        FoodReminderFields.sentFor: sentFor,
        FoodReminderFields.autoOrderEnabled: autoOrderEnabled,
        FoodReminderFields.autoOrderDate: autoOrderDate,
        FoodReminderFields.autoOrderSentFor: autoOrderSentFor,
      },
      UserFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> _hydratePrefs(
    DocumentReference<Map<String, dynamic>> ref,
  ) async {
    if (AuthStore.instance.uid == null) return;
    try {
      final snap = await ref.get();
      final data = snap.data()?[_map] as Map<String, dynamic>?;
      if (data == null) return;
      final days = (data[FoodReminderFields.daysBefore] as num?)?.toInt();
      final prefsEnabled = data[FoodReminderFields.prefsEnabled] as bool?;
      _loading = true;
      final store = NotificationSettingsStore.instance;
      if (prefsEnabled != null) {
        store.smartFoodReminderEnabled = prefsEnabled;
      }
      if (days != null && days > 0) {
        if (days == 1 || days == 3 || days == 5) {
          store.smartFoodReminderDays = days;
        } else {
          store.smartFoodReminderDays = -1;
          store.customSmartFoodReminderDays = days.clamp(1, 30);
        }
      }
    } catch (_) {
      // Offline: local defaults.
    } finally {
      _loading = false;
    }
  }
}
