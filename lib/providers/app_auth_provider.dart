import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../firebase_options.dart';
import '../repositories/user_repository.dart';

// TODO(FOODPOOL): serverClientId는 너 Firebase/Google Cloud 설정 값으로 교체
const kGoogleServerClientId = '1058649520805-po6b6irq1eu65o8rq4glf9lt86oh2i3d.apps.googleusercontent.com';

// TODO(FOODPOOL): 학교 이메일 도메인(실명제/학교계정 강제) 사용 시 변경
const kSchoolEmailDomain = 'handong.ac.kr';

class AppAuthProvider extends ChangeNotifier {
  AppAuthProvider(
    this._userRepo, {
    FirebaseAuth? auth,
  }) : _auth = auth ?? FirebaseAuth.instance {
    _sub = _auth.authStateChanges().listen((u) {
      user = u;
      isAuthReady = true;
      notifyListeners();
    });
  }

  final FirebaseAuth _auth;
  StreamSubscription<User?>? _sub;

  final UserRepository _userRepo;

  User? user;
  bool isAuthReady = false;

  bool isLoading = false;
  String? lastError;

  bool get isLoggedIn => user != null;

  // (선택) “학교 계정 여부”를 UI에서 쓰고 싶으면 getter 제공
  bool get isSchoolAccount {
    final email = user?.email;
    if (email == null) return false;
    return email.toLowerCase().endsWith('@$kSchoolEmailDomain');
  }

  Future<UserCredential?> signInWithGoogle({
    String? serverClientId = kGoogleServerClientId,
  }) async {
    lastError = null;
    isLoading = true;
    notifyListeners();

    try {
      final String? clientId =
          (defaultTargetPlatform == TargetPlatform.iOS ||
                  defaultTargetPlatform == TargetPlatform.macOS)
              ? DefaultFirebaseOptions.currentPlatform.iosClientId
              : null;

      // 1) GoogleSignIn 초기화
      await GoogleSignIn.instance.initialize(
        clientId: clientId,
        serverClientId: serverClientId,
      );

      // 2) 사용자 인증(계정 선택)
      final googleUser = await GoogleSignIn.instance.authenticate();

      // 3) 토큰 획득
      final googleAuth = googleUser.authentication;

      // 4) Firebase Credential 생성
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        // accessToken은 필요하면 추가
      );

      // 5) Firebase 로그인
      final result = await _auth.signInWithCredential(credential);

      final u = _auth.currentUser;

      // TODO(FOODPOOL): “학교 계정만 허용”을 강제하려면 여기서 1차 차단 가능
      // - 단, 이건 클라이언트 차단이라 우회 가능하므로
      //   최종 강제는 Cloud Functions(참여/생성 등)에서 email domain 체크 권장
      if (u?.email != null) {
        final email = u!.email!.toLowerCase();
        final ok = email.endsWith('@$kSchoolEmailDomain');
        if (!ok) {
          // 로그아웃 처리 후 에러 던지기
          await signOut();
          throw FirebaseAuthException(
            code: 'invalid-email-domain',
            message: '학교 구글 계정(@$kSchoolEmailDomain)으로만 로그인할 수 있어요.',
          );
        }
      }

      // 6) 유저 문서 ensure (신규 유저뿐 아니라, 문서 없으면 생성하도록 하는 게 안정적)
      // TODO(FOODPOOL): 기존 코드에서는 isNewUser일 때만 ensure했는데,
      //                실서비스/MVP에서는 "문서 없으면 생성"이 더 안전함.
      if (u != null) {
        await _userRepo.ensureUserDoc(u);
        await _userRepo.onLogin(u); // ✅ 매 로그인마다 실행
      }

      return result;
    } catch (e, st) {
      lastError = e.toString();
      debugPrint("Google Sign-In error: $e\n$st");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    lastError = null;
    isLoading = true;
    notifyListeners();

    try {
      await GoogleSignIn.instance.signOut();
      await _auth.signOut();
    } catch (e, st) {
      lastError = e.toString();
      debugPrint("Sign-out error: $e\n$st");
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
