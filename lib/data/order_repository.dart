import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geliyor_app/data/firestore_collections.dart';
import 'package:geliyor_app/state/address_store.dart';
import 'package:geliyor_app/state/auth_store.dart';
import 'package:geliyor_app/state/cart_store.dart';

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

    final address = AddressStore.instance.defaultAddress;
    final doc = await _col.add({
      OrderFields.userId: uid,
      OrderFields.status: OrderStatuses.preparing,
      OrderFields.statusMessage: 'Siparişiniz hazırlanıyor.',
      OrderFields.total: CartStore.instance.cartTotal,
      OrderFields.customerName:
          address?.contactName.trim().isNotEmpty == true
          ? address!.contactName.trim()
          : AuthStore.instance.fullName,
      OrderFields.phone:
          address?.phone.trim().isNotEmpty == true
          ? address!.phone.trim()
          : AuthStore.instance.phone,
      OrderFields.address: address?.address ?? '',
      OrderFields.paymentMethod: paymentMethod,
      OrderFields.deliverySlot: deliverySlot,
      OrderFields.items: [
        for (final item in items)
          {
            'productId': item.id,
            'title': item.title,
            'quantity': item.quantity,
            'unitPrice': item.unitPrice,
            'weight': item.weight,
            'imageUrl': item.imagePath,
          },
      ],
      OrderFields.createdAt: FieldValue.serverTimestamp(),
      OrderFields.updatedAt: FieldValue.serverTimestamp(),
    });
    return doc.id;
  }
}
