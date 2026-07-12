import 'dart:convert';

import 'package:agawaeuleo/data/fixtures/fixture_products.dart';
import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/data/supabase/entity_wire_mappers.dart';
import 'package:agawaeuleo/domain/entities/product.dart';
import 'package:agawaeuleo/domain/repositories/product_repository.dart';

/// [ProductRepository] 구현 (§5.3 캐시 읽기 전용, §11.9 수익 화면).
///
/// - **구성됨(캐시 모드)**: 로컬 Drift 캐시([MasterCacheDao])의 활성 제품을
///   `rank_index` 오름차순으로 읽는다(네트워크 미접촉 — 신선도는
///   `MasterDataCacheService`가 매니페스트 `products` 버전으로 갱신).
/// - **미구성(데모)**: [fixtureProducts]에서 해당 증상 제품을 필터링해 반환.
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl([this._cache]);

  final MasterCacheDao? _cache;

  bool get _isDemo => _cache == null;

  @override
  Stream<List<Product>> watchBySymptom(String symptomId) {
    if (_isDemo) {
      return Stream<List<Product>>.value(_demoProducts(symptomId));
    }
    return _cache!.watchProducts(symptomId).map(_mapRows);
  }

  @override
  Future<List<Product>> getBySymptom(String symptomId) async {
    if (_isDemo) return _demoProducts(symptomId);
    return _mapRows(await _cache!.getProducts(symptomId));
  }

  List<Product> _mapRows(List<CachedProductRow> rows) => [
    for (final row in rows) productFromWire(_decode(row.data)),
  ];

  /// 데모(미구성) 제품 목록 — 해당 증상, `rank_index` 오름차순.
  List<Product> _demoProducts(String symptomId) =>
      fixtureProducts
          .where((p) => p.symptomId == symptomId && p.isActive)
          .toList()
        ..sort((a, b) => a.rankIndex.compareTo(b.rankIndex));

  Map<String, dynamic> _decode(String json) =>
      (jsonDecode(json) as Map).cast<String, dynamic>();
}
