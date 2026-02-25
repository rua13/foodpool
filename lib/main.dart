import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ====== Services / Repositories / Providers (Foodpool에 맞게 경로 수정) ======
import 'services/user_service.dart';
import 'services/order_service.dart';
import 'services/order_chat_service.dart';

import 'repositories/user_repository.dart';
import 'repositories/order_repository.dart';
import 'repositories/order_chat_repository.dart';

import 'providers/app_auth_provider.dart';
import 'providers/user_provider.dart';
// (선택) order/chat provider가 있으면 추가
import 'providers/order_provider.dart';
import 'providers/order_chat_provider.dart';

// ====== Screens ======
import 'screens/init_gate.dart';
import 'screens/home/home_shell_screen.dart';
import 'screens/orders/order_detail_screen.dart';
import 'screens/orders/create_order_screen.dart';
import 'screens/chat/chat_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/profile/public_profile_screen.dart';
import 'screens/profile/report_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // --- Services ---
        Provider(create: (_) => UserService()),
        Provider(create: (_) => OrderService()),
        Provider(create: (_) => OrderChatService()),

        // --- Repositories ---
        Provider(create: (ctx) => UserRepository(ctx.read<UserService>())),
        Provider(create: (ctx) => OrderRepository(ctx.read<OrderService>())),
        Provider(create: (ctx) => OrderChatRepository(ctx.read<OrderChatService>())),

        // --- Providers ---
        ChangeNotifierProvider(
          // 네가 보낸 AppAuthProvider 생성자 시그니처 그대로 사용
          create: (ctx) => AppAuthProvider(ctx.read<UserRepository>()),
        ),
        ChangeNotifierProvider(
          // UserProvider는 bindToUid(uid) 패턴이 있으므로 그대로
          create: (ctx) => UserProvider(ctx.read<UserRepository>()),
        ),

        // (선택) 추후 도메인 provider
        ChangeNotifierProvider(create: (ctx) => OrderProvider(ctx.read<OrderRepository>())),
        ChangeNotifierProvider(create: (ctx) => OrderChatProvider(ctx.read<OrderChatRepository>())),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  GoRouter _createRouter(BuildContext context) {
    final auth = context.read<AppAuthProvider>();
    final user = context.read<UserProvider>();

    return GoRouter(
      initialLocation: '/',
      refreshListenable: Listenable.merge([auth, user]),

      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const InitGate(),
        ),

        // InitGate가 홈까지 보내주더라도, 실제 화면 라우트는 준비해두는 게 좋아
        GoRoute(
          path: '/home',
          builder: (context, state) => const HomeShellScreen(),
        ),

        GoRoute(
          path: '/create',
          builder: (context, state) => const CreateOrderScreen(),
        ),

        GoRoute(
          path: '/profile',
          builder: (context, state) => const ProfileScreen(),
        ),

        GoRoute(
          path: '/profile/view',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is PublicProfileData) {
              return PublicProfileScreen(data: extra);
            }
            return const PublicProfileScreen(
              data: PublicProfileData(
                name: '-',
                email: '-',
              ),
            );
          },
        ),

        GoRoute(
          path: '/report',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is PublicProfileData) {
              return ReportScreen(target: extra);
            }
            return const ReportScreen(
              target: PublicProfileData(name: '-', email: '-'),
            );
          },
        ),

        GoRoute(
          path: '/order/:orderId',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return OrderDetailScreen(orderId: orderId);
          },
        ),

        GoRoute(
          path: '/order/:orderId/chat',
          builder: (context, state) {
            final orderId = state.pathParameters['orderId']!;
            return ChatScreen(orderId: orderId); // A안: orderId만
          },
        ),
      ],

      // ✅ redirect는 "안전장치"로만 최소 적용
      // (실제 게이트는 InitGate가 담당)
      redirect: (context, state) {
        final path = state.uri.path;

        // auth 준비 전: 아무것도 하지 않음(InitGate가 로고/로딩)
        if (!auth.isAuthReady) return null;

        // 로그아웃 상태에서 딥링크 접근 방지: 무조건 '/'
        if (auth.user == null) {
          return path == '/' ? null : '/';
        }

        // 로그인은 됐는데 user 문서가 아직 확정 전이면 '/'로 모으기
        // (InitGate가 spinner 보여주면서 bind/confirm 처리)
        if (user.currentUser == null || !user.isServerConfirmed) {
          return path == '/' ? null : '/';
        }

        return null;
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final baseTheme = ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBCE9FF)),
      scaffoldBackgroundColor: Colors.white,
    );

    return MaterialApp.router(
      routerConfig: _createRouter(context),
      debugShowCheckedModeBanner: false,
      theme: baseTheme.copyWith(
        textTheme: GoogleFonts.interTextTheme(baseTheme.textTheme),
        primaryTextTheme: GoogleFonts.interTextTheme(baseTheme.primaryTextTheme),
      ),
    );
  }
}
