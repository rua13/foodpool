import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/order_member_model.dart';
import '../models/order_message_model.dart';
import '../services/order_chat_service.dart';

class OrderChatRepository {
  OrderChatRepository(this._service);

  final OrderChatService _service;

  Stream<List<OrderMessage>> listenMessages(String orderId) {
    return _service.watchMessagesAsc(orderId).map((snap) {
      return snap.docs.map((d) => OrderMessage.fromDoc(d)).toList(growable: false);
    });
  }

  Stream<List<OrderMember>> listenMembers(String orderId) {
    return _service.watchMembers(orderId).map((snap) {
      return snap.docs.map((d) => OrderMember.fromDoc(d)).toList(growable: false);
    });
  }

  Future<void> sendTextMessage({
    required String orderId,
    required String text,
  }) {
    return _service.sendTextMessage(orderId: orderId, text: text);
  }

  Future<void> sendExitNoticeMessage({
    required String orderId,
    required String text,
  }) {
    return _service.sendExitNoticeMessage(orderId: orderId, text: text);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMemberSnap({
    required String orderId,
    required String memberUid,
  }) {
    return _service.watchMember(orderId, memberUid);
  }

  Future<DocumentSnapshot<Map<String, dynamic>>> fetchMemberSnap({
    required String orderId,
    required String memberUid,
  }) {
    return _service.fetchMember(orderId, memberUid);
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrderSnap(String orderId) {
    return _service.watchOrder(orderId);
  }
}
