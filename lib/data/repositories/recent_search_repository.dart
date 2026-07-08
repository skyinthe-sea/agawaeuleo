import 'package:agawaeuleo/data/local/local.dart';

/// 최근 검색어 로컬 저장소 (§11.8). 도메인 인터페이스가 없는 순수 로컬 UX 상태이므로
/// data 레이어의 구체 저장소로 둔다(Supabase 동기화 대상 아님).
///
/// [RecentSearchesDao]를 감싸 UI 친화적인 `String` 목록으로 노출한다. 같은 검색어는
/// PK 충돌 upsert로 자동 중복 제거되며, 최신순으로 관찰된다.
class RecentSearchRepository {
  RecentSearchRepository(this._dao);

  final RecentSearchesDao _dao;

  /// 최근 검색어 기본 노출 개수.
  static const int defaultLimit = 10;

  /// 검색어 저장(재검색 시 시각만 갱신). 공백은 무시한다.
  Future<void> record(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return Future<void>.value();
    return _dao.record(trimmed);
  }

  /// 최근 검색어를 최신순으로 관찰.
  Stream<List<String>> watchRecent({int limit = defaultLimit}) => _dao
      .watchRecent(limit: limit)
      .map((rows) => rows.map((r) => r.query).toList(growable: false));

  /// 최근 검색어 1회 조회(최신순).
  Future<List<String>> getRecent({int limit = defaultLimit}) => _dao
      .getRecent(limit: limit)
      .then((rows) => rows.map((r) => r.query).toList(growable: false));

  /// 개별 삭제(좌스와이프 — §11.8).
  Future<void> delete(String query) async {
    await _dao.deleteQuery(query);
  }

  /// 전체 지우기.
  Future<void> clear() async {
    await _dao.clear();
  }
}
