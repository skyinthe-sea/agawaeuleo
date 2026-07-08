import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_error_mapper.dart';

/// Supabase 인증 원격 데이터소스 (§3.3 게스트 우선, §7.2 익명 RLS).
///
/// `AuthRepository`(lib/domain/repositories/auth_repository.dart)가 요구하는 원시 인증
/// 동작만 제공한다. 세션 유지/토큰 갱신은 `supabase_flutter`가 자동 처리한다. 모든 실패는
/// [mapSupabaseError]를 거쳐 `AppException` 계열로 변환해 던진다.
class AuthDataSource {
  AuthDataSource(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// 현재 세션의 user_id. 세션이 없으면 null.
  String? get currentUserId => _auth.currentUser?.id;

  /// 세션(익명 포함)이 존재하는지.
  bool get isSignedIn => _auth.currentSession != null;

  /// 현재 세션이 익명(게스트)인지 — JWT `is_anonymous`(§7.2).
  bool get isAnonymous => _auth.currentUser?.isAnonymous ?? false;

  /// 세션(익명 포함) 변화 스트림. 값 = 현재 user_id(세션 없으면 null).
  Stream<String?> authStateChanges() => _auth.onAuthStateChange
      .map((state) => state.session?.user.id)
      .mapErrorToAppException();

  /// 세션이 없으면 익명 로그인으로 부트스트랩하고 user_id를 반환. 이미 세션이 있으면
  /// 기존 user_id를 반환(§3.3 게스트 우선).
  Future<String> ensureSignedIn() async {
    final existing = _auth.currentUser?.id;
    if (existing != null) return existing;
    try {
      final res = await _auth.signInAnonymously();
      final id = res.user?.id;
      if (id == null) {
        throw const AuthException('익명 세션 생성에 실패했어요.');
      }
      return id;
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 익명/기존 세션에 OAuth 아이덴티티를 연결(승격 — PKCE 웹 플로우). 성공 시 true.
  /// M5에서 Apple은 네이티브 nonce 플로우로 정교화 가능(현재는 OAuth 링크로 충분).
  Future<bool> linkOAuth(OAuthProvider provider) async {
    try {
      return await _auth.linkIdentity(provider);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// Apple 계정 연결(iOS 필수 — §3.3).
  Future<bool> linkApple() => linkOAuth(OAuthProvider.apple);

  /// Google 계정 연결(§3.3).
  Future<bool> linkGoogle() => linkOAuth(OAuthProvider.google);

  /// 익명 세션을 이메일 계정으로 승격(user_id 유지 — §3.3). 익명 유저에 이메일/비밀번호를
  /// 부여하는 것이므로 `updateUser`를 사용한다(확인 메일 발송 후 확정).
  Future<void> linkEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.updateUser(UserAttributes(email: email, password: password));
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 이메일 회원가입(§11.4).
  Future<void> signUpEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signUp(email: email, password: password);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 이메일 로그인(§11.3).
  Future<void> signInEmail({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithPassword(email: email, password: password);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 비밀번호 재설정 메일 발송(§11.5).
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.resetPasswordForEmail(email);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 로그아웃(§3.3).
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 계정 및 서버 데이터 파기(§3.3 스토어 필수 — 앱 내 완결).
  ///
  /// `auth.users` 삭제는 service_role/Admin API로만 가능하므로(0002_rls.sql 주석) 서버측
  /// Edge Function `delete-account`(service_role 로 `auth.admin.deleteUser` 호출 →
  /// FK cascade 로 개인 데이터 파기)를 호출한 뒤 로컬 세션을 정리한다.
  ///
  /// M5 자리표시: `delete-account` Edge Function은 아직 배포 전이므로 이 호출은 함수가
  /// 존재해야 성공한다. 배포 전까지는 실패(AppException)한다 — M5에서 함수 구현 후 완결.
  Future<void> deleteAccount() async {
    try {
      await _client.functions.invoke('delete-account');
      await _auth.signOut();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }
}
