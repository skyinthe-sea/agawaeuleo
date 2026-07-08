import 'package:agawaeuleo/main.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:agawaeuleo/presentation/widgets/navigation/app_bottom_nav.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    // 테마 모드 복원용 저장소를 빈 상태로 목킹(기본값 = 시스템).
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  testWidgets('앱 부팅 후 하단 탭 3개(홈/기록/내 정보) 전환이 크래시 없이 동작한다', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgawaeuleoApp()));
    await tester.pumpAndSettle();

    // 초기 라우트는 스플래시.
    expect(find.text('스플래시'), findsOneWidget);

    // 홈 셸(하단 탭)로 진입.
    GoRouter.of(tester.element(find.text('스플래시'))).goNamed(Routes.home);
    await tester.pumpAndSettle();

    // 하단 탭바가 렌더링되고 3개 라벨이 존재한다.
    expect(find.byType(AppBottomNav), findsOneWidget);
    final nav = find.byType(AppBottomNav);
    expect(find.descendant(of: nav, matching: find.text('홈')), findsOneWidget);
    expect(find.descendant(of: nav, matching: find.text('기록')), findsOneWidget);
    expect(
      find.descendant(of: nav, matching: find.text('내 정보')),
      findsOneWidget,
    );

    // 기록 탭 → 내 정보 탭 → 홈 탭 순서로 전환(각 화면 본문 텍스트로 확인).
    await tester.tap(find.descendant(of: nav, matching: find.text('기록')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Scaffold, '기록'), findsWidgets);

    await tester.tap(find.descendant(of: nav, matching: find.text('내 정보')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Scaffold, '내 정보'), findsWidgets);

    await tester.tap(find.descendant(of: nav, matching: find.text('홈')));
    await tester.pumpAndSettle();
    expect(find.widgetWithText(Scaffold, '홈'), findsWidgets);

    // 예외 없이 여기 도달하면 스모크 통과.
    expect(tester.takeException(), isNull);
  });
}
