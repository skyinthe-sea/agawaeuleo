import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import 'notification_categories.dart';
import 'notification_permission_status.dart';

/// §3.2 S4 로컬 알림 인프라. `flutter_local_notifications` + `timezone` 초기화,
/// Android 채널 생성 / iOS 권한 요청, 권한 상태 조회, 예약/취소 API를 제공한다.
///
/// 미구성 가드: 실 키·서버 없이도 부팅되어야 하므로 모든 플랫폼 채널 호출은 예외를
/// 삼켜 앱을 죽이지 않는다(§8 "값이 비어도 부팅"). 실제 알림 표시는 통합 단계에서 트래킹
/// 화면·설정 토글과 배선된다.
class NotificationService {
  NotificationService({FlutterLocalNotificationsPlugin? plugin})
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  /// 한국어 고정 앱(§3.3) — 로컬 타임존 기본값. 조회 실패 시 UTC로 폴백한다.
  static const String defaultTimeZone = 'Asia/Seoul';

  bool _initialized = false;

  /// 초기화가 끝났는지.
  bool get isInitialized => _initialized;

  /// 플러그인·타임존 초기화 + Android 채널 생성. 여러 번 호출해도 1회만 수행한다.
  Future<void> ensureInitialized() async {
    if (_initialized) return;
    _configureTimeZone();

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    // iOS 권한은 프라이밍 화면(§11.6)에서 맥락과 함께 요청한다 — init 시에는 요청 금지.
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    try {
      await _plugin.initialize(
        settings: const InitializationSettings(android: android, iOS: darwin),
      );
      await _createAndroidChannels();
      _initialized = true;
    } on Object catch (error, stack) {
      // 미지원/미구성 환경에서도 앱은 계속 동작해야 한다.
      debugPrint('[NotificationService] init 실패(무시): $error\n$stack');
    }
  }

  void _configureTimeZone() {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation(defaultTimeZone));
    } on Object catch (error) {
      // getLocation 실패 시 기본 UTC 유지(예약은 여전히 동작, 시각만 UTC 기준).
      debugPrint('[NotificationService] 타임존 설정 실패(UTC 폴백): $error');
    }
  }

  Future<void> _createAndroidChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android == null) return;
    for (final category in NotificationCategory.values) {
      await android.createNotificationChannel(category.channel);
    }
  }

  /// OS 권한 요청(§11.6 "알림 켜기"). 허용되면 true.
  /// Android 13 미만은 런타임 권한이 없어 true로 간주한다.
  Future<bool> requestPermission() async {
    await ensureInitialized();
    try {
      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final granted = await ios?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final granted = await android?.requestNotificationsPermission();
        // null == Android 13 미만(런타임 권한 없음) → 허용으로 간주.
        return granted ?? true;
      }
    } on Object catch (error) {
      debugPrint('[NotificationService] 권한 요청 실패: $error');
    }
    return false;
  }

  /// 현재 OS 알림 권한 상태(§11.16 안내·프라이밍 노출 판단).
  Future<NotificationPermissionStatus> permissionStatus() async {
    await ensureInitialized();
    try {
      if (Platform.isAndroid) {
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        final enabled = await android?.areNotificationsEnabled();
        if (enabled == null) return NotificationPermissionStatus.unknown;
        return enabled
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      }
      if (Platform.isIOS) {
        final ios = _plugin
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
        final options = await ios?.checkPermissions();
        if (options == null) return NotificationPermissionStatus.unknown;
        return options.isEnabled
            ? NotificationPermissionStatus.granted
            : NotificationPermissionStatus.denied;
      }
    } on Object catch (error) {
      debugPrint('[NotificationService] 권한 조회 실패: $error');
    }
    return NotificationPermissionStatus.unknown;
  }

  /// [when] 시각에 [category] 채널로 알림 1건을 예약(§3.2 S4).
  /// 정확 알람 권한이 필요 없도록 `inexactAllowWhileIdle` 모드를 쓴다.
  Future<void> schedule({
    required int id,
    required String title,
    required String body,
    required DateTime when,
    required NotificationCategory category,
    String? payload,
  }) async {
    await ensureInitialized();
    final scheduledDate = tz.TZDateTime.from(when, tz.local);
    try {
      await _plugin.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: scheduledDate,
        notificationDetails: category.details(),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: payload,
      );
    } on Object catch (error) {
      debugPrint('[NotificationService] 예약 실패(무시): $error');
    }
  }

  /// 즉시 표시(FCM 포그라운드 메시지 등 — 서버 발송은 범위 밖, 유틸만 제공).
  Future<void> show({
    required int id,
    required String title,
    required String body,
    required NotificationCategory category,
    String? payload,
  }) async {
    await ensureInitialized();
    try {
      await _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: category.details(),
        payload: payload,
      );
    } on Object catch (error) {
      debugPrint('[NotificationService] 표시 실패(무시): $error');
    }
  }

  /// 특정 id 예약/알림 취소.
  Future<void> cancel(int id) async {
    try {
      await _plugin.cancel(id: id);
    } on Object catch (error) {
      debugPrint('[NotificationService] 취소 실패(무시): $error');
    }
  }

  /// 카테고리의 고정 알림 취소(재예약 전 중복 방지).
  Future<void> cancelCategory(NotificationCategory category) =>
      cancel(category.notificationId);

  /// 모든 예약/알림 취소.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } on Object catch (error) {
      debugPrint('[NotificationService] 전체 취소 실패(무시): $error');
    }
  }
}
