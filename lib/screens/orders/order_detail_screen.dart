import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/order_provider.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  Future<void> _joinAndGoChat(BuildContext context) async {
    // ✅ 요구 UX: "채팅하기 버튼 누르면 참여(join) + 채팅 이동"
    // 아직 joinOrder가 없다면 아래 TODO부터 구현하면 됨.
    await context.read<OrderProvider>().joinOrder(orderId);

    if (!context.mounted) return;
    context.push('/order/$orderId/chat');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 상세'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO: 방장만 삭제 가능하도록 Provider/Cloud Function/Rules와 연결
              // context.read<OrderProvider>().deleteOrder(orderId);
            },
            icon: const Icon(Icons.delete_outline),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('orderId: $orderId'),
            const SizedBox(height: 12),
            const Text('주문 정보 표시 (TODO)'),
            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () => _joinAndGoChat(context),
                child: const Text('채팅하기'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
