import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/app_auth_provider.dart';
import '../../repositories/order_repository.dart';

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
            _AllOrdersTab(),
            _MyOrdersTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => context.push('/create'),
          child: const Icon(Icons.edit),
        ),
      ),
    );
  }
}

class _AllOrdersTab extends StatelessWidget {
  const _AllOrdersTab();

  @override
  Widget build(BuildContext context) {
    final repo = context.read<OrderRepository>();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.watchAllOrders(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('오류: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('아직 생성된 주문이 없어요.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();

            final title = (data['title'] ?? '').toString();
            final store = (data['storeName'] ?? '').toString();
            final isClosed = (data['isClosed'] ?? false) == true;

            Timestamp? endAtTs;
            final rawEndAt = data['endAt'];
            if (rawEndAt is Timestamp) endAtTs = rawEndAt;

            return ListTile(
              tileColor: Colors.grey.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(title.isEmpty ? '(제목 없음)' : title),
              subtitle: Text([
                if (store.isNotEmpty) store,
                if (endAtTs != null) '마감: ${endAtTs.toDate()}',
                if (isClosed) '마감됨',
              ].join(' · ')),
              onTap: () => context.push('/order/${d.id}'),
            );
          },
        );
      },
    );
  }
}

class _MyOrdersTab extends StatelessWidget {
  const _MyOrdersTab();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final uid = auth.user?.uid;

    if (uid == null) {
      return const Center(child: Text('로그인이 필요합니다.'));
    }

    final repo = context.read<OrderRepository>();

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: repo.watchMyOrders(uid),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(child: Text('오류: ${snap.error}'));
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(child: Text('참여 중인 주문이 없어요.'));
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final d = docs[i];
            final data = d.data();

            final title = (data['title'] ?? '').toString();
            final store = (data['storeName'] ?? '').toString();

            return ListTile(
              tileColor: Colors.blue.shade50.withOpacity(0.25),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              title: Text(title.isEmpty ? '(제목 없음)' : title),
              subtitle: Text(store.isEmpty ? '가게명 없음' : store),
              onTap: () => context.push('/order/${d.id}'),
            );
          },
        );
      },
    );
  }
}
