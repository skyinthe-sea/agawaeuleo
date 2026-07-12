import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/symptom.dart';
import 'entity_wire_mappers.dart';
import 'supabase_error_mapper.dart';

/// 증상 마스터 원격 데이터소스 (§7.1 `symptoms`, §5.3 공개 읽기).
///
/// 공개 읽기(RLS `using (true)`)이므로 세션이 없어도 조회 가능. snake_case 컬럼 ↔
/// [Symptom] 매핑을 담당한다. `is_active` 필터·초성 검색은 리포지토리(도메인) 레이어가
/// 처리한다 — 여기서는 활성 증상만 노출(`is_active == true`).
class SymptomRemoteDataSource {
  SymptomRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'symptoms';

  /// DATA_ACCESS.md §1 — 필요한 컬럼만 select(`*` 금지).
  static const _columns =
      'id, slug, name, chosung, aliases, tagline, emoji_or_icon, '
      'product_keywords, order_index, audience, is_active, created_at';

  SupabaseQueryBuilder get _from => _client.from(_table);

  /// 활성 증상 전체를 `order_index` 순으로 관찰(홈 그리드 — §11.7).
  ///
  /// 실시간 스트림은 필터를 1개만 허용하므로 `is_active`는 원시 행 단계에서 걸러 매핑한다.
  Stream<List<Symptom>> watchAll() => _from
      .stream(primaryKey: ['id'])
      .order('order_index', ascending: true)
      .map(
        (rows) => rows
            .where((r) => r['is_active'] as bool? ?? true)
            .map(symptomFromWire)
            .toList(growable: false),
      )
      .mapErrorToAppException();

  /// 활성 증상 전체 1회 조회.
  Future<List<Symptom>> getAll() async {
    return (await fetchActiveRows())
        .map(symptomFromWire)
        .toList(growable: false);
  }

  /// 캐시 적재용 원시 행(활성만, order_index 오름차순) 1회 조회 (§5.3
  /// MasterDataCacheService). 매핑 전 와이어 행을 그대로 돌려준다.
  Future<List<Map<String, dynamic>>> fetchActiveRows() async {
    try {
      return await _from
          .select(_columns)
          .eq('is_active', true)
          .order('order_index', ascending: true);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// id로 단건 조회. 없으면 null.
  Future<Symptom?> getById(String id) => _single('id', id);

  /// slug(딥링크 진입 — §3.3)로 단건 조회. 없으면 null.
  Future<Symptom?> getBySlug(String slug) => _single('slug', slug);

  Future<Symptom?> _single(String column, String value) async {
    try {
      final row = await _from.select(_columns).eq(column, value).maybeSingle();
      return row == null ? null : symptomFromWire(row);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }
}
