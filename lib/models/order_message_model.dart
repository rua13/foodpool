import 'package:cloud_firestore/cloud_firestore.dart';

class OrderMessage {
  final String id;
  final String orderId;
  final String senderId;
  final String text;
  final String messageType;
  final DateTime createdAt;

  const OrderMessage({
    required this.id,
    required this.orderId,
    required this.senderId,
    required this.text,
    required this.messageType,
    required this.createdAt,
  });

  factory OrderMessage.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    final createdAtRaw = data['createdAt'];
    final createdAt = createdAtRaw is Timestamp
        ? createdAtRaw.toDate()
        // pending write 중 serverTimestamp가 아직 null이면 "지금 시각"으로 간주해
        // 하단(최신) 위치를 유지하고, 서버 확정 후에도 점프를 최소화한다.
        : (doc.metadata.hasPendingWrites
            ? DateTime.now()
            : DateTime.fromMillisecondsSinceEpoch(0));

    return OrderMessage(
      id: doc.id,
      orderId: (data['orderId'] ?? '') as String,
      senderId: (data['senderId'] ?? '') as String,
      text: (data['text'] ?? '') as String,
      messageType: (data['messageType'] ?? 'text') as String,
      createdAt: createdAt,
    );
  }

  bool get isExitNotice => messageType == 'system_exit';
  bool get isJoinNotice => messageType == 'system_join';

  Map<String, dynamic> toMapForCreate({
    required String orderId,
    required String senderId,
    required String text,
  }) {
    return {
      'orderId': orderId,
      'senderId': senderId,
      'text': text,
      'messageType': 'text',
      'createdAt': FieldValue.serverTimestamp(), // ✅ 서버 타임
    };
  }
}
