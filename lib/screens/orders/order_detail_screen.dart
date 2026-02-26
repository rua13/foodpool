import 'package:flutter/material.dart';
import 'package:foodpool/providers/app_auth_provider.dart';
import 'package:foodpool/services/order_chat_service.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foodpool/widgets/status_chip.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/order_provider.dart';
import '../../repositories/order_repository.dart';
import 'create_order_screen.dart';
import '../../widgets/exit_confirm_dialog.dart';

enum _OwnerMenuAction { toggleClosed, edit, delete }

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
    final noteStr = note;
    final isClosed = data['isClosed'] is bool
        ? data['isClosed'] as bool
        : (endAt != null && endAt.toDate().isBefore(DateTime.now()));

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
      status: isClosed ? OrderStatus.closed : OrderStatus.inProgress,
    );
  }

  Future<void> _joinAndGoChat(BuildContext context) async {
    // 여기 수정함
    final auth = context.read<AppAuthProvider>();
    final orderProvider = context.read<OrderProvider>();
    final chatService = context.read<OrderChatService>();
    final u = auth.user!;
    final displayName = u.displayName?.trim().isNotEmpty == true
        ? u.displayName!.trim()
        : (u.email?.split('@').first ?? '사용자');
    final photoUrl = (u.photoURL ?? '').trim();
    String joinNoticeText(String rawName) {
      final name = rawName.trim();
      if (name.isEmpty) return '참여자님이 참여하셨습니다.';
      if (name.endsWith('님')) return '$name이 참여하셨습니다.';
      return '$name님이 참여하셨습니다.';
    }

    try {
      // 1) join 호출(서버가 멱등 join이면 이미 참여여도 그냥 성공)
      final didJoin = await orderProvider.joinOrder(orderId, u.uid);

      // 2) ✅ members/{uid} 업서트 (프로필용) (여기도 수정)
      await chatService.upsertMyMemberProfile(
          orderId: orderId,
          displayName: displayName,
          photoUrl: photoUrl,
        );

      // 3) 실제로 새로 합류한 경우에만 참여 로그를 남긴다.
      if (didJoin) {
        await chatService.sendJoinNoticeMessage(
              orderId: orderId,
              text: joinNoticeText(displayName),
            );
      }

      if (!context.mounted) return;
      context.push('/order/$orderId/chat');
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('채팅 참여 실패: $e')),
      );
    }
  }

  Future<void> _handleOwnerMenuAction(
    BuildContext context, {
    required _OwnerMenuAction action,
    required OrderStatus status,
    required Map<String, dynamic> rawData,
  }) async {
    final orderProvider = context.read<OrderProvider>();
    try {
      switch (action) {
        case _OwnerMenuAction.toggleClosed:
          final shouldClose = status == OrderStatus.inProgress;
          final confirmed = await showExitConfirmDialog(
            context,
            title: shouldClose
                ? '새로운 참여자를 받을 수 없게 돼요.\n주문을 마감할까요?'
                : '다시 새로운 참여자를 받을 수 있게 돼요.\n주문 마감을 취소할까요?',
            cancelText: '취소',
            confirmText: shouldClose ? '마감하기' : '마감 취소하기',
          );
          if (!confirmed || !context.mounted) return;
          await orderProvider.setOrderClosed(orderId, shouldClose);
          break;
        case _OwnerMenuAction.edit:
          final confirmed = await showExitConfirmDialog(
            context,
            title: '주문 정보를 수정할까요?\n수정 화면으로 이동할게요.',
            cancelText: '취소',
            confirmText: '수정하기',
          );
          if (!confirmed || !context.mounted) return;
          context.push(
            '/create',
            extra: CreateOrderPrefillData.fromOrderDoc(
              orderId: orderId,
              data: rawData,
            ),
          );
          break;
        case _OwnerMenuAction.delete:
          final confirmed = await showExitConfirmDialog(
            context,
            title: '삭제한 글은 복구할 수 없게 돼요.\n정말 삭제할까요?',
            cancelText: '취소',
            confirmText: '삭제하기',
          );
          if (!confirmed || !context.mounted) return;
          await orderProvider.deleteOrder(orderId);
          if (!context.mounted) return;
          context.pop();
          break;
      }
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('처리 중 오류가 발생했어요: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final repo = context.read<OrderRepository>();
    final myUid = context.watch<AppAuthProvider>().user?.uid;
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

        final raw = doc.data()!;
        final data = _mapDocToDetail(raw);
        final ownerId = (raw['ownerId'] ?? '').toString();
        final isOwner = myUid != null && myUid == ownerId;

        return Scaffold(
          backgroundColor: const Color(0xFFFFFBF8),
          body: SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(25, 54, 25, 28),
              child: Column(
                children: [
                  Row(
                    children: [
                      InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: ()  {
                          if (context.canPop()) {
                            context.pop();
                          } else {
                            context.go('/home'); // 또는 네 홈 라우트(예: /orders)
                          }
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: SvgPicture.asset(
                            'lib/assets/icons/back.svg',
                            width: 22,
                            height: 22,
                          ),
                        ),
                      ),
                      const SizedBox(width: 20.57),
                      Text(
                        '공동주문 상세',
                        style: const TextStyle(
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
                  const SizedBox(height: 28.93),
                  _OrderInformationCard(
                    data: data,
                    isOwner: isOwner,
                    onOwnerMenuSelected: (action) {
                      _handleOwnerMenuAction(
                        context,
                        action: action,
                        status: data.status,
                        rawData: raw,
                      );
                    },
                  ),
                  const SizedBox(height: 23.9),
                  SizedBox(
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
                      child: Text(
                        '채팅하기',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
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
                ],
              ),
            ),
          ),
        );
      }
    );
  }
}

class _OrderInformationCard extends StatelessWidget {
  const _OrderInformationCard({
    required this.data,
    required this.isOwner,
    required this.onOwnerMenuSelected,
  });

  final _OrderDetailData data;
  final bool isOwner;
  final ValueChanged<_OwnerMenuAction> onOwnerMenuSelected;

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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(width: 12,),
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
              StatusChip(status: data.status),
              if (isOwner) ...[
                const SizedBox(width: 6),
                PopupMenuButton<_OwnerMenuAction>(
                  tooltip: '',
                  offset: const Offset(0, 36),
                  elevation: 8,
                  popUpAnimationStyle: AnimationStyle.noAnimation,
                  color: Colors.white,
                  constraints: const BoxConstraints(minWidth: 120, maxWidth: 120),
                  shape: RoundedRectangleBorder(
                    side: const BorderSide(width: 0.65, color: Color(0xFFE5E7EB)),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: onOwnerMenuSelected,
                  itemBuilder: (context) => [
                    PopupMenuItem<_OwnerMenuAction>(
                      value: _OwnerMenuAction.toggleClosed,
                      height: 41,
                      child: _OwnerMenuItemText(
                        text: data.status == OrderStatus.inProgress
                            ? '주문 마감'
                            : '마감 취소하기',
                        color: const Color(0xFF666666),
                      ),
                    ),
                    const PopupMenuItem<_OwnerMenuAction>(
                      value: _OwnerMenuAction.edit,
                      height: 41,
                      child: _OwnerMenuItemText(
                        text: '수정하기',
                        color: Color(0xFF666666),
                      ),
                    ),
                    const PopupMenuItem<_OwnerMenuAction>(
                      value: _OwnerMenuAction.delete,
                      height: 41,
                      child: _OwnerMenuItemText(
                        text: '삭제하기',
                        color: Color(0xFFFF5751),
                      ),
                    ),
                  ],
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: ShapeDecoration(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9999),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: SvgPicture.asset(
                      'lib/assets/icons/threedots.svg',
                      width: 20,
                      height: 20,
                      colorFilter: const ColorFilter.mode(
                        Color(0xFF666666),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            height: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          const SizedBox(height: 18.78),
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
          const SizedBox(height: 18.78),
          Divider(
            height: 1,
            color: Colors.black.withValues(alpha: 0.10),
          ),
          if (data.note.isNotEmpty) ...[
            const SizedBox(height: 18),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0),
              child: Text(
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
            ),
          ],
        ],
      ),
    );
  }
}

class _OwnerMenuItemText extends StatelessWidget {
  const _OwnerMenuItemText({
    required this.text,
    required this.color,
  });

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: color,
        fontSize: 14,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w500,
        height: 1.5,
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
        SizedBox(width: 12,),
        SizedBox(
          width: 106.5,
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
  final OrderStatus status;
}
