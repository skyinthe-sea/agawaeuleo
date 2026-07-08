import 'package:drift/drift.dart';

/// 최근 검색어 로컬 테이블 (§11.8 검색 — 로컬 저장, 좌스와이프 개별 삭제).
///
/// [query]를 PK로 두어 같은 검색어 재검색 시 [searchedAt]만 갱신(자동 중복 제거).
@DataClassName('RecentSearchRow')
class RecentSearches extends Table {
  /// 검색어(PK) — 재검색 시 upsert로 시각만 갱신.
  TextColumn get query => text()();

  /// 마지막 검색 시각(최근순 정렬 기준).
  DateTimeColumn get searchedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {query};
}
