import 'package:agawaeuleo/core/utils/hangul_chosung.dart';
import 'package:agawaeuleo/data/fixtures/fixture_symptoms.dart';
import 'package:agawaeuleo/data/repositories/support/retry.dart';
import 'package:agawaeuleo/data/supabase/symptom_remote_data_source.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/domain/repositories/symptom_repository.dart';

/// [SymptomRepository] 구현 (§5.3 공개 읽기, §11.7 홈 그리드, §11.8 검색).
///
/// - **구성됨(isConfigured)**: Supabase [SymptomRemoteDataSource]에서 읽고 메모리 캐시.
/// - **미구성(데모 모드)**: [fixtureSymptoms]를 반환(빈 화면 방지 — §12.2).
///
/// 1회 조회는 [retryWithBackoff]로 감싸 일시적 네트워크 오류를 흡수한다. 스트림은
/// 데이터소스가 이미 `AppException`으로 error 이벤트를 변환한다.
class SymptomRepositoryImpl implements SymptomRepository {
  SymptomRepositoryImpl([this._remote]);

  final SymptomRemoteDataSource? _remote;

  /// getAll 결과 메모리 캐시(§5.3 캐시). 스트림 방출 시에도 갱신한다.
  List<Symptom>? _cache;

  bool get _isDemo => _remote == null;

  @override
  Stream<List<Symptom>> watchAll() {
    if (_isDemo) return Stream<List<Symptom>>.value(_demoSymptoms());
    return _remote!.watchAll().map((list) {
      _cache = list;
      return list;
    });
  }

  @override
  Future<List<Symptom>> getAll() async {
    if (_isDemo) return _demoSymptoms();
    final cached = _cache;
    if (cached != null) return cached;
    final list = await retryWithBackoff(() => _remote!.getAll());
    return _cache = list;
  }

  @override
  Future<Symptom?> getById(String id) async {
    if (_isDemo) return _firstWhere(_demoSymptoms(), (s) => s.id == id);
    final cached = _cache;
    if (cached != null) {
      final hit = _firstWhere(cached, (s) => s.id == id);
      if (hit != null) return hit;
    }
    return retryWithBackoff(() => _remote!.getById(id));
  }

  @override
  Future<Symptom?> getBySlug(String slug) async {
    if (_isDemo) return _firstWhere(_demoSymptoms(), (s) => s.slug == slug);
    final cached = _cache;
    if (cached != null) {
      final hit = _firstWhere(cached, (s) => s.slug == slug);
      if (hit != null) return hit;
    }
    return retryWithBackoff(() => _remote!.getBySlug(slug));
  }

  @override
  Future<List<Symptom>> search(String query) async {
    if (query.trim().isEmpty) return const <Symptom>[];
    final all = await getAll();
    return all
        .where((s) => HangulChosung.matches(query, s.name, aliases: s.aliases))
        .toList(growable: false);
  }

  /// 데모(미구성) 증상 목록 — 활성만, `order_index` 오름차순.
  List<Symptom> _demoSymptoms() =>
      fixtureSymptoms.where((s) => s.isActive).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  static Symptom? _firstWhere(List<Symptom> list, bool Function(Symptom) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }
}
