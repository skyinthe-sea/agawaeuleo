import 'package:agawaeuleo/presentation/widgets/navigation/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('탭바가 3개 라벨과 함께 렌더되고 예외 없이 탭 전환된다', (tester) async {
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

    expect(find.text('홈'), findsOneWidget);
    expect(find.text('기록'), findsOneWidget);
    expect(find.text('내 정보'), findsOneWidget);

    await tester.tap(find.text('기록'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
