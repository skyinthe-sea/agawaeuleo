import '../entities/product.dart';

/// 제품 캐시 읽기 전용 저장소 (§3 C4, §7.1 `products`, §5.3).
///
/// 앱은 Supabase 캐시 테이블만 읽는다(파트너스 API 직접 호출 금지). 결과는
/// `rank_index` 순의 활성(is_active) 제품이다. 실패 시 `AppException` 계열을 던진다.
abstract class ProductRepository {
  /// 특정 증상의 추천 제품을 `rank_index` 순으로 관찰(§11.9 수익 화면).
  Stream<List<Product>> watchBySymptom(String symptomId);

  /// 특정 증상의 추천 제품 1회 조회.
  Future<List<Product>> getBySymptom(String symptomId);
}
