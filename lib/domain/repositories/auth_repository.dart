/// 인증/계정 저장소 (§3.3 게스트 우선, §7.2 익명 RLS). 인터페이스만 정의.
///
/// 첫 진입은 익명 세션([ensureSignedIn])으로 자동 생성되고, 이후 Apple/Google/이메일을
/// `linkIdentity()`로 연결(승격)하면 `user_id`가 유지되어 게스트 기록이 그대로 계정 데이터가 된다.
/// 실패 시 구현체는 `AppAuthException`(lib/core/error/app_exception.dart)을 던진다.
abstract class AuthRepository {
  /// 현재 세션의 user_id. 세션이 없으면 null.
  String? get currentUserId;

  /// 세션이 존재하는지(익명 포함).
  bool get isSignedIn;

  /// 현재 세션이 익명(게스트)인지(JWT `is_anonymous` — §7.2).
  bool get isAnonymous;

  /// 세션(익명 포함) 변화 스트림. 값 = 현재 user_id(세션 없으면 null).
  Stream<String?> authStateChanges();

  /// 세션이 없으면 익명 로그인으로 부트스트랩하고 user_id를 반환(§3.3 게스트 우선).
  /// 이미 세션이 있으면 기존 user_id를 반환.
  Future<String> ensureSignedIn();

  /// 익명/기존 세션에 Apple 계정을 연결(승격 — iOS 필수).
  Future<void> linkApple();

  /// 익명/기존 세션에 Google 계정을 연결(승격).
  Future<void> linkGoogle();

  /// 익명/기존 세션에 이메일 계정을 연결(승격).
  Future<void> linkEmail({required String email, required String password});

  /// 이메일 로그인.
  Future<void> signInEmail({required String email, required String password});

  /// 이메일 회원가입(§11.4).
  Future<void> signUpEmail({required String email, required String password});

  /// 비밀번호 재설정 메일 발송(§11.5).
  Future<void> resetPassword({required String email});

  /// 로그아웃.
  Future<void> signOut();

  /// 계정 및 서버 데이터 파기(§3.3 스토어 필수 — 앱 내 완결).
  Future<void> deleteAccount();
}
