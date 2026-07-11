import 'package:agawaeuleo/core/utils/daily_rotation.dart';
import 'package:flutter_test/flutter_test.dart';

/// 오늘의 응원 3일 주기 회전 규칙(전원 동일) 검증.
///
/// 앵커: 2026-01-01 KST 00:00 (== 2025-12-31 15:00 UTC). 인덱스는 KST 날짜만의
/// 함수라 기기/계정과 무관하게 모든 사용자가 같은 날 같은 값을 얻는다.
void main() {
  group('DailyRotation.indexFor', () {
    test('count가 0 이하면 -1(표시 항목 없음)', () {
      expect(DailyRotation.indexFor(DateTime.utc(2026, 6, 1), count: 0), -1);
      expect(DailyRotation.indexFor(DateTime.utc(2026, 6, 1), count: -3), -1);
    });

    test('같은 3일 구간의 날짜는 모두 같은 인덱스', () {
      final d0 = DateTime.utc(2026, 1, 1, 3); // KST day0
      final d1 = DateTime.utc(2026, 1, 2, 3); // KST day1
      final d2 = DateTime.utc(2026, 1, 3, 3); // KST day2
      expect(DailyRotation.indexFor(d0, count: 100), 0);
      expect(DailyRotation.indexFor(d1, count: 100), 0);
      expect(DailyRotation.indexFor(d2, count: 100), 0);
    });

    test('다음 3일 구간으로 넘어가면 인덱스가 정확히 1 증가', () {
      expect(
        DailyRotation.indexFor(DateTime.utc(2026, 1, 4, 3), count: 100),
        1,
      );
      expect(
        DailyRotation.indexFor(DateTime.utc(2026, 1, 7, 3), count: 100),
        2,
      );
    });

    test('count를 넘으면 0으로 순환(modulo)', () {
      expect(DailyRotation.indexFor(DateTime.utc(2026, 1, 1, 3), count: 2), 0);
      expect(DailyRotation.indexFor(DateTime.utc(2026, 1, 4, 3), count: 2), 1);
      expect(DailyRotation.indexFor(DateTime.utc(2026, 1, 7, 3), count: 2), 0);
    });

    test('KST 자정 경계 — UTC 15:00에 날짜가 넘어가 인덱스가 바뀐다', () {
      // 2026-01-03 14:59 UTC == KST 2026-01-03 23:59 → day2 → index0
      final beforeMidnight = DateTime.utc(2026, 1, 3, 14, 59);
      // 2026-01-03 15:00 UTC == KST 2026-01-04 00:00 → day3 → index1
      final afterMidnight = DateTime.utc(2026, 1, 3, 15);
      expect(DailyRotation.indexFor(beforeMidnight, count: 100), 0);
      expect(DailyRotation.indexFor(afterMidnight, count: 100), 1);
    });

    test('앵커 이전 날짜(음수 일수)도 안전하게 순환', () {
      // KST 2025-12-31 → day -1 → floor(-1/3) = -1 → ((-1 % 5)+5)%5 = 4
      expect(
        DailyRotation.indexFor(DateTime.utc(2025, 12, 31, 3), count: 5),
        4,
      );
    });

    test('같은 시각이면 항상 같은 인덱스(결정적)', () {
      final t = DateTime.utc(2026, 7, 11, 6);
      expect(
        DailyRotation.indexFor(t, count: 100),
        DailyRotation.indexFor(t, count: 100),
      );
    });

    test('periodDays 파라미터 — 1일 주기면 매일 1씩 증가', () {
      expect(
        DailyRotation.indexFor(
          DateTime.utc(2026, 1, 1, 3),
          count: 100,
          periodDays: 1,
        ),
        0,
      );
      expect(
        DailyRotation.indexFor(
          DateTime.utc(2026, 1, 2, 3),
          count: 100,
          periodDays: 1,
        ),
        1,
      );
    });
  });
}
