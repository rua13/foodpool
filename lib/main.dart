import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

// ====== Services / Repositories / Providers (Foodpool에 맞게 경로 수정) ======
import 'services/user_service.dart';
// import 'services/room_service.dart';
// import 'services/chat_service.dart';

import 'repositories/user_repository.dart';
// import 'repositories/room_repository.dart';
// import 'repositories/chat_repository.dart';

import 'providers/app_auth_provider.dart';
import 'providers/user_provider.dart';
// (선택) room/chat provider가 있으면 추가
// import 'providers/room_provider.dart';
// import 'providers/chat_provider.dart';

// ====== Screens ======
import 'screens/init_gate.dart';
import 'screens/home/home_shell_screen.dart';
// import 'screens/rooms/room_detail_screen.dart';
// import 'screens/rooms/create_room_screen.dart';
// import 'screens/chat/chat_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        // --- Services ---
        Provider(create: (_) => UserService()),
        // Provider(create: (_) => RoomService()),
        // Provider(create: (_) => ChatService()),

        // --- Repositories ---
        Provider(create: (ctx) => UserRepository(ctx.read<UserService>())),
        // Provider(create: (ctx) => RoomRepository(ctx.read<RoomService>())),
        // Provider(create: (ctx) => ChatRepository(ctx.read<ChatService>())),

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
        // ChangeNotifierProvider(create: (ctx) => RoomProvider(ctx.read<RoomRepository>())),
        // ChangeNotifierProvider(create: (ctx) => ChatProvider(ctx.read<ChatRepository>())),
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

        // GoRoute(
        //   path: '/create',
        //   builder: (context, state) => const CreateRoomScreen(),
        // ),

        // GoRoute(
        //   path: '/room/:roomId',
        //   builder: (context, state) {
        //     final roomId = state.pathParameters['roomId']!;
        //     return RoomDetailScreen(roomId: roomId);
        //   },
        // ),

        // GoRoute(
        //   path: '/room/:roomId/chat',
        //   builder: (context, state) {
        //     final roomId = state.pathParameters['roomId']!;
        //     return ChatScreen(roomId: roomId); // A안: roomId만
        //   },
        // ),
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
    return MaterialApp.router(
      routerConfig: _createRouter(context),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFBCE9FF)),
        scaffoldBackgroundColor: Colors.white,
        fontFamily: 'Pretendard',
      ),
    );
  }
}
