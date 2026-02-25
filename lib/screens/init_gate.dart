import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/app_auth_provider.dart';
import '../providers/user_provider.dart';

import '../models/user_model.dart';

// TODO(FOODPOOL): 아래 스크린 경로를 너 프로젝트 구조에 맞게 수정
import 'auth/login_screen.dart';
import 'onboarding/community_guide_screen.dart';
import 'home/home_shell_screen.dart';
import 'splash/logo_screen.dart';

class InitGate extends StatefulWidget {
  const InitGate({super.key});

  @override
  State<InitGate> createState() => _InitGateState();
}

class _InitGateState extends State<InitGate> {
  String? _boundUid;

  void _bindUserIfNeeded(String uid) {
    if (uid == _boundUid) return;
    _boundUid = uid;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<UserProvider>().bindToUid(uid);
    });
  }

  Widget _loading() => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final userProvider = context.watch<UserProvider>();

    // 0) Auth 상태 확정 전: 스플래시
    if (!auth.isAuthReady) {
      return const LogoScreen();
    }

    // 1) 로그인 여부 판단
    final uid = auth.user?.uid;
    if (uid == null) {
      _boundUid = null; // 바인딩 uid 초기화
      return const LoginScreen();
    }

    // 2) uid가 있으면 users/{uid} 바인딩
    _bindUserIfNeeded(uid);

    // 3) user 문서 로딩 중
    final u = userProvider.currentUser;
    if (u == null) return _loading();

    // 4) 서버 확정 전에는 게이트 판단 보류(깜빡임 방지)
    if (!userProvider.isServerConfirmed) return _loading();

    // 5) 온보딩(커뮤니티 가이드) 게이트
    switch (u.onboardingStep) {
      case OnboardingStep.guide:
        return const CommunityGuideScreen();

      case OnboardingStep.done:
        return const HomeShellScreen();
    }
  }
}
