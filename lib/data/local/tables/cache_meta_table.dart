import 'package:drift/drift.dart';

/// 마스터 캐시 메타(데이터셋별 로컬 버전) 테이블 (§5.3 서버 주도 무효화).
///
/// 서버 `content_versions(dataset, version)` 매니페스트에 대응하는 로컬 사본.
/// [MasterDataCacheService]가 부팅/복귀/실시간 구독 시 서버 버전과 이 값을
/// 비교해, 다른 데이터셋만 재조회하고 여기 버전을 갱신한다(stale-while-revalidate).
/// [dataset]은 서버와 동일한 문자열 계약: `symptoms` | `symptom_infos` | `products`.
@DataClassName('CacheMetaRow')
class CacheMeta extends Table {
  /// 데이터셋 키(서버 매니페스트와 동일).
  TextColumn get dataset => text()();

  /// 이 기기에 마지막으로 반영된 데이터셋 버전.
  IntColumn get version => integer().withDefault(const Constant(0))();

  /// 마지막 재조회 시각(디버그·정책용, nullable).
  DateTimeColumn get fetchedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {dataset};
}
