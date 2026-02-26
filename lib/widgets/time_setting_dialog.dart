import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

Future<TimeOfDay?> showFoodpoolTimeSettingDialog(
  BuildContext context, {
  required TimeOfDay initialTime,
}) {
  return showDialog<TimeOfDay>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.35),
    builder: (_) => _FoodpoolTimeSettingDialog(initialTime: initialTime),
  );
}

class _FoodpoolTimeSettingDialog extends StatefulWidget {
  const _FoodpoolTimeSettingDialog({required this.initialTime});

  final TimeOfDay initialTime;

  @override
  State<_FoodpoolTimeSettingDialog> createState() => _FoodpoolTimeSettingDialogState();
}

class _FoodpoolTimeSettingDialogState extends State<_FoodpoolTimeSettingDialog> {
  late final FixedExtentScrollController _hourCtrl;
  late final FixedExtentScrollController _minuteCtrl;
  late final FixedExtentScrollController _ampmCtrl;

  late int _hour12;
  late int _minute;
  late bool _isAm;

  @override
  void initState() {
    super.initState();
    final h24 = widget.initialTime.hour;
    _isAm = h24 < 12;
    _hour12 = h24 % 12 == 0 ? 12 : h24 % 12;
    _minute = widget.initialTime.minute;

    _hourCtrl = FixedExtentScrollController(initialItem: _hour12 - 1);
    _minuteCtrl = FixedExtentScrollController(initialItem: _minute);
    _ampmCtrl = FixedExtentScrollController(initialItem: _isAm ? 0 : 1);
  }

  @override
  void dispose() {
    _hourCtrl.dispose();
    _minuteCtrl.dispose();
    _ampmCtrl.dispose();
    super.dispose();
  }

  void _confirm() {
    var hour24 = _hour12 % 12;
    if (!_isAm) hour24 += 12;
    Navigator.of(context).pop(TimeOfDay(hour: hour24, minute: _minute));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      elevation: 0,
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 40),
      child: Container(
        width: 296,
        height: 340,
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          shadows: const [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 20,
              offset: Offset.zero,
              spreadRadius: 0,
            ),
          ],
        ),
        child: Column(
          children: [
            const SizedBox(height: 34),
            Text(
              '주문 시간 설정',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF576984),
                fontSize: 22.4,
                fontFamily: 'Pretendard Variable',
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
            const SizedBox(height: 28),
            SizedBox(
              height: 130,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _WheelPicker(
                    width: 56,
                    height: 102,
                    itemExtent: 33,
                    controller: _hourCtrl,
                    values: List<String>.generate(12, (i) => '${i + 1}'),
                    onChanged: (index) {
                      setState(() => _hour12 = (index % 12) + 1);
                    },
                  ),
                  const SizedBox(width: 14),
                  const _DotSeparator(),
                  const SizedBox(width: 14),
                  _WheelPicker(
                    width: 66,
                    height: 102,
                    itemExtent: 33,
                    controller: _minuteCtrl,
                    values: List<String>.generate(60, (i) => i.toString().padLeft(2, '0')),
                    onChanged: (index) {
                      setState(() => _minute = index % 60);
                    },
                  ),
                  const SizedBox(width: 12),
                  _WheelPicker(
                    width: 58,
                    height: 102,
                    itemExtent: 33,
                    controller: _ampmCtrl,
                    values: const ['AM', 'PM'],
                    looping: false,
                    onChanged: (index) {
                      setState(() => _isAm = index % 2 == 0);
                    },
                  ),
                ],
              ),
            ),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.fromLTRB(15, 0, 15, 20),
              child: Row(
                children: [
                  Expanded(
                    child: _DialogActionButton(
                      text: '취소',
                      backgroundColor: const Color(0xFF9F9F9F),
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _DialogActionButton(
                      text: '확인',
                      backgroundColor: const Color(0xFFFF5751),
                      onTap: _confirm,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WheelPicker extends StatelessWidget {
  const _WheelPicker({
    required this.width,
    required this.height,
    required this.itemExtent,
    required this.controller,
    required this.values,
    required this.onChanged,
    this.looping = true,
  });

  final double width;
  final double height;
  final double itemExtent;
  final FixedExtentScrollController controller;
  final List<String> values;
  final ValueChanged<int> onChanged;
  final bool looping;

  @override
  Widget build(BuildContext context) {
    final fadeHeight = (height - itemExtent) / 2;
    return SizedBox(
      width: width,
      height: height,
      child: Stack(
        children: [
          Positioned.fill(
            child: CupertinoPicker(
              scrollController: controller,
              itemExtent: itemExtent,
              looping: looping,
              squeeze: 1.1,
              diameterRatio: 1.25,
              selectionOverlay: const SizedBox.shrink(),
              onSelectedItemChanged: onChanged,
              children: values
                  .map(
                    (v) => Center(
                      child: Text(
                        v,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          color: const Color(0xFF576984),
                          fontSize: 23.4,
                          fontWeight: FontWeight.w500,
                          height: 1,
                        ),
                      ),
                    ),
                  )
                  .toList(growable: false),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: fadeHeight,
            child: const Divider(
              color: Color(0xFFBBBBBB),
              thickness: 1.95,
              height: 1.95,
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: fadeHeight + itemExtent,
            child: const Divider(
              color: Color(0xFFBBBBBB),
              thickness: 1.95,
              height: 1.95,
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: fadeHeight,
            child: IgnorePointer(
              child: Container(color: Colors.white.withValues(alpha: 0.70)),
            ),
          ),
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: fadeHeight,
            child: IgnorePointer(
              child: Container(color: Colors.white.withValues(alpha: 0.70)),
            ),
          ),
        ],
      ),
    );
  }
}

class _DotSeparator extends StatelessWidget {
  const _DotSeparator();

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SvgPicture.asset(
          'lib/assets/icons/dot.svg',
          width: 8,
          height: 8,
        ),
        const SizedBox(height: 5),
        SvgPicture.asset(
          'lib/assets/icons/dot.svg',
          width: 8,
          height: 8,
        ),
      ],
    );
  }
}

class _DialogActionButton extends StatelessWidget {
  const _DialogActionButton({
    required this.text,
    required this.backgroundColor,
    required this.onTap,
  });

  final String text;
  final Color backgroundColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(50)),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontFamily: 'Pretendard Variable',
            fontWeight: FontWeight.w500,
            height: 1,
          ),
        ),
      ),
    );
  }
}
