import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../repositories/user_repository.dart';

/// users/{uid} 로드/업데이트(가이드 동의 포함)
/// uid가 생기면 users/{uid}를 실시간 구독한다. 없으면 자동 생성한다.
/// 서버 확정 후에만 온보딩을 판단하도록 도와서,
/// 중간에 잘못된 화면이 반짝 띄워지는 것을 방지한다.
class UserProvider extends ChangeNotifier {
  UserProvider(this._repo);

  final UserRepository _repo;

  AppUser? currentUser;

  bool isLoading = false;
  String? error;

  StreamSubscription? _sub;

  bool _ensuringDoc = false;

  /// ✅ 캐시가 아닌 서버 스냅샷을 1번이라도 받았는지 여부
  bool isServerConfirmed = false;

  /// (편의 getter)
  bool get hasAgreedGuide => currentUser?.hasAgreedGuide ?? false;
  bool get onboardingDone => currentUser?.onboardingDone ?? false;
  bool get needsGuide => currentUser?.needsGuide ?? true;

  /// AuthProvider.user?.uid가 확보되면 호출
  void bindToUid(String uid) {
    // 이미 같은 uid를 보고 있고 구독도 살아있으면 스킵
    if (currentUser?.uid == uid && _sub != null) return;

    _sub?.cancel();

    // 상태 초기화
    currentUser = null;
    error = null;
    isLoading = true;
    isServerConfirmed = false;
    _ensuringDoc = false;
    notifyListeners();

    _sub = _repo.watchUserSnap(uid).listen((doc) async {
      // 1) 문서 없으면 생성 - ensure
      if (!doc.exists) {
        if (_ensuringDoc) return;
        _ensuringDoc = true;

        try {
          final fbUser = FirebaseAuth.instance.currentUser;
          if (fbUser != null && fbUser.uid == uid) {
            await _repo.ensureUserDoc(fbUser);
          }
        } finally {
          _ensuringDoc = false;
        }
        return;
      }

      // 2) 서버 확정 처리
      if (!doc.metadata.isFromCache) {
        isServerConfirmed = true;
      }

      // 3) 모델 파싱
      currentUser = AppUser.fromDoc(doc);

      isLoading = false;
      notifyListeners();
    }, onError: (e) {
      error = e.toString();
      isLoading = false;
      notifyListeners();
    });
  }

  /// ✅ 커뮤니티 가이드 동의(단일 동의)
  ///
  /// 보통 CommunityGuideScreen의 "동의하고 시작하기" 버튼에서 호출
  /// - terms(GuideAgreement) 저장
  /// - onboarding.step = done 으로 변경(Repository/Service가 같이 처리 권장)
  Future<void> agreeGuide({
    required String uid,
    required String version, // 예: "v1"
  }) async {
    error = null;
    isLoading = true;
    notifyListeners();

    try {
      await _repo.agreeGuide(uid: uid, version: version);

      // (선택) UI 플래그도 같이 소비하고 싶으면 여기서 호출
      // TODO(FOODPOOL): guideShown을 어떤 시점에 true로 둘지 정책 결정
      // await _repo.setGuideShownFlag(uid: uid, value: true);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
      // ✅ 실제 화면 전환은 InitGate가 currentUser.onboardingStep 변화를 보고 처리
    }
  }

  /// ✅ 온보딩 단계 변경(guide | done)
  /// - 보통 agreeGuide에서 service가 done으로 바꿔주면 굳이 따로 안 써도 됨.
  Future<void> setOnboardingStep({
    required String uid,
    required OnboardingStep step,
  }) async {
    error = null;
    isLoading = true;
    notifyListeners();

    try {
      await _repo.setOnboardingStep(uid: uid, step: step);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ 1회성 UI 플래그: guideShown
  /// - 예: 가이드 화면에서 1회만 다이얼로그 띄우기 등
  Future<void> setGuideShownFlag({
    required String uid,
    required bool value,
  }) async {
    error = null;
    isLoading = true;
    notifyListeners();

    try {
      await _repo.setGuideShownFlag(uid: uid, value: value);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  /// ✅ 현재 조작 중인 roomId 저장(홈이면 null)
  /// TODO(FOODPOOL): MVP에서 필요 없으면 모델/서비스/규칙에서 제거 추천
  Future<void> setCurrentOrderId({
    required String uid,
    required String? roomId,
  }) async {
    error = null;
    // 여기선 가벼운 업데이트라 isLoading을 굳이 true로 두지 않아도 됨(원하면 유지 가능)
    notifyListeners();

    try {
      await _repo.setCurrentOrderId(uid: uid, roomId: roomId);
    } catch (e) {
      error = e.toString();
      rethrow;
    } finally {
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
