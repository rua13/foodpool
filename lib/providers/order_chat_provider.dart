import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/order_member_model.dart';
import '../models/order_message_model.dart';
import '../repositories/order_chat_repository.dart';

class OrderChatProvider extends ChangeNotifier {
  OrderChatProvider(this._repo);

  final OrderChatRepository _repo;

  String? activeOrderId;

  List<OrderMessage> messages = [];
  bool isLoading = false;
  String? lastError;

  // senderId -> 프로필 캐시
  final Map<String, OrderMember> membersByUid = {};

  StreamSubscription? _msgSub;
  StreamSubscription? _membersSub;

  /// orderId 채팅방 진입
  void startListening(String orderId) {
    lastError = null;
    activeOrderId = orderId;

    isLoading = true;
    notifyListeners();

    _msgSub?.cancel();
    _membersSub?.cancel();
    membersByUid.clear();

    _msgSub = _repo.listenMessages(orderId).listen(
      (data) {
        messages = data;
        isLoading = false;
        notifyListeners();
      },
      onError: (e) {
        lastError = e.toString();
        isLoading = false;
        notifyListeners();
      },
    );

    _membersSub = _repo.listenMembers(orderId).listen(
      (data) {
        membersByUid
          ..clear()
          ..addEntries(data.map((m) => MapEntry(m.uid, m)));
        notifyListeners();
      },
      onError: (e) {
        lastError = e.toString();
        notifyListeners();
      },
    );
  }

  Future<void> sendText(String text) async {
    final orderId = activeOrderId;
    if (orderId == null) return;

    try {
      await _repo.sendTextMessage(orderId: orderId, text: text);
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  Future<void> sendExitNotice(String text) async {
    final orderId = activeOrderId;
    if (orderId == null) return;

    try {
      await _repo.sendExitNoticeMessage(orderId: orderId, text: text);
    } catch (e) {
      lastError = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  void stop() {
    activeOrderId = null;
    _msgSub?.cancel();
    _msgSub = null;
    _membersSub?.cancel();
    _membersSub = null;

    messages = [];
    membersByUid.clear();
    isLoading = false;
    lastError = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _membersSub?.cancel();
    super.dispose();
  }
}
