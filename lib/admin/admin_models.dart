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
    this.skt = '',
    required this.unitPrice,
    required this.oldPrice,
    required this.discountPercent,
    required this.imageUrl,
    required this.category,
    this.mainCategory = 'cat',
    required this.description,
    required this.active,
    required this.stock,
    this.features = const [],
    this.technicalFeatures = const [],
    this.trustBadgeIds = const [],
    this.productAdvantageIds = const [],
    this.productAdvantageValues = const {},
    this.proteinValue = '',
    this.preferredRank = '',
    this.repurchaseRate = '',
    this.rating = 0,
    this.reviewCount = 0,
    this.gallery = const [],
    this.seoTitle = '',
    this.metaDescription = '',
    this.createdAt,
  });

  final String id;
  final String title;
  final String brand;
  final String weight;

  /// Ürün barkodu (kopyalanırken boş bırakılır).
  final String barcode;

  /// Son kullanma (gösterim: `11.2027`)
  final String skt;
  final double unitPrice;
  final double oldPrice;
  final int discountPercent;
  final String imageUrl;
  final String category;
  final String mainCategory;
  final String description;
  final bool active;
  final int stock;
  final List<AdminProductFeature> features;
  final List<AdminProductFeature> technicalFeatures;
  final List<String> trustBadgeIds;
  final List<String> productAdvantageIds;
  final Map<String, String> productAdvantageValues;
  final String proteinValue;
  final String preferredRank;
  final String repurchaseRate;
  final double rating;
  final int reviewCount;
  final List<String> gallery;
  final String seoTitle;
  final String metaDescription;
  final DateTime? createdAt;

  factory AdminProduct.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? <String, dynamic>{};
    final created = d[ProductFields.createdAt];
    return AdminProduct(
      id: doc.id,
      title: (d[ProductFields.title] as String?) ?? '',
      brand: (d[ProductFields.brand] as String?) ?? '',
      weight: (d[ProductFields.weight] as String?) ?? '',
      barcode: (d[ProductFields.barcode] as String?) ?? '',
      skt: ProductSkt.fromFirestore(d),
      unitPrice: (d[ProductFields.unitPrice] as num?)?.toDouble() ?? 0,
      oldPrice: (d[ProductFields.oldPrice] as num?)?.toDouble() ?? 0,
      discountPercent: (d[ProductFields.discountPercent] as num?)?.toInt() ?? 0,
      imageUrl: (d[ProductFields.imageUrl] as String?) ?? '',
      category: (d[ProductFields.category] as String?) ?? '',
      mainCategory: (d[ProductFields.mainCategory] as String?) ?? 'cat',
      description: (d[ProductFields.description] as String?) ?? '',
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
      preferredRank: _preferredRankFrom(d[ProductFields.preferredRank]),
      repurchaseRate: _rateFrom(d[ProductFields.repurchaseRate]),
      rating: (d[ProductFields.rating] as num?)?.toDouble() ?? 0,
      reviewCount: (d[ProductFields.reviewCount] as num?)?.toInt() ?? 0,
      gallery:
          (d[ProductFields.gallery] as List?)?.whereType<String>().toList() ??
          const [],
      seoTitle: (d[ProductFields.seoTitle] as String?) ?? '',
      metaDescription: (d[ProductFields.metaDescription] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }

  Map<String, dynamic> toMap({bool isCreate = false}) {
    return {
      ProductFields.title: title.trim(),
      ProductFields.brand: brand.trim(),
      ProductFields.weight: weight.trim(),
      ProductFields.barcode: barcode.trim(),
      ...ProductSkt.toFirestoreFields(skt),
      ProductFields.unitPrice: unitPrice,
      ProductFields.oldPrice: oldPrice,
      ProductFields.discountPercent: discountPercent,
      ProductFields.imageUrl: imageUrl.trim(),
      ProductFields.category: category.trim(),
      ProductFields.mainCategory: mainCategory.trim(),
      ProductFields.description: description.trim(),
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
      ProductFields.preferredRank: preferredRank.trim(),
      ProductFields.repurchaseRate: repurchaseRate.trim(),
      ProductFields.rating: rating,
      ProductFields.reviewCount: reviewCount,
      ProductFields.gallery: gallery,
      ProductFields.seoTitle: seoTitle.trim(),
      ProductFields.metaDescription: metaDescription.trim(),
      ProductFields.updatedAt: FieldValue.serverTimestamp(),
      if (isCreate) ProductFields.createdAt: FieldValue.serverTimestamp(),
    };
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

  static Map<String, String> _advantageValuesFrom(dynamic raw) {
    if (raw is! Map) return const {};
    return raw.map(
      (key, value) => MapEntry('$key', (value as String?)?.trim() ?? ''),
    )..removeWhere((_, value) => value.isEmpty);
  }

  static String _proteinValueFrom(dynamic proteinField, dynamic advantageValues) {
    final direct = (proteinField as String?)?.trim() ?? '';
    if (direct.isNotEmpty) return direct;
    if (advantageValues is Map) {
      final legacy = (advantageValues[ProductAdvantageRepository.proteinAdvantageId]
              as String?)
          ?.trim();
      if (legacy != null && legacy.isNotEmpty) return legacy;
    }
    return '';
  }

  static String _preferredRankFrom(dynamic raw) {
    final value = (raw as String?)?.trim() ?? '';
    if (value.isEmpty) return '';
    return value.endsWith('.') ? value : '$value.';
  }

  static String _rateFrom(dynamic raw) {
    if (raw is num) return '%${raw.round()}';
    final value = (raw as String?)?.trim() ?? '';
    if (value.isEmpty) return '';
    return value.startsWith('%') ? value : '%$value';
  }

  /// Yeni ürün olarak kopyala — barkod boş, id yok (yeni kayıt).
  /// Orijinal ürün değişmez; kaydedince Firestore’da ayrı doküman oluşur.
  AdminProduct asCopy() {
    final baseTitle = title.trim();
    final copyTitle = baseTitle.isEmpty
        ? 'Kopya ürün'
        : (baseTitle.contains('(Kopya)')
              ? baseTitle
              : '$baseTitle (Kopya)');
    return AdminProduct(
      id: '',
      title: copyTitle,
      brand: brand,
      weight: weight,
      barcode: '',
      skt: skt,
      unitPrice: unitPrice,
      oldPrice: oldPrice,
      discountPercent: discountPercent,
      imageUrl: imageUrl,
      category: category,
      mainCategory: mainCategory,
      description: description,
      active: active,
      stock: stock,
      features: features,
      technicalFeatures: technicalFeatures,
      trustBadgeIds: trustBadgeIds,
      productAdvantageIds: productAdvantageIds,
      productAdvantageValues: productAdvantageValues,
      proteinValue: proteinValue,
      preferredRank: preferredRank,
      repurchaseRate: repurchaseRate,
      rating: rating,
      reviewCount: reviewCount,
      gallery: gallery,
      seoTitle: seoTitle,
      metaDescription: metaDescription,
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

class AdminOrder {
  const AdminOrder({
    required this.id,
    required this.userId,
    required this.status,
    required this.total,
    required this.statusMessage,
    required this.items,
    this.address = '',
    this.customerName = '',
    this.phone = '',
    this.paymentMethod = '',
    this.deliverySlot = '',
    this.createdAt,
  });

  final String id;
  final String userId;
  final String status;
  final double total;
  final String statusMessage;
  final List<AdminOrderItem> items;
  final String address;
  final String customerName;
  final String phone;
  final String paymentMethod;
  final String deliverySlot;
  final DateTime? createdAt;

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
    return AdminOrder(
      id: doc.id,
      userId: (d[OrderFields.userId] as String?) ?? '',
      status: (d[OrderFields.status] as String?) ?? OrderStatuses.preparing,
      total: (d[OrderFields.total] as num?)?.toDouble() ?? 0,
      statusMessage: (d[OrderFields.statusMessage] as String?) ?? '',
      items: parsedItems,
      address: (d[OrderFields.address] as String?) ?? '',
      customerName: (d[OrderFields.customerName] as String?) ?? '',
      phone: (d[OrderFields.phone] as String?) ?? '',
      paymentMethod: (d[OrderFields.paymentMethod] as String?) ?? '',
      deliverySlot: (d[OrderFields.deliverySlot] as String?) ?? '',
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}
