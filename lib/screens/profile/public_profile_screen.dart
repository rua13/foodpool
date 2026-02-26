import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PublicProfileData {
  const PublicProfileData({
    required this.name,
    required this.email,
    this.photoUrl,
  });

  final String name;
  final String email;
  final String? photoUrl;
}

class PublicProfileScreen extends StatelessWidget {
  const PublicProfileScreen({super.key, required this.data});

  final PublicProfileData data;

  @override
  Widget build(BuildContext context) {
    final hasPhoto = data.photoUrl != null && data.photoUrl!.isNotEmpty;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 54),
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
                    '프로필 보기',
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
            const SizedBox(height: 22),
            Container(
              width: 361,
              height: 136,
              padding: const EdgeInsets.symmetric(horizontal: 17),
              decoration: ShapeDecoration(
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
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
                      shape: const OvalBorder(
                        side: BorderSide(width: 2.5, color: Colors.white),
                      ),
                      image: DecorationImage(
                        image: hasPhoto
                            ? NetworkImage(data.photoUrl!)
                            : const NetworkImage('https://placehold.co/89x89')
                                as ImageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          data.name,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 24,
                            fontFamily: 'Pretendard Variable',
                            fontWeight: FontWeight.w600,
                            fontFamilyFallback: ['Inter'],
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          data.email,
                          style: const TextStyle(
                            color: Colors.black,
                            fontSize: 16,
                            fontFamily: 'Pretendard Variable',
                            fontWeight: FontWeight.w500,
                            fontFamilyFallback: ['Inter'],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            SizedBox(
              width: 361,
              height: 48,
              child: ElevatedButton(
                onPressed: () => context.push('/report', extra: data),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5751),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  '신고하기',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    height: 1.41,
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
