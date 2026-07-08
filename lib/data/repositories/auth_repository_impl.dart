import 'package:agawaeuleo/core/error/app_exception.dart';
import 'package:agawaeuleo/data/repositories/support/local_identity_store.dart';
import 'package:agawaeuleo/data/supabase/auth_data_source.dart';
import 'package:agawaeuleo/domain/repositories/auth_repository.dart';

/// [AuthRepository] 구현 (§3.3 게스트 우선, §7.2 익명 RLS).
///
/// - **구성됨**: [AuthDataSource](Supabase gotrue)에 위임. 익명 부트스트랩 → Apple/
///   Google/이메일 연결(승격)로 `user_id`를 유지한다.
/// - **미구성(로컬 전용)**: 원격 인증이 없으므로 [LocalIdentityStore]의 로컬 게스트 id로
///   [ensureSignedIn]을 만족시키고(§2-4 로그인 없이 사용), 로그인/연결/재설정 요청은
///   `AppAuthException`으로 "지금은 사용할 수 없음"을 알린다. [signOut]은 무해한 no-op.
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._identity, [this._dataSource]);

  final LocalIdentityStore _identity;
  final AuthDataSource? _dataSource;

  bool get _isConfigured => _dataSource != null;

  static const AppAuthException _unavailable = AppAuthException(
    message: '지금은 로그인 없이 사용 중이에요. 나중에 계정을 연결해 백업할 수 있어요.',
    code: 'auth_unavailable',
  );

  @override
  String? get currentUserId => _dataSource?.currentUserId ?? _identity.idOrNull;

  @override
  bool get isSignedIn => _dataSource?.isSignedIn ?? false;

  @override
  bool get isAnonymous => _dataSource?.isAnonymous ?? false;

  @override
  Stream<String?> authStateChanges() =>
      _dataSource?.authStateChanges() ?? Stream<String?>.value(null);

  @override
  Future<String> ensureSignedIn() async {
    final ds = _dataSource;
    if (ds != null) return ds.ensureSignedIn();
    // 미구성: 로컬 게스트 신원으로 대체(원격 세션 없음).
    return _identity.ensureId();
  }

  @override
  Future<void> linkApple() async {
    if (!_isConfigured) throw _unavailable;
    await _dataSource!.linkApple();
  }

  @override
  Future<void> linkGoogle() async {
    if (!_isConfigured) throw _unavailable;
    await _dataSource!.linkGoogle();
  }

  @override
  Future<void> linkEmail({
    required String email,
    required String password,
  }) async {
    if (!_isConfigured) throw _unavailable;
    await _dataSource!.linkEmail(email: email, password: password);
  }

  @override
  Future<void> signInEmail({
    required String email,
    required String password,
  }) async {
    if (!_isConfigured) throw _unavailable;
    await _dataSource!.signInEmail(email: email, password: password);
  }

  @override
  Future<void> signUpEmail({
    required String email,
    required String password,
  }) async {
    if (!_isConfigured) throw _unavailable;
    await _dataSource!.signUpEmail(email: email, password: password);
  }

  @override
  Future<void> resetPassword({required String email}) async {
    if (!_isConfigured) throw _unavailable;
    await _dataSource!.resetPassword(email: email);
  }

  @override
  Future<void> signOut() async {
    final ds = _dataSource;
    if (ds == null) return; // 미구성: 로컬 전용, 세션 없음 → no-op.
    await ds.signOut();
  }

  @override
  Future<void> deleteAccount() async {
    final ds = _dataSource;
    if (ds == null) {
      // 미구성: 원격 데이터 없음. 로컬 게스트 신원만 초기화한다.
      await _identity.reset();
      return;
    }
    await ds.deleteAccount();
  }
}
