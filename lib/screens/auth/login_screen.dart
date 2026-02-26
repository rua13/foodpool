import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../providers/app_auth_provider.dart';
import '../../widgets/foodpool_logo.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 402),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Center(
                    child: FoodpoolLogo(
                      textSize: 30.01,
                      iconHeight: 24,
                      iconWidth: 14,
                      spacing: 6,
                      letterSpacing: 0.19,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '공동 주문으로 최소 주문 금액 제한 없이 즐겨요',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.unbounded(
                      color: Color(0xFF717182),
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      height: 1.5,
                      letterSpacing: -0.31,
                    ),
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        elevation: 0,
                        backgroundColor: const Color(0xFFFF5751),
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            const Color(0xFFFF5751).withValues(alpha: 0.7),
                        disabledForegroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        textStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.5,
                          letterSpacing: -0.31,
                        ),
                      ),
                      onPressed: auth.isLoading
                          ? null
                          : () async {
                              try {
                                await context.read<AppAuthProvider>().signInWithGoogle();
                              } catch (_) {
                                // Error text is rendered below from provider.lastError.
                              }
                            },
                      child: auth.isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text(
                              'Google 학생 계정으로 로그인',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontFamily: 'Inter',
                                fontWeight: FontWeight.w500,
                                height: 1.5,
                                letterSpacing: -0.31,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SvgPicture.asset(
                        'lib/assets/icons/exclamation.svg',
                        width: 20,
                        height: 20,
                      ),
                      const SizedBox(width: 6),
                      const Text(
                        '학생 인증 계정으로만 로그인이 가능해요.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF717182),
                          fontSize: 14,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.43,
                          letterSpacing: -0.15,
                        ),
                      ),
                    ],
                  ),
                  if (auth.lastError != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      auth.lastError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFD93025),
                        fontSize: 13,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
