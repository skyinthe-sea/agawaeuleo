import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/symptom_info.dart';
import 'entity_wire_mappers.dart';
import 'supabase_error_mapper.dart';

/// 증상별 참고정보 원격 데이터소스 (§7.1 `symptom_infos`, §11.9, §5.3 공개 읽기).
///
/// jsonb `sections`/`emergency`/`sources`를 도메인 [InfoSection]/[EmergencySign]/
/// [InfoSource]로 매핑한다(타입 유니온 파싱 규칙은 `symptom_info_mappers.dart` —
/// 미지 type·필드 결손은 text 폴백/원소 스킵으로 흡수).
/// 증상당 참고정보는 최신(`updated_at`) 1건을 사용한다.
class SymptomInfoRemoteDataSource {
  SymptomInfoRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'symptom_infos';

  /// DATA_ACCESS.md §1 — 필요한 컬럼만 select(`*` 금지).
  static const _columns =
      'id, symptom_id, summary, sections, emergency, sources, updated_at';

  SupabaseQueryBuilder get _from => _client.from(_table);

  /// 특정 증상의 참고정보를 관찰. 없으면 null 방출.
  Stream<SymptomInfo?> watchBySymptom(String symptomId) => _from
      .stream(primaryKey: ['id'])
      .eq('symptom_id', symptomId)
      .order('updated_at', ascending: false)
      .map((rows) => rows.isEmpty ? null : symptomInfoFromWire(rows.first))
      .mapErrorToAppException();

  /// 특정 증상의 참고정보 1회 조회. 없으면 null.
  Future<SymptomInfo?> getBySymptom(String symptomId) async {
    try {
      final rows = await _from
          .select(_columns)
          .eq('symptom_id', symptomId)
          .order('updated_at', ascending: false)
          .limit(1);
      return rows.isEmpty ? null : symptomInfoFromWire(rows.first);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 캐시 적재용 — 증상당 최신(`updated_at`) 1건씩의 원시 행 (§5.3
  /// MasterDataCacheService). 전체를 최신순으로 받아 symptom_id별 첫 행만 남긴다.
  Future<List<Map<String, dynamic>>> fetchLatestRowsPerSymptom() async {
    try {
      final rows = await _from
          .select(_columns)
          .order('updated_at', ascending: false);
      final seen = <String>{};
      final latest = <Map<String, dynamic>>[];
      for (final row in rows) {
        final symptomId = row['symptom_id'] as String?;
        if (symptomId == null || !seen.add(symptomId)) continue;
        latest.add(row);
      }
      return latest;
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }
}
