import 'package:cloud_firestore/cloud_firestore.dart';

/// =======================
/// Foodpool users/{uid}
/// =======================
/// users/{userId}
/// {
///   "uid": "{userId}",
///   "displayName": "홍길동",
///   "email": "test@gmail.com",
///   "photoUrl": "...",
///   "terms": { ... } | null,                 // ✅ 커뮤니티 가이드 단일 동의(아래 GuideAgreement)
///   "createdAt": Timestamp,                  // 최초 1회
///   "lastLoginAt": Timestamp,                // 로그인 시 갱신
///   "currentOrderId": "roomId" | null,
///   "onboarding": { "step": "guide"|"done" } // ✅ done 고정(완료 후)
///   "uiFlag": { "guideShown": true|false }   // ✅ 1회성 UI 플래그(단일/확장 가능)
/// }
///
/// NOTE:
/// - Firestore 저장 시 createdAt/lastLoginAt은 serverTimestamp 권장.
/// - onboarding/terms/uiFlag는 스키마 단순화를 위해 Map 형태 유지.

enum OnboardingStep {
  guide,
  done,
}

OnboardingStep onboardingStepFromString(String? raw) {
  switch (raw) {
    case 'done':
      return OnboardingStep.done;
    case 'guide':
    default:
      // ✅ 기본값: guide (이번 프로젝트 요구사항 반영)
      return OnboardingStep.guide;
  }
}

String onboardingStepToString(OnboardingStep step) {
  switch (step) {
    case OnboardingStep.guide:
      return 'guide';
    case OnboardingStep.done:
      return 'done';
  }
}

class AppUser {
  final String uid;

  /// ✅ Google 계정에서 가져오는 정보(실명제 표시용)
  final String displayName;
  final String email;
  final String? photoUrl;

  /// ✅ 커뮤니티 가이드 단일 동의(동의 안했으면 null)
  /// - 필드명은 너가 제시한 스키마대로 "terms"를 그대로 사용
  final GuideAgreement? terms;

  final DateTime? createdAt;
  final DateTime? lastLoginAt;

  /// 홈이면 null
  final String? currentOrderId;

  /// ✅ 온보딩 단계(가이드 -> done)
  final OnboardingStep onboardingStep;

  /// ✅ 1회성 UI 플래그(현재는 guideShown만)
  final UiFlag uiFlag;

  const AppUser({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.photoUrl,
    required this.terms,
    required this.createdAt,
    required this.lastLoginAt,
    required this.currentOrderId,
    required this.onboardingStep,
    required this.uiFlag,
  });

  bool get onboardingDone => onboardingStep == OnboardingStep.done;
  bool get needsGuide => onboardingStep == OnboardingStep.guide;

  /// 커뮤니티 가이드 동의 여부
  bool get hasAgreedGuide => terms != null;

  factory AppUser.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};

    // onboarding/uiFlag는 Map일 수도 없을 수도 있으니 안전 파싱
    final onboarding = (data['onboarding'] is Map)
        ? Map<String, dynamic>.from(data['onboarding'] as Map)
        : <String, dynamic>{};

    final uiFlagRaw = (data['uiFlag'] is Map)
        ? Map<String, dynamic>.from(data['uiFlag'] as Map)
        : <String, dynamic>{};

    return AppUser(
      // ✅ uid 필드가 없으면 doc.id 사용(마이그레이션/누락 방지)
      uid: (data['uid'] as String?) ?? doc.id,

      displayName: (data['displayName'] ?? '') as String,
      email: (data['email'] ?? '') as String,
      photoUrl: data['photoUrl'] as String?,

      // ✅ "terms"는 커뮤니티 가이드 단일 동의
      terms: data['terms'] == null
          ? null
          : GuideAgreement.fromMap(Map<String, dynamic>.from(data['terms'])),

      createdAt: (data['createdAt'] is Timestamp)
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      lastLoginAt: (data['lastLoginAt'] is Timestamp)
          ? (data['lastLoginAt'] as Timestamp).toDate()
          : null,

      currentOrderId: data['currentOrderId'] as String?,

      // ✅ 없으면 기본값 guide
      onboardingStep: onboardingStepFromString(onboarding['step'] as String?),

      uiFlag: UiFlag.fromMap(uiFlagRaw),
    );
  }

  /// (선택) write/update에 쓰기 위한 Map
  /// - 실제 저장은 Repository에서 FieldValue.serverTimestamp 등을 섞어 쓰는 걸 추천
  Map<String, dynamic> toMapForWrite() {
    return {
      'uid': uid,
      'displayName': displayName,
      'email': email,
      'photoUrl': photoUrl,
      'terms': terms?.toMap(),
      'createdAt': createdAt == null ? null : Timestamp.fromDate(createdAt!),
      'lastLoginAt': lastLoginAt == null ? null : Timestamp.fromDate(lastLoginAt!),
      'currentOrderId': currentOrderId,
      'onboarding': {
        'step': onboardingStepToString(onboardingStep),
      },
      'uiFlag': uiFlag.toMap(),
    };
  }
}

/// ✅ 커뮤니티 가이드 단일 동의 모델
/// - 기존 TermsAgreement를 Foodpool 목적에 맞게 단순화
class GuideAgreement {
  final String version;     // 예: "v1"
  final DateTime agreedAt;  // 동의 시각

  const GuideAgreement({
    required this.version,
    required this.agreedAt,
  });

  factory GuideAgreement.fromMap(Map<String, dynamic> map) {
    final agreedAtRaw = map['agreedAt'];
    final agreedAt = agreedAtRaw is Timestamp
        ? agreedAtRaw.toDate()
        : DateTime.tryParse(agreedAtRaw?.toString() ?? '');

    return GuideAgreement(
      version: (map['version'] ?? 'v1') as String,
      agreedAt: agreedAt ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'version': version,
      'agreedAt': Timestamp.fromDate(agreedAt),
    };
  }
}

/// ✅ 1회성 UI 플래그(단일 플래그만)
class UiFlag {
  /// 예: 커뮤니티 가이드 화면에서 "안내 문구/다이얼로그"를 1회만 띄우고 싶을 때
  final bool guideShown;

  const UiFlag({
    required this.guideShown,
  });

  factory UiFlag.fromMap(Map<String, dynamic> map) {
    return UiFlag(
      guideShown: (map['guideShown'] ?? false) as bool,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'guideShown': guideShown,
    };
  }
}
