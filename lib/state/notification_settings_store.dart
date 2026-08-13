import 'package:flutter/foundation.dart';

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
    'sms': false,
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

  int get effectiveSmartFoodReminderDays => smartFoodReminderDays == -1
      ? customSmartFoodReminderDays
      : smartFoodReminderDays;

  bool get canSendInApp => allEnabled && (channels['inApp'] ?? true);

  bool categoryEnabled(String id) => canSendInApp && (preferences[id] ?? true);

  bool get canSendFoodReminder =>
      categoryEnabled('reminders') && smartFoodReminderEnabled;

  bool get canSendHealthReminder =>
      categoryEnabled('petWorld') && healthRemindersEnabled;

  bool get canSendOrderNotifications =>
      categoryEnabled('orders') && autoOrderNotifications;

  String get foodReminderSummary {
    if (!canSendFoodReminder) {
      return 'Mama hatırlatma bildirimleri kapalı.';
    }
    return 'Mama bitmeden $effectiveSmartFoodReminderDays gün önce bildirim gönderilir.';
  }

  String get autoOrderDaysSummary =>
      'Tahmini bitiş tarihinden $autoOrderDaysBefore gün önce sipariş oluşturulur.';

  String get autoOrderNotificationSummary {
    if (!canSendOrderNotifications) {
      return 'Sipariş ve kargo bildirimleri kapalı.';
    }
    return 'Sipariş, kargo ve durum güncellemeleri için bildirim alırsınız.';
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
      channels['sms'] = false;
    }
    notifyListeners();
  }

  void setPreference(String id, bool value) {
    preferences[id] = value;
    _syncAllEnabledFromChildren();
    notifyListeners();
  }

  void setChannel(String id, bool value) {
    channels[id] = value;
    _syncAllEnabledFromChildren();
    notifyListeners();
  }

  void setSmartFoodReminderEnabled(bool value) {
    smartFoodReminderEnabled = value;
    notifyListeners();
  }

  void setSmartFoodReminderDays(int days) {
    smartFoodReminderDays = days;
    notifyListeners();
  }

  void setCustomSmartFoodReminderDays(int days) {
    customSmartFoodReminderDays = days.clamp(1, 30);
    notifyListeners();
  }

  void setAutoOrderNotifications(bool value) {
    autoOrderNotifications = value;
    notifyListeners();
  }

  void setAutoOrderDaysBefore(int days) {
    autoOrderDaysBefore = days;
    notifyListeners();
  }

  void setHealthRemindersEnabled(bool value) {
    healthRemindersEnabled = value;
    notifyListeners();
  }

  void setHealthReminderDaysBefore(int days) {
    healthReminderDaysBefore = days;
    notifyListeners();
  }

  void setHealthReminderTimeIndex(int index) {
    healthReminderTimeIndex =
        index.clamp(0, reminderTimes.length - 1);
    notifyListeners();
  }

  void setVaccineCalendarEnabled(bool value) {
    vaccineCalendarEnabled = value;
    notifyListeners();
  }

  void _syncAllEnabledFromChildren() {
    allEnabled = preferences.values.any((v) => v) ||
        channels.values.any((v) => v);
  }
}
