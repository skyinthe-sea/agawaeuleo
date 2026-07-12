import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/product.dart';
import 'entity_wire_mappers.dart';
import 'supabase_error_mapper.dart';

/// 제품 캐시 원격 데이터소스 (§7.1 `products`, §11.9 수익 화면, §5.3).
///
/// 앱은 이 캐시만 읽는다(파트너스 API 직접 호출 금지). 활성(`is_active`) 제품을
/// `rank_index` 오름차순으로 반환한다. RLS `public read products`가 `using (is_active)`라
/// 비활성 행은 애초에 전달되지 않지만, 스트림 경로에서도 방어적으로 한 번 더 거른다.
class ProductRemoteDataSource {
  ProductRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'products';

  SupabaseQueryBuilder get _from => _client.from(_table);

  /// 특정 증상의 추천 제품을 `rank_index` 순으로 관찰(§11.9).
  Stream<List<Product>> watchBySymptom(String symptomId) => _from
      .stream(primaryKey: ['id'])
      .eq('symptom_id', symptomId)
      .order('rank_index', ascending: true)
      .map(
        (rows) => rows
            .where((r) => r['is_active'] as bool? ?? true)
            .map(productFromWire)
            .toList(growable: false),
      )
      .mapErrorToAppException();

  /// 특정 증상의 추천 제품 1회 조회.
  Future<List<Product>> getBySymptom(String symptomId) async {
    try {
      final rows = await _from
          .select()
          .eq('symptom_id', symptomId)
          .eq('is_active', true)
          .order('rank_index', ascending: true);
      return rows.map(productFromWire).toList(growable: false);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 캐시 적재용 — 활성 제품 전체 원시 행(symptom_id, rank_index 순) (§5.3
  /// MasterDataCacheService).
  Future<List<Map<String, dynamic>>> fetchActiveRows() async {
    try {
      return await _from
          .select()
          .eq('is_active', true)
          .order('symptom_id')
          .order('rank_index', ascending: true);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }
}
