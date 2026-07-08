import 'package:drift/drift.dart';

/// 즐겨찾기 로컬 테이블 (§5.3 로컬 우선, §7.1 `favorites`, §11.15).
///
/// [id]는 로컬 uuid(도메인 `Favorite.id`), [serverId]는 서버 uuid(동기화 매핑용).
/// (userId, targetType, targetId) 조합은 유일(중복 즐겨찾기 방지).
@DataClassName('FavoriteRow')
class Favorites extends Table {
  /// 로컬 uuid(PK) = 도메인 `Favorite.id`.
  TextColumn get id => text()();

  /// 서버 uuid(동기화 매핑용, 미동기화 시 null).
  TextColumn get serverId => text().nullable()();

  TextColumn get userId => text()();

  /// `FavoriteTargetType.wire` (symptom/product).
  TextColumn get targetType => text()();

  /// 대상 증상/제품의 uuid.
  TextColumn get targetId => text()();

  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {userId, targetType, targetId},
  ];
}
