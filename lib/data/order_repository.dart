import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/state/address_store.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/cart_store.dart';
import 'package:geliyor_app/state/coupon_store.dart';
import 'package:geliyor_app/utils/order_no.dart';

class OrderRepository {
  OrderRepository._();
  static final OrderRepository instance = OrderRepository._();

  CollectionReference<Map<String, dynamic>> get _col =>
      FirebaseFirestore.instance.collection(FirestoreCollections.orders);

  Future<String?> placeCurrentCart({
    required String paymentMethod,
    required String deliverySlot,
  }) async {
    final uid = AuthStore.instance.uid;
    if (uid == null) return null;
    final items = CartStore.instance.items;
    if (items.isEmpty) return null;
    if (!AddressStore.instance.hasDeliveryAddress) return null;

    final address = AddressStore.instance.defaultAddress!;
    final invoice = AddressStore.instance.defaultInvoiceAddress ?? address;
    final cart = CartStore.instance;
    final coupons = CouponStore.instance;
    final coupon = coupons.selected;
    final couponDiscount = coupons.discountFor(cart.cartTotal);
    final total = coupons.payableTotal(cart.cartTotal);
    final catalogIds = {
      for (final item in items) catalogProductIdFromCartItem(item),
    }.where((id) => id.isNotEmpty).toList();
    final catalog = <String, Map<String, dynamic>>{};
    if (catalogIds.isNotEmpty) {
      final snaps = await Future.wait([
        for (final id in catalogIds)
          FirebaseFirestore.instance
              .collection(FirestoreCollections.products)
              .doc(id)
              .get(),
      ]);
      for (final snap in snaps) {
        catalog[snap.id] = snap.data() ?? const <String, dynamic>{};
      }
    }
    final ref = _col.doc();
    await ref.set({
      OrderFields.userId: uid,
      OrderFields.status: OrderStatuses.preparing,
      OrderFields.statusMessage: 'Siparişiniz hazırlanıyor.',
      OrderFields.subtotal: cart.cartTotal,
      OrderFields.courierFee: cart.courierFee,
      OrderFields.couponId: coupon?.id ?? '',
      OrderFields.couponCode: coupon?.code ?? '',
      OrderFields.couponTitle: coupon?.title ?? '',
      OrderFields.couponDiscount: couponDiscount,
      OrderFields.total: total,
      OrderFields.customerName:
          address.contactName.trim().isNotEmpty
          ? address.contactName.trim()
          : AuthStore.instance.fullName,
      OrderFields.phone: AuthStore.instance.phone.trim(),
      OrderFields.address: address.address.trim(),
      OrderFields.city: address.city.trim(),
      OrderFields.district: address.district.trim(),
      OrderFields.billing: {
        'address': invoice.address.trim(),
        'city': invoice.city.trim(),
        'district': invoice.district.trim(),
        'town': invoice.district.trim(),
        'contactName': invoice.contactName.trim(),
        'accountType': invoice.isCorporate ? 'corporate' : 'individual',
        'nationalId': invoice.nationalId.trim(),
        'taxId': invoice.taxId.trim(),
        'taxOffice': invoice.taxOffice.trim(),
        'email': AuthStore.instance.email.trim(),
      },
      OrderFields.paymentMethod: paymentMethod,
      OrderFields.deliverySlot: deliverySlot,
      OrderFields.items: [
        for (final item in items)
          () {
            final catalogId = catalogProductIdFromCartItem(item);
            final product = catalog[catalogId] ?? const <String, dynamic>{};
            final barcode = item.barcode.trim().isNotEmpty
                ? item.barcode.trim()
                : (product[ProductFields.barcode] as String?)?.trim() ?? '';
            final vatRate = ProductFields.vatRateFrom(
              product[ProductFields.vatRate],
            );
            return {
              'productId': item.id,
              'catalogProductId': catalogId,
              'title': item.title,
              'quantity': item.quantity,
              'unitPrice': item.unitPrice,
              'weight': item.weight,
              'imageUrl': item.imagePath,
              'barcode': barcode,
              'vatRate': vatRate,
            };
          }(),
      ],
      OrderFields.createdAt: FieldValue.serverTimestamp(),
      OrderFields.updatedAt: FieldValue.serverTimestamp(),
      OrderFields.orderNo: OrderNo.fromId(ref.id),
    });
    return ref.id;
  }

  Future<void> saveGifts({
    required String orderId,
    required List<Map<String, dynamic>> gifts,
  }) async {
    final id = orderId.trim();
    if (id.isEmpty || gifts.isEmpty) {
      throw StateError('Hediye kaydı için sipariş yok.');
    }
    try {
      await FirebaseFunctions.instanceFor(region: 'europe-west1')
          .httpsCallable('saveOrderGifts')
          .call(<String, dynamic>{
            'orderId': id,
            'gifts': gifts,
          });
      return;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'not-found' || error.code == 'permission-denied') {
        rethrow;
      }
    } catch (_) {}

    final uid =
        AuthStore.instance.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      throw StateError('Hediye kaydı için oturum yok.');
    }
    await _col.doc(id).set({
      OrderFields.gifts: gifts,
      OrderFields.updatedAt: FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  Stream<List<PlacedOrder>> watchMine() {
    final uid = AuthStore.instance.uid;
    if (uid == null || uid.isEmpty) {
      return Stream.value(const []);
    }
    return _col.where(OrderFields.userId, isEqualTo: uid).snapshots().map((
      snap,
    ) {
      final list = snap.docs.map(PlacedOrder.fromDoc).toList();
      list.sort((a, b) {
        final aTime = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final bTime = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return bTime.compareTo(aTime);
      });
      return list;
    });
  }

  Future<String> latestOrderId() async {
    final uid =
        AuthStore.instance.uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) return '';
    final snap = await _col.where(OrderFields.userId, isEqualTo: uid).get();
    if (snap.docs.isEmpty) return '';
    final docs = [...snap.docs];
    docs.sort((a, b) {
      final aTime = a.data()[OrderFields.createdAt];
      final bTime = b.data()[OrderFields.createdAt];
      final aMs = aTime is Timestamp ? aTime.millisecondsSinceEpoch : 0;
      final bMs = bTime is Timestamp ? bTime.millisecondsSinceEpoch : 0;
      return bMs.compareTo(aMs);
    });
    return docs.first.id;
  }
}

class PlacedOrderLine {
  const PlacedOrderLine({
    required this.id,
    required this.title,
    required this.quantity,
    required this.unitPrice,
    this.weight = '',
    this.imageUrl = '',
  });

  final String id;
  final String title;
  final int quantity;
  final double unitPrice;
  final String weight;
  final String imageUrl;

  factory PlacedOrderLine.fromMap(Map<String, dynamic> map) {
    return PlacedOrderLine(
      id: (map['productId'] as String?) ?? (map['id'] as String?) ?? '',
      title: (map['title'] as String?) ?? '',
      quantity: (map['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (map['unitPrice'] as num?)?.toDouble() ?? 0,
      weight: (map['weight'] as String?) ?? '',
      imageUrl:
          (map['imageUrl'] as String?) ?? (map['imagePath'] as String?) ?? '',
    );
  }
}

class PlacedOrder {
  const PlacedOrder({
    required this.id,
    required this.status,
    required this.statusMessage,
    required this.total,
    required this.items,
    this.gifts = const [],
    this.createdAt,
  });

  final String id;
  final String status;
  final String statusMessage;
  final double total;
  final List<PlacedOrderLine> items;
  final List<String> gifts;
  final DateTime? createdAt;

  factory PlacedOrder.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? {};
    final rawItems = data[OrderFields.items];
    final items = <PlacedOrderLine>[];
    if (rawItems is List) {
      for (final item in rawItems) {
        if (item is Map) {
          items.add(PlacedOrderLine.fromMap(Map<String, dynamic>.from(item)));
        }
      }
    }
    final created = data[OrderFields.createdAt];
    return PlacedOrder(
      id: doc.id,
      status: (data[OrderFields.status] as String?) ?? OrderStatuses.preparing,
      statusMessage: (data[OrderFields.statusMessage] as String?) ?? '',
      total: (data[OrderFields.total] as num?)?.toDouble() ?? 0,
      items: items,
      gifts: giftTitlesFromRaw(data[OrderFields.gifts]),
      createdAt: created is Timestamp ? created.toDate() : null,
    );
  }
}

List<String> giftTitlesFromRaw(dynamic raw) {
  final titles = <String>[];
  void add(dynamic item) {
    if (item is! Map) return;
    final title = '${item['title'] ?? ''}'.trim();
    if (title.isNotEmpty) titles.add(title);
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
  return titles;
}

/// Sepet satırı `ürünId-ağırlık` formatında; stok düşümü katalog id'sine gider.
String catalogProductIdFromCartItem(CartItem item) {
  final id = item.id.trim();
  final weight = item.weight.trim();
  if (weight.isNotEmpty && id.endsWith('-$weight')) {
    return id.substring(0, id.length - weight.length - 1);
  }
  return id;
}
