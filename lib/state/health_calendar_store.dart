import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/user_doc_persist.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/notification_settings_store.dart';
import 'package:geliyor_app/state/pet_store.dart';

class HealthCalendarEntry {
  const HealthCalendarEntry({
    required this.title,
    required this.category,
    required this.frequency,
    required this.intervalMonths,
    required this.lastDoneDate,
    required this.nextDueDate,
    this.sentFor = '',
    this.reminderDate = '',
  });

  final String title;
  final String category;
  final String frequency;
  final int intervalMonths;
  final DateTime lastDoneDate;
  final DateTime nextDueDate;
  final String sentFor;
  final String reminderDate;

  HealthCalendarEntry copyWith({String? sentFor, String? reminderDate}) {
    return HealthCalendarEntry(
      title: title,
      category: category,
      frequency: frequency,
      intervalMonths: intervalMonths,
      lastDoneDate: lastDoneDate,
      nextDueDate: nextDueDate,
      sentFor: sentFor ?? this.sentFor,
      reminderDate: reminderDate ?? this.reminderDate,
    );
  }
}

/// Aşı / parazit / kontrol tarihlerini sunucuya yazar.
class HealthCalendarStore extends ChangeNotifier {
  HealthCalendarStore._();

  static final HealthCalendarStore instance = HealthCalendarStore._();

  static const timeHours = [9, 13, 17, 20];

  final Map<String, HealthCalendarEntry> _saved = {};
  bool _started = false;
  bool _loading = false;
  bool _hydrated = false;
  Timer? _debounce;

  Map<String, HealthCalendarEntry> get saved =>
      Map.unmodifiable(_saved);

  HealthCalendarEntry? entryFor(String title) => _saved[title];

  static void start() {
    final store = instance;
    if (store._started) return;
    store._started = true;
    void schedule() {
      if (store._loading) return;
      store._debounce?.cancel();
      store._debounce = Timer(const Duration(milliseconds: 700), store.sync);
    }

    AuthStore.instance.addListener(schedule);
    NotificationSettingsStore.instance.addListener(schedule);
    PetStore.instance.addListener(schedule);
    unawaited(store.sync());
  }

  void applyRemote(Map<String, dynamic>? data) {
    _loading = true;
    _saved.clear();
    if (data == null) {
      _hydrated = false;
      _loading = false;
      notifyListeners();
      return;
    }
    final items = UserDocPersist.asMapList(data[HealthCalendarFields.items]);
    for (final item in items) {
      final title = (item[HealthCalendarFields.title] as String?)?.trim() ?? '';
      final last = _parseYmd(item[HealthCalendarFields.lastDoneDate] as String?);
      final next = _parseYmd(item[HealthCalendarFields.nextDueDate] as String?);
      final interval =
          (item[HealthCalendarFields.intervalMonths] as num?)?.toInt() ?? 0;
      if (title.isEmpty || last == null || next == null || interval <= 0) {
        continue;
      }
      _saved[title] = HealthCalendarEntry(
        title: title,
        category: (item[HealthCalendarFields.category] as String?) ?? 'vaccine',
        frequency: (item[HealthCalendarFields.frequency] as String?) ?? '',
        intervalMonths: interval,
        lastDoneDate: last,
        nextDueDate: next,
        sentFor: (item[HealthCalendarFields.sentFor] as String?) ?? '',
        reminderDate: (item[HealthCalendarFields.reminderDate] as String?) ?? '',
      );
    }
    _hydrated = true;
    _loading = false;
    notifyListeners();
  }

  void markReady() {
    _hydrated = true;
  }

  void overlayLastDone(void Function(String title, DateTime lastDone) apply) {
    for (final entry in _saved.values) {
      apply(entry.title, entry.lastDoneDate);
    }
  }

  Future<void> recordDone({
    required String title,
    required String category,
    required String frequency,
    required int intervalMonths,
    required DateTime doneDate,
  }) async {
    final last = DateTime(doneDate.year, doneDate.month, doneDate.day);
    final next = addMonths(last, intervalMonths);
    final prev = _saved[title];
    _saved[title] = HealthCalendarEntry(
      title: title,
      category: category,
      frequency: frequency,
      intervalMonths: intervalMonths,
      lastDoneDate: last,
      nextDueDate: next,
      sentFor: '',
      reminderDate: prev?.reminderDate ?? '',
    );
    notifyListeners();
    await sync();
  }

  Future<void> sync() async {
    if (_loading) return;
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) return;
    if (!_hydrated && _saved.isEmpty) return;

    final settings = NotificationSettingsStore.instance;
    final today = _dateOnly(DateTime.now());
    final daysBefore = settings.healthReminderDaysBefore.clamp(0, 60);
    final timeHour = timeHours[settings.healthReminderTimeIndex.clamp(
      0,
      timeHours.length - 1,
    )];
    final enabled = settings.vaccineCalendarEnabled &&
        settings.canSendHealthReminder &&
        _saved.isNotEmpty;

    final items = <Map<String, dynamic>>[];
    final entries = _saved.values.toList();
    for (final entry in entries) {
      var notifyAt = _dateOnly(
        entry.nextDueDate.subtract(Duration(days: daysBefore)),
      );
      if (notifyAt.isAfter(entry.nextDueDate)) {
        notifyAt = _dateOnly(entry.nextDueDate);
      }
      if (notifyAt.isBefore(today) &&
          !_dateOnly(entry.nextDueDate).isBefore(today)) {
        notifyAt = today;
      }
      final reminderDate = _ymd(notifyAt);
      final sentFor =
          entry.reminderDate == reminderDate ? entry.sentFor : '';
      _saved[entry.title] = entry.copyWith(
        reminderDate: reminderDate,
        sentFor: sentFor,
      );
      items.add({
        HealthCalendarFields.title: entry.title,
        HealthCalendarFields.category: entry.category,
        HealthCalendarFields.frequency: entry.frequency,
        HealthCalendarFields.intervalMonths: entry.intervalMonths,
        HealthCalendarFields.lastDoneDate: _ymd(entry.lastDoneDate),
        HealthCalendarFields.nextDueDate: _ymd(entry.nextDueDate),
        HealthCalendarFields.reminderDate: reminderDate,
        HealthCalendarFields.sentFor: sentFor,
      });
    }

    await UserDocPersist.merge({
      UserFields.healthCalendar: {
        HealthCalendarFields.enabled: enabled,
        HealthCalendarFields.daysBefore: daysBefore,
        HealthCalendarFields.timeHour: timeHour,
        HealthCalendarFields.items: items,
      },
    });
  }

  static DateTime addMonths(DateTime date, int months) {
    var year = date.year;
    var month = date.month + months;
    while (month > 12) {
      month -= 12;
      year += 1;
    }
    while (month < 1) {
      month += 12;
      year -= 1;
    }
    final maxDay = DateTime(year, month + 1, 0).day;
    final day = date.day > maxDay ? maxDay : date.day;
    return DateTime(year, month, day);
  }

  static DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  static String _ymd(DateTime date) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${date.year}-${two(date.month)}-${two(date.day)}';
  }

  static DateTime? _parseYmd(String? raw) {
    final value = (raw ?? '').trim();
    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) return null;
    return DateTime.tryParse(value);
  }
}
