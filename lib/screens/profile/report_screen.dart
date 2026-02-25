import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import 'public_profile_screen.dart';

class ReportScreen extends StatefulWidget {
  const ReportScreen({super.key, required this.target});

  final PublicProfileData target;

  @override
  State<ReportScreen> createState() => _ReportScreenState();
}

class _ReportScreenState extends State<ReportScreen> {
  static const List<String> _reasons = [
    '거래 직전 취소',
    '연락 두절',
    '부적절한 콘텐츠',
    '욕설/비하 표현',
    '스팸/ 영리목적 홍보',
  ];

  final _detailCtrl = TextEditingController();
  String? _selectedReason;
  bool _hasEvidence = false;

  @override
  void dispose() {
    _detailCtrl.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _selectedReason != null && _detailCtrl.text.trim().isNotEmpty;

  Future<void> _submit() async {
    if (!_canSubmit) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('신고가 접수되었습니다.')),
    );
    if (!mounted) return;
    context.pop();
  }

  TextStyle get _sectionTitleStyle => const TextStyle(
        color: Color(0xFF0A0A0A),
        fontSize: 21,
        fontFamily: 'Pretendard Variable',
        fontFamilyFallback: ['Inter'],
        fontWeight: FontWeight.w600,
        height: 1.43,
        letterSpacing: -0.45,
      );

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    '신고하기',
                    style: TextStyle(
                      color: Color(0xFF0A0A0A),
                      fontSize: 20,
                      fontFamily: 'Inter',
                      fontWeight: FontWeight.w700,
                      height: 1.50,
                      letterSpacing: -0.45,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('신고 사유 선택', style: _sectionTitleStyle),
                    const SizedBox(height: 6),
                    const Text(
                      '해당하는 사유를 하나 선택해주세요.',
                      style: TextStyle(
                        color: Color(0xFF757575),
                        fontSize: 17,
                        fontFamily: 'Pretendard Variable',
                        fontFamilyFallback: ['Inter'],
                        fontWeight: FontWeight.w500,
                        height: 1.76,
                        letterSpacing: -0.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    ..._reasons.map(
                      (reason) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _ReasonOption(
                          label: reason,
                          selected: _selectedReason == reason,
                          onTap: () => setState(() => _selectedReason = reason),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('상세 내용', style: _sectionTitleStyle),
                    const SizedBox(height: 10),
                    Container(
                      decoration: ShapeDecoration(
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(width: 1, color: Color(0xFFCECECE)),
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: TextField(
                        controller: _detailCtrl,
                        minLines: 6,
                        maxLines: 6,
                        onChanged: (_) => setState(() {}),
                        style: const TextStyle(
                          color: Color(0xFF0A0A0A),
                          fontSize: 16,
                          fontFamily: 'Inter',
                          fontWeight: FontWeight.w500,
                          height: 1.50,
                          letterSpacing: -0.31,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 22, vertical: 17),
                          hintText: '신고 사유를 상세히 작성해주세요',
                          hintStyle: TextStyle(
                            color: Color(0xFFAAAAAA),
                            fontSize: 16,
                            fontFamily: 'Inter',
                            fontWeight: FontWeight.w500,
                            height: 1.50,
                            letterSpacing: -0.31,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text('증거 사진 업로드', style: _sectionTitleStyle),
                        const SizedBox(width: 6),
                        const Text(
                          '(선택)',
                          style: TextStyle(
                            color: Color(0xFF0A0A0A),
                            fontSize: 14,
                            fontFamily: 'Pretendard Variable',
                            fontFamilyFallback: ['Inter'],
                            fontWeight: FontWeight.w400,
                            height: 2.14,
                            letterSpacing: -0.45,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => setState(() => _hasEvidence = !_hasEvidence),
                      child: Container(
                        width: double.infinity,
                        height: 118,
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(width: 1, color: Color(0xFFCECECE)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            _hasEvidence ? '증거 사진 1개 첨부됨' : '탭해서 증거 사진 첨부',
                            style: const TextStyle(
                              color: Color(0xFF757575),
                              fontSize: 16,
                              fontFamily: 'Inter',
                              fontWeight: FontWeight.w500,
                              height: 1.50,
                              letterSpacing: -0.31,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _canSubmit ? _submit : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              _canSubmit ? const Color(0xFFFF5751) : const Color(0xFFACACAC),
                          disabledBackgroundColor: const Color(0xFFACACAC),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          '신고 완료',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 17,
                            fontFamily: 'Inter',
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ReasonOption extends StatelessWidget {
  const _ReasonOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(25),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: ShapeDecoration(
          shape: RoundedRectangleBorder(
            side: BorderSide(
              width: 1,
              color: selected ? const Color(0xFFFF5751) : const Color(0xFFCECECE),
            ),
            borderRadius: BorderRadius.circular(25),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF0A0A0A),
                  fontSize: 16,
                  fontFamily: 'Inter',
                  fontWeight: FontWeight.w500,
                  height: 1.50,
                  letterSpacing: -0.31,
                ),
              ),
            ),
            Container(
              width: 17,
              height: 17,
              decoration: ShapeDecoration(
                shape: OvalBorder(
                  side: BorderSide(
                    width: 1.30,
                    color: selected ? const Color(0xFFFF5751) : const Color(0xFF4B4B4B),
                  ),
                ),
              ),
              child: selected
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFF5751),
                          shape: BoxShape.circle,
                        ),
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
