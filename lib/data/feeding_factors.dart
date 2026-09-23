/// Yetişkin kedi formül çarpanları. Admin Mama Tüketim Takibi’nden düzenlenir.
class FeedingFactors {
  const FeedingFactors({
    this.neuteredYes = 0.9,
    this.neuteredNo = 1.0,
    this.bodyThin = 1.1,
    this.bodyIdeal = 1.0,
    this.bodyHeavy = 0.85,
    this.activityLow = 0.9,
    this.activityMid = 1.0,
    this.activityHigh = 1.1,
    this.extraNone = 1.0,
    this.extraTreat = 0.95,
    this.extraWet = 0.85,
    this.extraBoth = 0.8,
    this.clampLow = 0.75,
    this.clampHigh = 1.25,
  });

  static const defaults = FeedingFactors();

  final double neuteredYes;
  final double neuteredNo;
  final double bodyThin;
  final double bodyIdeal;
  final double bodyHeavy;
  final double activityLow;
  final double activityMid;
  final double activityHigh;
  final double extraNone;
  final double extraTreat;
  final double extraWet;
  final double extraBoth;
  final double clampLow;
  final double clampHigh;

  factory FeedingFactors.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return defaults;
    double n(String key, double fallback) {
      final value = data[key];
      if (value is num) return value.toDouble();
      return fallback;
    }

    return FeedingFactors(
      neuteredYes: n('neuteredYes', defaults.neuteredYes),
      neuteredNo: n('neuteredNo', defaults.neuteredNo),
      bodyThin: n('bodyThin', defaults.bodyThin),
      bodyIdeal: n('bodyIdeal', defaults.bodyIdeal),
      bodyHeavy: n('bodyHeavy', defaults.bodyHeavy),
      activityLow: n('activityLow', defaults.activityLow),
      activityMid: n('activityMid', defaults.activityMid),
      activityHigh: n('activityHigh', defaults.activityHigh),
      extraNone: n('extraNone', defaults.extraNone),
      extraTreat: n('extraTreat', defaults.extraTreat),
      extraWet: n('extraWet', defaults.extraWet),
      extraBoth: n('extraBoth', defaults.extraBoth),
      clampLow: n('clampLow', defaults.clampLow),
      clampHigh: n('clampHigh', defaults.clampHigh),
    );
  }

  Map<String, double> toMap() => {
        'neuteredYes': neuteredYes,
        'neuteredNo': neuteredNo,
        'bodyThin': bodyThin,
        'bodyIdeal': bodyIdeal,
        'bodyHeavy': bodyHeavy,
        'activityLow': activityLow,
        'activityMid': activityMid,
        'activityHigh': activityHigh,
        'extraNone': extraNone,
        'extraTreat': extraTreat,
        'extraWet': extraWet,
        'extraBoth': extraBoth,
        'clampLow': clampLow,
        'clampHigh': clampHigh,
      };
}

/// Mini ırk yetişkin köpek çarpanları.
/// Formül: Baz × kısır × aktivite × vücut × ek gıda
class MiniAdultDogFactors {
  const MiniAdultDogFactors({
    this.neuteredYes = 0.9,
    this.neuteredNo = 1.0,
    this.bodyThin = 1.1,
    this.bodyIdeal = 1.0,
    this.bodyHeavy = 0.85,
    this.activityLow = 0.85,
    this.activityMid = 1.0,
    this.activityHigh = 1.15,
    this.activityVeryHigh = 1.25,
    this.extraNone = 1.0,
    this.extraTreat = 0.95,
    this.extraWet = 0.85,
    this.extraBoth = 0.8,
  });

  static const defaults = MiniAdultDogFactors();

  final double neuteredYes;
  final double neuteredNo;
  final double bodyThin;
  final double bodyIdeal;
  final double bodyHeavy;
  final double activityLow;
  final double activityMid;
  final double activityHigh;
  final double activityVeryHigh;
  final double extraNone;
  final double extraTreat;
  final double extraWet;
  final double extraBoth;

  factory MiniAdultDogFactors.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return defaults;
    double n(String key, double fallback) {
      final value = data[key];
      if (value is num) return value.toDouble();
      return fallback;
    }

    return MiniAdultDogFactors(
      neuteredYes: n('neuteredYes', defaults.neuteredYes),
      neuteredNo: n('neuteredNo', defaults.neuteredNo),
      bodyThin: n('bodyThin', defaults.bodyThin),
      bodyIdeal: n('bodyIdeal', defaults.bodyIdeal),
      bodyHeavy: n('bodyHeavy', defaults.bodyHeavy),
      activityLow: n('activityLow', defaults.activityLow),
      activityMid: n('activityMid', defaults.activityMid),
      activityHigh: n('activityHigh', defaults.activityHigh),
      activityVeryHigh: n('activityVeryHigh', defaults.activityVeryHigh),
      extraNone: n('extraNone', defaults.extraNone),
      extraTreat: n('extraTreat', defaults.extraTreat),
      extraWet: n('extraWet', defaults.extraWet),
      extraBoth: n('extraBoth', defaults.extraBoth),
    );
  }

  Map<String, double> toMap() => {
        'neuteredYes': neuteredYes,
        'neuteredNo': neuteredNo,
        'bodyThin': bodyThin,
        'bodyIdeal': bodyIdeal,
        'bodyHeavy': bodyHeavy,
        'activityLow': activityLow,
        'activityMid': activityMid,
        'activityHigh': activityHigh,
        'activityVeryHigh': activityVeryHigh,
        'extraNone': extraNone,
        'extraTreat': extraTreat,
        'extraWet': extraWet,
        'extraBoth': extraBoth,
      };
}

/// Mini ırk yavru köpek çarpanları.
/// Formül: Baz × aktivite × vücut × ek gıda
class MiniPuppyFactors {
  const MiniPuppyFactors({
    this.bodyThin = 1.1,
    this.bodyIdeal = 1.0,
    this.bodyHeavy = 0.9,
    this.activityLow = 0.9,
    this.activityMid = 1.0,
    this.activityHigh = 1.1,
    this.activityVeryHigh = 1.2,
    this.extraNone = 1.0,
    this.extraTreat = 0.95,
    this.extraWet = 0.85,
    this.extraBoth = 0.8,
  });

  static const defaults = MiniPuppyFactors();

  final double bodyThin;
  final double bodyIdeal;
  final double bodyHeavy;
  final double activityLow;
  final double activityMid;
  final double activityHigh;
  final double activityVeryHigh;
  final double extraNone;
  final double extraTreat;
  final double extraWet;
  final double extraBoth;

  factory MiniPuppyFactors.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return defaults;
    double n(String key, double fallback) {
      final value = data[key];
      if (value is num) return value.toDouble();
      return fallback;
    }

    return MiniPuppyFactors(
      bodyThin: n('bodyThin', defaults.bodyThin),
      bodyIdeal: n('bodyIdeal', defaults.bodyIdeal),
      bodyHeavy: n('bodyHeavy', defaults.bodyHeavy),
      activityLow: n('activityLow', defaults.activityLow),
      activityMid: n('activityMid', defaults.activityMid),
      activityHigh: n('activityHigh', defaults.activityHigh),
      activityVeryHigh: n('activityVeryHigh', defaults.activityVeryHigh),
      extraNone: n('extraNone', defaults.extraNone),
      extraTreat: n('extraTreat', defaults.extraTreat),
      extraWet: n('extraWet', defaults.extraWet),
      extraBoth: n('extraBoth', defaults.extraBoth),
    );
  }

  Map<String, double> toMap() => {
        'bodyThin': bodyThin,
        'bodyIdeal': bodyIdeal,
        'bodyHeavy': bodyHeavy,
        'activityLow': activityLow,
        'activityMid': activityMid,
        'activityHigh': activityHigh,
        'activityVeryHigh': activityVeryHigh,
        'extraNone': extraNone,
        'extraTreat': extraTreat,
        'extraWet': extraWet,
        'extraBoth': extraBoth,
      };
}

/// Standart yavru köpek çarpanları (1–60 kg).
/// Formül: Baz × kısır × aktivite × vücut × ek gıda
class StandardPuppyFactors {
  const StandardPuppyFactors({
    this.neuteredYes = 0.95,
    this.neuteredNo = 1.0,
    this.bodyThin = 1.1,
    this.bodyIdeal = 1.0,
    this.bodyHeavy = 0.9,
    this.activityLow = 0.9,
    this.activityMid = 1.0,
    this.activityHigh = 1.1,
    this.activityVeryHigh = 1.2,
    this.extraNone = 1.0,
    this.extraTreat = 0.95,
    this.extraWet = 0.85,
    this.extraBoth = 0.8,
  });

  static const defaults = StandardPuppyFactors();

  final double neuteredYes;
  final double neuteredNo;
  final double bodyThin;
  final double bodyIdeal;
  final double bodyHeavy;
  final double activityLow;
  final double activityMid;
  final double activityHigh;
  final double activityVeryHigh;
  final double extraNone;
  final double extraTreat;
  final double extraWet;
  final double extraBoth;

  factory StandardPuppyFactors.fromMap(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) return defaults;
    double n(String key, double fallback) {
      final value = data[key];
      if (value is num) return value.toDouble();
      return fallback;
    }

    return StandardPuppyFactors(
      neuteredYes: n('neuteredYes', defaults.neuteredYes),
      neuteredNo: n('neuteredNo', defaults.neuteredNo),
      bodyThin: n('bodyThin', defaults.bodyThin),
      bodyIdeal: n('bodyIdeal', defaults.bodyIdeal),
      bodyHeavy: n('bodyHeavy', defaults.bodyHeavy),
      activityLow: n('activityLow', defaults.activityLow),
      activityMid: n('activityMid', defaults.activityMid),
      activityHigh: n('activityHigh', defaults.activityHigh),
      activityVeryHigh: n('activityVeryHigh', defaults.activityVeryHigh),
      extraNone: n('extraNone', defaults.extraNone),
      extraTreat: n('extraTreat', defaults.extraTreat),
      extraWet: n('extraWet', defaults.extraWet),
      extraBoth: n('extraBoth', defaults.extraBoth),
    );
  }

  Map<String, double> toMap() => {
        'neuteredYes': neuteredYes,
        'neuteredNo': neuteredNo,
        'bodyThin': bodyThin,
        'bodyIdeal': bodyIdeal,
        'bodyHeavy': bodyHeavy,
        'activityLow': activityLow,
        'activityMid': activityMid,
        'activityHigh': activityHigh,
        'activityVeryHigh': activityVeryHigh,
        'extraNone': extraNone,
        'extraTreat': extraTreat,
        'extraWet': extraWet,
        'extraBoth': extraBoth,
      };
}
