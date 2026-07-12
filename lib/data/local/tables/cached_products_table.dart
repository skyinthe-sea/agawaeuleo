import 'package:drift/drift.dart';

/// 추천 제품(쿠팡) 로컬 캐시 테이블 (§5.3 캐시 읽기, §11.9 수익 화면).
///
/// [data]는 Supabase `products` 행 전체의 JSON 문자열(와이어 셰이프 그대로).
/// 읽기 경로는 blob을 디코드해 공용 와이어 매퍼로 `Product`를 만든다. 조회·정렬
/// 컬럼만 승격한다:
///   - [symptomId] : 증상별 필터.
///   - [isActive]/[rankIndex] : 활성만, rank_index 오름차순.
/// 제품은 자주 바뀌므로(§어드민) 매니페스트 `products` 버전 변화 시 통째로 교체된다.
@DataClassName('CachedProductRow')
class CachedProducts extends Table {
  /// `products.id`(uuid, PK).
  TextColumn get id => text()();

  /// `products.symptom_id`.
  TextColumn get symptomId => text()();

  /// `products.rank_index`.
  IntColumn get rankIndex => integer().withDefault(const Constant(0))();

  /// `products.is_active`.
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  /// 원본 행 JSON(와이어 셰이프).
  TextColumn get data => text()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
