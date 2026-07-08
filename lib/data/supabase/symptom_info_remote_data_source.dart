import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/symptom_info.dart';
import 'row_mappers.dart';
import 'supabase_error_mapper.dart';

/// 증상별 참고정보 원격 데이터소스 (§7.1 `symptom_infos`, §11.9, §5.3 공개 읽기).
///
/// jsonb `sections`/`emergency`를 도메인 [InfoSection]/[EmergencySign]으로 매핑한다.
/// 증상당 참고정보는 최신(`updated_at`) 1건을 사용한다.
class SymptomInfoRemoteDataSource {
  SymptomInfoRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'symptom_infos';

  SupabaseQueryBuilder get _from => _client.from(_table);

  /// 특정 증상의 참고정보를 관찰. 없으면 null 방출.
  Stream<SymptomInfo?> watchBySymptom(String symptomId) => _from
      .stream(primaryKey: ['id'])
      .eq('symptom_id', symptomId)
      .order('updated_at', ascending: false)
      .map((rows) => rows.isEmpty ? null : _fromRow(rows.first))
      .mapErrorToAppException();

  /// 특정 증상의 참고정보 1회 조회. 없으면 null.
  Future<SymptomInfo?> getBySymptom(String symptomId) async {
    try {
      final rows = await _from
          .select()
          .eq('symptom_id', symptomId)
          .order('updated_at', ascending: false)
          .limit(1);
      return rows.isEmpty ? null : _fromRow(rows.first);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  SymptomInfo _fromRow(Map<String, dynamic> row) => SymptomInfo(
    id: row['id'] as String,
    symptomId: row['symptom_id'] as String,
    summary: row['summary'] as String,
    sections: asMapList(row['sections'])
        .map(
          (m) => InfoSection(
            title: (m['title'] ?? '') as String,
            body: (m['body'] ?? '') as String,
          ),
        )
        .toList(growable: false),
    emergency: asMapList(row['emergency'])
        .map(
          (m) => EmergencySign(
            sign: (m['sign'] ?? '') as String,
            action: (m['action'] ?? '') as String,
          ),
        )
        .toList(growable: false),
    updatedAt: parseDate(row['updated_at']),
  );
}
