import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_auth_provider.dart';
import '../../providers/user_provider.dart';

class CommunityGuideScreen extends StatelessWidget {
  const CommunityGuideScreen({super.key});

  static const String guideVersion = 'v1'; // TODO(FOODPOOL): 필요하면 버전 규칙 정의

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();
    final userProvider = context.watch<UserProvider>();

    final uid = auth.user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('커뮤니티 가이드')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const Expanded(
              child: SingleChildScrollView(
                child: Text(
                  // TODO(FOODPOOL): 실제 가이드 문구로 교체
                  'Foodpool 커뮤니티 가이드\n\n'
                  '- 실명 기반으로 운영됩니다.\n'
                  '- 욕설/비방/도배 금지\n'
                  '- 돈 관련 약속은 명확하게\n'
                  '- 마감 시간 준수\n',
                ),
              ),
            ),
            const SizedBox(height: 12),

            if (userProvider.error != null) ...[
              Text(
                userProvider.error!,
                style: const TextStyle(color: Colors.red),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: (uid == null || userProvider.isLoading)
                    ? null
                    : () async {
                        try {
                          await context.read<UserProvider>().agreeGuide(
                                uid: uid,
                                version: guideVersion,
                              );
                          // ✅ 성공하면 users 문서의 onboarding.step -> done
                          // ✅ watch가 감지 -> InitGate가 HomeShellScreen 렌더
                        } catch (_) {}
                      },
                child: userProvider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('동의하고 시작하기'),
              ),
            ),
            const SizedBox(height: 8),

            TextButton(
              onPressed: auth.isLoading
                  ? null
                  : () async {
                      await context.read<AppAuthProvider>().signOut();
                      // ✅ 로그아웃되면 InitGate가 LoginScreen 렌더
                    },
              child: const Text('로그아웃'),
            ),
          ],
        ),
      ),
    );
  }
}
