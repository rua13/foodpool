import 'package:cloud_firestore/cloud_firestore.dart';

class OrderService {
  OrderService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> ordersCol() =>
      _db.collection('orders');

  DocumentReference<Map<String, dynamic>> orderDoc(String orderId) =>
      ordersCol().doc(orderId);

  CollectionReference<Map<String, dynamic>> messagesCol(String orderId) =>
      orderDoc(orderId).collection('messages');

  CollectionReference<Map<String, dynamic>> membersCol(String orderId) =>
      orderDoc(orderId).collection('members');
}
