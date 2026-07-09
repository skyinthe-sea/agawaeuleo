import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../application/notification_providers.dart';
import '../../../../application/providers.dart';

/// §11.16 설정 화면 전용 프로바이더. **코드젠 없는 수동 Riverpod**(이 feature 소유).
/// 상위 [authRepositoryProvider]/[appConfigRepositoryProvider] 등은 watch만 한다.

/// 세션(익명 포함) 변화 트리거. 값 자체보다는 "다시 그려야 한다"는 신호로 쓰고,
/// 실제 게스트 여부는 [isGuestAccountProvider]에서 [AuthRepository.isAnonymous]/
/// [AuthRepository.isSignedIn]로 판단한다(둘 다 동기 getter라 스트림 값 자체는 불필요).
final authSessionChangesProvider = StreamProvider<String?>((ref) {
  final auth = ref.watch(authRepositoryProvider);
  return auth.authStateChanges();
});

/// 게스트(미연결) 여부. 세션 변화가 있을 때마다 재계산된다.
/// 현재 Supabase 미구성(픽스처 데모) 환경에서는 원격 인증이 없어 `isSignedIn`이 항상
/// false이므로 이 값은 항상 true(게스트)로 평가된다 — 계정 연결 배너가 정상 노출된다.
final isGuestAccountProvider = Provider<bool>((ref) {
  ref.watch(authSessionChangesProvider);
  final auth = ref.watch(authRepositoryProvider);
  return !auth.isSignedIn || auth.isAnonymous;
});

/// "1.0.0 (3)" 형태의 표시용 앱 버전 문자열.
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// §11.16 알림 그룹 상태. 로컬(shared_preferences) 저장만 담당 — 실제 알림
/// 스케줄링/구독(flutter_local_notifications, FCM 토픽)은 M5 몫이다.
class NotificationSettings {
  const NotificationSettings({
    this.masterEnabled = true,
    this.feedingReminderEnabled = true,
    this.noticeEnabled = true,
  });

  /// 마스터 스위치. 꺼지면 카테고리 스위치는 화면상 비활성(dim) 표시로만 반영한다.
  final bool masterEnabled;

  /// 수유 리마인더 카테고리.
  final bool feedingReminderEnabled;

  /// 공지사항 카테고리.
  final bool noticeEnabled;

  NotificationSettings copyWith({
    bool? masterEnabled,
    bool? feedingReminderEnabled,
    bool? noticeEnabled,
  }) => NotificationSettings(
    masterEnabled: masterEnabled ?? this.masterEnabled,
    feedingReminderEnabled:
        feedingReminderEnabled ?? this.feedingReminderEnabled,
    noticeEnabled: noticeEnabled ?? this.noticeEnabled,
  );
}

/// [NotificationSettings]를 shared_preferences에 복원/저장하는 수동 AsyncNotifier
/// (riverpod_annotation 미사용 — `AsyncNotifierProvider` 직접 배선).
class NotificationSettingsController
    extends AsyncNotifier<NotificationSettings> {
  static const String _masterKey = 'settings.notifications.master';
  static const String _feedingReminderKey =
      'settings.notifications.feeding_reminder';
  static const String _noticeKey = 'settings.notifications.notice';

  @override
  Future<NotificationSettings> build() async {
    final prefs = await SharedPreferences.getInstance();
    return NotificationSettings(
      masterEnabled: prefs.getBool(_masterKey) ?? true,
      feedingReminderEnabled: prefs.getBool(_feedingReminderKey) ?? true,
      noticeEnabled: prefs.getBool(_noticeKey) ?? true,
    );
  }

  /// 마스터 알림 토글.
  Future<void> setMaster(bool value) =>
      _persist(_masterKey, value, (s) => s.copyWith(masterEnabled: value));

  /// 수유 리마인더 카테고리 토글.
  Future<void> setFeedingReminder(bool value) => _persist(
    _feedingReminderKey,
    value,
    (s) => s.copyWith(feedingReminderEnabled: value),
  );

  /// 공지사항 카테고리 토글.
  Future<void> setNotice(bool value) =>
      _persist(_noticeKey, value, (s) => s.copyWith(noticeEnabled: value));

  Future<void> _persist(
    String key,
    bool value,
    NotificationSettings Function(NotificationSettings current) reduce,
  ) async {
    final current = state.value ?? const NotificationSettings();
    final next = reduce(current);
    state = AsyncData<NotificationSettings>(next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);

    await _applyToScheduler(next);
  }

  /// 저장된 토글 상태를 실제 로컬 알림 예약에 반영한다(§3.2 S4 · §11.16).
  ///   - 마스터 OFF: 카테고리와 무관하게 예약된 모든 알림을 취소.
  ///   - 마스터 ON + 수유 리마인더 ON: 최근 기록 기반으로 재예약.
  ///   - 마스터 ON + 수유 리마인더 OFF: 수유 리마인더만 취소.
  /// 스케줄러/서비스는 미구성·미부팅 환경을 내부 가드로 흡수하므로 실패해도 무해하다.
  Future<void> _applyToScheduler(NotificationSettings settings) async {
    if (!settings.masterEnabled) {
      await ref.read(notificationServiceProvider).cancelAll();
      return;
    }
    final scheduler = ref.read(feedingReminderSchedulerProvider);
    if (settings.feedingReminderEnabled) {
      await scheduler.rescheduleFromRecent();
    } else {
      await scheduler.cancel();
    }
  }
}

final notificationSettingsProvider =
    AsyncNotifierProvider<NotificationSettingsController, NotificationSettings>(
      NotificationSettingsController.new,
    );
