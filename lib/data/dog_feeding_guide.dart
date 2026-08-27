/// Köpek kuru mama tüketimi (g/gün).
///
/// Tablodaki aralıkların orta değeri günlük tahminde kullanılır. Giant
/// satırındaki `+` değerleri alt sınır olarak kabul edilir.
class DogFeedingRow {
  const DogFeedingRow({
    required this.size,
    required this.weightLabel,
    required this.lowMin,
    required this.lowMax,
    required this.midMin,
    required this.midMax,
    required this.highMin,
    required this.highMax,
    this.openEnded = false,
  });

  final String size;
  final String weightLabel;
  final int lowMin;
  final int lowMax;
  final int midMin;
  final int midMax;
  final int highMin;
  final int highMax;
  final bool openEnded;

  int gramsFor(String? activityLevel) {
    return switch (DogFeedingGuide.normalizeActivity(activityLevel)) {
      'Düşük' => _estimate(lowMin, lowMax),
      'Yüksek' => _estimate(highMin, highMax),
      _ => _estimate(midMin, midMax),
    };
  }

  String rangeFor(String? activityLevel) {
    return switch (DogFeedingGuide.normalizeActivity(activityLevel)) {
      'Düşük' => _rangeLabel(lowMin, lowMax),
      'Yüksek' => _rangeLabel(highMin, highMax),
      _ => _rangeLabel(midMin, midMax),
    };
  }

  int _estimate(int min, int max) =>
      openEnded ? min : ((min + max) / 2).round();

  String _rangeLabel(int min, int max) =>
      openEnded ? '$min g+' : '$min-$max g';
}

abstract final class DogFeedingGuide {
  static const List<DogFeedingRow> rows = [
    DogFeedingRow(
      size: 'X-Small',
      weightLabel: '0-4 kg',
      lowMin: 45,
      lowMax: 70,
      midMin: 55,
      midMax: 80,
      highMin: 65,
      highMax: 95,
    ),
    DogFeedingRow(
      size: 'Mini',
      weightLabel: '5-10 kg',
      lowMin: 75,
      lowMax: 125,
      midMin: 90,
      midMax: 145,
      highMin: 105,
      highMax: 170,
    ),
    DogFeedingRow(
      size: 'Medium',
      weightLabel: '11-25 kg',
      lowMin: 130,
      lowMax: 240,
      midMin: 155,
      midMax: 285,
      highMin: 185,
      highMax: 335,
    ),
    DogFeedingRow(
      size: 'Maxi',
      weightLabel: '26-44 kg',
      lowMin: 245,
      lowMax: 350,
      midMin: 290,
      midMax: 415,
      highMin: 340,
      highMax: 490,
    ),
    DogFeedingRow(
      size: 'Giant',
      weightLabel: '45 kg+',
      lowMin: 355,
      lowMax: 355,
      midMin: 420,
      midMax: 420,
      highMin: 495,
      highMax: 495,
      openEnded: true,
    ),
  ];

  static String normalizeActivity(String? value) {
    final normalized = (value ?? '').toLowerCase();
    if (normalized.contains('düşük') || normalized.contains('dusuk')) {
      return 'Düşük';
    }
    if (normalized.contains('yüksek') || normalized.contains('yuksek')) {
      return 'Yüksek';
    }
    return 'Orta';
  }

  static DogFeedingRow? fromSizeLabel(String? label) {
    final normalized = (label ?? '').toLowerCase();
    if (normalized.isEmpty) return null;
    for (final row in rows) {
      if (normalized.contains(row.size.toLowerCase())) return row;
    }
    return null;
  }

  static int? dailyGramsFor({
    required String? sizeLabel,
    required String? activityLevel,
  }) {
    return fromSizeLabel(sizeLabel)?.gramsFor(activityLevel);
  }
}
