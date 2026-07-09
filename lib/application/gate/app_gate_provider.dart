import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/domain/entities/remote_app_config.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// §3.3 앱 게이트 판정 결과(강제 업데이트 / 점검 / 통과).
enum AppGateStatus {
  /// 이용 가능 — 스플래시 분기 계속 진행.
  passed,

  /// 강제 업데이트 필요 — 스토어 안내 화면으로 잠금.
  forceUpdate,

  /// 점검 모드 — 점검 안내 화면으로 잠금.
  maintenance,
}

/// §3.3 게이트 판정값. [isBlocked]가 true면 앱 진입을 잠근다.
@immutable
class AppGateResult {
  const AppGateResult(this.status, {this.maintenanceMessage});

  /// 통과(잠그지 않음) — 미구성/오프라인/판정불가 시의 안전 기본값.
  static const AppGateResult passed = AppGateResult(AppGateStatus.passed);

  final AppGateStatus status;

  /// 점검 안내 문구(nullable — 서버 미지정 시 화면 기본 문구 사용).
  final String? maintenanceMessage;

  /// 강제 업데이트 또는 점검이면 true(스플래시가 상태 화면으로 잠금).
  bool get isBlocked => status != AppGateStatus.passed;
}

/// §3.3 강제 업데이트/점검 게이트(수동 Riverpod — 코드젠 없음).
///
/// - [AppConfigRepository.getConfig]로 원격 설정을 1회 조회한다. 구현체는 미구성/오프라인/
///   실패 시 [RemoteAppConfig.safeDefault]를 돌려주므로 이 게이트는 그 경우 자연히 통과한다
///   (미구성 가드 — 실 키/네트워크 없이도 부팅 가능).
/// - `maintenance`가 켜져 있으면 점검, 아니면 `package_info_plus` 현재 버전과 플랫폼 최소
///   버전을 비교해 강제 업데이트 여부를 판정한다.
///
/// 재조회(점검/스토어 이동 후 복귀 시)는 `ref.invalidate(appGateProvider)`로 다시 돌린다.
final appGateProvider = FutureProvider<AppGateResult>((ref) async {
  final config = await ref.watch(appConfigRepositoryProvider).getConfig();

  // 점검이 최우선(서버 전역 차단).
  if (config.maintenance) {
    return AppGateResult(
      AppGateStatus.maintenance,
      maintenanceMessage: config.maintenanceMessage,
    );
  }

  // 현재 버전 조회 실패(예: 플러그인 미가용 환경)는 잠그지 않는다(안전 기본값).
  final PackageInfo info;
  try {
    info = await PackageInfo.fromPlatform();
  } on Object {
    return AppGateResult.passed;
  }

  final isIos = defaultTargetPlatform == TargetPlatform.iOS;
  if (config.isForceUpdateRequired(
    currentVersion: info.version,
    isIos: isIos,
  )) {
    return const AppGateResult(AppGateStatus.forceUpdate);
  }

  return AppGateResult.passed;
});
