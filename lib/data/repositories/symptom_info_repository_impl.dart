import 'dart:convert';

import 'package:agawaeuleo/data/fixtures/fixture_symptoms.dart';
import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/supabase/entity_wire_mappers.dart';
import 'package:agawaeuleo/domain/entities/symptom_info.dart';
import 'package:agawaeuleo/domain/repositories/symptom_info_repository.dart';

/// [SymptomInfoRepository] 구현 (§5.3 공개 읽기·오프라인 캐시, §11.9 증상 상세 정보).
///
/// - **구성됨(캐시 모드)**: 로컬 Drift 캐시([MasterCacheDao])의 증상별 최신 참고정보를
///   읽는다(네트워크 미접촉 — 신선도는 `MasterDataCacheService` 담당).
/// - **미구성(데모)**: [fixtureSymptomInfos]에서 해당 증상 정보를 반환(없으면 null).
class SymptomInfoRepositoryImpl implements SymptomInfoRepository {
  SymptomInfoRepositoryImpl([this._cache]);

  final MasterCacheDao? _cache;

  bool get _isDemo => _cache == null;

  @override
  Stream<SymptomInfo?> watchBySymptom(String symptomId) {
    if (_isDemo) {
      return Stream<SymptomInfo?>.value(_demoInfo(symptomId));
    }
    return _cache!.watchSymptomInfo(symptomId).map(_mapRow);
  }

  @override
  Future<SymptomInfo?> getBySymptom(String symptomId) async {
    if (_isDemo) return _demoInfo(symptomId);
    return _mapRow(await _cache!.getSymptomInfo(symptomId));
  }

  SymptomInfo? _mapRow(CachedSymptomInfoRow? row) =>
      row == null ? null : symptomInfoFromWire(_decode(row.data));

  /// 데모(미구성) 참고정보 — 해당 증상. 없으면 null.
  SymptomInfo? _demoInfo(String symptomId) {
    for (final info in fixtureSymptomInfos) {
      if (info.symptomId == symptomId) return info;
    }
    return null;
  }

  Map<String, dynamic> _decode(String json) =>
      (jsonDecode(json) as Map).cast<String, dynamic>();
}
