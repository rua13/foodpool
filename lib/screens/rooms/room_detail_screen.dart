import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class RoomDetailScreen extends StatelessWidget {
  const RoomDetailScreen({super.key, required this.roomId});

  final String roomId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('주문 상세'),
        actions: [
          IconButton(
            onPressed: () {
              // TODO(FOODPOOL): 방 삭제(방장만) 연결
            },
            icon: const Icon(Icons.delete_outline),
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            Text('roomId: $roomId'),
            const SizedBox(height: 12),

            // TODO(FOODPOOL): Firestore에서 room 문서 읽어 정보 표시
            const Text('주문 정보(가게명/링크/마감시간/배달비/최소주문금액 등) (TODO)'),
            const SizedBox(height: 24),

            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  context.push('/room/$roomId/chat');
                },
                child: const Text('채팅하기'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () {
                  // TODO(FOODPOOL): 참여하기(joinRoom 함수 호출) 연결
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
