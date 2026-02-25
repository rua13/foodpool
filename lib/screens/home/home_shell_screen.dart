import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../providers/app_auth_provider.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Foodpool'),
          actions: [
            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await context.read<AppAuthProvider>().signOut();
                    },
              child: const Text('로그아웃'),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: '전체'),
              Tab(text: '내 주문'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _AllRoomsTab(),
            _MyRoomsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            // TODO(FOODPOOL): 공동주문 만들기 화면으로 이동
            context.push('/create');
            // - Navigator면: Navigator.push(...)
          },
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}

class _AllRoomsTab extends StatelessWidget {
  const _AllRoomsTab();

  @override
  Widget build(BuildContext context) {
    // TODO(FOODPOOL):
    // - rooms 전체 공개 목록 스트림 연결
    // - 참여중 방 상단 / 마감 방 하단 정렬(초기엔 클라 정렬 추천)
    return const Center(
      child: Text('전체 방 목록 (TODO)'),
    );
  }
}

class _MyRoomsTab extends StatelessWidget {
  const _MyRoomsTab();

  @override
  Widget build(BuildContext context) {
    // TODO(FOODPOOL):
    // - rooms.where(memberIds array-contains uid)
    // - "퇴장한 방은 안 보이게" => memberIds에 없으면 자동 제외(요구사항과 일치)
    // - 마감된 방만 띄우려면 endAt <= now 필터(초기엔 클라에서 필터)
    return const Center(
      child: Text('내 주문(참여 중/마감) (TODO)'),
    );
  }
}
