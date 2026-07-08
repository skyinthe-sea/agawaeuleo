import 'package:agawaeuleo/core/error/app_exception.dart';
import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/repositories/support/id_generator.dart';
import 'package:agawaeuleo/data/repositories/support/local_identity_store.dart';
import 'package:agawaeuleo/data/repositories/support/personal_payloads.dart';
import 'package:agawaeuleo/domain/entities/tracking_log.dart';
import 'package:agawaeuleo/domain/repositories/tracking_repository.dart';

/// [TrackingRepository] 구현 — **로컬 우선 쓰기 → 동기화 큐**(§5.3, §11.10~11.11).
///
/// 쓰기는 항상 로컬(Drift)에 먼저 반영하고([TrackingLogsDao]), 구성된 경우에만
/// `pending_ops`에 연산을 큐잉한다([PendingOpsDao]). 실제 원격 push는 `SyncService`가
/// 온라인 전환/큐 변화에 따라 수행한다. 따라서 로그인·연결 상태와 무관하게 즉시 기록된다
/// (§2-4). 읽기는 전적으로 로컬 스트림이다.
///
/// 로컬 행의 `user_id`는 [LocalIdentityStore]의 안정적 로컬 게스트 id로 통일한다(세션
/// 승격과 무관하게 로컬 일관성 유지). 동기화 push 시 원격 데이터소스가 `auth.uid()`로
/// 덮어쓴다.
class TrackingRepositoryImpl implements TrackingRepository {
  TrackingRepositoryImpl(
    this._dao,
    this._pendingOps,
    this._identity, {
    this.syncEnabled = true,
  });

  final TrackingLogsDao _dao;
  final PendingOpsDao _pendingOps;
  final LocalIdentityStore _identity;

  /// 구성됨(Supabase) 여부. false면 큐잉하지 않고 로컬 전용으로만 동작.
  final bool syncEnabled;

  // ── 읽기 (로컬 스트림) ─────────────────────────────────────────────
  @override
  Stream<List<TrackingLog>> watchByDay({
    required DateTime day,
    String? babyId,
  }) => _dao.watchByDay(day: day, babyId: babyId);

  @override
  Future<List<TrackingLog>> getByDay({required DateTime day, String? babyId}) =>
      _dao.getByDay(day: day, babyId: babyId);

  @override
  Stream<List<TrackingLog>> watchInProgress({String? babyId}) =>
      _dao.watchInProgress(babyId: babyId);

  @override
  Future<List<TrackingLog>> getInProgress({String? babyId}) =>
      _dao.getInProgress(babyId: babyId);

  // ── 쓰기 (로컬 우선 → 큐) ──────────────────────────────────────────
  @override
  Future<TrackingLog> add(TrackingLog log) async {
    final uid = await _identity.ensureId();
    final prepared = log.copyWith(
      id: log.id.isEmpty ? newUuidV4() : log.id,
      userId: uid,
    );
    await _dao.upsert(prepared);
    await _enqueue(PendingOpType.insert, prepared);
    return prepared;
  }

  @override
  Future<TrackingLog> update(TrackingLog log) async {
    final uid = await _identity.ensureId();
    final prepared = log.copyWith(userId: uid);
    await _dao.upsert(prepared);
    await _enqueue(PendingOpType.update, prepared);
    return prepared;
  }

  @override
  Future<TrackingLog> stop({
    required String id,
    required DateTime endedAt,
    double? amount,
    String? note,
  }) async {
    final existing = await _dao.getById(id);
    if (existing == null) {
      throw const AppNotFoundException(message: '종료할 기록을 찾을 수 없어요.');
    }
    final updated = existing.copyWith(
      endedAt: endedAt,
      amount: amount ?? existing.amount,
      note: note ?? existing.note,
    );
    await _dao.upsert(updated);
    await _enqueue(PendingOpType.update, updated);
    return updated;
  }

  @override
  Future<void> delete(String id) async {
    await _dao.deleteById(id);
    if (!syncEnabled) return;
    // 아직 동기화되지 않은 큐 항목(insert/update)을 먼저 취소한다 — 서버에 존재하지
    // 않는 행이면 delete는 no-op, 이미 동기화됐다면 아래 delete 연산이 서버에서 제거.
    await _pendingOps.removeByLocalId(id);
    await _pendingOps.enqueue(
      opType: PendingOpType.delete,
      entityType: SyncEntityType.trackingLog,
      localId: id,
      payload: '',
    );
  }

  Future<void> _enqueue(PendingOpType opType, TrackingLog log) async {
    if (!syncEnabled) return;
    await _pendingOps.enqueue(
      opType: opType,
      entityType: SyncEntityType.trackingLog,
      localId: log.id,
      payload: encodeTrackingLog(log),
    );
  }
}
