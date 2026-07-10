import 'package:agawaeuleo/presentation/widgets/brand/ink_seal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('기본 InkSeal은 글리프 "아"를 렌더한다', (tester) async {
    await pumpWidgetWithTheme(tester, const InkSeal());

    expect(find.text('아'), findsOneWidget);
    expect(find.byType(Transform), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('크기 프리셋(sm/md/lg)이 각각 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const Row(children: [InkSeal.sm(), InkSeal.md(), InkSeal.lg()]),
    );

    expect(find.text('아'), findsNWidgets(3));
    expect(tester.takeException(), isNull);
  });

  testWidgets('animate: true 스탬프인 모션이 예외 없이 재생·완료된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const InkSeal.md(animate: true, haptic: true),
    );

    expect(find.text('아'), findsOneWidget);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('reduce-motion 시 스케일/회전 없이 즉시 표시된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const InkSeal.md(animate: true),
      reduceMotion: true,
    );
    await tester.pumpAndSettle();

    expect(find.text('아'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('watermark: true는 낮은 존재감의 배색으로 렌더된다', (tester) async {
    await pumpWidgetWithTheme(tester, const InkSeal.lg(watermark: true));

    expect(find.text('아'), findsOneWidget);
    expect(find.byType(Opacity), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
