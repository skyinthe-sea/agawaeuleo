import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// §3.3 푸시/로컬 알림 카테고리(카테고리별 on/off).
///
/// 각 카테고리는 Android 알림 채널 1개와 고정 notification id(같은 카테고리의 예약을
/// 취소/갱신할 때 사용)를 소유한다. 설정 화면(§11.16)의 카테고리 토글과 1:1로 대응한다:
///   - [feedingReminder]  ↔ `settings.notifications.feeding_reminder`(로컬 스케줄)
///   - [general]          ↔ `settings.notifications.notice`(FCM 서버 발송 — 범위 밖)
enum NotificationCategory {
  /// "다음 수유 예상" / "밤중 기록 리마인더"(§3.2 S4, §11.6). 로컬 예약 알림.
  feedingReminder(
    channelId: 'feeding_reminder',
    channelName: '수유 리마인더',
    channelDescription: '다음 수유 예상 시각과 밤중 기록 리마인더 알림',
    notificationId: 1001,
    importance: Importance.high,
    priority: Priority.high,
  ),

  /// 앱 공지·소식(§3.3). 서버(FCM) 발송 대상 — 채널만 미리 만들어 둔다.
  general(
    channelId: 'general',
    channelName: '공지사항',
    channelDescription: '앱 소식과 안내 알림',
    notificationId: 2001,
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  const NotificationCategory({
    required this.channelId,
    required this.channelName,
    required this.channelDescription,
    required this.notificationId,
    required this.importance,
    required this.priority,
  });

  /// Android 알림 채널 식별자(생성 후 변경 불가).
  final String channelId;

  /// 사용자에게 노출되는 채널 이름(기기 알림 설정에 표시).
  final String channelName;

  /// 채널 설명(기기 알림 설정에 표시).
  final String channelDescription;

  /// 이 카테고리의 예약/표시에 쓰는 고정 알림 id.
  final int notificationId;

  /// Android 채널 중요도.
  final Importance importance;

  /// Android 알림 우선순위(개별 알림).
  final Priority priority;

  /// 이 카테고리의 Android 알림 채널 정의.
  AndroidNotificationChannel get channel => AndroidNotificationChannel(
    channelId,
    channelName,
    description: channelDescription,
    importance: importance,
  );

  /// 플랫폼별 표시 상세. iOS 권한은 프라이밍(§11.6)에서 별도로 받으므로 여기서
  /// 요청하지 않고 표시 옵션만 지정한다.
  NotificationDetails details() => NotificationDetails(
    android: AndroidNotificationDetails(
      channelId,
      channelName,
      channelDescription: channelDescription,
      importance: importance,
      priority: priority,
    ),
    iOS: const DarwinNotificationDetails(),
  );
}
