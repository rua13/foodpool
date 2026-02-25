import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../providers/app_auth_provider.dart';
import 'main_page.dart';

class HomeShellScreen extends StatelessWidget {
  const HomeShellScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AppAuthProvider>();

    return MainPage(
      onTapWrite: () => context.push('/create'),
      onTapOrder: (orderId) => context.push('/order/$orderId'),
      onTapProfile: auth.isLoading
          ? null
          : () async {
              await context.read<AppAuthProvider>().signOut();
            },
    );
  }
}
