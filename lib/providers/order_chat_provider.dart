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
  final Map<String, StreamSubscription> _memberSubs = {};

  /// orderId 채팅방 진입
  void startListening(String orderId) {
    lastError = null;
    activeOrderId = orderId;

    isLoading = true;
    notifyListeners();

    _msgSub?.cancel();
    _cancelAllMemberSubs(); // 방 바뀌면 기존 member 구독도 정리

    _msgSub = _repo.listenMessages(orderId).listen(
      (data) {
        messages = data;
        isLoading = false;
        notifyListeners();

        _ensureMemberSubscriptionsForCurrentMessages();
      },
      onError: (e) {
        lastError = e.toString();
        isLoading = false;
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

  void stop() {
    activeOrderId = null;
    _msgSub?.cancel();
    _msgSub = null;
    _cancelAllMemberSubs();

    messages = [];
    membersByUid.clear();
    isLoading = false;
    lastError = null;
    notifyListeners();
  }

  void _ensureMemberSubscriptionsForCurrentMessages() {
    final orderId = activeOrderId;
    if (orderId == null) return;

    final senderIds = messages.map((m) => m.senderId).where((id) => id.isNotEmpty).toSet();

    // 새로 등장한 senderId만 구독 추가
    for (final uid in senderIds) {
      if (_memberSubs.containsKey(uid)) continue;

      _memberSubs[uid] = _repo
          .watchMemberSnap(orderId: orderId, memberUid: uid)
          .listen((snap) {
        if (!snap.exists) return;

        final member = OrderMember.fromDoc(snap);
        membersByUid[uid] = member;
        notifyListeners();
      });
    }

    // 더 이상 안 쓰는 senderId 구독은 정리(메시지 스크롤이 길어질수록 계속 남는 걸 방지)
    final toRemove = _memberSubs.keys.where((uid) => !senderIds.contains(uid)).toList();
    for (final uid in toRemove) {
      _memberSubs[uid]?.cancel();
      _memberSubs.remove(uid);
      // membersByUid는 굳이 지우지 않아도 되지만(캐시), 원하면 지워도 됨
      // membersByUid.remove(uid);
    }
  }

  void _cancelAllMemberSubs() {
    for (final sub in _memberSubs.values) {
      sub.cancel();
    }
    _memberSubs.clear();
  }

  @override
  void dispose() {
    _msgSub?.cancel();
    _cancelAllMemberSubs();
    super.dispose();
  }
}
