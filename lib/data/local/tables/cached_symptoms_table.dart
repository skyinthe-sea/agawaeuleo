import 'package:drift/drift.dart';

/// 증상 마스터 로컬 캐시 테이블 (§5.3 캐시 읽기, 오프라인 우선).
///
/// [data]는 Supabase `symptoms` 행 전체의 JSON 문자열(와이어 셰이프 그대로).
/// 읽기 경로는 이 blob을 디코드해 공용 와이어 매퍼(`entity_wire_mappers.dart`)로
/// `Symptom`을 만든다. 조회·정렬에 필요한 컬럼만 별도 승격한다:
///   - [slug]  : `getBySlug` 단건 조회.
///   - [orderIndex]/[isActive] : 홈 그리드(활성만, order_index 오름차순).
/// 캐시는 [MasterDataCacheService]가 매니페스트 버전 변화 시 통째로 교체한다.
@DataClassName('CachedSymptomRow')
class CachedSymptoms extends Table {
  /// `symptoms.id`(uuid, PK).
  TextColumn get id => text()();

  /// `symptoms.slug`.
  TextColumn get slug => text()();

  /// `symptoms.order_index`.
  IntColumn get orderIndex => integer().withDefault(const Constant(0))();

  /// `symptoms.is_active`.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// 원본 행 JSON(와이어 셰이프).
  TextColumn get data => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
