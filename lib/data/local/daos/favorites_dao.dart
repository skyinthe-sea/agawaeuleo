import 'package:agawaeuleo/data/local/app_database.dart';
import 'package:agawaeuleo/data/local/mappers/favorite_mapper.dart';
import 'package:agawaeuleo/data/local/tables/favorites_table.dart';
import 'package:agawaeuleo/domain/entities/favorite.dart';
import 'package:drift/drift.dart';

part 'favorites_dao.g.dart';

/// 즐겨찾기 로컬 DAO (§11.15). 별 토글은 리포지토리가
/// [getByTarget]/[upsert]/[deleteByTarget] 조합으로 구현한다.
@DriftAccessor(tables: [Favorites])
class FavoritesDao extends DatabaseAccessor<AppDatabase>
    with _$FavoritesDaoMixin {
  FavoritesDao(super.attachedDatabase);

  List<Favorite> _map(List<FavoriteRow> rows) =>
      rows.map((r) => r.toDomain()).toList();

  Selectable<FavoriteRow> _allQuery() =>
      select(favorites)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]);

  /// 최근 추가순으로 전체 관찰.
  Stream<List<Favorite>> watchAll() => _allQuery().watch().map(_map);

  Future<List<Favorite>> getAll() => _allQuery().get().then(_map);

  Future<void> upsert(Favorite favorite) =>
      into(favorites).insertOnConflictUpdate(favorite.toCompanion());

  Future<int> deleteById(String id) =>
      (delete(favorites)..where((t) => t.id.equals(id))).go();

  Future<int> setServerId(String id, String serverId) =>
      (update(favorites)..where((t) => t.id.equals(id))).write(
        FavoritesCompanion(serverId: Value(serverId)),
      );

  // ── (userId, targetType, targetId) 단건 조회 — 별 토글/상태용 ──────
  Selectable<FavoriteRow> _targetQuery({
    required String userId,
    required FavoriteTargetType targetType,
    required String targetId,
  }) => select(favorites)
    ..where(
      (t) =>
          t.userId.equals(userId) &
          t.targetType.equals(targetType.wire) &
          t.targetId.equals(targetId),
    )
    ..limit(1);

  /// 대상 즐겨찾기 여부를 관찰(§11.9 별 상태 실시간).
  Stream<Favorite?> watchByTarget({
    required String userId,
    required FavoriteTargetType targetType,
    required String targetId,
  }) => _targetQuery(
    userId: userId,
    targetType: targetType,
    targetId: targetId,
  ).watchSingleOrNull().map((r) => r?.toDomain());

  Future<Favorite?> getByTarget({
    required String userId,
    required FavoriteTargetType targetType,
    required String targetId,
  }) => _targetQuery(
    userId: userId,
    targetType: targetType,
    targetId: targetId,
  ).getSingleOrNull().then((r) => r?.toDomain());

  /// 대상 기준 삭제(별 해제) — 삭제 행 수 반환.
  Future<int> deleteByTarget({
    required String userId,
    required FavoriteTargetType targetType,
    required String targetId,
  }) =>
      (delete(favorites)..where(
            (t) =>
                t.userId.equals(userId) &
                t.targetType.equals(targetType.wire) &
                t.targetId.equals(targetId),
          ))
          .go();
}
