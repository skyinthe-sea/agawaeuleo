import 'package:agawaeuleo/presentation/widgets/navigation/app_bottom_nav.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/_app_harness.dart';

void main() {
  testWidgets('앱 부팅 후 하단 탭 3개(홈/기록/내 정보) 전환이 크래시 없이 동작한다', (tester) async {
    // 스플래시(→홈 고정) 부팅 후 홈 셸에 도달한다.
    await pumpBootedApp(tester);

    // 하단 탭바가 렌더링되고 3개 라벨이 존재한다.
    final nav = find.byType(AppBottomNav);
    expect(nav, findsOneWidget);
    expect(find.descendant(of: nav, matching: find.text('홈')), findsOneWidget);
    expect(find.descendant(of: nav, matching: find.text('기록')), findsOneWidget);
    expect(
      find.descendant(of: nav, matching: find.text('내 정보')),
      findsOneWidget,
    );

    // 기록 탭 → 내 정보 탭 → 홈 탭 순서로 전환한다.
    await tester.tap(find.descendant(of: nav, matching: find.text('기록')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: nav, matching: find.text('내 정보')));
    await tester.pumpAndSettle();
    await tester.tap(find.descendant(of: nav, matching: find.text('홈')));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    await disposeApp(tester);
  });
}
