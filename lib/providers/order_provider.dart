import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._repo,);

  final OrderRepository _repo;

  bool isLoading = false;
  String? error;

  Future<String> createOrder({
    required String ownerId,
    required String title,
    required String storeName,
    required String pickupSpot,
    required String link,
    required String depositMethods,
    required int minimumOrderAmount,
    required int deliveryFee,
    required DateTime endAtLocal,
  }) async {
    error = null;
    isLoading = true;
    notifyListeners();

    try {
      final ts = Timestamp.fromDate(endAtLocal);
      final orderId = await _repo.createOrder(
        ownerId: ownerId,
        title: title,
        storeName: storeName,
        pickupSpot: pickupSpot,
        link: link,
        depositMethods: depositMethods,
        minimumOrderAmount: minimumOrderAmount,
        deliveryFee: deliveryFee,
        endAt: ts,
      );
      return orderId;
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> joinOrder(String orderId, String uid) =>
      _repo.joinOrder(orderId: orderId, uid: uid);
  Future<void> leaveOrder(String orderId, String uid) => _repo.leaveOrder(orderId: orderId, uid: uid);

}
