/// Yavru kedi kuru mama tüketimi (g/gün). Esas: ay.
class KittenFeedingRow {
  const KittenFeedingRow({
    required this.months,
    required this.dailyGrams,
  });

  final int months;
  final int dailyGrams;

  String get monthLabel => '$months ay';
}

abstract final class KittenFeedingGuide {
  static const List<KittenFeedingRow> rows = [
    KittenFeedingRow(months: 1, dailyGrams: 25),
    KittenFeedingRow(months: 2, dailyGrams: 40),
    KittenFeedingRow(months: 3, dailyGrams: 50),
    KittenFeedingRow(months: 4, dailyGrams: 55),
    KittenFeedingRow(months: 5, dailyGrams: 60),
    KittenFeedingRow(months: 6, dailyGrams: 65),
    KittenFeedingRow(months: 7, dailyGrams: 70),
    KittenFeedingRow(months: 8, dailyGrams: 70),
    KittenFeedingRow(months: 9, dailyGrams: 70),
    KittenFeedingRow(months: 10, dailyGrams: 70),
    KittenFeedingRow(months: 11, dailyGrams: 70),
    KittenFeedingRow(months: 12, dailyGrams: 70),
  ];

  static List<int> get monthRows => [
        for (final row in rows) row.months,
      ];

  static KittenFeedingRow lookup(int months) {
    final clamped = months.clamp(rows.first.months, rows.last.months);
    return rows.firstWhere(
      (row) => row.months == clamped,
      orElse: () => rows.first,
    );
  }

  static int? dailyGramsFor(int? months) {
    if (months == null || months <= 0) return null;
    return lookup(months).dailyGrams;
  }
}
