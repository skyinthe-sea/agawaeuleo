import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/daily_encouragement.dart';
import 'supabase_error_mapper.dart';

/// 오늘의 응원 문구 원격 데이터소스 (`daily_encouragements`, §7.1 공개 읽기).
///
/// 공개 읽기(RLS `using (is_active)`)이므로 세션이 없어도 조회 가능. snake_case
/// 컬럼 ↔ [DailyEncouragement] 매핑을 담당한다. 활성 문구만 `order_index` 순으로
/// 노출한다(회전 노출은 프레젠테이션 레이어에서 날짜로 인덱싱).
class DailyEncouragementRemoteDataSource {
  DailyEncouragementRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'daily_encouragements';

  SupabaseQueryBuilder get _from => _client.from(_table);

  /// 활성 응원 문구 전체를 `order_index` 순으로 관찰.
  ///
  /// 실시간 스트림은 필터를 1개만 허용하므로 `is_active`는 원시 행 단계에서 걸러 매핑한다.
  Stream<List<DailyEncouragement>> watchAll() => _from
      .stream(primaryKey: ['id'])
      .order('order_index', ascending: true)
      .map(
        (rows) => rows
            .where((r) => r['is_active'] as bool? ?? true)
            .map(_fromRow)
            .toList(growable: false),
      )
      .mapErrorToAppException();

  /// 활성 응원 문구 전체 1회 조회.
  Future<List<DailyEncouragement>> getAll() async {
    try {
      // 필요한 컬럼만 선택(페이로드 최소화). 활성만·순서대로.
      final rows = await _from
          .select('id, message, order_index, is_active')
          .eq('is_active', true)
          .order('order_index', ascending: true);
      return rows.map(_fromRow).toList(growable: false);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  DailyEncouragement _fromRow(Map<String, dynamic> row) => DailyEncouragement(
    id: row['id'] as String,
    message: row['message'] as String? ?? '',
    orderIndex: (row['order_index'] as num?)?.toInt() ?? 0,
    isActive: row['is_active'] as bool? ?? true,
  );
}
