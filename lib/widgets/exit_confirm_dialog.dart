import 'package:flutter/material.dart';

Future<bool> showExitConfirmDialog(
  BuildContext context, {
  String title = '정말로 퇴장할까요?',
  String cancelText = '취소',
  String confirmText = '퇴장하기',
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: true,
    barrierColor: Colors.black.withValues(alpha: 0.60),
    builder: (context) => _ExitConfirmDialog(
      title: title,
      cancelText: cancelText,
      confirmText: confirmText,
    ),
  );
  return result ?? false;
}

class _ExitConfirmDialog extends StatelessWidget {
  const _ExitConfirmDialog({
    required this.title,
    required this.cancelText,
    required this.confirmText,
  });

  final String title;
  final String cancelText;
  final String confirmText;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 34),
      child: Container(
        width: 333.16,
        padding: const EdgeInsets.fromLTRB(20, 34, 20, 20),
        decoration: ShapeDecoration(
          color: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          shadows: const [
            BoxShadow(
              color: Color(0x26000000),
              blurRadius: 25,
              offset: Offset(0, 2),
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.black,
                fontSize: 18,
                fontFamily: 'Pretendard Variable',
                fontWeight: FontWeight.w500,
                height: 1.09,
              ),
            ),
            const SizedBox(height: 36),
            Row(
              children: [
                Expanded(
                  child: _ExitDialogButton(
                    text: cancelText,
                    backgroundColor: const Color(0xFFF9F5F2),
                    textColor: const Color(0xFF0A0A0A),
                    fontWeight: FontWeight.w500,
                    onTap: () => Navigator.of(context).pop(false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ExitDialogButton(
                    text: confirmText,
                    backgroundColor: const Color(0xFFFF5751),
                    textColor: Colors.white,
                    fontWeight: FontWeight.w600,
                    onTap: () => Navigator.of(context).pop(true),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ExitDialogButton extends StatelessWidget {
  const _ExitDialogButton({
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    required this.fontWeight,
    required this.onTap,
  });

  final String text;
  final Color backgroundColor;
  final Color textColor;
  final FontWeight fontWeight;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 42.24,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          shadowColor: const Color(0x3F000000),
        ),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: textColor,
            fontSize: 16,
            fontFamily: 'Pretendard Variable',
            fontWeight: fontWeight,
          ),
        ),
      ),
    );
  }
}
