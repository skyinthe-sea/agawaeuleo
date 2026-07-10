import 'package:agawaeuleo/presentation/widgets/segments/sliding_segment.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('items 라벨이 모두 렌더되고 선택 항목 탭 시 onChanged가 호출된다', (tester) async {
    String? changed;
    await pumpWidgetWithTheme(
      tester,
      SizedBox(
        width: 240,
        child: SlidingSegment<String>(
          items: const ['남아', '여아'],
          selected: '남아',
          labelOf: (item) => item,
          onChanged: (value) => changed = value,
        ),
      ),
    );

    expect(find.text('남아'), findsOneWidget);
    expect(find.text('여아'), findsOneWidget);

    await tester.tap(find.text('여아'));
    await tester.pumpAndSettle();

    expect(changed, '여아');
    expect(tester.takeException(), isNull);
  });

  testWidgets('이미 선택된 항목을 다시 탭해도 onChanged가 호출되지 않는다', (tester) async {
    var callCount = 0;
    await pumpWidgetWithTheme(
      tester,
      SizedBox(
        width: 240,
        child: SlidingSegment<String>(
          items: const ['일간', '주간', '월간'],
          selected: '주간',
          labelOf: (item) => item,
          onChanged: (_) => callCount++,
        ),
      ),
    );

    await tester.tap(find.text('주간'));
    await tester.pumpAndSettle();

    expect(callCount, 0);
  });
}
