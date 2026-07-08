import 'package:drift/drift.dart';

/// 육아 기록 로컬 테이블 (§5.3 로컬 우선, §7.1 `tracking_logs`, §11.10~11.11).
///
/// [id]는 클라이언트가 생성하는 로컬 uuid(도메인 `TrackingLog.id`와 동일).
/// [serverId]는 Supabase가 부여한 서버 uuid로, 동기화 매핑용(미동기화 시 null).
@DataClassName('TrackingLogRow')
class TrackingLogs extends Table {
  /// 로컬 uuid(PK) = 도메인 `TrackingLog.id`.
  TextColumn get id => text()();

  /// 서버 uuid(동기화 매핑용, 미동기화 시 null).
  TextColumn get serverId => text().nullable()();

  TextColumn get userId => text()();

  /// nullable — 선택된 아기 없이도 기록 가능.
  TextColumn get babyId => text().nullable()();

  /// `TrackingType.wire` (feed/sleep/diaper).
  TextColumn get type => text()();

  /// `TrackingSubtype.wire` (breast/formula/solid/pee/poo/mixed) — sleep은 null.
  TextColumn get subtype => text().nullable()();

  /// ml, 분 등.
  RealColumn get amount => real().nullable()();

  TextColumn get note => text().nullable()();

  DateTimeColumn get startedAt => dateTime()();

  /// null = 진행 중 타이머(§11.11).
  DateTimeColumn get endedAt => dateTime().nullable()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
