import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';

/// Uygulama genelinde bildirim tercihlerini tek noktadan yönetir.
class NotificationSettingsStore extends ChangeNotifier {
  NotificationSettingsStore._();

  static final NotificationSettingsStore instance = NotificationSettingsStore._();

  static const reminderTimes = ['09:00', '13:00', '17:00', '20:00'];
  static const reminderTimeLabels = ['Sabah', 'Öğle', 'Akşam', 'Gece'];

  bool allEnabled = true;

  final Map<String, bool> preferences = {
    'orders': true,
    'campaigns': true,
    'products': true,
    'petWorld': true,
    'points': true,
    'reminders': true,
  };

  final Map<String, bool> channels = {
    'inApp': true,
    'email': true,
    'sms': true,
  };

  /// Akıllı Plan — mama bitmeden kaç gün önce hatırlatma.
  bool smartFoodReminderEnabled = true;
  int smartFoodReminderDays = 3;
  int customSmartFoodReminderDays = 7;

  /// Otomatik sipariş bildirimleri ve sipariş oluşturma zamanı.
  bool autoOrderNotifications = true;
  int autoOrderDaysBefore = 3;

  /// Pet E-Nabız / sağlık hatırlatmaları.
  bool healthRemindersEnabled = true;
  int healthReminderDaysBefore = 3;
  int healthReminderTimeIndex = 3;

  /// Aşı takvimi ana anahtarı.
  bool vaccineCalendarEnabled = true;
  bool _suppressPersist = false;
  bool _hasRemote = false;

  int get effectiveSmartFoodReminderDays => smartFoodReminderDays == -1
      ? customSmartFoodReminderDays
      : smartFoodReminderDays;

  bool get canSendInApp => allEnabled && (channels['inApp'] ?? true);

  bool categoryEnabled(String id) =>
      allEnabled && (preferences[id] ?? true);

  bool get canSendFoodReminder =>
      categoryEnabled('reminders') && smartFoodReminderEnabled;

  bool get canSendHealthReminder =>
      categoryEnabled('petWorld') &&
      categoryEnabled('reminders') &&
      healthRemindersEnabled;

  bool get canSendOrderNotifications =>
      categoryEnabled('orders') && autoOrderNotifications;

  String get foodReminderSummary {
    if (!canSendFoodReminder) {
      return 'Mama hatırlatma bildirimleri kapalı.';
    }
    return 'Mama bitmeden $effectiveSmartFoodReminderDays gün önce bildirim gönderilir.';
  }

  String get autoOrderDaysSummary =>
      'Tahmini bitiş tarihinden $autoOrderDaysBefore gün önce sipariş zamanı bildirimi gönderilir.';

  String get autoOrderNotificationSummary {
    if (!canSendOrderNotifications) {
      return 'Sipariş ve kurye bildirimleri kapalı.';
    }
    return 'Sipariş, kurye ve durum güncellemeleri için bildirim alırsınız.';
  }

  DateTime notificationDateForDue(DateTime dueDate, {int? daysBefore}) {
    final days = daysBefore ?? healthReminderDaysBefore;
    final due = DateTime(dueDate.year, dueDate.month, dueDate.day);
    return due.subtract(Duration(days: days));
  }

  DateTime? foodReminderNotifyDate(DateTime estimatedEndDate) {
    if (!canSendFoodReminder) return null;
    return notificationDateForDue(
      estimatedEndDate,
      daysBefore: effectiveSmartFoodReminderDays,
    );
  }

  String healthNotificationLine(DateTime dueDate) {
    if (!canSendHealthReminder) {
      return 'Sağlık hatırlatma bildirimleri kapalı.';
    }
    final notifyAt = notificationDateForDue(dueDate);
    final timeIndex =
        healthReminderTimeIndex.clamp(0, reminderTimes.length - 1);
    final time = reminderTimes[timeIndex];
    return 'Bildirim: ${_formatDayMonth(notifyAt)} $time '
        '($healthReminderDaysBefore gün önce)';
  }

  String _formatDayMonth(DateTime date) {
    const months = [
      'Oca',
      'Şub',
      'Mar',
      'Nis',
      'May',
      'Haz',
      'Tem',
      'Ağu',
      'Eyl',
      'Eki',
      'Kas',
      'Ara',
    ];
    return '${date.day} ${months[date.month - 1]}';
  }

  void setAllEnabled(bool value) {
    allEnabled = value;
    if (!value) {
      for (final key in preferences.keys) {
        preferences[key] = false;
      }
      for (final key in channels.keys) {
        channels[key] = false;
      }
    } else {
      for (final key in preferences.keys) {
        preferences[key] = true;
      }
      channels['inApp'] = true;
      channels['email'] = true;
      channels['sms'] = true;
    }
    notifyListeners();
    _persist();
  }

  void setPreference(String id, bool value) {
    preferences[id] = value;
    _syncAllEnabledFromChildren();
    notifyListeners();
    _persist();
  }

  void setChannel(String id, bool value) {
    channels[id] = value;
    _syncAllEnabledFromChildren();
    notifyListeners();
    _persist();
  }

  void setSmartFoodReminderEnabled(bool value) {
    smartFoodReminderEnabled = value;
    notifyListeners();
    _persist();
  }

  void setSmartFoodReminderDays(int days) {
    smartFoodReminderDays = days;
    notifyListeners();
    _persist();
  }

  void setCustomSmartFoodReminderDays(int days) {
    customSmartFoodReminderDays = days.clamp(1, 30);
    notifyListeners();
    _persist();
  }

  void setAutoOrderNotifications(bool value) {
    autoOrderNotifications = value;
    notifyListeners();
    _persist();
  }

  void setAutoOrderDaysBefore(int days) {
    autoOrderDaysBefore = days;
    notifyListeners();
    _persist();
  }

  void setHealthRemindersEnabled(bool value) {
    healthRemindersEnabled = value;
    notifyListeners();
    _persist();
  }

  void setHealthReminderDaysBefore(int days) {
    healthReminderDaysBefore = days;
    notifyListeners();
    _persist();
  }

  void setHealthReminderTimeIndex(int index) {
    healthReminderTimeIndex =
        index.clamp(0, reminderTimes.length - 1);
    notifyListeners();
    _persist();
  }

  void setVaccineCalendarEnabled(bool value) {
    vaccineCalendarEnabled = value;
    notifyListeners();
    _persist();
  }

  void applyRemote(Map<String, dynamic>? data) {
    _suppressPersist = true;
    _hasRemote = true;
    if (data != null) {
      allEnabled = data['allEnabled'] as bool? ?? allEnabled;
      _applyBoolMap(preferences, data['preferences']);
      _applyBoolMap(channels, data['channels']);
      smartFoodReminderEnabled =
          data['smartFoodReminderEnabled'] as bool? ?? smartFoodReminderEnabled;
      smartFoodReminderDays =
          (data['smartFoodReminderDays'] as num?)?.toInt() ??
          smartFoodReminderDays;
      customSmartFoodReminderDays =
          (data['customSmartFoodReminderDays'] as num?)?.toInt() ??
          customSmartFoodReminderDays;
      autoOrderNotifications =
          data['autoOrderNotifications'] as bool? ?? autoOrderNotifications;
      autoOrderDaysBefore =
          (data['autoOrderDaysBefore'] as num?)?.toInt() ?? autoOrderDaysBefore;
      healthRemindersEnabled =
          data['healthRemindersEnabled'] as bool? ?? healthRemindersEnabled;
      healthReminderDaysBefore =
          (data['healthReminderDaysBefore'] as num?)?.toInt() ??
          healthReminderDaysBefore;
      healthReminderTimeIndex =
          (data['healthReminderTimeIndex'] as num?)?.toInt() ??
          healthReminderTimeIndex;
      vaccineCalendarEnabled =
          data['vaccineCalendarEnabled'] as bool? ?? vaccineCalendarEnabled;
      final version = (data['channelsVersion'] as num?)?.toInt() ?? 0;
      if (version < 2 && allEnabled) {
        channels['inApp'] = true;
        channels['email'] = true;
        channels['sms'] = true;
      }
    }
    _suppressPersist = false;
    notifyListeners();
    if (data != null && ((data['channelsVersion'] as num?)?.toInt() ?? 0) < 2) {
      _persist();
    }
  }

  void resetLocal() {
    _suppressPersist = true;
    _hasRemote = false;
    allEnabled = true;
    for (final key in preferences.keys) {
      preferences[key] = true;
    }
    channels['inApp'] = true;
    channels['email'] = true;
    channels['sms'] = true;
    smartFoodReminderEnabled = true;
    smartFoodReminderDays = 3;
    customSmartFoodReminderDays = 7;
    autoOrderNotifications = true;
    autoOrderDaysBefore = 3;
    healthRemindersEnabled = true;
    healthReminderDaysBefore = 3;
    healthReminderTimeIndex = 3;
    vaccineCalendarEnabled = true;
    _suppressPersist = false;
    notifyListeners();
  }

  void _applyBoolMap(Map<String, bool> target, dynamic raw) {
    if (raw is! Map) return;
    for (final entry in raw.entries) {
      final key = entry.key.toString();
      if (!target.containsKey(key)) continue;
      final value = entry.value;
      if (value is bool) target[key] = value;
    }
  }

  void _persist() {
    if (_suppressPersist) return;
    unawaited(_write());
  }

  Future<void> persistNow() async {
    if (!_hasRemote) return;
    await _write();
  }

  Future<void> _write() async {
    await UserDocPersist.merge({
      UserFields.notificationSettings: {
        'allEnabled': allEnabled,
        'preferences': Map<String, bool>.from(preferences),
        'channels': Map<String, bool>.from(channels),
        'smartFoodReminderEnabled': smartFoodReminderEnabled,
        'smartFoodReminderDays': smartFoodReminderDays,
        'customSmartFoodReminderDays': customSmartFoodReminderDays,
        'autoOrderNotifications': autoOrderNotifications,
        'autoOrderDaysBefore': autoOrderDaysBefore,
        'healthRemindersEnabled': healthRemindersEnabled,
        'healthReminderDaysBefore': healthReminderDaysBefore,
        'healthReminderTimeIndex': healthReminderTimeIndex,
        'vaccineCalendarEnabled': vaccineCalendarEnabled,
        'channelsVersion': 2,
      },
    });
  }

  void _syncAllEnabledFromChildren() {
    allEnabled = preferences.values.any((v) => v) ||
        channels.values.any((v) => v);
  }
}
