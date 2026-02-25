import 'package:cloud_firestore/cloud_firestore.dart';

class OrderMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String text;
  final DateTime createdAt;

  const OrderMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.text,
    required this.createdAt,
  });

  factory OrderMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final createdAtRaw = data['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);

    return OrderMessage(
      id: doc.id,
      orderId: (data['orderId'] ?? '') as String,
      senderId: (data['senderId'] ?? '') as String,
      text: (data['text'] ?? '') as String,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toMapForCreate({
    required String orderId,
    required String senderId,
    required String text,
  }) {
    return {
      'orderId': orderId,
      'senderId': senderId,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(), // ✅ 서버 타임
    };
  }
}
