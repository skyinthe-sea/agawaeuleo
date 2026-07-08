import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/tracking_log.dart';
import 'row_mappers.dart';
import 'supabase_error_mapper.dart';

/// 육아 기록 원격 데이터소스 (§7.1 `tracking_logs`, §11.10~11.11). 본인 소유만(RLS `own logs`).
///
/// 쓰기 시 `user_id`는 현재 세션의 `auth.uid()`로 강제한다. 실시간 스트림([watchAll]/
/// [watchInProgress])은 필터를 1개만 허용하므로 날짜 범위 필터는 적용하지 않는다 — 하루치
/// 스코프([watchByDay])는 리포지토리가 클라이언트에서 걸러야 한다. 1회 조회([getByDay]/
/// [getInProgress])는 복수 필터가 가능해 서버에서 범위를 좁힌다.
class TrackingRemoteDataSource {
  TrackingRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'tracking_logs';

  SupabaseQueryBuilder get _from => _client.from(_table);

  String? get _uid => _client.auth.currentUser?.id;

  /// 본인 기록을 `started_at` 역순으로 관찰. [babyId]가 있으면 해당 아기로 스코프.
  /// (실시간 필터 1개 제약 → 날짜 필터는 리포지토리에서 클라이언트 처리.)
  Stream<List<TrackingLog>> watchAll({String? babyId}) {
    final base = _from.stream(primaryKey: ['id']);
    // .eq는 SupabaseStreamFilterBuilder에만 있고 SupabaseStreamBuilder를 반환하므로
    // 공통 상위 타입으로 받는다.
    final SupabaseStreamBuilder stream = babyId == null
        ? base
        : base.eq('baby_id', babyId);
    return stream
        .order('started_at', ascending: false)
        .map((rows) => rows.map(_fromRow).toList(growable: false))
        .mapErrorToAppException();
  }

  /// [day]의 로컬 캘린더 날짜에 속한 기록을 `started_at` 역순으로 1회 조회.
  Future<List<TrackingLog>> getByDay({
    required DateTime day,
    String? babyId,
  }) async {
    try {
      final start = DateTime(day.year, day.month, day.day);
      final end = start.add(const Duration(days: 1));
      var query = _from
          .select()
          .gte('started_at', start.toUtc().toIso8601String())
          .lt('started_at', end.toUtc().toIso8601String());
      if (babyId != null) query = query.eq('baby_id', babyId);
      final rows = await query.order('started_at', ascending: false);
      return rows.map(_fromRow).toList(growable: false);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 진행 중(`ended_at is null`) 타이머 로그를 관찰(§11.11 "진행 중" 배지).
  /// (실시간 필터 1개 제약 → `ended_at is null`은 원시 행에서 거른다.)
  Stream<List<TrackingLog>> watchInProgress({String? babyId}) {
    final base = _from.stream(primaryKey: ['id']);
    final SupabaseStreamBuilder stream = babyId == null
        ? base
        : base.eq('baby_id', babyId);
    return stream
        .order('started_at', ascending: false)
        .map(
          (rows) => rows
              .where((r) => r['ended_at'] == null)
              .map(_fromRow)
              .toList(growable: false),
        )
        .mapErrorToAppException();
  }

  /// 진행 중 타이머 로그 1회 조회(앱 재시작 복원 — §11.11).
  Future<List<TrackingLog>> getInProgress({String? babyId}) async {
    try {
      var query = _from.select().isFilter('ended_at', null);
      if (babyId != null) query = query.eq('baby_id', babyId);
      final rows = await query.order('started_at', ascending: false);
      return rows.map(_fromRow).toList(growable: false);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 기록 추가. 저장된(서버 확정) 로그를 반환.
  Future<TrackingLog> add(TrackingLog log) async {
    try {
      final row = await _from.insert(_toInsert(log)).select().single();
      return _fromRow(row);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 기록 수정. 수정된 로그를 반환.
  Future<TrackingLog> update(TrackingLog log) async {
    try {
      final row = await _from
          .update(_toUpdate(log))
          .eq('id', log.id)
          .select()
          .single();
      return _fromRow(row);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 진행 중 로그를 종료 — `ended_at` 설정(§11.11). [amount]/[note]도 함께 갱신 가능.
  /// 변경 컬럼만 부분 UPDATE 한다. 종료된 로그를 반환.
  Future<TrackingLog> stop({
    required String id,
    required DateTime endedAt,
    double? amount,
    String? note,
  }) async {
    try {
      final patch = <String, dynamic>{
        'ended_at': endedAt.toUtc().toIso8601String(),
        'amount': ?amount,
        'note': ?note,
      };
      final row = await _from.update(patch).eq('id', id).select().single();
      return _fromRow(row);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 기록 삭제(§11.10 좌스와이프 삭제).
  Future<void> delete(String id) async {
    try {
      await _from.delete().eq('id', id);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  TrackingLog _fromRow(Map<String, dynamic> row) => TrackingLog(
    id: row['id'] as String,
    userId: row['user_id'] as String,
    babyId: row['baby_id'] as String?,
    type: TrackingType.fromWire(row['type'] as String),
    subtype: TrackingSubtype.tryFromWire(row['subtype'] as String?),
    amount: asDoubleOrNull(row['amount']),
    note: row['note'] as String?,
    startedAt: parseDate(row['started_at']),
    endedAt: parseDateOrNull(row['ended_at']),
    createdAt: parseDate(row['created_at']),
  );

  Map<String, dynamic> _toInsert(TrackingLog log) => {
    if (log.id.isNotEmpty) 'id': log.id,
    'user_id': _uid ?? log.userId,
    'baby_id': log.babyId,
    'type': log.type.wire,
    'subtype': log.subtype?.wire,
    'amount': log.amount,
    'note': log.note,
    'started_at': log.startedAt.toUtc().toIso8601String(),
    'ended_at': log.endedAt?.toUtc().toIso8601String(),
    'created_at': log.createdAt.toUtc().toIso8601String(),
  };

  Map<String, dynamic> _toUpdate(TrackingLog log) => {
    'baby_id': log.babyId,
    'type': log.type.wire,
    'subtype': log.subtype?.wire,
    'amount': log.amount,
    'note': log.note,
    'started_at': log.startedAt.toUtc().toIso8601String(),
    'ended_at': log.endedAt?.toUtc().toIso8601String(),
  };
}
