import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:foodpool/models/user_model.dart';
import 'package:foodpool/providers/app_auth_provider.dart';
import 'package:foodpool/repositories/order_repository.dart';
import 'package:foodpool/repositories/user_repository.dart';
import 'package:foodpool/widgets/order_card.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '--:--';
    final d = ts.toDate();
    return '${_two(d.hour)}:${_two(d.minute)}';
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
    final minOrder =
        data['minimumOrderAmount'] is int ? data['minimumOrderAmount'] as int : null;
    final endAt = data['endAt'] is Timestamp ? data['endAt'] as Timestamp : null;

    return OrderCardData(
      orderId: doc.id,
      title: (data['title'] ?? '(제목 없음)').toString(),
      time: _formatTime(endAt),
      store: (data['storeName'] ?? '(가게명 없음)').toString(),
      price: _formatMoney(minOrder),
      place: (data['pickupSpot'] ?? '(픽업 위치 없음)').toString(),
    );
  }

  Future<void> _confirmWithdrawal(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('탈퇴하기'),
          content: const Text('현재는 계정 탈퇴 대신 로그아웃이 진행됩니다. 계속할까요?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('취소'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('확인'),
            ),
          ],
        );
      },
    );
    if (confirm != true || !context.mounted) return;
    await context.read<AppAuthProvider>().signOut();
    if (!context.mounted) return;
    context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    final uid = context.watch<AppAuthProvider>().user?.uid;
    if (uid == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFFFFBF8),
        body: SafeArea(
          child: Center(
            child: Text(
              '로그인이 필요합니다.',
              style: GoogleFonts.inter(),
            ),
          ),
        ),
      );
    }

    final userRepo = context.read<UserRepository>();
    final orderRepo = context.read<OrderRepository>();

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
                    child: Padding(
                      padding: const EdgeInsets.all(2),
                      child: SvgPicture.asset(
                        'lib/assets/icons/back.svg',
                        width: 22,
                        height: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    '마이페이지',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0A0A0A),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: -0.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: StreamBuilder<AppUser?>(
                stream: userRepo.watchUser(uid),
                builder: (context, userSnap) {
                  if (userSnap.hasError) {
                    return Center(child: Text('프로필 로드 오류: ${userSnap.error}'));
                  }
                  if (!userSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final appUser = userSnap.data!;

                  return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: orderRepo.watchMyOrders(uid),
                    builder: (context, orderSnap) {
                      if (orderSnap.hasError) {
                        return Center(child: Text('주문 로드 오류: ${orderSnap.error}'));
                      }
                      if (!orderSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final myOrders =
                          orderSnap.data!.docs.map(_mapDocToCard).toList(growable: false);

                      return SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _ProfileCard(user: appUser),
                            const SizedBox(height: 20),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Expanded(
                                        child: Divider(
                                          thickness: 1,
                                          color: Color(0xFFD7D7D7),
                                        ),
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 15),
                                        child: Text(
                                          '내가 쓴 글',
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            color: const Color(0xFF0A0A0A),
                                            fontSize: 16,
                                            fontWeight: FontWeight.w500,
                                            height: 1.5,
                                            letterSpacing: -0.31,
                                          ),
                                        ),
                                      ),
                                      const Expanded(
                                        child: Divider(
                                          thickness: 1,
                                          color: Color(0xFFD7D7D7),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 15),
                                  if (myOrders.isEmpty)
                                    Container(
                                      width: double.infinity,
                                      padding: const EdgeInsets.all(20),
                                      decoration: ShapeDecoration(
                                        color: Colors.white,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(20),
                                        ),
                                      ),
                                      child: Text(
                                        '작성한 공동주문이 아직 없어요.',
                                        style: GoogleFonts.inter(
                                          color: const Color(0xB20A0A0A),
                                          fontSize: 14,
                                          fontWeight: FontWeight.w400,
                                          height: 1.43,
                                        ),
                                      ),
                                    ),
                                  ...myOrders.map(
                                    (order) => Padding(
                                      padding: const EdgeInsets.only(bottom: 15),
                                      child: OrderCard(
                                        data: order,
                                        onTap: () => context.push('/order/${order.orderId}'),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 18),
              child: SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: () => _confirmWithdrawal(context),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(width: 2, color: Color(0xFFFF5751)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    foregroundColor: const Color(0xFFFF5751),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'lib/assets/icons/exit.svg',
                        width: 21,
                        height: 21,
                        colorFilter: const ColorFilter.mode(
                          Color(0xFFFF5751),
                          BlendMode.srcIn,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '탈퇴하기',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                          color: const Color(0xFFFF5751),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                          letterSpacing: -0.31,
                        ),
                      ),
                    ],
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

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.user});

  final AppUser user;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = user.photoUrl != null && user.photoUrl!.isNotEmpty;

    return Container(
      height: 136,
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 17),
      decoration: ShapeDecoration(
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        shadows: const [
          BoxShadow(
            color: Color(0x19000000),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 88.8,
            height: 88.8,
            decoration: ShapeDecoration(
              shape: OvalBorder(
                side: const BorderSide(width: 2.5, color: Colors.white),
              ),
              color: const Color(0xFFF3F3F3),
              image: hasPhoto
                  ? DecorationImage(
                      image: NetworkImage(user.photoUrl!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: hasPhoto
                ? null
                : Padding(
                    padding: const EdgeInsets.all(20),
                    child: SvgPicture.asset('lib/assets/icons/profile.svg'),
                  ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName.isEmpty ? '-' : user.displayName,
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email.isEmpty ? '-' : user.email,
                  style: GoogleFonts.inter(
                    color: Colors.black,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
