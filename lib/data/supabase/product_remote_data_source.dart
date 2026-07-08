import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/product.dart';
import 'row_mappers.dart';
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
            .map(_fromRow)
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
      return rows.map(_fromRow).toList(growable: false);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  Product _fromRow(Map<String, dynamic> row) => Product(
    id: row['id'] as String,
    symptomId: row['symptom_id'] as String,
    coupangPid: row['coupang_pid'] as String,
    title: row['title'] as String,
    imageUrl: row['image_url'] as String?,
    price: asIntOrNull(row['price']),
    rating: asDoubleOrNull(row['rating']),
    deeplink: row['deeplink'] as String,
    rankIndex: asIntOrNull(row['rank_index']) ?? 0,
    isActive: row['is_active'] as bool? ?? true,
    fetchedAt: parseDate(row['fetched_at']),
  );
}
