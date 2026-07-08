import 'package:supabase_flutter/supabase_flutter.dart';

import '../../config/app_config.dart';

/// Supabase 초기화 + 게스트(익명) 세션 부트스트랩 래퍼 (§3.3 게스트 우선, §5.1).
///
/// 미구성 가드: [AppConfig.supabaseUrl]/[AppConfig.supabaseAnonKey]가 비어 있으면
/// (발주자가 `.env` 값을 아직 채우지 않은 상태) Supabase에 접근하지 않고 초기화를 건너뛰며
/// `false`를 반환한다. 이 경우 앱은 로컬(Drift) 전용으로 동작하고, 원격 리포지토리·
/// [AppConfigRepository]는 안전 기본값을 반환하도록 설계되어 있다.
class SupabaseBootstrap {
  const SupabaseBootstrap._();

  static var _initialized = false;

  /// `.env`에 Supabase URL/anonKey가 모두 채워졌는지. false면 원격 접근 금지.
  static bool get isConfigured =>
      AppConfig.supabaseUrl.isNotEmpty && AppConfig.supabaseAnonKey.isNotEmpty;

  /// 이미 초기화가 끝났는지(중복 [Supabase.initialize] 방지).
  static bool get isInitialized => _initialized;

  /// 구성돼 있으면 [Supabase.initialize] 후 세션이 없을 때 익명 로그인으로 게스트
  /// 세션을 만든다(§3.3). 초기화에 성공하면 `true`, 미구성이면 `false`.
  ///
  /// 익명 로그인이 실패해도(오프라인 등) 예외를 던지지 않는다 — 게스트 부트스트랩 실패로
  /// 앱이 죽지 않게 하기 위함(§3.3 "실패해도 앱은 죽지 않게"). 세션 없는 상태로 계속
  /// 진행하며, 이후 온라인 복귀 시 리포지토리가 재시도한다.
  static Future<bool> ensureInitialized() async {
    if (!isConfigured) return false;
    if (!_initialized) {
      await Supabase.initialize(
        url: AppConfig.supabaseUrl,
        // publishableKey == 기존 anon key(같은 값, supabase_flutter 2.16 신 명칭).
        publishableKey: AppConfig.supabaseAnonKey,
      );
      _initialized = true;
    }
    await _ensureGuestSession();
    return true;
  }

  /// 세션이 없으면 익명 로그인 시도(실패는 삼킨다 — §3.3).
  static Future<void> _ensureGuestSession() async {
    final auth = Supabase.instance.client.auth;
    if (auth.currentSession != null) return;
    try {
      await auth.signInAnonymously();
    } on Object {
      // 게스트 부트스트랩 실패 허용: 세션 없이 진행, 콘텐츠 열람은 공개 읽기로 가능.
    }
  }
}
