import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/core/notifications/notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 알림 시스템 프로바이더 배선 (§3.2 S4 · §3.3 · §11.6).
///
/// providers.dart(코드젠)는 **수정 금지**라 알림 관련 프로바이더는 이 별도 파일에서
/// **코드젠 없는 수동 Riverpod**으로 배선한다. 트래킹 리포지토리 등 상위 의존성은
/// providers.dart의 코드젠 프로바이더를 그대로 watch 한다.
///
/// 통합 단계 주의:
///   - `main()`에서 [notificationServiceProvider].ensureInitialized()와
///     [fcmClientProvider].ensureInitialized()를 시작 시 1회 호출해 채널 생성/토큰
///     로깅을 기동할 수 있다(권한 요청은 프라이밍 화면에서만).
///   - 트래킹 저장 성공 후 [feedingReminderSchedulerProvider].rescheduleFromRecent()를
///     호출하면 "다음 수유 예상" 알림이 갱신된다.

/// 로컬 알림 서비스(단일 인스턴스, 앱 수명 유지).
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// FCM 클라이언트(미구성 가드 내장 — google-services 없이도 안전).
final fcmClientProvider = Provider<FcmClient>((ref) => FcmClient());

/// "다음 수유 예상" 스케줄러. 트래킹 리포지토리(providers.dart 코드젠)를 watch.
final feedingReminderSchedulerProvider = Provider<FeedingReminderScheduler>(
  (ref) => FeedingReminderScheduler(
    service: ref.watch(notificationServiceProvider),
    tracking: ref.watch(trackingRepositoryProvider),
  ),
);

/// 현재 OS 알림 권한 상태(§11.16 안내·§11.6 프라이밍 재노출 판단).
final notificationPermissionStatusProvider =
    FutureProvider<NotificationPermissionStatus>(
      (ref) => ref.watch(notificationServiceProvider).permissionStatus(),
    );
