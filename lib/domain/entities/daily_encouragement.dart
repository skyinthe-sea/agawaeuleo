/// 오늘의 응원 문구 엔티티 (홈 인사 하위 영역 — 발주자 요청 기능).
///
/// `daily_encouragements` 테이블(공개 읽기 마스터 데이터)의 한 행. 홈 상단에서
/// 3일마다 `order_index` 순서대로 하나씩 회전 노출된다(§7.1 홈, 회전 규칙은
/// `core/utils/daily_rotation.dart`).
///
/// 순수 도메인 모델 — Supabase/Drift 등 데이터 소스에 의존하지 않는다. 읽기 전용
/// 표시 데이터라 freezed 코드젠 없이 손수 불변 클래스로 둔다(단순 값 객체 —
/// snake_case 컬럼 ↔ 이 엔티티 매핑은 data 레이어가 담당).
class DailyEncouragement {
  const DailyEncouragement({
    required this.id,
    required this.message,
    this.orderIndex = 0,
    this.isActive = true,
  });

  /// `id` (uuid).
  final String id;

  /// `message` — 표시할 응원 문구.
  final String message;

  /// `order_index` — 회전 순서(안정 정렬 키).
  final int orderIndex;

  /// `is_active`.
  final bool isActive;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyEncouragement &&
          other.id == id &&
          other.message == message &&
          other.orderIndex == orderIndex &&
          other.isActive == isActive;

  @override
  int get hashCode => Object.hash(id, message, orderIndex, isActive);
}
