import 'package:agawaeuleo/data/fixtures/fixture_products.dart';
import 'package:agawaeuleo/data/repositories/support/retry.dart';
import 'package:agawaeuleo/data/supabase/product_remote_data_source.dart';
import 'package:agawaeuleo/domain/entities/product.dart';
import 'package:agawaeuleo/domain/repositories/product_repository.dart';

/// [ProductRepository] 구현 (§5.3 캐시 읽기 전용, §11.9 수익 화면).
///
/// - **구성됨**: Supabase [ProductRemoteDataSource]에서 활성 제품을 `rank_index`
///   오름차순으로 읽고, 증상별로 메모리 캐시.
/// - **미구성(데모)**: [fixtureProducts]에서 해당 증상 제품을 필터링해 반환.
class ProductRepositoryImpl implements ProductRepository {
  ProductRepositoryImpl([this._remote]);

  final ProductRemoteDataSource? _remote;

  /// symptomId → 제품 목록 메모리 캐시.
  final Map<String, List<Product>> _cache = <String, List<Product>>{};

  bool get _isDemo => _remote == null;

  @override
  Stream<List<Product>> watchBySymptom(String symptomId) {
    if (_isDemo) {
      return Stream<List<Product>>.value(_demoProducts(symptomId));
    }
    return _remote!.watchBySymptom(symptomId).map((list) {
      _cache[symptomId] = list;
      return list;
    });
  }

  @override
  Future<List<Product>> getBySymptom(String symptomId) async {
    if (_isDemo) return _demoProducts(symptomId);
    final cached = _cache[symptomId];
    if (cached != null) return cached;
    final list = await retryWithBackoff(() => _remote!.getBySymptom(symptomId));
    return _cache[symptomId] = list;
  }

  /// 데모(미구성) 제품 목록 — 해당 증상, `rank_index` 오름차순.
  List<Product> _demoProducts(String symptomId) {
    final list =
        fixtureProducts
            .where((p) => p.symptomId == symptomId && p.isActive)
            .toList()
          ..sort((a, b) => a.rankIndex.compareTo(b.rankIndex));
    return list;
  }
}
