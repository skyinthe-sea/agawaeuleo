// 개발용 데모 모드 픽스처 — Supabase 미구성(AppConfig.isConfigured == false) 시
// 증상 상세 화면의 "추천 제품" 섹션이 빈 상태로 보이지 않도록 하는 로컬
// 가짜(fake) 제품 데이터입니다.
//
// 실제 쿠팡 파트너스 상품이 아닙니다. [deeplink]는 `https://example.com/...`
// 자리표시 URL이며, 절대 실제 결제/이동에 사용되어서는 안 됩니다. 제목은
// 전부 `[샘플]`을 접두해 화면상으로도 실데이터와 구분되도록 했습니다.
//
// **프로덕션 빌드에서는 사용되지 않습니다.** Supabase가 정상 구성되면
// data 레이어의 리포지토리 구현체가 Edge Function이 채운 실제 `products`
// 캐시 테이블 데이터로 대체합니다(§6, §7.3). 이 파일은 순수 도메인 객체
// 리스트만 제공하며 어떤 데이터 소스에도 의존하지 않습니다.
library;

import 'package:agawaeuleo/data/fixtures/fixture_symptoms.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';

/// `(제목, 가격(원), 평점)` — `[샘플]` 접두는 [_productsFor]에서 일괄 부여한다.
typedef _ProductSpec = (String title, int? price, double? rating);

/// [slug] 증상에 대한 가짜 제품 목록을 생성한다.
///
/// - `id`/`coupangPid`/`deeplink`는 `slug`+순번 기준으로 결정적(deterministic)으로 생성.
/// - `deeplink`는 `https://example.com/...` 자리표시 — 실제 쿠팡 링크 아님.
/// - `imageUrl`은 실제 이미지 자산이 없어 `null`로 둔다(위젯이 플레이스홀더로 대체).
List<Product> _productsFor(String slug, List<_ProductSpec> items) {
  final symptomId = fixtureSymptomId(slug);
  return [
    for (final (index, item) in items.indexed)
      Product(
        id: 'fixture-product-$slug-${index + 1}',
        symptomId: symptomId,
        coupangPid: 'FIXTURE-${slug.toUpperCase()}-${index + 1}',
        title: '[샘플] ${item.$1}',
        price: item.$2,
        rating: item.$3,
        deeplink: 'https://example.com/fixture-deeplink/$slug/${index + 1}',
        rankIndex: index,
        fetchedAt: fixtureGeneratedAt,
      ),
  ];
}

/// 시드(0004_seed.sql)의 16종 증상 각각에 대한 2~3개의 가짜(fake) 추천 제품.
///
/// `product_keywords`(§7.1)를 참고해 그럴듯한 제목을 붙였을 뿐, 실제 상품이
/// 아니다 — 딥링크·평점·가격 모두 개발용 자리표시 값이다.
final List<Product> fixtureProducts = <Product>[
  ..._productsFor('colic', const [
    ('아기 배앓이 마사지오일 100ml', 12900, 4.6),
    ('영아산통 완화 트림쿠션', 15900, 4.4),
    ('아기 가스제거 마사지기', 18900, 4.3),
  ]),
  ..._productsFor('teething', const [
    ('실리콘 치발기 냉장보관형', 9900, 4.5),
    ('이앓이젤 잇몸 진정 케어', 11900, 4.2),
    ('유아 치아발육기 세트', 13900, 4.4),
  ]),
  ..._productsFor('newborn_heat_rash', const [
    ('신생아 저자극 로션 200ml', 14900, 4.7),
    ('태열 진정 크림', 16900, 4.5),
    ('신생아 순한 스킨케어 3종 세트', 24900, 4.6),
  ]),
  ..._productsFor('stool_color_abnormal', const [
    ('아기 유산균 분말 30포', 19900, 4.5),
    ('신생아 배 마사지오일', 12900, 4.3),
  ]),
  ..._productsFor('burping_trouble', const [
    ('트림 방석 수유쿠션', 21900, 4.4),
    ('역류방지 쿠션', 26900, 4.6),
    ('유아 가스배출 마사지오일', 13900, 4.2),
  ]),
  ..._productsFor('spit_up_reflux', const [
    ('역류방지 쿠션 각도조절형', 27900, 4.5),
    ('역류방지 젖병 240ml', 15900, 4.4),
    ('트림 방석 신생아용', 19900, 4.3),
  ]),
  ..._productsFor('runny_stuffy_nose', const [
    ('아기 콧물흡입기 전동식', 32900, 4.6),
    ('생리식염수 스프레이 100ml', 8900, 4.5),
    ('유아용 초음파 가습기', 39900, 4.4),
  ]),
  ..._productsFor('fever', const [
    ('유아 비접촉식 체온계', 24900, 4.7),
    ('해열패치 대용량', 6900, 4.3),
    ('아기 쿨매트 접이식', 17900, 4.5),
  ]),
  ..._productsFor('rash', const [
    ('아기 저자극 로션 300ml', 15900, 4.5),
    ('유아 순한 크림 100ml', 13900, 4.4),
    ('베이비 파우더 무향', 7900, 4.2),
  ]),
  ..._productsFor('sleep_regression', const [
    ('아기 백색소음기 휴대용', 28900, 4.6),
    ('유아 수면조끼 사계절용', 22900, 4.5),
    ('유아 무드등 수유등', 19900, 4.4),
  ]),
  ..._productsFor('constipation', const [
    ('아기 배 마사지오일 50ml', 11900, 4.4),
    ('아기 유산균 스틱 30포', 21900, 4.5),
  ]),
  ..._productsFor('diarrhea', const [
    ('기저귀 발진크림 100g', 9900, 4.6),
    ('유아 전해질음료 6팩', 14900, 4.3),
    ('순한 물티슈 캡형 3팩', 12900, 4.5),
  ]),
  ..._productsFor('hiccups', const [
    ('실리콘 공갈젖꼭지 2p', 8900, 4.3),
    ('수유쿠션 각도조절형', 25900, 4.5),
  ]),
  ..._productsFor('prickly_heat', const [
    ('땀띠 파우더 무향 100g', 7900, 4.4),
    ('아기 쿨매트 여름용', 17900, 4.5),
    ('유아 저자극 바디워시 500ml', 13900, 4.6),
  ]),
  ..._productsFor('jaundice', const [
    ('신생아 황달관리 매트', 34900, 4.3),
    ('신생아 바디수트 5매 세트', 19900, 4.5),
  ]),
  ..._productsFor('eye_discharge_tearing', const [
    ('아기 눈물눈곱 티슈 80매', 6900, 4.5),
    ('신생아 아이케어 티슈 2팩', 8900, 4.4),
  ]),
];

// 참고: 증상별 필터링/정렬(`symptomId`, `rankIndex` 기준)은 이 파일에 두지
// 않는다. `Product.symptomId`/`Product.rankIndex`는 freezed 생성 믹스인
// (`_$Product`, `product.freezed.dart`)이 제공하는 게터라 build_runner 실행
// 전(통합 단계 이전)에는 해석되지 않는다(§domain 계약과 동일한 codegen 제약).
// `ProductRepository` 데모 구현체가 [fixtureProducts]를 읽어 직접
// `where((p) => p.symptomId == id)` 형태로 필터링하면 된다.
