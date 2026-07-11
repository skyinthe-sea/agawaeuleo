/// 날짜 기반 결정적 회전 인덱스 계산.
///
/// 홈 "오늘의 응원" 문구를 N일마다 하나씩 순환 노출하는 데 쓴다. 핵심 요구:
/// **모든 사용자가 같은 날 같은 항목을 본다** — 기기/계정 상태가 아니라 한국 시간
/// (KST, UTC+9) 날짜에만 의존한다. 한국은 서머타임이 없어 UTC+9 고정이 안전하다.
///
/// 순수 함수(부수효과 없음)라 단위 테스트로 회전 규칙을 못박을 수 있다.
class DailyRotation {
  const DailyRotation._();

  /// 회전 기준 앵커(이 날을 0일차로 본다). 임의 상수 — 변경하면 전체 위상이 이동한다.
  static final DateTime anchor = DateTime.utc(2026, 1, 1);

  /// 음수까지 안전한 내림 나눗셈(`floor(a / b)`). Dart `~/`는 0을 향해 잘리므로 직접 구현.
  static int _floorDiv(int a, int b) => (a - (((a % b) + b) % b)) ~/ b;

  /// KST 기준 [anchor]로부터의 경과 일수(자정 경계, 음수 가능).
  static int kstDayNumber(DateTime now, {DateTime? anchor}) {
    final base = anchor ?? DailyRotation.anchor;
    final kst = now.toUtc().add(const Duration(hours: 9));
    final today = DateTime.utc(kst.year, kst.month, kst.day);
    return today.difference(base).inDays;
  }

  /// [count]개 항목을 [periodDays]일마다 하나씩 순환할 때 오늘의 인덱스(0-based).
  ///
  /// - 같은 [periodDays] 구간 안의 날짜는 모두 같은 인덱스를 돌려준다.
  /// - 다음 구간으로 넘어가면 인덱스가 정확히 1 증가하고, 끝에서 0으로 되돌아온다.
  /// - [count]가 0 이하면 -1(표시할 항목 없음).
  static int indexFor(
    DateTime now, {
    required int count,
    int periodDays = 3,
    DateTime? anchor,
  }) {
    if (count <= 0) return -1;
    final safePeriod = periodDays <= 0 ? 1 : periodDays;
    final day = kstDayNumber(now, anchor: anchor);
    final step = _floorDiv(day, safePeriod);
    return ((step % count) + count) % count;
  }
}
