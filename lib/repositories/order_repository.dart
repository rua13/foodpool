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

  Future<void> joinOrder({required String orderId, required String uid}) async {
    final ref = _svc.ordersCol().doc(orderId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('order not found');

      final data = snap.data()!;
      final memberIds = List<String>.from((data['memberIds'] ?? []) as List);
      final already = memberIds.contains(uid);

      if (already) return; // ✅ 멱등: 이미 멤버면 성공 처리

      tx.update(ref, {
        'memberIds': FieldValue.arrayUnion([uid]),
        'memberCount': ((data['memberCount'] ?? memberIds.length) + 1),
      });
    });
  }

  Future<void> leaveOrder({required String orderId, required String uid}) async {
    final ref = _svc.ordersCol().doc(orderId);

    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) throw Exception('order not found');

      final data = snap.data()!;
      final memberIds = List<String>.from((data['memberIds'] ?? []) as List);
      final isMember = memberIds.contains(uid);

      // 멤버가 아니면 그냥 성공 처리(멱등)
      if (!isMember) return;

      final currentCount = (data['memberCount'] ?? memberIds.length) as int;

      tx.update(ref, {
        'memberIds': FieldValue.arrayRemove([uid]),
        'memberCount': (currentCount - 1).clamp(0, 1 << 30),
      });
    });
  }

}
