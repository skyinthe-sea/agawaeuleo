/// 로컬 동기화 큐(`pending_ops`)에서 사용하는 열거형 (§5.3 로컬 우선).
///
/// 개인기록(기록/아기/즐겨찾기)은 로컬에 먼저 저장한 뒤 Supabase로 동기화한다.
/// 각 변경은 [PendingOp]으로 큐잉되며, 실제 업로드는 상위 동기화 레이어가 담당한다.
library;

/// 동기화 연산 종류 (`pending_ops.op_type`).
enum PendingOpType {
  insert('insert'),
  update('update'),
  delete('delete');

  const PendingOpType(this.wire);

  /// DB `op_type` 텍스트 값.
  final String wire;

  /// DB 텍스트 → enum. 알 수 없으면 예외.
  static PendingOpType fromWire(String value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'Unknown PendingOpType');
  }

  /// DB 텍스트 → enum. 알 수 없거나 null이면 null.
  static PendingOpType? tryFromWire(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}

/// 동기화 대상 엔티티 종류 (`pending_ops.entity_type`).
///
/// 로컬 테이블 ↔ Supabase 테이블 매핑 키. `wire`는 Supabase 테이블명(단수형)과
/// 무관한 논리 이름이며, 상위 동기화 레이어가 실제 테이블로 라우팅한다.
enum SyncEntityType {
  trackingLog('tracking_log'),
  baby('baby'),
  favorite('favorite');

  const SyncEntityType(this.wire);

  /// DB `entity_type` 텍스트 값.
  final String wire;

  /// DB 텍스트 → enum. 알 수 없으면 예외.
  static SyncEntityType fromWire(String value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    throw ArgumentError.value(value, 'value', 'Unknown SyncEntityType');
  }

  /// DB 텍스트 → enum. 알 수 없거나 null이면 null.
  static SyncEntityType? tryFromWire(String? value) {
    for (final t in values) {
      if (t.wire == value) return t;
    }
    return null;
  }
}
