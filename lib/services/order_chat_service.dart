import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// =======================
/// Orders Chat Service
/// 경로:
/// - orders/{orderId}
/// - orders/{orderId}/messages/{messageId}
/// - orders/{orderId}/members/{uid}
/// =======================
class OrderChatService {
  OrderChatService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _db;
  final FirebaseAuth _auth;

  // ---------- refs ----------
  DocumentReference<Map<String, dynamic>> _orderRef(String orderId) {
    return _db.collection('orders').doc(orderId);
  }

  CollectionReference<Map<String, dynamic>> _messagesCol(String orderId) {
    return _orderRef(orderId).collection('messages');
  }

  CollectionReference<Map<String, dynamic>> _membersCol(String orderId) {
    return _orderRef(orderId).collection('members');
  }

  DocumentReference<Map<String, dynamic>> _memberRef(String orderId, String uid) {
    return _orderRef(orderId).collection('members').doc(uid);
  }

  String _requireUid() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw StateError('로그인이 필요합니다.');
    return uid;
  }

  // ---------- order ----------
  /// (선택) 채팅 헤더용: orders/{orderId} 스냅샷
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchOrder(String orderId) {
    return _orderRef(orderId).snapshots();
  }

  // ---------- messages ----------
  /// 메시지 스트림
  /// - 카톡처럼 "아래로 쌓기"를 원하면:
  ///   - UI(ListView)에서 reverse: true를 쓰거나
  ///   - 여기서 ascending으로 받고 UI는 일반 방향을 쓰는 식으로 정하면 됨
  ///
  /// 지금은 "오래된 → 최신" (ascending)으로 반환:
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessagesAsc(String orderId) {
    return _messagesCol(orderId)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  /// 최신 메시지부터 받고 싶으면 이걸 사용(선택)
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMessagesDesc(String orderId) {
    return _messagesCol(orderId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  /// 메시지 보내기 (필수 필드만)
  /// 문서 예:
  /// {
  ///   orderId: "...",
  ///   senderId: "...",
  ///   text: "...",
  ///   createdAt: serverTimestamp
  /// }
  Future<void> sendTextMessage({
    required String orderId,
    required String text,
  }) async {
    final uid = _requireUid();
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

    final msgRef = _messagesCol(orderId).doc();

    await msgRef.set({
      'orderId': orderId,
      'senderId': uid,
      'text': trimmed,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // (선택) orders 문서에 lastMessage / updatedAt 같은 걸 남기고 싶으면
    // 여기서 batch로 같이 업데이트하면 됨.
    //
    // 주의: 너 rules에서 orders.updatedAt은 클라 변경 금지로 묶어둔 적이 있었음.
    // 지금도 그 정책이면 여기서 orders를 건드리면 permission-denied 뜸.
  }

  // ---------- members (옵션 A 핵심) ----------
  /// 채팅에서 프로필을 보여주기 위한 "주문방 멤버 프로필" upsert
  ///
  /// members/{uid}
  /// {
  ///   uid: "...",
  ///   displayName: "...",
  ///   photoUrl: "...",
  ///   joinedAt: serverTimestamp (최초 1회)
  ///   updatedAt: serverTimestamp (매번)
  /// }
  ///
  /// join 직후(orders.memberIds에 uid 추가된 이후)에 호출하는 것을 권장.
  Future<void> upsertMyMemberProfile({
    required String orderId,
    required String displayName,
    required String photoUrl,
  }) async {
    final uid = _requireUid();

    final ref = _memberRef(orderId, uid);

    final name = displayName.trim();
    final photo = photoUrl.trim();

    // joinedAt은 "최초 1회"만 저장하고, 이후 재진입 시에는 유지한다.
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final base = <String, dynamic>{
        'uid': uid,
        'displayName': name.isEmpty ? '사용자' : name,
        'photoUrl': photo, // 빈 문자열이어도 string
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (snap.exists) {
        tx.set(ref, base, SetOptions(merge: true));
        return;
      }

      tx.set(ref, {
        ...base,
        'joinedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  /// 특정 멤버 프로필 1개 watch (senderId -> 이걸로 UI 표시)
  Stream<DocumentSnapshot<Map<String, dynamic>>> watchMember(
    String orderId,
    String memberUid,
  ) {
    return _memberRef(orderId, memberUid).snapshots();
  }

  /// 주문방 멤버 전체 스트림
  Stream<QuerySnapshot<Map<String, dynamic>>> watchMembers(String orderId) {
    return _membersCol(orderId).snapshots();
  }

  /// 특정 멤버 프로필 1개 fetch (캐시/매핑용)
  Future<DocumentSnapshot<Map<String, dynamic>>> fetchMember(
    String orderId,
    String memberUid,
  ) {
    return _memberRef(orderId, memberUid).get();
  }
}
