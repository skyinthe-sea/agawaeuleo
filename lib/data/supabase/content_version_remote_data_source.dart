import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_error_mapper.dart';

/// 콘텐츠 버전 매니페스트 원격 데이터소스 (§5.3 서버 주도 캐시 무효화).
///
/// `content_versions(dataset, version)` — 데이터셋별 버전 정수. Supabase 트리거가
/// 마스터 테이블(symptoms/symptom_infos/products) 변경 시 자동 증가시킨다
/// (`supabase/migrations/0010_content_versions.sql`). 클라이언트는 이 매니페스트를
/// 부팅·복귀·**단일 실시간 구독**으로 읽어, 로컬 `cache_meta` 버전과 다른 데이터셋만
/// 재조회한다. `dataset` 키는 서버·클라이언트 공유 계약:
/// `symptoms` | `symptom_infos` | `products`.
class ContentVersionRemoteDataSource {
  ContentVersionRemoteDataSource(this._client);

  final SupabaseClient _client;

  static const _table = 'content_versions';

  SupabaseQueryBuilder get _from => _client.from(_table);

  /// 데이터셋 → 버전 맵 1회 조회.
  Future<Map<String, int>> fetchVersions() async {
    try {
      final rows = await _from.select('dataset, version');
      return _toMap(rows);
    } on Object catch (error, stackTrace) {
      throw mapSupabaseError(error, stackTrace);
    }
  }

  /// 매니페스트 변화 관찰(단일 realtime 채널 — 앱이 열린 동안 즉시 재검증 트리거).
  Stream<Map<String, int>> watchVersions() => _from
      .stream(primaryKey: ['dataset'])
      .map(_toMap)
      .mapErrorToAppException();

  Map<String, int> _toMap(List<Map<String, dynamic>> rows) => {
    for (final row in rows)
      if (row['dataset'] is String)
        row['dataset'] as String: (row['version'] as num?)?.toInt() ?? 0,
  };
}
