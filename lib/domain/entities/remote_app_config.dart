import 'package:freezed_annotation/freezed_annotation.dart';

part 'remote_app_config.freezed.dart';

/// 원격 설정 엔티티 (§7.1 `app_config` key/value 조합, §3.3 강제 업데이트·점검).
///
/// `app_config` 테이블의 key/value(jsonb) 행들을 data 레이어가 이 엔티티로 조립한다.
/// (예: 'min_version_ios', 'min_version_android', 'maintenance').
@freezed
abstract class RemoteAppConfig with _$RemoteAppConfig {
  const RemoteAppConfig._();

  const factory RemoteAppConfig({
    /// iOS 최소 허용 버전(semver). 미만이면 강제 업데이트.
    @Default('0.0.0') String minVersionIos,

    /// Android 최소 허용 버전(semver). 미만이면 강제 업데이트.
    @Default('0.0.0') String minVersionAndroid,

    /// 점검 모드 플래그. true면 앱 이용 차단 화면 노출.
    @Default(false) bool maintenance,

    /// 점검 안내 메시지(nullable).
    String? maintenanceMessage,
  }) = _RemoteAppConfig;

  /// 미구성(AppConfig.isConfigured == false)·오프라인 시 앱을 잠그지 않는 안전 기본값.
  factory RemoteAppConfig.safeDefault() => const RemoteAppConfig();

  /// 플랫폼별 최소 허용 버전.
  String minVersionFor({required bool isIos}) =>
      isIos ? minVersionIos : minVersionAndroid;

  /// [currentVersion]이 플랫폼 최소 버전보다 낮으면 강제 업데이트 필요 (§3.3).
  bool isForceUpdateRequired({
    required String currentVersion,
    required bool isIos,
  }) => _compareVersions(currentVersion, minVersionFor(isIos: isIos)) < 0;

  /// semver 비교. a<b → -1, a==b → 0, a>b → 1. 빌드/프리릴리스 접미사는 무시.
  static int _compareVersions(String a, String b) {
    final pa = _parseVersion(a);
    final pb = _parseVersion(b);
    final len = pa.length > pb.length ? pa.length : pb.length;
    for (var i = 0; i < len; i++) {
      final x = i < pa.length ? pa[i] : 0;
      final y = i < pb.length ? pb[i] : 0;
      if (x != y) return x < y ? -1 : 1;
    }
    return 0;
  }

  static List<int> _parseVersion(String version) {
    final core = version.split(RegExp('[+-]')).first;
    return core
        .split('.')
        .map((part) => int.tryParse(part.trim()) ?? 0)
        .toList();
  }
}
