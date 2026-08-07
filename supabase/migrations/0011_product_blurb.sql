-- 0011_product_blurb.sql
--
-- 제품 카드의 "가격" 표시를 "한 줄 설명"으로 대체(발주자 요청, 2026-08-08).
--
-- 배경: 쿠팡 파트너스 Open API 키는 파트너스 "최종승인"(누적 판매금액 조건)
-- 이후에만 발급된다. 승인 전까지 products.price 는 어드민 수동 입력값이며
-- 시세 변동을 따라가지 못해 무기한 박제된 가격이 표시되는 문제가 있었다.
-- → 앱/어드민에서 가격·평점 표시를 걷어내고, 어드민이 직접 쓰는 짧은 설명
--   (blurb)을 노출한다.
--
-- price / rating 컬럼은 **삭제하지 않는다**:
--   - 기존 데이터 보존(파괴적 변경 회피).
--   - 파트너스 API 승인 후 refresh-products(Edge Function)가 다시 채우게 되면
--     그대로 재사용할 수 있다.
-- 즉 이 마이그레이션은 순수 additive 이며 롤백이 필요 없다.

alter table products
  add column if not exists blurb text;

comment on column products.blurb is
  '제품 카드 한 줄 설명(어드민 수동 입력). 앱은 가격 대신 이 값을 노출한다. '
  'null/빈 값이면 앱은 설명 줄을 그리지 않는다.';
