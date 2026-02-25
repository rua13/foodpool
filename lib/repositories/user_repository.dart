import 'package:firebase_auth/firebase_auth.dart';

import '../models/user_model.dart';
import '../services/user_service.dart';

/// Provider가 원하는 형태로 Service를 포장하는 계층
class UserRepository {
  UserRepository(this._service);

  final UserService _service;

  Future<AppUser?> fetchUser(String uid) async {
    final doc = await _service.getUserDoc(uid);
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  Stream<AppUser?> watchUser(String uid) {
    return _service.watchUserDoc(uid).map((doc) {
      if (!doc.exists) return null;
      return AppUser.fromDoc(doc);
    });
  }

  Stream watchUserSnap(String uid) {
    return _service.watchUserDoc(uid);
  }

  /// ✅ 로그인 성공 직후 호출: users/{uid}를 "반드시" 만들어둠 + lastLoginAt 갱신
  ///
  /// Foodpool users 스키마 기준:
  /// - uid, displayName, email, photoUrl: Google 계정 기반
  /// - createdAt: 최초 1회
  /// - lastLoginAt: 매 로그인
  /// - onboarding.step: 없으면 guide, 완료 후 done
  /// - uiFlag.guideShown: 기본 false
  Future<void> ensureUserDoc(User firebaseUser) async {
    // TODO(FOODPOOL SERVICE):
    // UserService.upsertUser 시그니처를 Foodpool 스키마에 맞춰 수정해야 함.
    // 최소로는 아래 필드들을 upsert할 수 있어야 함:
    // - uid, displayName, email, photoUrl
    // - createdAt(serverTimestamp, create 시에만)
    // - lastLoginAt(serverTimestamp)
    // - onboarding.step(default guide)
    // - uiFlag.guideShown(default false)
    await _service.upsertUser(
      uid: firebaseUser.uid,
      displayName: firebaseUser.displayName ?? '사용자',
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,

      // 기본값(문서 최초 생성시에만 적용되도록 service에서 처리 권장)
      defaultOnboardingStep: onboardingStepToString(OnboardingStep.guide),
      defaultGuideShown: false,
    );
  }

  /// ✅ 커뮤니티 가이드 동의 처리(단일 동의)
  ///
  /// 저장 예:
  /// terms: { version: "v1", agreedAt: serverTimestamp }
  /// onboarding.step: "done"
  Future<void> agreeGuide({
    required String uid,
    required String version, // 예: "v1"
  }) async {
    // TODO(FOODPOOL SERVICE):
    // 아래 메서드를 service에 구현
    // - terms 저장(GuideAgreement)
    // - onboarding.step 을 done으로
    // - uiFlag.guideShown 을 true로(원하면)
    await _service.saveGuideAgreement(
      uid: uid,
      version: version,
    );
  }

  /// ✅ 온보딩 단계 업데이트 (guide | done)
  Future<void> setOnboardingStep({
    required String uid,
    required OnboardingStep step,
  }) async {
    await _service.setOnboardingStep(
      uid: uid,
      step: onboardingStepToString(step),
    );
  }

  /// ✅ 1회성 UI 플래그: guideShown
  Future<void> setGuideShownFlag({
    required String uid,
    required bool value,
  }) async {
    await _service.setUiFlag(
      uid: uid,
      patch: {'guideShown': value},
    );
  }

  /// ✅ 사용자가 현재 조작 중인 orderId 저장(홈이면 null)
  ///
  /// TODO(FOODPOOL): 이 기능이 진짜 필요 없으면 모델/서비스/규칙에서 제거 추천.
  Future<void> setCurrentOrderId({
    required String uid,
    required String? orderId,
  }) async {
    await _service.setCurrentOrderId(uid: uid, orderId: orderId);
  }
}
