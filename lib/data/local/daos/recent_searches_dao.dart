import 'package:agawaeuleo/data/local/app_database.dart';
import 'package:agawaeuleo/data/local/tables/recent_searches_table.dart';
import 'package:drift/drift.dart';

part 'recent_searches_dao.g.dart';

/// 최근 검색어 로컬 DAO (§11.8 — 저장, 상위 N 관찰, 좌스와이프 개별 삭제).
@DriftAccessor(tables: [RecentSearches])
class RecentSearchesDao extends DatabaseAccessor<AppDatabase>
    with _$RecentSearchesDaoMixin {
  RecentSearchesDao(super.attachedDatabase);

  static const int defaultLimit = 10;

  /// 검색어 저장 — 같은 검색어 재검색 시 [searchedAt]만 갱신(중복 제거).
  Future<void> record(String query, {DateTime? searchedAt}) =>
      into(recentSearches).insertOnConflictUpdate(
        RecentSearchesCompanion.insert(
          query: query,
          searchedAt: searchedAt ?? DateTime.now(),
        ),
      );

  Selectable<RecentSearchRow> _recentQuery(int limit) => select(recentSearches)
    ..orderBy([(t) => OrderingTerm.desc(t.searchedAt)])
    ..limit(limit);

  /// 최근 검색어 상위 [limit]개 관찰(최신순).
  Stream<List<RecentSearchRow>> watchRecent({int limit = defaultLimit}) =>
      _recentQuery(limit).watch();

  Future<List<RecentSearchRow>> getRecent({int limit = defaultLimit}) =>
      _recentQuery(limit).get();

  /// 좌스와이프 개별 삭제(§11.8).
  Future<int> deleteQuery(String query) =>
      (delete(recentSearches)..where((t) => t.query.equals(query))).go();

  /// 전체 지우기.
  Future<int> clear() => delete(recentSearches).go();
}
