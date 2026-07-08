import 'package:agawaeuleo/data/local/app_database.dart';
import 'package:agawaeuleo/data/local/sync/sync_op.dart';
import 'package:agawaeuleo/data/local/tables/pending_ops_table.dart';
import 'package:drift/drift.dart';

part 'pending_ops_dao.g.dart';

/// 동기화 큐 로컬 DAO (§5.3 로컬 우선 → Supabase 동기화).
///
/// 상위 동기화 레이어가 [watchAll]/[getPending]으로 FIFO 처리하고, 성공 시
/// [remove], 실패 시 [incrementRetry]를 호출한다.
@DriftAccessor(tables: [PendingOps])
class PendingOpsDao extends DatabaseAccessor<AppDatabase>
    with _$PendingOpsDaoMixin {
  PendingOpsDao(super.attachedDatabase);

  /// 동기화 연산 큐잉 — 생성된 큐 id 반환.
  Future<int> enqueue({
    required PendingOpType opType,
    required SyncEntityType entityType,
    required String localId,
    required String payload,
    DateTime? createdAt,
  }) => into(pendingOps).insert(
    PendingOpsCompanion.insert(
      opType: opType.wire,
      entityType: entityType.wire,
      payload: payload,
      localId: localId,
      createdAt: createdAt == null ? const Value.absent() : Value(createdAt),
    ),
  );

  Selectable<PendingOpRow> _fifoQuery() => select(pendingOps)
    ..orderBy([
      (t) => OrderingTerm.asc(t.createdAt),
      (t) => OrderingTerm.asc(t.id),
    ]);

  /// 처리 순서(FIFO)대로 큐 관찰.
  Stream<List<PendingOpRow>> watchAll() => _fifoQuery().watch();

  Future<List<PendingOpRow>> getPending() => _fifoQuery().get();

  /// 동기화 성공 후 큐에서 제거.
  Future<int> remove(int id) =>
      (delete(pendingOps)..where((t) => t.id.equals(id))).go();

  /// 대상 로컬 엔티티에 걸린 큐 항목 제거(엔티티 삭제 시 정리용).
  Future<int> removeByLocalId(String localId) =>
      (delete(pendingOps)..where((t) => t.localId.equals(localId))).go();

  /// 동기화 실패 시 재시도 횟수 +1.
  Future<int> incrementRetry(int id) => customUpdate(
    'UPDATE pending_ops SET retry_count = retry_count + 1 WHERE id = ?',
    variables: [Variable.withInt(id)],
    updates: {pendingOps},
  );

  /// 전체 지우기.
  Future<int> clear() => delete(pendingOps).go();
}
