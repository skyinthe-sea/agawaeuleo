import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../application/providers.dart';
import '../../../domain/entities/baby.dart';
import '../../../domain/entities/tracking_log.dart';

/// §11.10~11.12 기록 기능 상태. feature 내부 수동 Riverpod(코드젠 없음).
/// 리포지토리 프로바이더(keepAlive)만 watch 하고, 화면 수명에 맞춰 autoDispose 한다.

/// 아기 목록(다둥이 드롭다운) — §11.10.
final trackingBabiesProvider = StreamProvider.autoDispose<List<Baby>>(
  (ref) => ref.watch(babyRepositoryProvider).watchAll(),
);

/// 현재 선택된 아기 id(로컬 저장, 앱 전역) — §11.10.
final selectedBabyIdProvider = StreamProvider.autoDispose<String?>(
  (ref) => ref.watch(babyRepositoryProvider).watchSelectedBabyId(),
);

/// [trackingDayProvider] / [inProgressProvider] 스코프 키.
typedef DayScope = ({DateTime day, String? babyId});

/// 특정 날짜의 기록 타임라인(시작시간 역순) — §11.10.
final trackingDayProvider = StreamProvider.autoDispose
    .family<List<TrackingLog>, DayScope>(
      (ref, scope) => ref
          .watch(trackingRepositoryProvider)
          .watchByDay(day: scope.day, babyId: scope.babyId),
    );

/// 진행 중(ended_at == null) 타이머 로그 — §11.11 "진행 중" 배지·복원.
final inProgressProvider = StreamProvider.autoDispose
    .family<List<TrackingLog>, String?>(
      (ref, babyId) =>
          ref.watch(trackingRepositoryProvider).watchInProgress(babyId: babyId),
    );

// ── 오늘 요약 밴드 집계 ────────────────────────────────────────────────

/// 오늘 요약 밴드(수유 횟수 / 수면 시간 / 기저귀 횟수) — §11.10.
class TodayTotals {
  const TodayTotals({
    required this.feedCount,
    required this.sleepMinutes,
    required this.diaperCount,
  });

  final int feedCount;

  /// 완료된(ended_at 있는) 수면의 총 분.
  final int sleepMinutes;
  final int diaperCount;

  static TodayTotals of(List<TrackingLog> logs) {
    var feed = 0;
    var sleep = 0;
    var diaper = 0;
    for (final log in logs) {
      switch (log.type) {
        case TrackingType.feed:
          feed++;
        case TrackingType.sleep:
          sleep += log.duration?.inMinutes ?? 0;
        case TrackingType.diaper:
          diaper++;
      }
    }
    return TodayTotals(
      feedCount: feed,
      sleepMinutes: sleep,
      diaperCount: diaper,
    );
  }
}

// ── 기록 요약(§11.12) 집계 ────────────────────────────────────────────

/// 요약 기간 탭 — §11.12.
enum SummaryRange {
  today('오늘', 1),
  week('7일', 7),
  month('30일', 30);

  const SummaryRange(this.label, this.days);

  final String label;
  final int days;
}

/// 타입별 통계 카드 값(횟수·총량·평균 간격) — §11.12.
class TypeStat {
  const TypeStat({
    required this.count,
    required this.totalAmount,
    required this.avgIntervalMinutes,
  });

  final int count;

  /// feed=ml 총합, sleep=분 총합, diaper=횟수.
  final double totalAmount;

  /// 연속 기록 시작시간 간격 평균(분). 2건 미만이면 null.
  final double? avgIntervalMinutes;

  static const empty = TypeStat(
    count: 0,
    totalAmount: 0,
    avgIntervalMinutes: null,
  );
}

/// 막대그래프·일자 리스트용 하루 버킷 — §11.12.
class DayBucket {
  const DayBucket({
    required this.day,
    required this.countsByType,
    required this.logs,
  });

  final DateTime day;
  final Map<TrackingType, int> countsByType;
  final List<TrackingLog> logs;

  int get total => logs.length;
}

/// 요약 화면 데이터 묶음 — §11.12.
class SummaryData {
  const SummaryData({
    required this.range,
    required this.stats,
    required this.days,
  });

  final SummaryRange range;
  final Map<TrackingType, TypeStat> stats;

  /// 과거→현재(막대 좌→우) 정렬.
  final List<DayBucket> days;
}

/// [summaryProvider] 스코프 키.
typedef SummaryScope = ({SummaryRange range, String? babyId});

/// 기간별 통계·막대·일자 리스트 집계 — §11.12.
/// 리포지토리에 범위 조회가 없어 [DayScope] 단위로 getByDay 를 모아 집계한다(로컬).
final summaryProvider = FutureProvider.autoDispose
    .family<SummaryData, SummaryScope>((ref, scope) async {
      final repo = ref.watch(trackingRepositoryProvider);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      final buckets = <DayBucket>[];
      final all = <TrackingLog>[];
      for (var i = scope.range.days - 1; i >= 0; i--) {
        final day = today.subtract(Duration(days: i));
        final logs = await repo.getByDay(day: day, babyId: scope.babyId);
        all.addAll(logs);
        final counts = <TrackingType, int>{};
        for (final log in logs) {
          counts[log.type] = (counts[log.type] ?? 0) + 1;
        }
        buckets.add(DayBucket(day: day, countsByType: counts, logs: logs));
      }

      final stats = <TrackingType, TypeStat>{};
      for (final type in TrackingType.values) {
        final typeLogs = all.where((l) => l.type == type).toList()
          ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
        final count = typeLogs.length;

        double total;
        switch (type) {
          case TrackingType.feed:
            total = typeLogs.fold(0, (s, l) => s + (l.amount ?? 0));
          case TrackingType.sleep:
            total = typeLogs.fold(
              0,
              (s, l) => s + (l.duration?.inMinutes ?? 0).toDouble(),
            );
          case TrackingType.diaper:
            total = count.toDouble();
        }

        double? avg;
        if (typeLogs.length >= 2) {
          var sum = 0;
          for (var i = 1; i < typeLogs.length; i++) {
            sum += typeLogs[i].startedAt
                .difference(typeLogs[i - 1].startedAt)
                .inMinutes;
          }
          avg = sum / (typeLogs.length - 1);
        }

        stats[type] = TypeStat(
          count: count,
          totalAmount: total,
          avgIntervalMinutes: avg,
        );
      }

      return SummaryData(range: scope.range, stats: stats, days: buckets);
    });
