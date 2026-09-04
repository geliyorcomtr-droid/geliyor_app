import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';

class AppCoupon {
  const AppCoupon({
    required this.id,
    required this.code,
    required this.title,
    this.description = '',
    this.type = CouponTypes.amount,
    this.value = 0,
    this.minSubtotal = 0,
    this.publicCoupon = true,
    this.singleUse = false,
    this.active = true,
    this.order = 0,
  });

  final String id;
  final String code;
  final String title;
  final String description;
  final String type;
  final double value;
  final double minSubtotal;
  final bool publicCoupon;
  final bool singleUse;
  final bool active;
  final int order;

  bool get isPercent => type == CouponTypes.percent;

  String get discountLabel {
    if (isPercent) return '%${value.round()}';
    return '${_format(value)} TL';
  }

  double discountFor(double subtotal) {
    if (subtotal <= 0 || value <= 0) return 0;
    if (subtotal < minSubtotal) return 0;
    final raw = isPercent ? subtotal * (value / 100) : value;
    if (raw <= 0) return 0;
    return raw > subtotal ? subtotal : raw;
  }

  String? eligibilityError(double subtotal) {
    if (!active) return 'Bu kupon artık geçerli değil.';
    if (subtotal < minSubtotal) {
      return 'Bu kupon için sepet en az ${_format(minSubtotal)} TL olmalı.';
    }
    if (discountFor(subtotal) <= 0) return 'Bu kupon bu siparişte uygulanamaz.';
    return null;
  }

  factory AppCoupon.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return AppCoupon.fromMap(doc.id, doc.data() ?? {});
  }

  factory AppCoupon.fromMap(String id, Map<String, dynamic> data) {
    return AppCoupon(
      id: id,
      code: ((data[CouponFields.code] as String?) ?? '').trim().toUpperCase(),
      title: (data[CouponFields.title] as String?) ?? '',
      description: (data[CouponFields.description] as String?) ?? '',
      type: (data[CouponFields.type] as String?) ?? CouponTypes.amount,
      value: (data[CouponFields.value] as num?)?.toDouble() ?? 0,
      minSubtotal: (data[CouponFields.minSubtotal] as num?)?.toDouble() ?? 0,
      publicCoupon: data[CouponFields.publicCoupon] as bool? ?? true,
      singleUse: data[CouponFields.singleUse] as bool? ?? false,
      active: data[CouponFields.active] as bool? ?? true,
      order: (data[CouponFields.order] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    CouponFields.code: code.trim().toUpperCase(),
    CouponFields.title: title.trim(),
    CouponFields.description: description.trim(),
    CouponFields.type: type,
    CouponFields.value: value,
    CouponFields.minSubtotal: minSubtotal,
    CouponFields.publicCoupon: publicCoupon,
    CouponFields.singleUse: singleUse,
    CouponFields.active: active,
    CouponFields.order: order,
    CouponFields.updatedAt: FieldValue.serverTimestamp(),
  };

  AppCoupon copyWith({
    String? code,
    String? title,
    String? description,
    String? type,
    double? value,
    double? minSubtotal,
    bool? publicCoupon,
    bool? singleUse,
    bool? active,
    int? order,
  }) {
    return AppCoupon(
      id: id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      type: type ?? this.type,
      value: value ?? this.value,
      minSubtotal: minSubtotal ?? this.minSubtotal,
      publicCoupon: publicCoupon ?? this.publicCoupon,
      singleUse: singleUse ?? this.singleUse,
      active: active ?? this.active,
      order: order ?? this.order,
    );
  }

  static String _format(double value) {
    final whole = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < whole.length; i++) {
      final remaining = whole.length - i;
      buffer.write(whole[i]);
      if (remaining > 1 && remaining % 3 == 1) buffer.write('.');
    }
    return buffer.toString();
  }
}

const defaultCoupons = <AppCoupon>[
  AppCoupon(
    id: 'hosgeldin-50',
    code: 'HOSGELDIN50',
    title: 'Hoş geldin kuponu',
    description: 'İlk siparişlerde 50 TL indirim.',
    type: CouponTypes.amount,
    value: 50,
    minSubtotal: 250,
    publicCoupon: true,
    singleUse: true,
    order: 0,
  ),
  AppCoupon(
    id: 'dost-25',
    code: 'DOST25',
    title: 'Kampanya kuponu',
    description: 'Kampanyalar sayfasından kazanılan 25 TL indirim.',
    type: CouponTypes.amount,
    value: 25,
    minSubtotal: 0,
    publicCoupon: false,
    singleUse: true,
    order: 1,
  ),
  AppCoupon(
    id: 'mama-25',
    code: 'MAMA25',
    title: 'Mama bitiş kuponu',
    description: 'Mama bitmek üzere bildiriminde tanımlanan kupon.',
    type: CouponTypes.amount,
    value: 25,
    minSubtotal: 0,
    publicCoupon: false,
    singleUse: true,
    order: 2,
  ),
];

class CouponRepository {
  CouponRepository._();
  static final CouponRepository instance = CouponRepository._();

  static const earnedRewardId = 'dost-25';
  static const foodReminderCouponId = 'mama-25';

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(FirestoreCollections.coupons);

  DocumentReference<Map<String, dynamic>> get _settingsDoc =>
      FirebaseFirestore.instance
          .collection(FirestoreCollections.settings)
          .doc(SettingsDocs.foodCoupon);

  CollectionReference<Map<String, dynamic>> get _queue => FirebaseFirestore
      .instance
      .collection(FirestoreCollections.foodCouponQueue);

  Future<void> ensureDefaults() async {
    try {
      final existing = await _col.limit(1).get();
      if (existing.docs.isEmpty) {
        final batch = FirebaseFirestore.instance.batch();
        for (final coupon in defaultCoupons) {
          batch.set(_col.doc(coupon.id), coupon.toMap());
        }
        await batch.commit();
      } else {
        final food = await _col.doc(foodReminderCouponId).get();
        if (!food.exists) {
          final mama = defaultCoupons.firstWhere(
            (c) => c.id == foodReminderCouponId,
          );
          await _col.doc(mama.id).set(mama.toMap());
        }
      }
    } catch (_) {}
  }

  Stream<List<AppCoupon>> watchAll() {
    return _col.snapshots().map((snap) {
      final list = snap.docs.map(AppCoupon.fromDoc).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
      return list;
    });
  }

  Stream<List<AppCoupon>> watchActive() {
    return watchAll().map(
      (list) =>
          list.where((coupon) => coupon.active && coupon.code.isNotEmpty).toList(),
    );
  }

  Future<void> save(AppCoupon coupon) {
    final id = coupon.id.trim().isEmpty ? _col.doc().id : coupon.id;
    return _col.doc(id).set(coupon.toMap(), SetOptions(merge: true));
  }

  Future<void> grantToUser(String userId, String couponId) {
    return FirebaseFirestore.instance
        .collection(FirestoreCollections.users)
        .doc(userId)
        .set({
          UserFields.earnedCouponIds: FieldValue.arrayUnion([couponId]),
          UserFields.updatedAt: FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Stream<FoodCouponSettings> watchSettings() {
    return _settingsDoc.snapshots().map(FoodCouponSettings.fromDoc);
  }

  Future<void> saveSettings(FoodCouponSettings settings) {
    return _settingsDoc.set(settings.toMap(), SetOptions(merge: true));
  }

  Stream<List<FoodCouponJob>> watchQueue() {
    return _queue.snapshots().map((snap) {
      final list = snap.docs.map(FoodCouponJob.fromDoc).toList()
        ..sort((a, b) {
          final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return right.compareTo(left);
        });
      return list;
    });
  }

  Future<void> updateQueueStatus(
    String jobId, {
    required String status,
    String couponId = '',
    String couponCode = '',
  }) {
    return _queue.doc(jobId).set({
      FoodCouponQueueFields.status: status,
      FoodCouponQueueFields.couponId: couponId,
      FoodCouponQueueFields.couponCode: couponCode,
      FoodCouponQueueFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

class FoodCouponSettings {
  const FoodCouponSettings({
    this.mode = FoodCouponModes.manual,
    this.couponId = CouponRepository.foodReminderCouponId,
  });

  final String mode;
  final String couponId;

  bool get isAutomatic => mode == FoodCouponModes.automatic;
  bool get isManual => mode == FoodCouponModes.manual;
  bool get isOff => mode == FoodCouponModes.off;

  factory FoodCouponSettings.fromDoc(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? {};
    final mode = (data[FoodCouponSettingsFields.mode] as String?) ?? '';
    return FoodCouponSettings(
      mode: mode.isEmpty ? FoodCouponModes.manual : mode,
      couponId:
          (data[FoodCouponSettingsFields.couponId] as String?)?.trim().isNotEmpty ==
              true
          ? (data[FoodCouponSettingsFields.couponId] as String).trim()
          : CouponRepository.foodReminderCouponId,
    );
  }

  Map<String, dynamic> toMap() => {
    FoodCouponSettingsFields.mode: mode,
    FoodCouponSettingsFields.couponId: couponId,
    FoodCouponSettingsFields.updatedAt: FieldValue.serverTimestamp(),
  };
}

class FoodCouponJob {
  const FoodCouponJob({
    required this.id,
    required this.userId,
    required this.customerName,
    required this.phone,
    required this.petName,
    required this.foodTitle,
    required this.remainingDays,
    required this.reminderDate,
    required this.status,
    this.couponId = '',
    this.couponCode = '',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String customerName;
  final String phone;
  final String petName;
  final String foodTitle;
  final int remainingDays;
  final String reminderDate;
  final String status;
  final String couponId;
  final String couponCode;
  final DateTime? createdAt;

  bool get isPending => status == FoodCouponQueueStatuses.pending;

  factory FoodCouponJob.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final created = data[FoodCouponQueueFields.createdAt];
    return FoodCouponJob(
      id: doc.id,
      userId: (data[FoodCouponQueueFields.userId] as String?) ?? '',
      customerName: (data[FoodCouponQueueFields.customerName] as String?) ?? '',
      phone: (data[FoodCouponQueueFields.phone] as String?) ?? '',
      petName: (data[FoodCouponQueueFields.petName] as String?) ?? '',
      foodTitle: (data[FoodCouponQueueFields.foodTitle] as String?) ?? '',
      remainingDays:
          (data[FoodCouponQueueFields.remainingDays] as num?)?.toInt() ?? 0,
      reminderDate: (data[FoodCouponQueueFields.reminderDate] as String?) ?? '',
      status:
          (data[FoodCouponQueueFields.status] as String?) ??
          FoodCouponQueueStatuses.pending,
      couponId: (data[FoodCouponQueueFields.couponId] as String?) ?? '',
      couponCode: (data[FoodCouponQueueFields.couponCode] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
