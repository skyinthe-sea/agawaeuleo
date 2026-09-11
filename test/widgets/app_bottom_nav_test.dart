import 'package:agawaeuleo/presentation/widgets/navigation/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('먹 캡슐: 두 탭(홈·내 정보) 라벨이 늘 보이고 선택이 시맨틱스에 반영된다', (tester) async {
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

    // 라벨은 바탕 겹 + 알약 안 겹(장식) 두 번 그려진다 — 둘 다 늘 보인다.
    expect(find.text('홈'), findsNWidgets(2));
    expect(find.text('내 정보'), findsNWidgets(2));

    // 스크린리더에는 탭마다 하나씩, 선택 상태와 함께 노출된다.
    // 기록 탭은 발주자 요청으로 숨김(주석) — 라벨 자체가 없어야 한다.
    final handle = tester.ensureSemantics();
    expect(find.bySemanticsLabel('홈'), findsOneWidget);
    expect(find.bySemanticsLabel('내 정보'), findsOneWidget);
    expect(find.bySemanticsLabel('기록'), findsNothing);
    expect(
      tester.getSemantics(find.bySemanticsLabel('홈')),
      isSemantics(isButton: true, isSelected: true),
    );

    // 내 정보를 누르면 먹 알약이 흘러가 선택이 옮겨지고 예외가 없다.
    await tester.tap(find.bySemanticsLabel('내 정보'));
    await tester.pumpAndSettle();

    expect(index, 1);
    expect(
      tester.getSemantics(find.bySemanticsLabel('내 정보')),
      isSemantics(isButton: true, isSelected: true),
    );
    handle.dispose();
    expect(tester.takeException(), isNull);
  });
}
