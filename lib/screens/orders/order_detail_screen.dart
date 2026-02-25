import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  Future<void> _joinAndGoChat(BuildContext context) async {
    // TODO(FOODPOOL):
    // 1) OrderProvider.joinOrder(orderId) (Callable Function 호출)
    // 2) 성공하면 채팅 화면으로 이동
    //
    // 예:
    // await context.read<OrderProvider>().joinOrder(orderId);
    // if (!context.mounted) return;
    // context.push('/order/$orderId/chat');

    context.push('/order/$orderId/chat'); // 임시
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 상세'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO(FOODPOOL): order 삭제(방장만) => OrderProvider.deleteOrder(orderId)
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
            const SizedBox(height: 12),

            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () async {
                  // TODO(FOODPOOL): join만 하고 stay (내 주문에 추가만)
                  // await context.read<OrderProvider>().joinOrder(orderId);
                },
                child: const Text('주문 참여(내 주문에 추가)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
