import 'package:flutter/material.dart';

class CommunityGuideDialog extends StatelessWidget {
  const CommunityGuideDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('커뮤니티 가이드'),
      content: const Text('로그인할 때마다 보여주기로 설정된 안내입니다.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('확인'),
        ),
      ],
    );
  }
}