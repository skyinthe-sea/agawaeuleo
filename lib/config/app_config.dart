import 'env.dart';

class AppConfig {
  static String get supabaseUrl => Env.supabaseUrl;
  static String get supabaseAnonKey => Env.supabaseAnonKey;
  static String? get sentryDsn => Env.sentryDsn;
  // 원격 config(강제업데이트/점검)는 app_config 테이블에서 로드
}
