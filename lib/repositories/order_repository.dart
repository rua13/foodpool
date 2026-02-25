import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/order_service.dart';

class OrderRepository {
  OrderRepository(this._svc);

  final OrderService _svc;

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrderSnap(String orderId) {
    return _svc.orderDoc(orderId).snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchAllOrders() {
    return _svc.ordersCol()
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchMyOrders(String uid) {
    return _svc.ordersCol()
        .where('memberIds', arrayContains: uid)
        // .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<String> createOrder({
    required String ownerId,
    required String title,
    required String storeName,
    required String pickupSpot,
    required String link,
    required String depositMethods,
    required int minimumOrderAmount,
    required int deliveryFee,
    required Timestamp endAt,
  }) async {
    final ref = _svc.ordersCol().doc();

    final now = FieldValue.serverTimestamp();

    await ref.set({
      'ownerId': ownerId,
      'title': title,
      'storeName': storeName,
      'pickupSpot': pickupSpot,
      'link': link,

      'depositMethods': depositMethods,
      'minimumOrderAmount': minimumOrderAmount,
      'deliveryFee': deliveryFee,

      'endAt': endAt,
      'isClosed': false,

      'memberIds': [ownerId],
      'memberCount': 1,

      'createdAt': now,
      'updatedAt': now,
    });

    return ref.id;
  }

  Future<void> sendMessage({
    required String orderId,
    required String senderId,
    required String text,
  }) async {
    final ref = _svc.messagesCol(orderId).doc();
    await ref.set({
      'orderId': orderId,
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // ⚠️ 절대 orders.updatedAt을 클라에서 올리면 안 됨 (서버 트리거가 처리)
  }
}
