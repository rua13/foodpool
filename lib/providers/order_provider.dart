import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../repositories/order_repository.dart';

class OrderProvider extends ChangeNotifier {
  OrderProvider(this._repo, {FirebaseFunctions? functions})
      : _functions = functions ?? FirebaseFunctions.instance;

  final OrderRepository _repo;
  final FirebaseFunctions _functions;

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

  Future<void> joinOrder(String orderId) async {
    error = null;
    isLoading = true;
    notifyListeners();
    try {
      final callable = _functions.httpsCallable('joinOrder');
      await callable.call({'orderId': orderId});
    } on FirebaseFunctionsException catch (e) {
      error = '${e.code}: ${e.message ?? ''}';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> leaveOrder(String orderId) async {
    error = null;
    isLoading = true;
    notifyListeners();
    try {
      final callable = _functions.httpsCallable('leaveOrder');
      await callable.call({'orderId': orderId});
    } on FirebaseFunctionsException catch (e) {
      error = '${e.code}: ${e.message ?? ''}';
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}
