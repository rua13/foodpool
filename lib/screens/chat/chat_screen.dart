import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


import '../../providers/order_chat_provider.dart';
import '../../repositories/order_chat_repository.dart';
import '../../models/order_member_model.dart';
import 'package:flutter_svg/flutter_svg.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.orderId});

  final String orderId;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();

  StreamSubscription? _orderSub;
  String _title = '공동주문';
  int _participantCount = 1;

  @override
  void initState() {
    super.initState();

    // 1) 메시지 구독 시작
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<OrderChatProvider>().startListening(widget.orderId);
    });

    // 2) 헤더용 order 문서 구독 (title, memberCount)
    final repo = context.read<OrderChatRepository>();
    _orderSub = repo.watchOrderSnap(widget.orderId).listen((snap) {
      final data = snap.data();
      if (data == null) return;

      setState(() {
        _title = (data['title'] ?? '공동주문').toString();
        _participantCount = (data['memberCount'] is int) ? data['memberCount'] as int : 1;
      });
    });
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  String _formatKoreanTime(DateTime dt) {
    final period = dt.hour < 12 ? '오전' : '오후';
    final hour12 = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$period  ${hour12.toString().padLeft(2, '0')}:$minute';
  }

  String _joinNoticeText(String rawName) {
    final name = rawName.trim();
    if (name.isEmpty) return '참여자님이 참여하셨습니다.';
    if (name.endsWith('님')) return '$name이 참여하셨습니다.';
    return '$name님이 참여하셨습니다.';
  }

  Future<void> _send() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;

    try {
      await context.read<OrderChatProvider>().sendText(text);
      _textCtrl.clear();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollCtrl.hasClients) return;
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent + 160,
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
        );
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('전송 실패: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser?.uid;

    final chat = context.watch<OrderChatProvider>();
    final messages = chat.messages;

    // “참여 알림” 표시 이름(내 이름) — members 업서트가 됐으면 membersByUid에서 가져와도 됨
    final me = (myUid == null) ? null : chat.membersByUid[myUid];
    final joinName = (me?.displayName.trim().isNotEmpty == true)
        ? me!.displayName
        : (FirebaseAuth.instance.currentUser?.displayName?.trim().isNotEmpty == true
            ? FirebaseAuth.instance.currentUser!.displayName!.trim()
            : (FirebaseAuth.instance.currentUser?.email?.split('@').first ?? '참여자'));
    // final user = context.watch<UserProvider>().currentUser;
    // final displayName = user?.displayName.trim() ?? '';
    // final fallbackFromEmail =
    //     FirebaseAuth.instance.currentUser?.email?.split('@').first ?? '';
    // final joinName =
    //     displayName.isNotEmpty ? displayName : (fallbackFromEmail.isNotEmpty ? fallbackFromEmail : '참여자');

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: Column(
          children: [
            _ChatHeader(
              title: _title,
              participantCount: _participantCount,
              onTapBack: () => Navigator.of(context).maybePop(),
              onTapExit: () => Navigator.of(context).maybePop(),
            ),
            Expanded(
              child: chat.isLoading 
              ? const Center(child: CircularProgressIndicator())
              : ListView(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                children: [
                  const _ChatGuideCard(),
                  const SizedBox(height: 16),
                  _JoinNoticeChip(text: _joinNoticeText(joinName)),
                  const SizedBox(height: 16),
                  ..._buildMessageWidgets(
                    context,
                    messages: messages,
                    myUid: myUid,
                    membersByUid: chat.membersByUid,
                  ),
                ],
              ),
            ),
            _ChatInputBar(
              textController: _textCtrl,
              onSend: _send,
            ),
          ],
        ),
      ),
    );
  }
  List<Widget> _buildMessageWidgets(
    BuildContext context, {
    required List messages,
    required String? myUid,
    required Map<String, OrderMember> membersByUid,
  }) {
    final widgets = <Widget>[];

    for (var i = 0; i < messages.length; i++) {
      final m = messages[i];

      final isMine = (myUid != null && m.senderId == myUid);

      final senderProfile = membersByUid[m.senderId];
      final senderName = senderProfile?.displayName ?? '';
      final senderPhotoUrl = senderProfile?.photoUrl ?? '';

      final timeText = _formatKoreanTime(m.createdAt);

      final view = _ChatMessageView(
        text: m.text,
        timeText: timeText,
        isMine: isMine,
        senderName: senderName.isEmpty ? '사용자' : senderName,
        senderPhotoUrl: senderPhotoUrl,
      );

      if (view.isMine) {
        widgets.add(_MyMessageRow(message: view));
      } else {
        final prev = i > 0 ? messages[i - 1] : null;
        final prevSenderId = prev?.senderId as String?;
        final showProfile = prev == null || prevSenderId != m.senderId;

        widgets.add(
          _OtherMessageRow(
            message: view,
            showProfile: showProfile,
          ),
        );
      }

      widgets.add(const SizedBox(height: 8));
    }

    return widgets;
  }
}

class _ChatHeader extends StatelessWidget {
  const _ChatHeader({
    required this.title,
    required this.participantCount,
    required this.onTapBack,
    required this.onTapExit,
  });

  final String title;
  final int participantCount;
  final VoidCallback onTapBack;
  final VoidCallback onTapExit;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFFFBF8),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconButton(
            onPressed: onTapBack,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
            icon: SvgPicture.asset(
              'lib/assets/icons/back.svg',
              width: 22,
              height: 22,
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      height: 1.5,
                      letterSpacing: -0.45,
                    ),
                  ),
                  Text(
                    '$participantCount명 참여중',
                    style: const TextStyle(
                      color: Color(0xFF717182),
                      fontSize: 12,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      height: 1.33,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTapExit,
            child: Container(
              width: 45,
              height: 37,
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  side: BorderSide(
                    width: 0.62,
                    color: Colors.black.withValues(alpha: 0.10),
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'lib/assets/icons/exit.svg',
                  width: 21,
                  height: 21,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChatGuideCard extends StatelessWidget {
  const _ChatGuideCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(17, 17, 17, 17),
      decoration: ShapeDecoration(
        color: const Color(0x19FFB4A2),
        shape: RoundedRectangleBorder(
          side: const BorderSide(
            width: 0.63,
            color: Color(0x33FFB4A2),
          ),
          borderRadius: BorderRadius.circular(16.43),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SvgPicture.asset(
            'lib/assets/icons/exclamation.svg',
            width: 20.53,
            height: 20.53,
          ),
          const SizedBox(width: 8.21),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '채팅 가이드',
                  style: TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 14.38,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.43,
                    letterSpacing: -0.15,
                  ),
                ),
                SizedBox(height: 4.11),
                Text(
                  '• 실명 기반 채팅방입니다.',
                  style: TextStyle(
                    color: Color(0xB20A0A0A),
                    fontSize: 12.32,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
                Text(
                  '• 참여 취소는 단계에 따라 제한될 수 있습니다.',
                  style: TextStyle(
                    color: Color(0xB20A0A0A),
                    fontSize: 12.32,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
                Text(
                  '응답이 없을 경우 참여가 취소될 수 있습니다.',
                  style: TextStyle(
                    color: Color(0xB20A0A0A),
                    fontSize: 12.32,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
                  ),
                ),
                Text(
                  '• 개인정보 공유는 신중하게 해주시길 바랍니다.',
                  style: TextStyle(
                    color: Color(0xB20A0A0A),
                    fontSize: 12.32,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    height: 1.33,
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

class _JoinNoticeChip extends StatelessWidget {
  const _JoinNoticeChip({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: ShapeDecoration(
          color: const Color(0xB2ECECF0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(99999),
          ),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF363641),
            fontSize: 12,
            fontFamily: 'Inter',
            fontWeight: FontWeight.w400,
            height: 1.33,
          ),
        ),
      ),
    );
  }
}

class _MyMessageRow extends StatelessWidget {
  const _MyMessageRow({required this.message});

  final _ChatMessageView message;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Flexible(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 242),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.52, vertical: 9.68),
              decoration: const ShapeDecoration(
                color: Color(0xFFFF5751),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(14.52),
                    bottomLeft: Radius.circular(14.52),
                    bottomRight: Radius.circular(14.52),
                  ),
                ),
              ),
              child: Text(
                message.text,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16.94,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w400,
                  height: 1.43,
                  letterSpacing: -0.18,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 6.05),
        Text(
          message.timeText,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF171C1F),
            fontSize: 10.89,
            fontFamily: 'SF Pro',
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _OtherMessageRow extends StatelessWidget {
  const _OtherMessageRow({
    required this.message,
    required this.showProfile,
  });

  final _ChatMessageView message;
  final bool showProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 42,
          child: showProfile
              ? Container(
                  width: 41.14,
                  height: 41.14,
                  decoration: ShapeDecoration(
                    color: const Color(0xFFFFD6CD),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(120.03),
                    ),
                  ),
                  clipBehavior: Clip.antiAlias,
                  alignment: Alignment.center,
                  child: (message.senderPhotoUrl.trim().isNotEmpty)
                      ? Image.network(
                          message.senderPhotoUrl,
                          width: 41.14,
                          height: 41.14,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Text(
                            message.senderName.isNotEmpty ? message.senderName[0] : '?',
                            style: const TextStyle(
                              color: Color(0xFF171C1F),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        )
                      : Text(
                          message.senderName.isNotEmpty ? message.senderName[0] : '?',
                          style: const TextStyle(
                            color: Color(0xFF171C1F),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                )
              : null,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (showProfile)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6.05),
                  child: Text(
                    message.senderName,
                    style: const TextStyle(
                      color: Color(0xFF171C1F),
                      fontSize: 14.52,
                      fontFamily: 'Pretendard Variable',
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Flexible(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 242),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14.52, vertical: 9.68),
                        decoration: const ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.only(
                              topRight: Radius.circular(14.52),
                              bottomLeft: Radius.circular(14.52),
                              bottomRight: Radius.circular(14.52),
                            ),
                          ),
                        ),
                        child: Text(
                          message.text,
                          style: const TextStyle(
                            color: Color(0xFF171C1F),
                            fontSize: 16.94,
                            fontFamily: 'Pretendard Variable',
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6.05),
                  Text(
                    message.timeText,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF171C1F),
                      fontSize: 10.89,
                      fontFamily: 'SF Pro',
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ChatInputBar extends StatelessWidget {
  const _ChatInputBar({
    required this.textController,
    required this.onSend,
  });

  final TextEditingController textController;
  final VoidCallback onSend;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(24, 15.38, 24, 18),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Container(
                height: 39,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: ShapeDecoration(
                  color: const Color(0xFFEFEFEF),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(25),
                  ),
                ),
                alignment: Alignment.center,
                child: TextField(
                  controller: textController,
                  onSubmitted: (_) => onSend(),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: '메시지를 입력하세요...',
                    hintStyle: TextStyle(
                      color: Color(0x7F0A0A0A),
                      fontSize: 16,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.31,
                    ),
                  ),
                  style: const TextStyle(
                    color: Color(0xFF0A0A0A),
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w400,
                    letterSpacing: -0.31,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            InkWell(
              onTap: onSend,
              borderRadius: BorderRadius.circular(99999),
              child: Container(
                width: 39.22,
                height: 39.22,
                decoration: ShapeDecoration(
                  color: const Color(0xFFFF5751),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(99999),
                  ),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    'lib/assets/icons/send.svg',
                    width: 16.34,
                    height: 16.34,
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

/// ✅ 기존 UI 위젯을 최대한 안 깨기 위해 “뷰 모델”을 하나 둠
class _ChatMessageView {
  const _ChatMessageView({
    required this.text,
    required this.timeText,
    required this.isMine,
    required this.senderName,
    required this.senderPhotoUrl,
  });

  final String text;
  final String timeText;
  final bool isMine;
  final String senderName;
  final String senderPhotoUrl;
}