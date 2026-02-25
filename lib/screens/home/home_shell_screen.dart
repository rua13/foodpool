import 'package:flutter/material.dart';
import 'package:foodpool/widgets/order_card.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/app_auth_provider.dart';
import '../../repositories/order_repository.dart';
import 'main_page.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '--:--';
    final d = ts.toDate();
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  String _formatMoney(int? n) {
    if (n == null) return '-';
    final s = n.toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final idxFromEnd = s.length - i;
      buf.write(s[i]);
      if (idxFromEnd > 1 && idxFromEnd % 3 == 1) buf.write(',');
    }
    return buf.toString();
  }

  OrderCardData _mapDocToCard(QueryDocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data();

    final title = (data['title'] ?? '').toString();
    final store = (data['storeName'] ?? '').toString();
    final place = (data['pickupSpot'] ?? '').toString();

    final endAt = data['endAt'] is Timestamp ? data['endAt'] as Timestamp : null;

    final minOrder = data['minimumOrderAmount'] is int ? data['minimumOrderAmount'] as int : null;
    // UI의 price에 뭘 보여줄지 정책 필요:
    // - 일단 MVP: "최소주문금액"을 표시
    final priceText = minOrder == null ? '-' : '${_formatMoney(minOrder)}원';

    return OrderCardData(
      orderId: doc.id,
      title: title.isEmpty ? '(제목 없음)' : title,
      time: _formatTime(endAt),
      store: store.isEmpty ? '(가게명 없음)' : store,
      price: priceText,
      place: place.isEmpty ? '(수령장소 없음)' : place,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final repo = context.read<OrderRepository>();

    final uid = auth.user?.uid;
    if (uid == null) {
      // redirect가 잘 되어 있으면 여기까지 잘 안 오지만 안전장치
      return MainPage(
        allOrders: const [],
        myOrders: const [],
        onTapWrite: null,
        onTapOrder: null,
        onTapProfile: null,
      );
    }

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.watchAllOrders(),
      builder: (context, allSnap) {
        if (allSnap.hasError) {
          return Center(child: Text('전체 주문 로드 오류: ${allSnap.error}'));
        }
        if (!allSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allOrders = allSnap.data!.docs.map(_mapDocToCard).toList(growable: false);

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: repo.watchMyOrders(uid),
          builder: (context, mySnap) {
            if (mySnap.hasError) {
              return Center(child: Text('내 주문 로드 오류: ${mySnap.error}'));
            }
            if (!mySnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final myOrders = mySnap.data!.docs.map(_mapDocToCard).toList(growable: false);

            return MainPage(
              allOrders: allOrders,
              myOrders: myOrders,
              onTapWrite: () => context.push('/create'),
              onTapOrder: (orderId) => context.push('/order/$orderId'),
              onTapProfile: auth.isLoading
                  ? null
                  : () async {
                      await context.read<AppAuthProvider>().signOut();
                    },
            );
          },
        );
      },
    );
  }
}
