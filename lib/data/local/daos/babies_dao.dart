import 'package:agawaeuleo/data/local/app_database.dart';
import 'package:agawaeuleo/data/local/mappers/baby_mapper.dart';
import 'package:agawaeuleo/data/local/tables/babies_table.dart';
import 'package:agawaeuleo/domain/entities/baby.dart';
import 'package:drift/drift.dart';

part 'babies_dao.g.dart';

/// 아기 프로필 로컬 DAO (§11.14).
@DriftAccessor(tables: [Babies])
class BabiesDao extends DatabaseAccessor<AppDatabase> with _$BabiesDaoMixin {
  BabiesDao(super.attachedDatabase);

  List<Baby> _map(List<BabyRow> rows) => rows.map((r) => r.toDomain()).toList();

  Selectable<BabyRow> _allQuery() =>
      select(babies)..orderBy([(t) => OrderingTerm.asc(t.createdAt)]);

  /// 생성순으로 관찰.
  Stream<List<Baby>> watchAll() => _allQuery().watch().map(_map);

  Future<List<Baby>> getAll() => _allQuery().get().then(_map);

  Future<Baby?> getById(String id) =>
      (select(babies)..where((t) => t.id.equals(id))).getSingleOrNull().then(
        (r) => r?.toDomain(),
      );

  /// 로컬 우선 저장(생성/수정 공통). id 충돌 시 갱신.
  Future<void> upsert(Baby baby) =>
      into(babies).insertOnConflictUpdate(baby.toCompanion());

  Future<int> deleteById(String id) =>
      (delete(babies)..where((t) => t.id.equals(id))).go();

  Future<int> setServerId(String id, String serverId) =>
      (update(babies)..where((t) => t.id.equals(id))).write(
        BabiesCompanion(serverId: Value(serverId)),
      );
}
