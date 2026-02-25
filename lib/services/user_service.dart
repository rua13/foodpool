import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  UserService({FirebaseFirestore? firestore})
      : _db = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> userRef(String uid) =>
      _db.collection('users').doc(uid);

  Future<DocumentSnapshot<Map<String, dynamic>>> getUserDoc(String uid) {
    return userRef(uid).get();
  }

  Stream<DocumentSnapshot<Map<String, dynamic>>> watchUserDoc(String uid) {
    return userRef(uid).snapshots(includeMetadataChanges: true);
  }

  /// ✅ users/{uid} 없으면 생성, 있으면 merge 업데이트
  ///
  /// Foodpool 목적:
  /// - createdAt: 최초 1회만
  /// - lastLoginAt: 매 로그인 갱신
  /// - displayName/email/photoUrl: 구글 계정 정보 스냅샷(표시용) → 보통 최신화 권장
  /// - onboarding.step: 없으면 guide 기본값
  /// - uiFlag.guideShown: 없으면 false 기본값
  ///
  /// TODO(FOODPOOL):
  /// - "displayName을 사용자가 수정 못 하게" 할 거면 여기서 항상 구글 값을 덮어쓰는 게 맞음.
  /// - "한 번만 저장하고 고정"이면, 기존 코드처럼 비어있을 때만 채우게 바꾸면 됨.
  Future<void> upsertUser({
    required String uid,
    required String displayName,
    required String email,
    String? photoUrl,

    // 기본값(문서 최초 생성 시에만 의미 있게 적용되도록 트랜잭션에서 처리)
    required String defaultOnboardingStep, // 보통 "guide"
    required bool defaultGuideShown,        // 보통 false
  }) async {
    final ref = userRef(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      if (snap.exists) {
        final d = snap.data() ?? {};

        // ✅ 기존 값
        final curOnboarding = (d['onboarding'] is Map)
            ? Map<String, dynamic>.from(d['onboarding'] as Map)
            : <String, dynamic>{};

        final curUiFlag = (d['uiFlag'] is Map)
            ? Map<String, dynamic>.from(d['uiFlag'] as Map)
            : <String, dynamic>{};

        // ✅ 패치: lastLoginAt은 항상 갱신
        final patch = <String, dynamic>{
          'uid': uid,
          'lastLoginAt': FieldValue.serverTimestamp(),
        };

        // ✅ 구글 계정 기반 정보는 최신화(실명제/프로필 표시 목적)
        // TODO(FOODPOOL): "처음만 저장" 정책이면 조건부로 바꿔도 됨.
        patch['displayName'] = displayName;
        patch['email'] = email;
        patch['photoUrl'] = photoUrl;

        // ✅ onboarding 기본값이 비어 있으면 채우기
        final curStep = (curOnboarding['step'] as String?)?.trim();
        if (curStep == null || curStep.isEmpty) {
          patch['onboarding'] = {
            'step': defaultOnboardingStep,
            'updatedAt': FieldValue.serverTimestamp(),
          };
        }

        // ✅ uiFlag.guideShown 기본값이 없으면 채우기
        if (!curUiFlag.containsKey('guideShown')) {
          patch['uiFlag'] = {
            ...curUiFlag,
            'guideShown': defaultGuideShown,
          };
        }

        tx.set(ref, patch, SetOptions(merge: true));
        return;
      }

      // ✅ 문서 최초 생성
      final data = <String, dynamic>{
        'uid': uid,
        'displayName': displayName,
        'email': email,
        'photoUrl': photoUrl,

        'terms': null, // ✅ 커뮤니티 가이드 동의 전

        'createdAt': FieldValue.serverTimestamp(),
        'lastLoginAt': FieldValue.serverTimestamp(),

        'currentOrderId': null,

        'onboarding': {
          'step': defaultOnboardingStep, // ✅ 기본 guide
          'updatedAt': FieldValue.serverTimestamp(),
        },

        'uiFlag': {
          'guideShown': defaultGuideShown, // ✅ 기본 false
        },
      };

      tx.set(ref, data, SetOptions(merge: false));
    });
  }

  /// ✅ 커뮤니티 가이드 단일 동의 저장
  ///
  /// 요구사항:
  /// - terms(GuideAgreement) 저장
  /// - onboarding.step = done 으로 전환
  /// - (선택) uiFlag.guideShown = true 로 소비
  Future<void> saveGuideAgreement({
    required String uid,
    required String version, // 예: "v1"
  }) async {
    await userRef(uid).set({
      'terms': {
        'version': version,
        'agreedAt': FieldValue.serverTimestamp(),
      },
      'onboarding': {
        'step': 'done',
        'updatedAt': FieldValue.serverTimestamp(),
      },
      // (선택) 가이드 1회 UI를 "봤다" 처리까지 같이 하고 싶으면 true
      // TODO(FOODPOOL): guideShown의 의미를 "가이드 화면 진입"으로 할지, "동의 완료"로 할지 정하기
      'uiFlag': {
        'guideShown': true,
      },
    }, SetOptions(merge: true));
  }

  /// ✅ 온보딩 단계 업데이트 (merge)
  /// step: "guide" | "done"
  Future<void> setOnboardingStep({
    required String uid,
    required String step,
  }) async {
    await userRef(uid).set({
      'onboarding': {
        'step': step,
        'updatedAt': FieldValue.serverTimestamp(),
      },
    }, SetOptions(merge: true));
  }

  /// ✅ uiFlag 부분 업데이트 (merge)
  ///
  /// 예: setUiFlag(uid, { "guideShown": true })
  Future<void> setUiFlag({
    required String uid,
    required Map<String, dynamic> patch,
  }) async {
    await userRef(uid).set({
      'uiFlag': patch,
    }, SetOptions(merge: true));
  }

  /// ✅ 현재 조작 중인 orderId 저장(홈이면 null)
  Future<void> setCurrentOrderId({
    required String uid,
    required String? orderId,
  }) async {
    await userRef(uid).set({
      'currentOrderId': orderId,
    }, SetOptions(merge: true));
  }
}
