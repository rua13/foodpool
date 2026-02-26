import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({required this.status});

  final OrderStatus status;

  @override
  Widget build(BuildContext context) {
    final isClosed = status == OrderStatus.closed;

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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

enum OrderStatus {
  inProgress,
  closed,
}