import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/product_card.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/product_thumbnail.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_parallax.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_reveal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

/// §11.9-6 제품 카드(DESIGN v2 §7.3-6 확장 "에디토리얼 랭킹 보드") 스모크.
///
/// 1위 히어로/2위 이하 행이 각각 제목·한 줄 설명·순위를 노출하는지, 가격·평점이
/// 새지 않는지(0011), 사진이 있을 때 패럴랙스 프레임이 붙는지를 확인한다.
Product _product({
  String title = '테스트 젖병 트윈팩',
  String? blurb = '수유 중 공기 혼입이 적어요',
  String? imageUrl,
}) => Product(
  id: 'p1',
  symptomId: 's1',
  coupangPid: 'PID1',
  title: title,
  blurb: blurb,
  imageUrl: imageUrl,
  price: 19900,
  rating: 4.5,
  deeplink: 'https://example.com/p1',
  fetchedAt: DateTime(2026),
);

void main() {
  testWidgets('히어로 카드: 1위 배지·BEST PICK·CTA·제목·한 줄 설명을 노출한다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      ProductHeroCard(product: _product()),
      reduceMotion: true,
    );

    expect(find.text('1'), findsOneWidget);
    expect(find.text('BEST PICK'), findsOneWidget);
    expect(find.text('쿠팡에서 보기'), findsOneWidget);
    expect(find.text('테스트 젖병 트윈팩'), findsOneWidget);
    expect(find.text('수유 중 공기 혼입이 적어요'), findsOneWidget);

    // 0011 — 가격/평점은 필드가 살아 있어도 카드에 새지 않는다.
    expect(find.textContaining('19,900'), findsNothing);
    expect(find.textContaining('4.5'), findsNothing);
  });

  testWidgets('행 카드: 순위 배지와 제목/한 줄 설명을 노출하고, 설명이 비면 줄을 생략한다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      Column(
        children: [
          ProductCard(product: _product(), rank: 2),
          ProductCard(
            product: _product(title: '설명 없는 제품', blurb: '   '),
            rank: 3,
          ),
        ],
      ),
      reduceMotion: true,
    );

    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    expect(find.text('테스트 젖병 트윈팩'), findsOneWidget);
    expect(find.text('설명 없는 제품'), findsOneWidget);
    // 공백뿐인 blurb는 줄 자체를 그리지 않는다.
    expect(find.text('   '), findsNothing);
    expect(find.byType(ProductThumbnail), findsNWidgets(2));
  });

  testWidgets('사진이 있으면 패럴랙스 프레임으로 감싸고, 없으면 감싸지 않는다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      Column(
        children: [
          ProductCard(
            product: _product(imageUrl: 'https://example.com/a.png'),
            rank: 2,
          ),
          ProductCard(product: _product(), rank: 3),
        ],
      ),
    );
    await tester.pump();

    expect(find.byType(ScrollParallax), findsOneWidget);
    // 이미지 로더 실패(테스트 환경 HTTP 400)는 errorBuilder가 흡수한다.
    tester.takeException();

    await tester.pumpWidget(const SizedBox.shrink());
    // 테스트 환경의 이미지 로더가 남기는 타이머를 소진시킨다.
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('ScrollReveal: reduce-motion이면 모션 레이어 없이 자식을 그대로 그린다', (
    tester,
  ) async {
    await pumpWidgetWithTheme(
      tester,
      const ScrollReveal(child: Text('보임')),
      reduceMotion: true,
    );

    expect(find.text('보임'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(ScrollReveal),
        matching: find.byType(Opacity),
      ),
      findsNothing,
    );
  });
}
