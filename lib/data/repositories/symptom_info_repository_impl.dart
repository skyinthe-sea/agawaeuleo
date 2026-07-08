import 'package:agawaeuleo/data/fixtures/fixture_symptoms.dart';
import 'package:agawaeuleo/data/repositories/support/retry.dart';
import 'package:agawaeuleo/data/supabase/symptom_info_remote_data_source.dart';
import 'package:agawaeuleo/domain/entities/symptom_info.dart';
import 'package:agawaeuleo/domain/repositories/symptom_info_repository.dart';

/// [SymptomInfoRepository] 구현 (§5.3 공개 읽기, §11.9 증상 상세 정보).
///
/// - **구성됨**: Supabase [SymptomInfoRemoteDataSource]에서 읽고 증상별 메모리 캐시.
/// - **미구성(데모)**: [fixtureSymptomInfos]에서 해당 증상 정보를 반환(없으면 null).
class SymptomInfoRepositoryImpl implements SymptomInfoRepository {
  SymptomInfoRepositoryImpl([this._remote]);

  final SymptomInfoRemoteDataSource? _remote;

  /// symptomId → 참고정보 메모리 캐시.
  final Map<String, SymptomInfo?> _cache = <String, SymptomInfo?>{};

  bool get _isDemo => _remote == null;

  @override
  Stream<SymptomInfo?> watchBySymptom(String symptomId) {
    if (_isDemo) {
      return Stream<SymptomInfo?>.value(_demoInfo(symptomId));
    }
    return _remote!.watchBySymptom(symptomId).map((info) {
      _cache[symptomId] = info;
      return info;
    });
  }

  @override
  Future<SymptomInfo?> getBySymptom(String symptomId) async {
    if (_isDemo) return _demoInfo(symptomId);
    if (_cache.containsKey(symptomId)) return _cache[symptomId];
    final info = await retryWithBackoff(() => _remote!.getBySymptom(symptomId));
    return _cache[symptomId] = info;
  }

  /// 데모(미구성) 참고정보 — 해당 증상. 없으면 null.
  SymptomInfo? _demoInfo(String symptomId) {
    for (final info in fixtureSymptomInfos) {
      if (info.symptomId == symptomId) return info;
    }
    return null;
  }
}
