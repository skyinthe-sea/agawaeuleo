import 'package:drift/drift.dart';

/// 증상 참고정보 로컬 캐시 테이블 (§5.3 캐시 읽기, §11.9).
///
/// 증상당 최신(`updated_at`) 1건만 보관한다([symptomId] PK). [data]는 Supabase
/// `symptom_infos` 행 전체의 JSON 문자열(와이어 셰이프 — sections/emergency/sources
/// jsonb 포함). 읽기 경로는 blob을 디코드해 공용 와이어 매퍼로 `SymptomInfo`를 만든다
/// (미지 섹션 타입·필드 결손은 매퍼가 방어적으로 흡수).
@DataClassName('CachedSymptomInfoRow')
class CachedSymptomInfos extends Table {
  /// `symptom_infos.symptom_id`(PK — 증상당 1건).
  TextColumn get symptomId => text()();

  /// 원본 행 JSON(와이어 셰이프).
  TextColumn get data => text()();

  /// `symptom_infos.updated_at`(최신 판별용).
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {symptomId};
}
