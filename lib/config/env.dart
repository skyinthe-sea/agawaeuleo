import 'package:envied/envied.dart';

part 'env.g.dart';

@Envied(path: '.env', obfuscate: true)
abstract class Env {
  // defaultValue '': 발주자가 값을 채우기 전에도 빌드가 가능해야 함 (미구성 시 런타임 가드)
  @EnviedField(varName: 'SUPABASE_URL', obfuscate: true, defaultValue: '')
  static final String supabaseUrl = _Env.supabaseUrl;
  @EnviedField(varName: 'SUPABASE_ANON_KEY', obfuscate: true, defaultValue: '')
  static final String supabaseAnonKey = _Env.supabaseAnonKey;
  @EnviedField(varName: 'SENTRY_DSN', obfuscate: true, optional: true)
  static final String? sentryDsn = _Env.sentryDsn;
}
