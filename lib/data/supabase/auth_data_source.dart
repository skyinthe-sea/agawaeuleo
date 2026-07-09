import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../core/error/app_exception.dart';
import 'supabase_error_mapper.dart';

/// Supabase 인증 원격 데이터소스 (§3.3 게스트 우선, §7.2 익명 RLS, §13.4 스토어 필수).
///
/// `AuthRepository`(lib/domain/repositories/auth_repository.dart)가 요구하는 원시 인증
/// 동작만 제공한다. 세션 유지/토큰 갱신은 `supabase_flutter`가 자동 처리한다. 모든 실패는
/// [mapSupabaseError]를 거쳐 `AppException` 계열로 변환해 던진다(사용자 취소는
/// `code == 'canceled'` 로 구분해 화면이 조용히 무시할 수 있게 한다).
///
/// **계정 연결(승격)은 네이티브 플로우**: Apple은 `sign_in_with_apple`,
/// Google은 `google_sign_in`으로 OS 시트를 띄워 id_token을 받고, 익명 세션에
/// [GoTrueClient.linkIdentityWithIdToken]로 붙인다. 이렇게 하면 `user_id`가 유지되어
/// 게스트 시절 기록·즐겨찾기가 그대로 계정 데이터가 된다(브라우저 왕복 없음).
class AuthDataSource {
  AuthDataSource(this._client);

  final SupabaseClient _client;

  GoTrueClient get _auth => _client.auth;

  /// Google 로그인 서버(웹) 클라이언트 id. 토큰 audience 검증에 필요하다(특히 Android).
  /// 네이티브 설정은 발주자 몫(§12.1)이므로 값은 비워 두고 `--dart-define`으로 주입한다.
  /// (예: `flutter run --dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`)
  static const String _googleServerClientId = String.fromEnvironment(
    'GOOGLE_SERVER_CLIENT_ID',
  );

  bool _googleInitialized = false;

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
  /// 기존 user_id를 반환(§3.3 게스트 우선). 로그아웃/계정삭제 후 게스트 복귀에도 쓴다.
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

  /// 익명/기존 세션에 **Apple 계정을 네이티브로 연결**(iOS 필수 — §13.4).
  ///
  /// replay 공격 방어를 위해 raw nonce를 만들고 그 SHA-256을 Apple에 넘긴 뒤, Supabase에는
  /// raw nonce를 넘겨 토큰의 nonce 클레임과 대조하게 한다(Supabase Apple 네이티브 표준 패턴).
  Future<void> linkApple() async {
    try {
      final rawNonce = _auth.generateRawNonce();
      final hashedNonce = sha256.convert(utf8.encode(rawNonce)).toString();

      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: const [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final idToken = credential.identityToken;
      if (idToken == null) {
        throw const AuthException('Apple 로그인 토큰을 받지 못했어요.');
      }
      await _auth.linkIdentityWithIdToken(
        provider: OAuthProvider.apple,
        idToken: idToken,
        nonce: rawNonce,
      );
    } on SignInWithAppleAuthorizationException catch (error, stackTrace) {
      throw _mapAppleError(error, stackTrace);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 익명/기존 세션에 **Google 계정을 네이티브로 연결**(§3.3).
  Future<void> linkGoogle() async {
    try {
      await _ensureGoogleInitialized();
      final google = GoogleSignIn.instance;
      if (!google.supportsAuthenticate()) {
        throw const AuthException('이 기기에서는 Google 로그인을 사용할 수 없어요.');
      }
      final account = await google.authenticate();
      final idToken = account.authentication.idToken;
      if (idToken == null) {
        throw const AuthException('Google 로그인 토큰을 받지 못했어요.');
      }
      await _auth.linkIdentityWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );
    } on GoogleSignInException catch (error, stackTrace) {
      throw _mapGoogleError(error, stackTrace);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 익명 세션을 이메일 계정으로 승격(user_id 유지 — §3.3, §11.4). 익명 유저에 이메일/
  /// 비밀번호를 부여하는 것이므로 `updateUser`를 쓴다(확인 메일 발송 후 확정될 수 있음).
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

  /// 이메일 회원가입(§11.4). 익명이 아닌 신규 가입 경로.
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

  /// 로그아웃(§3.3). 게스트(익명) 복귀는 호출부가 [ensureSignedIn]으로 잇는다.
  Future<void> signOut() async {
    try {
      await _auth.signOut();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 계정 및 서버 데이터 파기(§3.3·§13.4 스토어 필수 — 앱 내 완결).
  ///
  /// `auth.users` 삭제는 service_role/Admin API로만 가능하므로 서버측 Edge Function
  /// `delete-account`(supabase/functions/delete-account/index.ts)를 **현재 사용자 JWT로**
  /// 호출한다. 함수가 JWT를 검증해 본인 계정만 `auth.admin.deleteUser`로 지우고, 개인
  /// 데이터는 FK `on delete cascade`로 함께 파기된다. 성공 후 로컬 세션을 정리한다.
  Future<void> deleteAccount() async {
    try {
      // functions.invoke 는 현재 세션의 access token 을 Authorization 헤더로 자동 첨부한다.
      final response = await _client.functions.invoke('delete-account');
      final status = response.status;
      if (status < 200 || status >= 300) {
        throw AuthException('계정 삭제에 실패했어요. (status: $status)');
      }
      await _auth.signOut();
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await GoogleSignIn.instance.initialize(
      serverClientId: _googleServerClientId.isEmpty
          ? null
          : _googleServerClientId,
    );
    _googleInitialized = true;
  }

  AppException _mapAppleError(
    SignInWithAppleAuthorizationException error,
    StackTrace stackTrace,
  ) {
    if (error.code == AuthorizationErrorCode.canceled) {
      return AppAuthException(
        message: '로그인을 취소했어요.',
        code: 'canceled',
        cause: error,
        stackTrace: stackTrace,
      );
    }
    return AppAuthException(
      message: 'Apple 로그인에 실패했어요. 다시 시도해 주세요.',
      code: error.code.name,
      cause: error,
      stackTrace: stackTrace,
    );
  }

  AppException _mapGoogleError(
    GoogleSignInException error,
    StackTrace stackTrace,
  ) {
    final canceled = error.code == GoogleSignInExceptionCode.canceled;
    return AppAuthException(
      message: canceled ? '로그인을 취소했어요.' : 'Google 로그인에 실패했어요. 다시 시도해 주세요.',
      code: canceled ? 'canceled' : error.code.name,
      cause: error,
      stackTrace: stackTrace,
    );
  }
}
