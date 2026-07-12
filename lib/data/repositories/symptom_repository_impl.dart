import 'dart:convert';

import 'package:agawaeuleo/core/utils/hangul_chosung.dart';
import 'package:agawaeuleo/data/fixtures/fixture_symptoms.dart';
import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/supabase/entity_wire_mappers.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/domain/repositories/symptom_repository.dart';

/// [SymptomRepository] 구현 (§5.3 공개 읽기·오프라인 캐시, §11.7 홈, §11.8 검색).
///
/// - **구성됨(캐시 모드)**: 앱은 로컬 Drift 캐시([MasterCacheDao])에서만 읽는다.
///   네트워크는 화면 진입마다 접촉하지 않으며, 캐시 신선도는 `MasterDataCacheService`가
///   서버 매니페스트 버전 비교로 갱신한다(§5.3 stale-while-revalidate).
/// - **미구성(데모 모드)**: [fixtureSymptoms]를 반환(빈 화면 방지 — §12.2).
///
/// 캐시 행의 `data`(와이어 JSON)는 공용 매퍼 [symptomFromWire]로 도메인화한다
/// (원격 데이터소스와 동일 정의).
class SymptomRepositoryImpl implements SymptomRepository {
  SymptomRepositoryImpl([this._cache]);

  final MasterCacheDao? _cache;

  bool get _isDemo => _cache == null;

  @override
  Stream<List<Symptom>> watchAll() {
    if (_isDemo) return Stream<List<Symptom>>.value(_demoSymptoms());
    return _cache!.watchSymptoms().map(_mapRows);
  }

  @override
  Future<List<Symptom>> getAll() async {
    if (_isDemo) return _demoSymptoms();
    return _mapRows(await _cache!.getSymptoms());
  }

  @override
  Future<Symptom?> getById(String id) async {
    if (_isDemo) return _firstWhere(_demoSymptoms(), (s) => s.id == id);
    final row = await _cache!.getSymptomById(id);
    return row == null ? null : symptomFromWire(_decode(row.data));
  }

  @override
  Future<Symptom?> getBySlug(String slug) async {
    if (_isDemo) return _firstWhere(_demoSymptoms(), (s) => s.slug == slug);
    final row = await _cache!.getSymptomBySlug(slug);
    return row == null ? null : symptomFromWire(_decode(row.data));
  }

  @override
  Future<List<Symptom>> search(String query) async {
    if (query.trim().isEmpty) return const <Symptom>[];
    final all = await getAll();
    return all
        .where((s) => HangulChosung.matches(query, s.name, aliases: s.aliases))
        .toList(growable: false);
  }

  List<Symptom> _mapRows(List<CachedSymptomRow> rows) => [
    for (final row in rows) symptomFromWire(_decode(row.data)),
  ];

  /// 데모(미구성) 증상 목록 — 활성만, `order_index` 오름차순.
  List<Symptom> _demoSymptoms() =>
      fixtureSymptoms.where((s) => s.isActive).toList()
        ..sort((a, b) => a.orderIndex.compareTo(b.orderIndex));

  Map<String, dynamic> _decode(String json) =>
      (jsonDecode(json) as Map).cast<String, dynamic>();

  static Symptom? _firstWhere(List<Symptom> list, bool Function(Symptom) test) {
    for (final item in list) {
      if (test(item)) return item;
    }
    return null;
  }
}
