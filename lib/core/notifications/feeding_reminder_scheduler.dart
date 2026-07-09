import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../domain/entities/tracking_log.dart';
import '../../domain/repositories/tracking_repository.dart';
import 'notification_categories.dart';
import 'notification_service.dart';

/// §3.2 S4 "다음 수유 예상" 로컬 알림 스케줄러.
///
/// 최근 수유 기록을 근거로 다음 수유 예상 시각에 알림 1건을 예약한다.
///   - 간격 = 최근 [maxIntervalSamples]회 수유의 평균 간격(연속 수유 시작 시각 차),
///     표본이 없으면 [defaultInterval](3시간).
///   - 예상 시각 = 마지막 수유 시작 + 간격. 이미 지났으면 지금 + 간격으로 보정.
/// 설정 토글(마스터/수유 리마인더)이 꺼져 있으면 예약하지 않고 기존 예약을 취소한다.
class FeedingReminderScheduler {
  FeedingReminderScheduler({required this._service, required this._tracking});

  final NotificationService _service;
  final TrackingRepository _tracking;

  /// 수유 기록이 부족할 때의 기본 간격(§3.2 S4).
  static const Duration defaultInterval = Duration(hours: 3);

  /// 평균 계산에 쓰는 최근 간격 표본 수(최근 3회 수유 → 최대 2~3개 간격).
  static const int maxIntervalSamples = 3;

  /// 최근 기록을 훑는 일수(오늘 + 과거 며칠).
  static const int lookbackDays = 2;

  /// 간격이 비정상적으로 짧을 때의 하한(오작동 기록 방어).
  static const Duration minInterval = Duration(minutes: 30);

  // ── 설정 prefs 키(§11.16 settings_providers.dart와 동일 문자열을 미러링) ──
  // 이 키들은 features/settings/providers/settings_providers.dart의 private 상수와
  // 반드시 같은 값이어야 한다(그 파일은 수정 금지라 문자열을 복제한다 — 통합 시 seam).
  static const String _masterKey = 'settings.notifications.master';
  static const String _feedingReminderKey =
      'settings.notifications.feeding_reminder';

  /// 최근 수유 기록을 근거로 "다음 수유 예상" 알림을 재예약한다.
  /// 토글 OFF / 수유 기록 없음이면 기존 예약을 취소하고 종료한다.
  Future<void> rescheduleFromRecent({String? babyId, DateTime? now}) async {
    final enabled = await _feedingReminderEnabled();
    if (!enabled) {
      await _service.cancelCategory(NotificationCategory.feedingReminder);
      return;
    }

    final feeds = await _recentFeeds(babyId: babyId, now: now);
    if (feeds.isEmpty) {
      await _service.cancelCategory(NotificationCategory.feedingReminder);
      return;
    }

    final interval = _averageInterval(feeds);
    final current = now ?? DateTime.now();
    // feeds는 startedAt 내림차순 — 첫 원소가 가장 최근 수유.
    var when = feeds.first.startedAt.add(interval);
    if (!when.isAfter(current)) {
      when = current.add(interval);
    }

    await _service.schedule(
      id: NotificationCategory.feedingReminder.notificationId,
      title: '수유 시간이 다가와요',
      body:
          '마지막 수유로부터 약 ${_formatInterval(interval)} 지났어요. '
          '다음 수유를 준비해 주세요.',
      when: when,
      category: NotificationCategory.feedingReminder,
    );
  }

  /// 수유 리마인더를 취소(설정 OFF / 로그아웃 등).
  Future<void> cancel() =>
      _service.cancelCategory(NotificationCategory.feedingReminder);

  Future<bool> _feedingReminderEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    final master = prefs.getBool(_masterKey) ?? true;
    final feeding = prefs.getBool(_feedingReminderKey) ?? true;
    return master && feeding;
  }

  /// 최근 [lookbackDays]일 내 수유(type=feed) 기록을 startedAt 내림차순으로 수집.
  Future<List<TrackingLog>> _recentFeeds({
    String? babyId,
    DateTime? now,
  }) async {
    final today = now ?? DateTime.now();
    final feeds = <TrackingLog>[];
    for (var i = 0; i < lookbackDays; i++) {
      final day = today.subtract(Duration(days: i));
      try {
        final logs = await _tracking.getByDay(day: day, babyId: babyId);
        feeds.addAll(logs.where((l) => l.type == TrackingType.feed));
      } on Object catch (error) {
        debugPrint('[FeedingReminderScheduler] 기록 조회 실패(무시): $error');
      }
    }
    feeds.sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return feeds;
  }

  /// 연속 수유 시작 시각 차의 평균(최근 [maxIntervalSamples]개). 표본 없으면 기본값.
  Duration _averageInterval(List<TrackingLog> feedsDesc) {
    if (feedsDesc.length < 2) return defaultInterval;
    final gaps = <Duration>[];
    for (
      var i = 0;
      i < feedsDesc.length - 1 && gaps.length < maxIntervalSamples;
      i++
    ) {
      final gap = feedsDesc[i].startedAt.difference(feedsDesc[i + 1].startedAt);
      if (gap > Duration.zero) gaps.add(gap);
    }
    if (gaps.isEmpty) return defaultInterval;
    final totalMs = gaps.fold<int>(0, (sum, g) => sum + g.inMilliseconds);
    final avg = Duration(milliseconds: totalMs ~/ gaps.length);
    return avg < minInterval ? defaultInterval : avg;
  }

  String _formatInterval(Duration d) {
    final hours = d.inHours;
    final minutes = d.inMinutes.remainder(60);
    if (hours <= 0) return '$minutes분';
    if (minutes == 0) return '$hours시간';
    return '$hours시간 $minutes분';
  }
}
