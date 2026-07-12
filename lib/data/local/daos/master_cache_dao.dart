import 'package:agawaeuleo/data/local/app_database.dart';
import 'package:agawaeuleo/data/local/tables/cache_meta_table.dart';
import 'package:agawaeuleo/data/local/tables/cached_products_table.dart';
import 'package:agawaeuleo/data/local/tables/cached_symptom_infos_table.dart';
import 'package:agawaeuleo/data/local/tables/cached_symptoms_table.dart';
import 'package:drift/drift.dart';

part 'master_cache_dao.g.dart';

/// 마스터 데이터(증상·참고정보·제품) 로컬 캐시 DAO (§5.3 오프라인 우선).
///
/// 리포지토리는 이 DAO의 `watch*`/`get*`로 **로컬만** 읽고(네트워크 미접촉),
/// [MasterDataCacheService]가 `replace*`/`setVersion`으로 서버 스냅샷을 통째로
/// 반영한다. 각 데이터셋 교체는 트랜잭션(delete-all → batch insert)이라 부분
/// 반영이 남지 않는다. blob(`data`) 디코드·엔티티 매핑은 리포지토리가 담당한다.
@DriftAccessor(
  tables: [CachedSymptoms, CachedSymptomInfos, CachedProducts, CacheMeta],
)
class MasterCacheDao extends DatabaseAccessor<AppDatabase>
    with _$MasterCacheDaoMixin {
  MasterCacheDao(super.attachedDatabase);

  // ── 증상 ──────────────────────────────────────────────────────────────
  Selectable<CachedSymptomRow> _activeSymptoms() => select(cachedSymptoms)
    ..where((t) => t.isActive.equals(true))
    ..orderBy([(t) => OrderingTerm.asc(t.orderIndex)]);

  /// 활성 증상 전체 관찰(order_index 오름차순 — 홈 그리드).
  Stream<List<CachedSymptomRow>> watchSymptoms() => _activeSymptoms().watch();

  Future<List<CachedSymptomRow>> getSymptoms() => _activeSymptoms().get();

  Future<CachedSymptomRow?> getSymptomBySlug(String slug) =>
      (select(cachedSymptoms)
            ..where((t) => t.slug.equals(slug))
            ..limit(1))
          .getSingleOrNull();

  Future<CachedSymptomRow?> getSymptomById(String id) =>
      (select(cachedSymptoms)
            ..where((t) => t.id.equals(id))
            ..limit(1))
          .getSingleOrNull();

  /// 증상 캐시 통째 교체(트랜잭션).
  Future<void> replaceSymptoms(List<CachedSymptomsCompanion> rows) =>
      transaction(() async {
        await delete(cachedSymptoms).go();
        await batch((b) => b.insertAll(cachedSymptoms, rows));
      });

  // ── 참고정보 ──────────────────────────────────────────────────────────
  Future<CachedSymptomInfoRow?> getSymptomInfo(String symptomId) =>
      (select(cachedSymptomInfos)
            ..where((t) => t.symptomId.equals(symptomId))
            ..limit(1))
          .getSingleOrNull();

  Stream<CachedSymptomInfoRow?> watchSymptomInfo(String symptomId) =>
      (select(cachedSymptomInfos)
            ..where((t) => t.symptomId.equals(symptomId))
            ..limit(1))
          .watchSingleOrNull();

  /// 참고정보 캐시 통째 교체(트랜잭션 — 증상당 최신 1건).
  Future<void> replaceSymptomInfos(List<CachedSymptomInfosCompanion> rows) =>
      transaction(() async {
        await delete(cachedSymptomInfos).go();
        await batch((b) => b.insertAll(cachedSymptomInfos, rows));
      });

  // ── 제품 ──────────────────────────────────────────────────────────────
  Selectable<CachedProductRow> _activeProducts(String symptomId) =>
      select(cachedProducts)
        ..where((t) => t.symptomId.equals(symptomId) & t.isActive.equals(true))
        ..orderBy([(t) => OrderingTerm.asc(t.rankIndex)]);

  Stream<List<CachedProductRow>> watchProducts(String symptomId) =>
      _activeProducts(symptomId).watch();

  Future<List<CachedProductRow>> getProducts(String symptomId) =>
      _activeProducts(symptomId).get();

  /// 제품 캐시 통째 교체(트랜잭션).
  Future<void> replaceProducts(List<CachedProductsCompanion> rows) =>
      transaction(() async {
        await delete(cachedProducts).go();
        await batch((b) => b.insertAll(cachedProducts, rows));
      });

  // ── 캐시 메타(데이터셋 버전) ───────────────────────────────────────────
  Future<int?> getVersion(String dataset) async {
    final row =
        await (select(cacheMeta)
              ..where((t) => t.dataset.equals(dataset))
              ..limit(1))
            .getSingleOrNull();
    return row?.version;
  }

  Future<void> setVersion(String dataset, int version, DateTime fetchedAt) =>
      into(cacheMeta).insertOnConflictUpdate(
        CacheMetaCompanion.insert(
          dataset: dataset,
          version: Value(version),
          fetchedAt: Value(fetchedAt),
        ),
      );
}
