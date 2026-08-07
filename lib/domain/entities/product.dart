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

    /// `blurb` — 제품 카드 한 줄 설명(어드민 수동 입력, nullable).
    ///
    /// 파트너스 API 승인 전까지 [price]는 수동 입력이라 시세를 따라가지 못한다.
    /// 그래서 앱은 가격 대신 이 값을 노출한다(마이그레이션 0011). null/빈 값이면
    /// 설명 줄을 그리지 않는다.
    String? blurb,

    /// `image_url`(nullable).
    String? imageUrl,

    /// `price`(원, nullable).
    ///
    /// **앱 UI에는 노출하지 않는다** — 수동 입력값이라 부정확할 수 있다(0011).
    /// 파트너스 API 승인 후 `refresh-products`가 채우면 재사용할 수 있도록
    /// 필드·컬럼은 보존한다.
    int? price,

    /// `rating`(numeric, nullable).
    ///
    /// [price]와 같은 이유로 UI 비노출(0011). 필드·컬럼은 보존.
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
