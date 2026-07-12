import 'package:agawaeuleo/presentation/widgets/navigation/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('활성 탭 라벨만 보이고, 세 탭은 접근성 라벨로 존재한다', (tester) async {
    var index = 0;
    await pumpWidgetWithTheme(
      tester,
      StatefulBuilder(
        builder: (context, setState) => AppBottomNav(
          currentIndex: index,
          onTap: (value) => setState(() => index = value),
        ),
      ),
    );

    // 활성 탭(홈) 라벨만 시각적으로 렌더되고, 나머지 라벨은 아이콘 단독이라 없다.
    expect(find.text('홈'), findsOneWidget);
    expect(find.text('기록'), findsNothing);
    expect(find.text('내 정보'), findsNothing);

    // 라벨이 시각적으로 숨어도 세 탭 모두 스크린리더 라벨로 존재한다.
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('홈'), findsOneWidget);
    expect(find.bySemanticsLabel('기록'), findsOneWidget);
    expect(find.bySemanticsLabel('내 정보'), findsOneWidget);
    handle.dispose();

    // 비활성 아이콘(기록)을 탭하면 활성 라벨이 '기록'으로 모핑되고 예외가 없다.
    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();

    expect(find.text('기록'), findsOneWidget);
    expect(find.text('홈'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
