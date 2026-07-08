import 'package:freezed_annotation/freezed_annotation.dart';

part 'product.freezed.dart';

/// 제품 캐시 엔티티 (§7.1 `products`, §3 C4).
///
/// 앱은 이 캐시만 읽는다(파트너스 API 직접 호출 없음 — §5.3). [deeplink]는
/// 파트너스 코드가 포함된 링크로, 탭 시 외부 브라우저로 오픈한다(§3 C4).
@freezed
abstract class Product with _$Product {
  const factory Product({
    required String id,
    required String symptomId,

    /// `coupang_pid` — 쿠팡 상품 식별자.
    required String coupangPid,

    required String title,

    /// `image_url`(nullable).
    String? imageUrl,

    /// `price`(원, nullable).
    int? price,

    /// `rating`(numeric, nullable).
    double? rating,

    /// `deeplink` — 내 코드 포함 파트너스 링크.
    required String deeplink,

    /// `rank_index` — 증상 내 정렬 순서.
    @Default(0) int rankIndex,

    /// `is_active`.
    @Default(true) bool isActive,

    /// `fetched_at` — Edge Function upsert 시각.
    required DateTime fetchedAt,
  }) = _Product;
}
