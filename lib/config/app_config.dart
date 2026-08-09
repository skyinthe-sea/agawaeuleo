import 'env.dart';

class AppConfig {
  static String get supabaseUrl => Env.supabaseUrl;
  static String get supabaseAnonKey => Env.supabaseAnonKey;
  static String? get sentryDsn => Env.sentryDsn;
  // 원격 config(강제업데이트/점검)는 app_config 테이블에서 로드

  /// 개인기록(아기 프로필·트래킹·즐겨찾기)의 서버 동기화 스위치.
  ///
  /// **게스트 전용 출시에서는 반드시 `false`.** 계정 연결·백업·복원 UI가 전부 비활성인
  /// 지금, 익명 세션으로 개인기록을 서버에 올려도 이용자가 되돌려받을 방법이 없다.
  /// 그러면서 앱 내 약관·개인정보처리방침·스토어 설명은 "기록은 기기 안에만 저장되며
  /// 서버로 전송되지 않습니다"라고 약속하고 있어(§13, `store/legal/privacy_policy.md`),
  /// 켜 두면 그 약속이 거짓이 되고 App Store 심사에서 5.1.1(데이터 수집·저장) 사유가
  /// 된다. 그래서 이득 없는 전송을 끄고 문구를 사실로 만든다.
  ///
  /// `false`일 때 꺼지는 것 (모두 `providers.dart`/`SupabaseBootstrap`에서 분기):
  ///   - 익명(게스트) Supabase 세션 생성 — `signInAnonymously()` 자체를 호출하지 않는다.
  ///   - 개인기록 원격 데이터소스 3종 → `SyncService`가 완전 no-op.
  ///   - 리포지토리의 `pending_ops` 적재 → 보낼 큐가 아예 쌓이지 않는다.
  ///
  /// 영향 없는 것: 증상·참고정보·제품 등 **공용 마스터 데이터 조회**. RLS가
  /// `for select using (true)`(`supabase/migrations/0002_rls.sql`)라 세션 없이
  /// anon 키만으로 읽히며, 매니페스트 캐싱(§5.3)도 그대로 동작한다.
  ///
  /// 계정 기능을 되살릴 때 이 값을 `true`로 되돌리면 기존 동기화 경로가 그대로 살아난다.
  static const bool personalDataSyncEnabled = false;
}
