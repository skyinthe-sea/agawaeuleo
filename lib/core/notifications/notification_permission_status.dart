/// OS 알림 권한 상태(§11.6 프라이밍·§11.16 설정 안내에서 사용).
///
/// 플랫폼마다 조회 가능한 정밀도가 달라 [notDetermined]는 신뢰성 있게 구분되지 않을 수
/// 있다(iOS `checkPermissions`는 활성/비활성만 반환). 그런 경우 [unknown]으로 폴백한다.
enum NotificationPermissionStatus {
  /// 알림이 허용됨.
  granted,

  /// 사용자가 거부했거나 기기 설정에서 꺼짐.
  denied,

  /// 아직 요청하지 않음(주로 iOS 첫 실행 전). 조회로 확정 못 하면 [unknown] 사용.
  notDetermined,

  /// 조회 불가/미지원 플랫폼.
  unknown;

  /// 실제로 알림을 보낼 수 있는 상태인지.
  bool get isGranted => this == NotificationPermissionStatus.granted;
}
