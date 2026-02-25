import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class OrderDetailScreen extends StatelessWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  static const Map<String, _OrderDetailData> _mockOrders = {
    'order-1': _OrderDetailData(
      title: '마라탕 드실 분!!',
      time: '17:10',
      storeName: '행복한마라탕 법원점',
      minimumOrderAmount: '19,900',
      pickupSpot: '비전관',
      deliveryFee: '3,000',
      depositMethod: '주문 전 선입금',
      link: 'http://baemin.com',
      note: '채팅방 들어오면 바로 계좌 보내드릴게용',
    ),
    'order-2': _OrderDetailData(
      title: '고바콤',
      time: '18:30',
      storeName: '굽네치킨 양덕점',
      minimumOrderAmount: '19,900',
      pickupSpot: '비전관',
      deliveryFee: '3,000',
      depositMethod: '주문 전 선입금',
      link: 'http://baemin.com',
      note: '채팅방 들어오면 바로 계좌 보내드릴게용',
    ),
    'order-3': _OrderDetailData(
      title: '대왕비빔밥 (육회 비빔밥)',
      time: '16:55',
      storeName: '고기듬뿍대왕비빔밥 본점',
      minimumOrderAmount: '20,000',
      pickupSpot: '현동홀',
      deliveryFee: '3,000',
      depositMethod: '주문 전 선입금',
      link: 'http://baemin.com',
      note: '채팅방 들어오면 바로 계좌 보내드릴게용',
    ),
    'order-4': _OrderDetailData(
      title: '요아정',
      time: '17:05',
      storeName: '행복한마라탕 법원점',
      minimumOrderAmount: '19,900',
      pickupSpot: '소라',
      deliveryFee: '3,000',
      depositMethod: '주문 전 선입금',
      link: 'http://baemin.com',
      note: '채팅방 들어오면 바로 계좌 보내드릴게용',
    ),
  };

  _OrderDetailData get _data =>
      _mockOrders[orderId] ??
      _OrderDetailData(
        title: '공동주문',
        time: '-',
        storeName: '-',
        minimumOrderAmount: '-',
        pickupSpot: '-',
        deliveryFee: '-',
        depositMethod: '-',
        link: '-',
        note: '주문 정보를 불러오는 중이에요.',
      );

  Future<void> _joinAndGoChat(BuildContext context) async {
    context.push('/order/$orderId/chat');
  }

  @override
  Widget build(BuildContext context) {
    final data = _data;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => context.pop(),
                    icon: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 22,
                      color: Color(0xFF0A0A0A),
                    ),
                  ),
                  const SizedBox(width: 6),
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
            const SizedBox(height: 12),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: _OrderInformationCard(data: data),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
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
          Text(
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
            textAlign: TextAlign.right,
            style: const TextStyle(
              color: Color(0xFF0A0A0A),
              fontSize: 16,
              fontFamily: 'Inter',
              fontWeight: FontWeight.w500,
              height: 1.5,
              letterSpacing: -0.31,
            ),
          ),
        ),
      ],
    );
  }
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
}
