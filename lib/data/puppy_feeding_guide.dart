/// Yavru köpek kuru mama tüketimi (g/gün). Esas: ay + ırk (standart / mini).
class PuppyFeedingRow {
  const PuppyFeedingRow({
    required this.months,
    required this.standardGrams,
    required this.miniGrams,
  });

  final int months;
  final int standardGrams;
  final int miniGrams;

  String get monthLabel => '$months ay';

  int gramsFor({required bool isMini}) =>
      isMini ? miniGrams : standardGrams;
}

abstract final class PuppyFeedingGuide {
  static const List<PuppyFeedingRow> rows = [
    PuppyFeedingRow(months: 1, standardGrams: 100, miniGrams: 50),
    PuppyFeedingRow(months: 2, standardGrams: 195, miniGrams: 80),
    PuppyFeedingRow(months: 3, standardGrams: 255, miniGrams: 110),
    PuppyFeedingRow(months: 4, standardGrams: 275, miniGrams: 115),
    PuppyFeedingRow(months: 5, standardGrams: 280, miniGrams: 115),
    PuppyFeedingRow(months: 6, standardGrams: 280, miniGrams: 110),
    PuppyFeedingRow(months: 7, standardGrams: 255, miniGrams: 100),
    PuppyFeedingRow(months: 8, standardGrams: 230, miniGrams: 90),
    PuppyFeedingRow(months: 9, standardGrams: 205, miniGrams: 80),
    PuppyFeedingRow(months: 10, standardGrams: 180, miniGrams: 80),
    PuppyFeedingRow(months: 11, standardGrams: 180, miniGrams: 80),
    PuppyFeedingRow(months: 12, standardGrams: 180, miniGrams: 80),
  ];

  static List<int> get monthRows => [
        for (final row in rows) row.months,
      ];

  static PuppyFeedingRow lookup(int months) {
    final clamped = months.clamp(rows.first.months, rows.last.months);
    return rows.firstWhere(
      (row) => row.months == clamped,
      orElse: () => rows.first,
    );
  }

  static int? dailyGramsFor(int? months, {required bool isMini}) {
    if (months == null || months <= 0) return null;
    return lookup(months).gramsFor(isMini: isMini);
  }
}
