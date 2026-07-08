import '../entities/remote_app_config.dart';

/// 원격 설정 저장소 (§3.3 강제 업데이트·점검, §7.1 `app_config`).
///
/// 미구성(AppConfig.isConfigured == false)·오프라인 시 구현체는 앱을 잠그지 않도록
/// [RemoteAppConfig.safeDefault]를 반환한다(미구성 가드). 실패 시에도 안전 기본값 반환을 권장.
abstract class AppConfigRepository {
  /// 원격 설정 1회 조회.
  Future<RemoteAppConfig> getConfig();

  /// 원격 설정 변화 관찰(점검 모드 실시간 반영용).
  Stream<RemoteAppConfig> watch();
}
