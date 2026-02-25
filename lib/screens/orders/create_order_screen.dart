import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/app_auth_provider.dart';
import '../../providers/order_provider.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({super.key});

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleCtrl = TextEditingController();
  final _storeNameCtrl = TextEditingController();
  final _pickupCtrl = TextEditingController();
  final _linkCtrl = TextEditingController();
  final _depositMethodsCtrl = TextEditingController();
  final _minOrderAmountCtrl = TextEditingController();
  final _deliveryFeeCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  TimeOfDay? _selectedTime;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _storeNameCtrl.dispose();
    _pickupCtrl.dispose();
    _linkCtrl.dispose();
    _depositMethodsCtrl.dispose();
    _minOrderAmountCtrl.dispose();
    _deliveryFeeCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  DateTime _buildEndAtLocal(TimeOfDay time) {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, time.hour, time.minute);
  }

  int? _parseMoney(String raw) {
    final digits = raw.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return null;
    return int.tryParse(digits);
  }

  bool _isSubmitEnabled(bool isLoading) {
    return !isLoading &&
        _titleCtrl.text.trim().isNotEmpty &&
        _storeNameCtrl.text.trim().isNotEmpty &&
        _pickupCtrl.text.trim().isNotEmpty &&
        _depositMethodsCtrl.text.trim().isNotEmpty &&
        _parseMoney(_minOrderAmountCtrl.text) != null &&
        _parseMoney(_deliveryFeeCtrl.text) != null &&
        _selectedTime != null;
  }

  Future<void> _pickTime() async {
    final now = TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFFFF5751),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked == null) return;
    setState(() => _selectedTime = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주문 시간을 선택해주세요.')),
      );
      return;
    }

    final endAt = _buildEndAtLocal(_selectedTime!);
    if (!endAt.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('주문 시간은 현재 시간 이후만 가능해요.')),
      );
      return;
    }

    final minOrderAmount = _parseMoney(_minOrderAmountCtrl.text);
    final deliveryFee = _parseMoney(_deliveryFeeCtrl.text);
    if (minOrderAmount == null || deliveryFee == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('금액은 숫자로 입력해주세요.')),
      );
      return;
    }

    final uid = context.read<AppAuthProvider>().user?.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('로그인이 필요합니다.')),
      );
      return;
    }

    try {
      await context.read<OrderProvider>().createOrder(
            ownerId: uid,
            title: _titleCtrl.text.trim(),
            storeName: _storeNameCtrl.text.trim(),
            pickupSpot: _pickupCtrl.text.trim(),
            link: _linkCtrl.text.trim().isEmpty ? '-' : _linkCtrl.text.trim(),
            depositMethods: _depositMethodsCtrl.text.trim(),
            minimumOrderAmount: minOrderAmount,
            deliveryFee: deliveryFee,
            endAtLocal: endAt,
          );
      if (!mounted) return;
      await _showSubmitSuccessDialog();
      if (!mounted) return;
      context.go('/home');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('생성 실패: $e')),
      );
    }
  }

  Future<void> _showSubmitSuccessDialog() {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.50),
      builder: (context) => const _CreateOrderSuccessDialog(),
    );
  }

  TextStyle get _labelStyle => GoogleFonts.inter(
        color: const Color(0xFF0A0A0A),
        fontSize: 17,
        fontWeight: FontWeight.w500,
        height: 1.18,
        letterSpacing: -0.15,
      );

  InputDecoration _fieldDecoration({
    required String hintText,
    Color borderColor = const Color(0xFFD7D7D7),
    Widget? prefixIcon,
    EdgeInsets? contentPadding,
    TextStyle? hintStyle,
    int? hintMaxLines,
  }) {
    return InputDecoration(
      isDense: true,
      hintText: hintText,
      hintMaxLines: hintMaxLines,
      hintStyle: hintStyle ??
          GoogleFonts.inter(
            color: const Color(0x7F0A0A0A),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.31,
          ),
      contentPadding:
          contentPadding ?? const EdgeInsets.symmetric(horizontal: 16, vertical: 19),
      filled: true,
      fillColor: Colors.white,
      prefixIcon: prefixIcon == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: prefixIcon,
            ),
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(width: 1, color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(width: 1, color: Color(0xFFFF5751)),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(width: 1, color: Color(0xFFFF5751)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(width: 1, color: Color(0xFFFF5751)),
      ),
    );
  }

  Widget _buildLabel(String text, {bool required = false}) {
    return RichText(
      text: TextSpan(
        style: _labelStyle,
        children: [
          TextSpan(text: text),
          if (required)
            const TextSpan(text: ' '),
          if (required)
            TextSpan(
              text: '*',
              style: GoogleFonts.inter(
                color: const Color(0xFFFF5751),
                fontSize: 16,
                fontWeight: FontWeight.w500,
                height: 1.25,
                letterSpacing: -0.15,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required bool requiredField,
    required TextEditingController controller,
    required String hintText,
    String? Function(String?)? validator,
    TextInputType keyboardType = TextInputType.text,
    List<TextInputFormatter>? inputFormatters,
    Color borderColor = const Color(0xFFD7D7D7),
    Widget? prefixIcon,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildLabel(label, required: requiredField),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          style: GoogleFonts.inter(
            color: const Color(0xFF0A0A0A),
            fontSize: 16,
            fontWeight: FontWeight.w400,
            letterSpacing: -0.31,
          ),
          decoration: _fieldDecoration(
            hintText: hintText,
            borderColor: borderColor,
            prefixIcon: prefixIcon,
          ),
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          onChanged: (_) => setState(() {}),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = context.watch<OrderProvider>();
    final submitEnabled = _isSubmitEnabled(orderProvider.isLoading);
    final selectedTimeText = _selectedTime == null
        ? '17:30'
        : '${_two(_selectedTime!.hour)}:${_two(_selectedTime!.minute)}';

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
                    child: const Padding(
                      padding: EdgeInsets.all(2),
                      child: Icon(
                        Icons.arrow_back_ios_new_rounded,
                        size: 22,
                        color: Color(0xFF0A0A0A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 18),
                  Text(
                    '공동주문 만들기',
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
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 26),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTextField(
                        label: '제목',
                        requiredField: true,
                        controller: _titleCtrl,
                        hintText: '제목을 입력하세요.',
                        borderColor: const Color(0xFFFF5751),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '필수 항목입니다.' : null,
                      ),
                      const SizedBox(height: 34),
                      _buildLabel('주문 시간', required: true),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickTime,
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          height: 56,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          decoration: ShapeDecoration(
                            color: Colors.white,
                            shape: RoundedRectangleBorder(
                              side: const BorderSide(width: 1, color: Color(0xFFD7D7D7)),
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: Color(0x7F0A0A0A),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedTimeText,
                                style: GoogleFonts.inter(
                                  color: _selectedTime == null
                                      ? const Color(0x7F0A0A0A)
                                      : const Color(0xFF0A0A0A),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  letterSpacing: -0.31,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 34),
                      _buildTextField(
                        label: '가게명',
                        requiredField: true,
                        controller: _storeNameCtrl,
                        hintText: '가게명을 입력하세요.',
                        prefixIcon: const Icon(
                          Icons.storefront_outlined,
                          size: 17,
                          color: Color(0x7F0A0A0A),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '필수 항목입니다.' : null,
                      ),
                      const SizedBox(height: 34),
                      _buildTextField(
                        label: '최소 주문 금액',
                        requiredField: true,
                        controller: _minOrderAmountCtrl,
                        hintText: '3,000원',
                        prefixIcon: const Icon(
                          Icons.credit_card_outlined,
                          size: 17,
                          color: Color(0x7F0A0A0A),
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,원 ]'))],
                        validator: (v) => _parseMoney(v ?? '') == null ? '숫자를 입력해주세요.' : null,
                      ),
                      const SizedBox(height: 34),
                      _buildTextField(
                        label: '픽업 위치',
                        requiredField: true,
                        controller: _pickupCtrl,
                        hintText: '정문 앞',
                        prefixIcon: const Icon(
                          Icons.location_on_outlined,
                          size: 17,
                          color: Color(0x7F0A0A0A),
                        ),
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '필수 항목입니다.' : null,
                      ),
                      const SizedBox(height: 34),
                      _buildTextField(
                        label: '배달비',
                        requiredField: true,
                        controller: _deliveryFeeCtrl,
                        hintText: '3,000원',
                        prefixIcon: SvgPicture.asset(
                          'lib/assets/icons/won.svg',
                          width: 17,
                          height: 17,
                        ),
                        keyboardType: TextInputType.number,
                        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9,원 ]'))],
                        validator: (v) => _parseMoney(v ?? '') == null ? '숫자를 입력해주세요.' : null,
                      ),
                      const SizedBox(height: 34),
                      _buildTextField(
                        label: '입금 방법',
                        requiredField: true,
                        controller: _depositMethodsCtrl,
                        hintText: '예. 선입금',
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? '필수 항목입니다.' : null,
                      ),
                      const SizedBox(height: 34),
                      _buildTextField(
                        label: '주문 링크',
                        requiredField: false,
                        controller: _linkCtrl,
                        hintText: 'https://...',
                      ),
                      const SizedBox(height: 34),
                      _buildLabel('추가 내용'),
                      const SizedBox(height: 8),
                      Container(
                        decoration: ShapeDecoration(
                          color: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          shadows: const [
                            BoxShadow(
                              color: Color(0x0C000000),
                              blurRadius: 4,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextFormField(
                          controller: _noteCtrl,
                          minLines: 5,
                          maxLines: 5,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF0A0A0A),
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            height: 1.71,
                            letterSpacing: -0.31,
                          ),
                          decoration: _fieldDecoration(
                            hintText: '메뉴 선택 방법, 결제 방법 등 자유롭게 작성해주세요',
                            contentPadding:
                                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            borderColor: Colors.transparent,
                            hintMaxLines: 1,
                            hintStyle: GoogleFonts.inter(
                              color: const Color(0x7F0A0A0A),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              height: 1.71,
                              letterSpacing: -0.31,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: ShapeDecoration(
                          color: const Color(0x19FFB4A2),
                          shape: RoundedRectangleBorder(
                            side: const BorderSide(width: 0.62, color: Color(0x33FFB4A2)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SvgPicture.asset(
                              'lib/assets/icons/exclamation.svg',
                              width: 20,
                              height: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '작성 가이드',
                                    style: GoogleFonts.inter(
                                      color: const Color(0xFF0A0A0A),
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      height: 1.43,
                                      letterSpacing: -0.15,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  const _GuideText('• 정확한 픽업 시간과 장소를 명시해주세요'),
                                  const SizedBox(height: 4),
                                  const _GuideText('• 배달비는 공정하게 분담해주세요'),
                                  const SizedBox(height: 4),
                                  const _GuideText('• 주문 후 반드시 연락 가능한 상태를 유지해주세요'),
                                  const SizedBox(height: 4),
                                  const _GuideText('• 개인정보 공유는 신중하게 해주세요'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: submitEnabled ? _submit : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor:
                                submitEnabled ? const Color(0xFFFF5751) : const Color(0xFFACACAC),
                            disabledBackgroundColor: const Color(0xFFACACAC),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                          ),
                          child: orderProvider.isLoading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  '게시하기',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    color: Colors.white,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w500,
                                    height: 1.2,
                                    letterSpacing: -0.31,
                                  ),
                                ),
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

class _GuideText extends StatelessWidget {
  const _GuideText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: GoogleFonts.inter(
        color: const Color(0xB20A0A0A),
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.33,
      ),
    );
  }
}

class _CreateOrderSuccessDialog extends StatelessWidget {
  const _CreateOrderSuccessDialog();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 28),
      child: Container(
        width: 345.73,
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          shadows: const [
            BoxShadow(
              color: Color(0x3F000000),
              blurRadius: 50,
              offset: Offset(0, 25),
              spreadRadius: -12,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: ShapeDecoration(
                color: const Color(0x19FF5A3C),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20642200),
                ),
              ),
              alignment: Alignment.center,
              child: SvgPicture.asset(
                'lib/assets/icons/check.svg',
                width: 40,
                height: 40,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '게시 완료!',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xFF0A0A0A),
                fontSize: 18,
                fontWeight: FontWeight.w700,
                height: 1.56,
                letterSpacing: -0.44,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '공동주문이 성공적으로 생성되었습니다',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: const Color(0xB20A0A0A),
                fontSize: 14,
                fontWeight: FontWeight.w400,
                height: 1.43,
                letterSpacing: -0.15,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF5751),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: Text(
                  '확인',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 16,
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
