import 'package:agawaeuleo/data/local/app_database.dart';
import 'package:agawaeuleo/data/local/mappers/tracking_log_mapper.dart';
import 'package:agawaeuleo/data/local/tables/tracking_logs_table.dart';
import 'package:agawaeuleo/domain/entities/tracking_log.dart';
import 'package:drift/drift.dart';

part 'tracking_logs_dao.g.dart';

/// 육아 기록 로컬 DAO (§11.10 타임라인, §11.11 진행중 타이머 복원).
@DriftAccessor(tables: [TrackingLogs])
class TrackingLogsDao extends DatabaseAccessor<AppDatabase>
    with _$TrackingLogsDaoMixin {
  TrackingLogsDao(super.attachedDatabase);

  List<TrackingLog> _map(List<TrackingLogRow> rows) =>
      rows.map((r) => r.toDomain()).toList();

  /// 로컬 우선 저장(생성/수정 공통). id 충돌 시 갱신(upsert).
  /// [serverId]는 건드리지 않는다([TrackingLog] → 컴패니언 기본 `absent`).
  Future<void> upsert(TrackingLog log) =>
      into(trackingLogs).insertOnConflictUpdate(log.toCompanion());

  Future<TrackingLog?> getById(String id) =>
      (select(trackingLogs)..where((t) => t.id.equals(id)))
          .getSingleOrNull()
          .then((r) => r?.toDomain());

  /// 좌스와이프 삭제(§11.10) — 실제 삭제 행 수 반환.
  Future<int> deleteById(String id) =>
      (delete(trackingLogs)..where((t) => t.id.equals(id))).go();

  /// §11.14 아기 삭제 시 해당 아기의 기록을 일괄 삭제한다.
  /// 원격 삭제 전파(`pending_ops`)를 위해 삭제된 기록의 로컬 id 목록을 반환한다.
  Future<List<String>> deleteByBabyId(String babyId) async {
    final query = select(trackingLogs)..where((t) => t.babyId.equals(babyId));
    final rows = await query.get();
    final ids = rows.map((r) => r.id).toList();
    await (delete(trackingLogs)..where((t) => t.babyId.equals(babyId))).go();
    return ids;
  }

  /// §3.3 전체 기록 수(백업 유도 임계값 판단용).
  Future<int> countAll() {
    final count = trackingLogs.id.count();
    final query = selectOnly(trackingLogs)..addColumns([count]);
    return query.map((row) => row.read(count) ?? 0).getSingle();
  }

  /// 동기화 완료 후 서버 uuid 기록.
  Future<int> setServerId(String id, String serverId) =>
      (update(trackingLogs)..where((t) => t.id.equals(id))).write(
        TrackingLogsCompanion(serverId: Value(serverId)),
      );

  // ── 일자별 조회(§11.10 오늘 타임라인) ─────────────────────────────
  Selectable<TrackingLogRow> _dayQuery({
    required DateTime day,
    String? babyId,
  }) {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));
    return select(trackingLogs)
      ..where((t) {
        var cond =
            t.startedAt.isBiggerOrEqualValue(start) &
            t.startedAt.isSmallerThanValue(end);
        if (babyId != null) cond = cond & t.babyId.equals(babyId);
        return cond;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
  }

  /// [day]의 기록을 `started_at` 역순으로 관찰.
  Stream<List<TrackingLog>> watchByDay({
    required DateTime day,
    String? babyId,
  }) => _dayQuery(day: day, babyId: babyId).watch().map(_map);

  Future<List<TrackingLog>> getByDay({required DateTime day, String? babyId}) =>
      _dayQuery(day: day, babyId: babyId).get().then(_map);

  // ── 진행 중 타이머 복원(§11.11) ──────────────────────────────────
  Selectable<TrackingLogRow> _inProgressQuery({String? babyId}) {
    return select(trackingLogs)
      ..where((t) {
        var cond = t.endedAt.isNull();
        if (babyId != null) cond = cond & t.babyId.equals(babyId);
        return cond;
      })
      ..orderBy([(t) => OrderingTerm.desc(t.startedAt)]);
  }

  /// `ended_at IS NULL`(진행 중) 기록 관찰 — 앱 재시작 시 타이머 복원.
  Stream<List<TrackingLog>> watchInProgress({String? babyId}) =>
      _inProgressQuery(babyId: babyId).watch().map(_map);

  Future<List<TrackingLog>> getInProgress({String? babyId}) =>
      _inProgressQuery(babyId: babyId).get().then(_map);
}
