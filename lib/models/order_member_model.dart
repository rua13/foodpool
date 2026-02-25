import 'package:cloud_firestore/cloud_firestore.dart';

class OrderMember {
  final String uid;
  final String displayName;
  final String photoUrl;
  final DateTime? joinedAt;
  final DateTime? updatedAt;

  const OrderMember({
    required this.uid,
    required this.displayName,
    required this.photoUrl,
    required this.joinedAt,
    required this.updatedAt,
  });

  factory OrderMember.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    DateTime? _toDate(dynamic raw) => raw is Timestamp ? raw.toDate() : null;

    return OrderMember(
      uid: (data['uid'] as String?) ?? doc.id,
      displayName: (data['displayName'] ?? '') as String,
      photoUrl: (data['photoUrl'] ?? '') as String,
      joinedAt: _toDate(data['joinedAt']),
      updatedAt: _toDate(data['updatedAt']),
    );
  }
}
