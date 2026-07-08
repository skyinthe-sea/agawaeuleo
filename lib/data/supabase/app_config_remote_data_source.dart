import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/remote_app_config.dart';
import 'supabase_error_mapper.dart';

/// 원격 설정 원격 데이터소스 (§7.1 `app_config`, §3.3 강제 업데이트·점검).
///
/// `app_config`는 `(key text, value jsonb)` 키/값 행 집합이다. 아래 키를 [RemoteAppConfig]로
/// 조립한다. value(jsonb)는 다음 형태를 모두 허용한다:
///   - `min_version_ios` / `min_version_android` : JSON 문자열 `"1.2.0"` 또는 `{"value":"1.2.0"}`.
///   - `maintenance` : JSON bool `true` / 문자열 `"true"` / 객체 `{"enabled":true,"message":"..."}`.
///   - `maintenance_message` : JSON 문자열.
///
/// 미구성/오프라인 가드는 상위 `AppConfigRepository`가 [RemoteAppConfig.safeDefault]로
/// 담당한다 — 이 데이터소스는 초기화된 클라이언트가 있을 때만 생성된다.
class AppConfigRemoteDataSource {
  AppConfigRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'app_config';

  SupabaseQueryBuilder get _from => _client.from(_table);

  /// 원격 설정 1회 조회.
  Future<RemoteAppConfig> getConfig() async {
    try {
      final rows = await _from.select();
      return _assemble(rows);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 원격 설정 변화 관찰(점검 모드 실시간 반영).
  Stream<RemoteAppConfig> watch() =>
      _from.stream(primaryKey: ['key']).map(_assemble).mapErrorToAppException();

  RemoteAppConfig _assemble(List<Map<String, dynamic>> rows) {
    // 기본값은 RemoteAppConfig의 @Default와 동일(§7.1 안전 기본값).
    var minIos = '0.0.0';
    var minAndroid = '0.0.0';
    var maintenance = false;
    String? maintenanceMessage;

    for (final row in rows) {
      final key = row['key'] as String?;
      final value = row['value'];
      switch (key) {
        case 'min_version_ios':
          minIos = _asString(value) ?? minIos;
        case 'min_version_android':
          minAndroid = _asString(value) ?? minAndroid;
        case 'maintenance':
          if (value is bool) {
            maintenance = value;
          } else if (value is Map) {
            maintenance =
                (value['enabled'] ?? value['maintenance'] ?? false) == true;
            maintenanceMessage =
                _asString(value['message']) ?? maintenanceMessage;
          } else {
            maintenance = _asString(value)?.toLowerCase() == 'true';
          }
        case 'maintenance_message':
          maintenanceMessage = _asString(value) ?? maintenanceMessage;
      }
    }

    return RemoteAppConfig(
      minVersionIos: minIos,
      minVersionAndroid: minAndroid,
      maintenance: maintenance,
      maintenanceMessage: maintenanceMessage,
    );
  }

  /// jsonb value에서 문자열을 뽑는다: 직접 String이거나 `{"value": ...}` 형태를 지원.
  static String? _asString(Object? value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map && value['value'] != null) {
      return value['value'].toString();
    }
    return value.toString();
  }
}
