import 'package:flutter/material.dart';
import 'package:foodpool/providers/app_auth_provider.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/order_provider.dart';
import '../../repositories/order_repository.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  String _two(int n) => n.toString().padLeft(2, '0');

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

  _OrderDetailData _mapDocToDetail(Map<String, dynamic> data) {
    final endAt = data['endAt'] is Timestamp ? data['endAt'] as Timestamp : null;
    final endAtStr = endAt == null
        ? '-'
        : '${_two(endAt.toDate().hour)}:${_two(endAt.toDate().minute)}';

    final minOrder = data['minimumOrderAmount'] is int ? data['minimumOrderAmount'] as int : null;
    final deliveryFee = data['deliveryFee'] is int ? data['deliveryFee'] as int : null;

    final minOrderStr = minOrder == null ? '-' : _formatMoney(minOrder);
    final deliveryFeeStr = deliveryFee == null ? '-' : _formatMoney(deliveryFee);

    final depositMethods = (data['depositMethods'] ?? '-').toString();

    final note = (data['note'] ?? '').toString().trim();
    final noteStr = note.isEmpty ? '채팅방 들어오면 바로 계좌 보내드릴게용' : note;
    final isClosed = endAt != null && endAt.toDate().isBefore(DateTime.now());

    return _OrderDetailData(
      title: (data['title'] ?? '-').toString(),
      time: endAtStr,
      storeName: (data['storeName'] ?? '-').toString(),
      minimumOrderAmount: minOrderStr,
      pickupSpot: (data['pickupSpot'] ?? '-').toString(),
      deliveryFee: deliveryFeeStr,
      depositMethod: depositMethods,
      link: (data['link'] ?? '-').toString(),
      note: noteStr,
      status: isClosed ? _OrderDetailStatus.closed : _OrderDetailStatus.inProgress,
    );
  }

  Future<void> _joinAndGoChat(BuildContext context) async {
    try {
      final uid = context.read<AppAuthProvider>().user!.uid;

      // ✅ 추천: 항상 join 호출(서버가 멱등 join이면 이미 참여여도 그냥 성공)
      await context.read<OrderProvider>().joinOrder(orderId, uid);
      if (!context.mounted) return;
      context.push('/order/$orderId/chat');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅 참여 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<OrderRepository>();
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: repo.watchOrderSnap(orderId),
      builder: (context, snap) {
        if (snap.hasError) {
          return Scaffold(
            backgroundColor: const Color(0xFFFFFBF8),
            body: SafeArea(
              child: Center(child: Text('주문 정보를 불러오지 못했어요.\n${snap.error}')),
            ),
          );
        }

        // 로딩 중에도 UI 뼈대는 유지하고 싶으면 여기서 스켈레톤을 넣어도 됨.
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFFBF8),
            body: SafeArea(child: Center(child: CircularProgressIndicator())),
          );
        }

        final doc = snap.data!;
        if (!doc.exists) {
          return const Scaffold(
            backgroundColor: Color(0xFFFFFBF8),
            body: SafeArea(child: Center(child: Text('존재하지 않는 주문이에요.'))),
          );
        }

        final data = _mapDocToDetail(doc.data()!);

        return Scaffold(
          backgroundColor: const Color(0xFFFFFBF8),
          body: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 14),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => context.pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(2),
                          child: Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 22,
                            color: Color(0xFF0A0A0A),
                          ),
                        ),
                      ),
                      const SizedBox(width: 18),
                      const Text(
                        '공동주문 상세',
                        style: TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 20,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w700,
                          height: 1.5,
                          letterSpacing: -0.45,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 18),
                    child: _OrderInformationCard(data: data),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 28),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _joinAndGoChat(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFF5751),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                      child: const Text(
                        '채팅하기',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.26,
                          letterSpacing: -0.31,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}

class _OrderInformationCard extends StatelessWidget {
  const _OrderInformationCard({required this.data});

  final _OrderDetailData data;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 24),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(
            width: 0.62,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          borderRadius: BorderRadius.circular(20),
        ),
        shadows: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 2,
            offset: Offset(0, 1),
            spreadRadius: -1,
          ),
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 3,
            offset: Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  data.title,
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 18,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w700,
                    height: 1.5,
                    letterSpacing: -0.44,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              _DetailStatusChip(status: data.status),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 20),
          _InfoRow(label: '주문 시간', value: data.time),
          const SizedBox(height: 15),
          _InfoRow(label: '가게명', value: data.storeName),
          const SizedBox(height: 15),
          _InfoRow(label: '최소 주문 금액', value: data.minimumOrderAmount),
          const SizedBox(height: 15),
          _InfoRow(label: '픽업 위치', value: data.pickupSpot),
          const SizedBox(height: 15),
          _InfoRow(label: '배달비', value: data.deliveryFee),
          const SizedBox(height: 15),
          _InfoRow(label: '입금 방법', value: data.depositMethod),
          const SizedBox(height: 15),
          _InfoRow(label: '링크', value: data.link),
          const SizedBox(height: 18),
          Text(
            data.note,
            style: const TextStyle(
              color: Color(0xCC0A0A0A),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.63,
              letterSpacing: -0.31,
            ),
          ),
          const SizedBox(height: 18),
          Divider(
            height: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 94,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF717182),
              fontSize: 14,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w400,
              height: 1.43,
              letterSpacing: -0.15,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.left,
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: -0.31,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

class _DetailStatusChip extends StatelessWidget {
  const _DetailStatusChip({required this.status});

  final _OrderDetailStatus status;

  @override
  Widget build(BuildContext context) {
    final isClosed = status == _OrderDetailStatus.closed;
    return Container(
      width: 59,
      height: 24,
      decoration: ShapeDecoration(
        color: isClosed ? const Color(0xFFFFF3EB) : const Color(0xFFEAF9F8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      alignment: Alignment.center,
      child: Text(
        isClosed ? '주문 마감' : '진행 중',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: isClosed ? const Color(0xFFFF5751) : const Color(0xFF2EC4B6),
          fontSize: isClosed ? 10 : 12,
          fontFamily: 'Inter',
          fontWeight: FontWeight.w500,
          height: 1.2,
          letterSpacing: -0.45,
        ),
      ),
    );
  }
}

enum _OrderDetailStatus {
  inProgress,
  closed,
}

class _OrderDetailData {
  const _OrderDetailData({
    required this.title,
    required this.time,
    required this.storeName,
    required this.minimumOrderAmount,
    required this.pickupSpot,
    required this.deliveryFee,
    required this.depositMethod,
    required this.link,
    required this.note,
    required this.status,
  });

  final String title;
  final String time;
  final String storeName;
  final String minimumOrderAmount;
  final String pickupSpot;
  final String deliveryFee;
  final String depositMethod;
  final String link;
  final String note;
  final _OrderDetailStatus status;
}
