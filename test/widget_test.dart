import 'package:agawaeuleo/presentation/widgets/navigation/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/_app_harness.dart';

void main() {
  testWidgets('앱 부팅 후 하단 탭을 아이콘으로 전환하면 활성 라벨만 모핑되고 크래시가 없다', (tester) async {
    // 스플래시(→홈 고정) 부팅 후 홈 셸에 도달한다.
    await pumpBootedApp(tester);

    // 하단 탭바가 렌더링되고, 활성 탭(홈) 라벨만 시각적으로 보인다(비활성은 아이콘 단독).
    final nav = find.byType(AppBottomNav);
    expect(nav, findsOneWidget);
    expect(find.descendant(of: nav, matching: find.text('홈')), findsOneWidget);
    expect(find.descendant(of: nav, matching: find.text('기록')), findsNothing);
    expect(find.descendant(of: nav, matching: find.text('내 정보')), findsNothing);

    // 라벨 텍스트 대신 비활성 아이콘을 탭해 기록 → 내 정보 → 홈 순서로 전환한다.
    await tester.tap(
      find.descendant(
        of: nav,
        matching: find.byIcon(Icons.assignment_outlined),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.descendant(of: nav, matching: find.text('기록')), findsOneWidget);

    await tester.tap(
      find.descendant(of: nav, matching: find.byIcon(Icons.person_outline)),
    );
    await tester.pumpAndSettle();
    expect(
      find.descendant(of: nav, matching: find.text('내 정보')),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: nav, matching: find.byIcon(Icons.home_outlined)),
    );
    await tester.pumpAndSettle();
    expect(find.descendant(of: nav, matching: find.text('홈')), findsOneWidget);

    expect(tester.takeException(), isNull);

    await disposeApp(tester);
  });
}
