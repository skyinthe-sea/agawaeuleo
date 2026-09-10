import 'package:shared_preferences/shared_preferences.dart';

/// 어드민 접속 설정(Supabase URL + service_role 키)을 기기에 1회 저장한다.
///
/// APK/깃에 시크릿을 넣지 않기 위한 런타임 설정 — 최초 실행 시 [ConfigScreen]에서
/// 입력받아 [SharedPreferences]에 보관하고, 이후 실행은 저장된 값을 재사용한다.
class AdminConfig {
  const AdminConfig({required this.url, required this.serviceKey});

  final String url;
  final String serviceKey;

  bool get isComplete => url.trim().isNotEmpty && serviceKey.trim().isNotEmpty;
}

class ConfigStore {
  static const _kUrl = 'supabase_url';
  static const _kKey = 'supabase_service_key';

  /// 알려진 프로젝트 URL 기본값(발주자 프로젝트). 키는 비워둔다.
  static const defaultUrl = 'https://jmvhdsxsotbgpqwxtogm.supabase.co';

  Future<AdminConfig?> load() async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString(_kUrl);
    final key = prefs.getString(_kKey);
    if (url == null || key == null || url.isEmpty || key.isEmpty) return null;
    return AdminConfig(url: url, serviceKey: key);
  }

  Future<void> save(AdminConfig config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUrl, config.url.trim());
    await prefs.setString(_kKey, config.serviceKey.trim());
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_kUrl);
    await prefs.remove(_kKey);
  }
}
