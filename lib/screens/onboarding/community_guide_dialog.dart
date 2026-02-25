import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

class CommunityGuideDialog extends StatelessWidget {
  const CommunityGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 19),
      child: Container(
        width: 364,
        height: 262,
        padding: const EdgeInsets.all(20),
        decoration: ShapeDecoration(
          color: const Color(0xFFFFF4EF),
          shape: RoundedRectangleBorder(
            side: const BorderSide(
              width: 0.63,
              color: Color(0x33FFB4A2),
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
        child: Column(
          children: [
            Row(
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
                        '커뮤니티 가이드',
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
                      _GuideLine('• 정확한 픽업 시간과 장소를 명시해주세요.'),
                      SizedBox(height: 4.11),
                      _GuideLine('• 배달비는 공정하게 분담해주세요.'),
                      SizedBox(height: 4.11),
                      _GuideLine('• 주문 후 반드시 연락 가능한 상태를 유지해주세요.'),
                      SizedBox(height: 4.11),
                      _GuideLine('• 개인정보 공유는 신중하게 해주세요.'),
                      SizedBox(height: 4.11),
                      _GuideLine('• 신고 접수 시, 별도 경고 없이 영구 정지될 수 있어요.'),
                      SizedBox(height: 4.11),
                      Text(
                        '• 개인의 부주의로 인해 발생한 모든 책임은 해당 이용자 \n   본인에게 있습니다.',
                        style: TextStyle(
                          color: Color(0xB20A0A0A),
                          fontSize: 12.32,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w400,
                          height: 1.41,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: const Color(0xFFFF5751),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 78, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                child: const Text(
                  '동의했습니다.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w500,
                    height: 1.50,
                    letterSpacing: -0.31,
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

class _GuideLine extends StatelessWidget {
  const _GuideLine(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xB20A0A0A),
        fontSize: 12.32,
        fontFamily: 'Inter',
        fontWeight: FontWeight.w400,
        height: 1.33,
      ),
    );
  }
}
