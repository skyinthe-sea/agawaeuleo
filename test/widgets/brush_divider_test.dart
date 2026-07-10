import 'package:agawaeuleo/presentation/widgets/dividers/brush_divider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('BrushDivider.section은 좌정렬 폭 64로 렌더된다', (tester) async {
    await pumpWidgetWithTheme(tester, const BrushDivider.section());

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(BrushDivider),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBox.width, 64);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('BrushDivider.center는 중앙정렬 폭 88로 렌더된다', (tester) async {
    await pumpWidgetWithTheme(tester, const BrushDivider.center());

    final sizedBox = tester.widget<SizedBox>(
      find.descendant(
        of: find.byType(BrushDivider),
        matching: find.byType(SizedBox),
      ),
    );
    expect(sizedBox.width, 88);
    expect(tester.takeException(), isNull);
  });

  testWidgets('동일 폭 재렌더 시(같은 color) 예외 없이 리페인트된다', (tester) async {
    await pumpWidgetWithTheme(tester, const BrushDivider());
    await pumpWidgetWithTheme(tester, const BrushDivider());

    expect(tester.takeException(), isNull);
  });
}
