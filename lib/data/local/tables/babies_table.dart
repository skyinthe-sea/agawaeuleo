import 'package:drift/drift.dart';

/// 아기 프로필 로컬 테이블 (§5.3 로컬 우선, §7.1 `babies`, §11.14).
///
/// [id]는 로컬 uuid(도메인 `Baby.id`), [serverId]는 서버 uuid(동기화 매핑용).
@DataClassName('BabyRow')
class Babies extends Table {
  /// 로컬 uuid(PK) = 도메인 `Baby.id`.
  TextColumn get id => text()();

  /// 서버 uuid(동기화 매핑용, 미동기화 시 null).
  TextColumn get serverId => text().nullable()();

  TextColumn get userId => text()();

  TextColumn get name => text()();

  /// `birth_date` — 없으면 개월수 미표시.
  DateTimeColumn get birthDate => dateTime().nullable()();

  /// `BabyGender.wire` (male/female/na). 기본값 'na'.
  TextColumn get gender => text().withDefault(const Constant('na'))();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
