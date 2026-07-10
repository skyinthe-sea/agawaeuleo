import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('기본(flat) 카드는 child를 그대로 렌더한다(기존 호출부 무변경 확인)', (tester) async {
    await pumpWidgetWithTheme(tester, const AppCard(child: Text('flat')));

    expect(find.text('flat'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('raised 카드는 예외 없이 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const AppCard(emphasis: AppCardEmphasis.raised, child: Text('raised')),
    );

    expect(find.text('raised'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('hero 카드는 아랫장 스택 + 그레인과 함께 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const AppCard(emphasis: AppCardEmphasis.hero, child: Text('hero')),
    );

    expect(find.text('hero'), findsOneWidget);
    expect(find.byType(Stack), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('탭 가능한 hero 카드도 탭 시 예외 없이 콜백된다', (tester) async {
    var tapped = false;
    await pumpWidgetWithTheme(
      tester,
      AppCard(
        emphasis: AppCardEmphasis.hero,
        onTap: () => tapped = true,
        child: const Text('hero-tap'),
      ),
    );

    await tester.tap(find.text('hero-tap'));
    await tester.pumpAndSettle();

    expect(tapped, isTrue);
    expect(tester.takeException(), isNull);
  });
}
