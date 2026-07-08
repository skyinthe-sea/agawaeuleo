import 'package:agawaeuleo/data/local/app_database.dart';
import 'package:agawaeuleo/domain/entities/tracking_log.dart';
import 'package:drift/drift.dart';

/// 도메인 `TrackingLog` ↔ Drift 행/컴패니언 매퍼 (§5.2 도메인 분리).
extension TrackingLogRowMapper on TrackingLogRow {
  /// 로컬 행 → 도메인 엔티티.
  ///
  /// [type]은 로컬에 항상 유효값이 저장되므로 `fromWire`(엄격),
  /// [subtype]은 sleep 등에서 null일 수 있어 `tryFromWire` 사용.
  TrackingLog toDomain() => TrackingLog(
    id: id,
    userId: userId,
    babyId: babyId,
    type: TrackingType.fromWire(type),
    subtype: TrackingSubtype.tryFromWire(subtype),
    amount: amount,
    note: note,
    startedAt: startedAt,
    endedAt: endedAt,
    createdAt: createdAt,
  );
}

extension TrackingLogCompanionMapper on TrackingLog {
  /// 도메인 엔티티 → upsert용 컴패니언.
  ///
  /// [serverId]는 기본 `absent` — 로컬 저장은 서버 uuid를 건드리지 않고,
  /// 동기화 후 `TrackingLogsDao.setServerId`로 별도 기록한다.
  TrackingLogsCompanion toCompanion({
    Value<String?> serverId = const Value.absent(),
  }) => TrackingLogsCompanion.insert(
    id: id,
    serverId: serverId,
    userId: userId,
    babyId: Value(babyId),
    type: type.wire,
    subtype: Value(subtype?.wire),
    amount: Value(amount),
    note: Value(note),
    startedAt: startedAt,
    endedAt: Value(endedAt),
    createdAt: createdAt,
  );
}
