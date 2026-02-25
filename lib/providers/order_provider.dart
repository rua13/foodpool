import 'package:flutter/foundation.dart';
import '../repositories/order_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class OrderProvider extends ChangeNotifier {
  OrderProvider(this._repo);

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
      // endAt: local DateTime -> Timestamp
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

  // join/leave는 Cloud Functions callable로 갈 거라
  // 여기에는 나중에 FirebaseFunctions 붙여서 구현할 예정.
}
