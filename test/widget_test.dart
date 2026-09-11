import 'package:agawaeuleo/presentation/features/home/home_screen.dart';
import 'package:agawaeuleo/presentation/widgets/navigation/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'features/_app_harness.dart';

void main() {
  testWidgets('앱 부팅 후 하단 먹 캡슐로 탭을 전환해도 크래시가 없다', (tester) async {
    // 스플래시(→홈 고정) 부팅 후 홈 셸에 도달한다.
    await pumpBootedApp(tester);

    // 하단 먹 캡슐 — 기록 탭은 발주자 요청으로 숨김, 탭은 홈·내 정보 두 개다.
    final nav = find.byType(AppBottomNav);
    expect(nav, findsOneWidget);
    expect(find.descendant(of: nav, matching: find.text('홈')), findsWidgets);
    expect(find.descendant(of: nav, matching: find.text('내 정보')), findsWidgets);
    expect(
      find.descendant(
        of: nav,
        matching: find.byIcon(Icons.assignment_outlined),
      ),
      findsNothing,
    );

    // 내 정보 → 홈 순서로 전환한다.
    await tester.tap(find.bySemanticsLabel('내 정보'));
    await tester.pumpAndSettle();
    // 내 정보 탭에서도 기록 관련 메뉴(아기 프로필)는 보이지 않는다.
    expect(find.text('즐겨찾기'), findsOneWidget);
    expect(find.text('아기 프로필'), findsNothing);

    await tester.tap(find.bySemanticsLabel('홈'));
    await tester.pumpAndSettle();
    expect(find.byType(HomeScreen), findsOneWidget);

    expect(tester.takeException(), isNull);

    await disposeApp(tester);
  });
}
