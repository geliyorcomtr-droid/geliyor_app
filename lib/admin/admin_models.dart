import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/data/product_advantage_repository.dart';
import 'package:geliyor_app/utils/product_skt.dart';

class AdminProduct {
  const AdminProduct({
    required this.id,
    required this.title,
    required this.brand,
    required this.weight,
    this.barcode = '',
    this.vatRate = 20,
    this.skt = '',
    required this.unitPrice,
    required this.oldPrice,
    this.purchasePrice = 0,
    required this.discountPercent,
    required this.imageUrl,
    required this.category,
    this.extraCategories = const [],
    this.placements = const [],
    this.mainCategory = 'cat',
    required this.description,
    this.ingredients = '',
    required this.active,
    required this.stock,
    this.features = const [],
    this.technicalFeatures = const [],
    this.trustBadgeIds = const [],
    this.productAdvantageIds = const [],
    this.productAdvantageValues = const {},
    this.proteinValue = '',
    this.animalProteinValue = '',
    this.preferredRank = '',
    this.repurchaseRate = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.gallery = const [],
    this.boughtTogetherIds = const [],
    this.seoTitle = '',
    this.metaDescription = '',
    this.rewardPoints = 0,
    this.createdAt,
    this.softtrMatched = false,
  });

  final String id;
  final String title;
  final String brand;
  final String weight;

  /// Ürün barkodu / stok kodu (aynı numara).
  final String barcode;

  /// Satış fiyatı KDV dahil; fatura bu orana göre ayrılır.
  final int vatRate;

  /// Son kullanma (gösterim: `11.2027`)
  final String skt;
  final double unitPrice;
  final double oldPrice;

  /// Softtr alış fiyatı (KDV hariç kabul edilir).
  final double purchasePrice;
  final int discountPercent;
  final String imageUrl;
  final String category;
  final List<String> extraCategories;
  final List<String> placements;
  final String mainCategory;
  final String description;
  final String ingredients;
  final bool active;
  final int stock;
  final List<AdminProductFeature> features;
  final List<AdminProductFeature> technicalFeatures;
  final List<String> trustBadgeIds;
  final List<String> productAdvantageIds;
  final Map<String, String> productAdvantageValues;
  final String proteinValue;
  final String animalProteinValue;
  final String preferredRank;
  final String repurchaseRate;
  final double rating;
  final int reviewCount;
  final List<String> gallery;
  final List<String> boughtTogetherIds;
  final String seoTitle;
  final String metaDescription;

  /// Puanla alınacak ürünün maliyeti. 0 ise puan ödülü değildir.
  final int rewardPoints;
  final DateTime? createdAt;
  final bool softtrMatched;

  bool get showAsGift =>
      placements.contains(ProductPlacements.gift) ||
      placements.contains(ProductPlacements.giftTier1);
  bool get showAsPremiumGift =>
      placements.contains(ProductPlacements.giftPremium) ||
      placements.contains(ProductPlacements.giftTier3);

  /// 0: ₺1.000–1.999, 1: ₺2.000–3.999, 2: ₺4.000+. İşaret yoksa null.
  bool get isPointReward =>
      placements.contains(ProductPlacements.pointReward) && rewardPoints > 0;

  int? get giftTier {
    if (placements.contains(ProductPlacements.giftTier3) ||
        placements.contains(ProductPlacements.giftPremium)) {
      return 2;
    }
    if (placements.contains(ProductPlacements.giftTier2)) return 1;
    if (placements.contains(ProductPlacements.giftTier1) ||
        placements.contains(ProductPlacements.gift)) {
      return 0;
    }
    return null;
  }
  bool get isInStock => stock > 0;

  factory AdminProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final created = d[ProductFields.createdAt];
    return AdminProduct(
      id: doc.id,
      title: (d[ProductFields.title] as String?) ?? '',
      brand: (d[ProductFields.brand] as String?) ?? '',
      weight: (d[ProductFields.weight] as String?) ?? '',
      barcode: (d[ProductFields.barcode] as String?) ?? '',
      vatRate: ProductFields.vatRateFrom(d[ProductFields.vatRate]),
      skt: ProductSkt.fromFirestore(d),
      unitPrice: (d[ProductFields.unitPrice] as num?)?.toDouble() ?? 0,
      oldPrice: (d[ProductFields.oldPrice] as num?)?.toDouble() ?? 0,
      purchasePrice: (d[ProductFields.purchasePrice] as num?)?.toDouble() ?? 0,
      discountPercent: (d[ProductFields.discountPercent] as num?)?.toInt() ?? 0,
      imageUrl: (d[ProductFields.imageUrl] as String?) ?? '',
      category: (d[ProductFields.category] as String?) ?? '',
      extraCategories: _stringList(d[ProductFields.extraCategories]),
      placements: _stringList(d[ProductFields.placements]),
      mainCategory: (d[ProductFields.mainCategory] as String?) ?? 'cat',
      description: (d[ProductFields.description] as String?) ?? '',
      ingredients: (d[ProductFields.ingredients] as String?) ?? '',
      active: d[ProductFields.active] as bool? ?? true,
      stock: (d[ProductFields.stock] as num?)?.toInt() ?? 0,
      features: _featuresFrom(d[ProductFields.features]),
      technicalFeatures: _featuresFrom(d[ProductFields.technicalFeatures]),
      trustBadgeIds:
          (d[ProductFields.trustBadgeIds] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      productAdvantageIds:
          (d[ProductFields.productAdvantageIds] as List?)
              ?.whereType<String>()
              .toList() ??
          const [],
      productAdvantageValues: _advantageValuesFrom(
        d[ProductFields.productAdvantageValues],
      ),
      proteinValue: _proteinValueFrom(
        d[ProductFields.proteinValue],
        d[ProductFields.productAdvantageValues],
      ),
      animalProteinValue: _animalProteinValueFrom(
        d[ProductFields.animalProteinValue],
        d[ProductFields.productAdvantageValues],
      ),
      preferredRank: _preferredRankFrom(d[ProductFields.preferredRank]),
      repurchaseRate: _bagDaysFrom(d[ProductFields.repurchaseRate]),
      rating: (d[ProductFields.rating] as num?)?.toDouble() ?? 0,
      reviewCount: (d[ProductFields.reviewCount] as num?)?.toInt() ?? 0,
      gallery: _stringList(d[ProductFields.gallery]),
      boughtTogetherIds: _idList(d[ProductFields.boughtTogetherIds], limit: 3),
      seoTitle: (d[ProductFields.seoTitle] as String?) ?? '',
      metaDescription: (d[ProductFields.metaDescription] as String?) ?? '',
      rewardPoints: (d[ProductFields.rewardPoints] as num?)?.toInt() ?? 0,
      createdAt: created is Timestamp ? created.toDate() : null,
      softtrMatched: d[ProductFields.softtrMatched] == true,
    );
  }

  Map<String, dynamic> toMap({bool isCreate = false}) {
    return {
      ProductFields.title: title.trim(),
      ProductFields.brand: brand.trim(),
      ProductFields.weight: weight.trim(),
      ProductFields.barcode: barcode.trim(),
      ProductFields.vatRate: ProductFields.vatRateFrom(vatRate),
      ...ProductSkt.toFirestoreFields(skt),
      ProductFields.unitPrice: unitPrice,
      ProductFields.oldPrice: oldPrice,
      ProductFields.purchasePrice: purchasePrice,
      ProductFields.discountPercent: discountPercent,
      ProductFields.imageUrl: imageUrl.trim(),
      ProductFields.category: category.trim(),
      ProductFields.extraCategories: extraCategories
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList(),
      ProductFields.placements: placements,
      ProductFields.mainCategory: mainCategory.trim(),
      ProductFields.description: description.trim(),
      ProductFields.ingredients: ingredients.trim(),
      ProductFields.active: active,
      ProductFields.stock: stock,
      ProductFields.features: features.map((e) => e.toMap()).toList(),
      ProductFields.technicalFeatures: technicalFeatures
          .map((e) => e.toMap())
          .toList(),
      ProductFields.trustBadgeIds: trustBadgeIds,
      ProductFields.productAdvantageIds: productAdvantageIds,
      ProductFields.productAdvantageValues: productAdvantageValues,
      ProductFields.proteinValue: proteinValue.trim(),
      ProductFields.animalProteinValue: animalProteinValue.trim(),
      ProductFields.preferredRank: preferredRank.trim(),
      ProductFields.repurchaseRate: repurchaseRate.trim(),
      ProductFields.rating: rating,
      ProductFields.reviewCount: reviewCount,
      ProductFields.gallery: gallery,
      ProductFields.boughtTogetherIds: _idList(boughtTogetherIds, limit: 3),
      ProductFields.seoTitle: seoTitle.trim(),
      ProductFields.metaDescription: metaDescription.trim(),
      ProductFields.rewardPoints: rewardPoints < 0 ? 0 : rewardPoints,
      ProductFields.updatedAt: FieldValue.serverTimestamp(),
      if (isCreate) ProductFields.createdAt: FieldValue.serverTimestamp(),
    };
  }

  static List<String> _stringList(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<String>()
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }

  static List<String> _idList(dynamic raw, {required int limit}) {
    final ids = <String>[];
    if (raw is! List) return ids;
    for (final value in raw) {
      final id = '$value'.trim();
      if (id.isEmpty || ids.contains(id)) continue;
      ids.add(id);
      if (ids.length >= limit) break;
    }
    return ids;
  }

  static List<AdminProductFeature> _featuresFrom(dynamic raw) {
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (item) =>
              AdminProductFeature.fromMap(Map<String, dynamic>.from(item)),
        )
        .toList();
  }

  static String _textValue(dynamic raw) {
    if (raw == null) return '';
    if (raw is num) {
      final rounded = raw.round();
      return raw == rounded ? '$rounded' : '$raw';
    }
    return '$raw'.trim();
  }

  static Map<String, String> _advantageValuesFrom(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry('$key', _textValue(value)),
    )..removeWhere((_, value) => value.isEmpty);
  }

  static String _proteinValueFrom(dynamic proteinField, dynamic advantageValues) {
    final direct = _textValue(proteinField);
    if (direct.isNotEmpty) return direct;
    if (advantageValues is Map) {
      final legacy = _textValue(
        advantageValues[ProductAdvantageRepository.proteinAdvantageId],
      );
      if (legacy.isNotEmpty) return legacy;
    }
    return '';
  }

  static String _animalProteinValueFrom(
    dynamic proteinField,
    dynamic advantageValues,
  ) {
    final direct = _textValue(proteinField);
    if (direct.isNotEmpty) return direct;
    if (advantageValues is Map) {
      for (final entry in advantageValues.entries) {
        if (!ProductAdvantageRepository.isAnimalProteinId('${entry.key}')) {
          continue;
        }
        final legacy = _textValue(entry.value);
        if (legacy.isNotEmpty) return legacy;
      }
    }
    return '';
  }

  static String _preferredRankFrom(dynamic raw) {
    final value = (raw as String?)?.trim() ?? '';
    if (value.isEmpty) return '';
    return value.endsWith('.') ? value : '$value.';
  }

  static String _bagDaysFrom(dynamic raw) {
    if (raw is num) return '${raw.round()}';
    final value = (raw as String?)?.trim() ?? '';
    if (value.isEmpty) return '';
    return value.replaceAll('%', '').trim();
  }

  /// Yeni ürün olarak kopyala — barkod boş, id yok (yeni kayıt).
  /// Orijinal ürün değişmez; kaydedince Firestore’da ayrı doküman oluşur.
  AdminProduct asCopy() {
    return AdminProduct(
      id: '',
      title: title.trim(),
      brand: brand,
      weight: weight,
      barcode: '',
      vatRate: vatRate,
      skt: skt,
      unitPrice: unitPrice,
      oldPrice: oldPrice,
      purchasePrice: purchasePrice,
      discountPercent: discountPercent,
      imageUrl: imageUrl,
      category: category,
      extraCategories: extraCategories,
      placements: placements,
      mainCategory: mainCategory,
      description: description,
      ingredients: ingredients,
      active: active,
      stock: stock,
      features: features,
      technicalFeatures: technicalFeatures,
      trustBadgeIds: trustBadgeIds,
      productAdvantageIds: productAdvantageIds,
      productAdvantageValues: productAdvantageValues,
      proteinValue: proteinValue,
      animalProteinValue: animalProteinValue,
      preferredRank: preferredRank,
      repurchaseRate: repurchaseRate,
      rating: rating,
      reviewCount: reviewCount,
      gallery: gallery,
      boughtTogetherIds: boughtTogetherIds,
      seoTitle: seoTitle,
      metaDescription: metaDescription,
      rewardPoints: rewardPoints,
    );
  }
}

class AdminProductFeature {
  const AdminProductFeature({
    required this.title,
    required this.description,
    required this.iconUrl,
  });

  final String title;
  final String description;
  final String iconUrl;

  factory AdminProductFeature.fromMap(Map<String, dynamic> map) {
    return AdminProductFeature(
      title: (map['title'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      iconUrl: (map['iconUrl'] as String?) ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'title': title.trim(),
    'description': description.trim(),
    'iconUrl': iconUrl.trim(),
  };
}

class AdminOrderItem {
  const AdminOrderItem({
    required this.productId,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    this.weight = '',
    this.imageUrl = '',
  });

  final String productId;
  final String title;
  final int quantity;
  final double unitPrice;
  final String weight;
  final String imageUrl;

  double get lineTotal => unitPrice * quantity;

  factory AdminOrderItem.fromMap(Map<String, dynamic> map) {
    return AdminOrderItem(
      productId: (map['productId'] as String?) ?? (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      weight: (map['weight'] as String?) ?? '',
      imageUrl:
          (map['imageUrl'] as String?) ?? (map['imagePath'] as String?) ?? '',
    );
  }
}

class AdminOrderGift {
  const AdminOrderGift({
    required this.productId,
    required this.title,
    this.imageUrl = '',
    this.premium = false,
  });

  final String productId;
  final String title;
  final String imageUrl;
  final bool premium;

  factory AdminOrderGift.fromMap(Map<String, dynamic> map) {
    return AdminOrderGift(
      productId: (map['productId'] as String?) ?? (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      imageUrl:
          (map['imageUrl'] as String?) ?? (map['imagePath'] as String?) ?? '',
      premium: map['premium'] as bool? ?? false,
    );
  }

  static List<AdminOrderGift> parseList(dynamic raw) {
    final parsed = <AdminOrderGift>[];
    void add(dynamic item) {
      if (item is Map) {
        parsed.add(AdminOrderGift.fromMap(Map<String, dynamic>.from(item)));
      }
    }

    if (raw is List) {
      for (final item in raw) {
        add(item);
      }
    } else if (raw is Map) {
      for (final item in raw.values) {
        add(item);
      }
    }
    return parsed;
  }
}

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.userId,
    required this.status,
    required this.total,
    required this.statusMessage,
    required this.items,
    this.subtotal = 0,
    this.courierFee = 0,
    this.address = '',
    this.customerName = '',
    this.phone = '',
    this.paymentMethod = '',
    this.deliverySlot = '',
    this.couponCode = '',
    this.couponDiscount = 0,
    this.gifts = const [],
    this.invoiceLink = '',
    this.invoiceNumber = '',
    this.invoiceDate = '',
    this.cargoCompany = '',
    this.cargoTrackingCode = '',
    this.cargoTrackingUrl = '',
    this.billingName = '',
    this.billingAddress = '',
    this.billingAccountType = '',
    this.billingNationalId = '',
    this.billingTaxId = '',
    this.billingTaxOffice = '',
    this.createdAt,
    this.smsCreatedAt,
    this.smsShippingAt,
    this.smsCancelledAt,
    this.smsDeliveredAt,
    this.smsLastError = '',
  });

  final String id;
  final String userId;
  final String status;
  final double total;
  final double subtotal;
  final double courierFee;
  final String statusMessage;
  final List<AdminOrderItem> items;
  final String address;
  final String customerName;
  final String phone;
  final String paymentMethod;
  final String deliverySlot;
  final String couponCode;
  final double couponDiscount;
  final List<AdminOrderGift> gifts;
  final String invoiceLink;
  final String invoiceNumber;
  final String invoiceDate;
  final String cargoCompany;
  final String cargoTrackingCode;
  final String cargoTrackingUrl;
  final String billingName;
  final String billingAddress;
  final String billingAccountType;
  final String billingNationalId;
  final String billingTaxId;
  final String billingTaxOffice;
  final DateTime? createdAt;
  final DateTime? smsCreatedAt;
  final DateTime? smsShippingAt;
  final DateTime? smsCancelledAt;
  final DateTime? smsDeliveredAt;
  final String smsLastError;

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  factory AdminOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawItems = d[OrderFields.items];
    final created = d[OrderFields.createdAt];
    final parsedItems = <AdminOrderItem>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          parsedItems.add(
            AdminOrderItem.fromMap(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final parsedGifts = AdminOrderGift.parseList(d[OrderFields.gifts]);
    final total = (d[OrderFields.total] as num?)?.toDouble() ?? 0;
    final courierFee = (d[OrderFields.courierFee] as num?)?.toDouble() ?? 0;
    final subtotal =
        (d[OrderFields.subtotal] as num?)?.toDouble() ?? (total - courierFee);
    final billingRaw = d[OrderFields.billing];
    final billing = billingRaw is Map
        ? Map<String, dynamic>.from(billingRaw)
        : const <String, dynamic>{};
    return AdminOrder(
      id: doc.id,
      userId: (d[OrderFields.userId] as String?) ?? '',
      status: (d[OrderFields.status] as String?) ?? OrderStatuses.preparing,
      total: total,
      subtotal: subtotal,
      courierFee: courierFee,
      statusMessage: (d[OrderFields.statusMessage] as String?) ?? '',
      items: parsedItems,
      address: (d[OrderFields.address] as String?) ?? '',
      customerName: (d[OrderFields.customerName] as String?) ?? '',
      phone: (d[OrderFields.phone] as String?) ?? '',
      paymentMethod: (d[OrderFields.paymentMethod] as String?) ?? '',
      deliverySlot: (d[OrderFields.deliverySlot] as String?) ?? '',
      couponCode: (d[OrderFields.couponCode] as String?) ?? '',
      couponDiscount: (d[OrderFields.couponDiscount] as num?)?.toDouble() ?? 0,
      gifts: parsedGifts,
      invoiceLink: (d[OrderFields.invoiceLink] as String?) ?? '',
      invoiceNumber: (d[OrderFields.invoiceNumber] as String?) ?? '',
      invoiceDate: (d[OrderFields.invoiceDate] as String?) ?? '',
      cargoCompany: (d[OrderFields.cargoCompany] as String?) ?? '',
      cargoTrackingCode: (d[OrderFields.cargoTrackingCode] as String?) ?? '',
      cargoTrackingUrl: (d[OrderFields.cargoTrackingUrl] as String?) ?? '',
      billingName: (billing['contactName'] as String?) ?? '',
      billingAddress: (billing['address'] as String?) ?? '',
      billingAccountType: (billing['accountType'] as String?) ?? '',
      billingNationalId: (billing['nationalId'] as String?) ?? '',
      billingTaxId: (billing['taxId'] as String?) ?? '',
      billingTaxOffice: (billing['taxOffice'] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
      smsCreatedAt: d[OrderFields.smsCreatedAt] is Timestamp
          ? (d[OrderFields.smsCreatedAt] as Timestamp).toDate()
          : null,
      smsShippingAt: d[OrderFields.smsShippingAt] is Timestamp
          ? (d[OrderFields.smsShippingAt] as Timestamp).toDate()
          : null,
      smsCancelledAt: d[OrderFields.smsCancelledAt] is Timestamp
          ? (d[OrderFields.smsCancelledAt] as Timestamp).toDate()
          : null,
      smsDeliveredAt: d[OrderFields.smsDeliveredAt] is Timestamp
          ? (d[OrderFields.smsDeliveredAt] as Timestamp).toDate()
          : null,
      smsLastError: (d[OrderFields.smsLastError] as String?) ?? '',
    );
  }
}
