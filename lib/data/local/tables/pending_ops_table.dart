import 'package:drift/drift.dart';

/// 동기화 큐 로컬 테이블 (§5.3 로컬 우선 → Supabase 동기화).
///
/// 개인기록의 각 로컬 변경(생성/수정/삭제)을 FIFO로 큐잉한다. 실제 업로드는
/// 상위 동기화 레이어가 [createdAt] 오름차순으로 처리하고, 성공 시 행을 삭제,
/// 실패 시 [retryCount]를 증가시킨다.
@DataClassName('PendingOpRow')
class PendingOps extends Table {
  /// 로컬 큐 id(autoincrement PK).
  IntColumn get id => integer().autoIncrement()();

  /// `PendingOpType.wire` (insert/update/delete).
  TextColumn get opType => text()();

  /// `SyncEntityType.wire` (tracking_log/baby/favorite).
  TextColumn get entityType => text()();

  /// 직렬화된 페이로드(JSON 문자열). 상위 레이어가 해석.
  TextColumn get payload => text()();

  /// 대상 로컬 엔티티 id(엔티티 테이블의 `id`).
  TextColumn get localId => text()();

  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  IntColumn get retryCount => integer().withDefault(const Constant(0))();
}
