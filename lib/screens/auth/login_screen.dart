import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/app_auth_provider.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Foodpool 로그인')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '학교 구글 계정으로 로그인해 주세요.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                if (auth.lastError != null) ...[
                  Text(
                    auth.lastError!,
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                ],

                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed: auth.isLoading
                        ? null
                        : () async {
                            try {
                              await context.read<AppAuthProvider>().signInWithGoogle();
                              // ✅ 성공하면 authStateChanges -> InitGate가 알아서 다음 화면 렌더
                            } catch (_) {
                              // 에러 메시지는 provider.lastError로 표시
                            }
                          },
                    child: auth.isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Google로 로그인'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
