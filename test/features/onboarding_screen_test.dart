import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/features/onboarding/data/onboarding_prefs.dart';
import 'package:agawaeuleo/presentation/features/onboarding/onboarding_screen.dart';
import 'package:agawaeuleo/presentation/features/onboarding/widgets/onboarding_float_cards.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:agawaeuleo/presentation/widgets/brand/ink_seal.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 온보딩 단독 라우터 — 종료 동작이 홈으로 가는지만 본다.
GoRouter _router() => GoRouter(
  initialLocation: RoutePaths.onboarding,
  routes: [
    GoRoute(
      path: RoutePaths.onboarding,
      name: Routes.onboarding,
      builder: (context, state) => const OnboardingScreen(),
    ),
    GoRoute(
      path: RoutePaths.home,
      name: Routes.home,
      builder: (context, state) => const Scaffold(body: Text('HOME')),
    ),
  ],
);

Future<void> _pumpOnboarding(
  WidgetTester tester, {
  bool reduceMotion = true,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  tester.view
    ..physicalSize = const Size(1206, 2622)
    ..devicePixelRatio = 3;
  addTearDown(tester.view.reset);
  final data = MediaQueryData.fromView(
    tester.view,
  ).copyWith(disableAnimations: reduceMotion);
  await tester.pumpWidget(
    MediaQuery(
      data: data,
      child: MaterialApp.router(
        theme: AppTheme.light(),
        routerConfig: _router(),
      ),
    ),
  );
  await tester.pump();
}

void main() {
  testWidgets('첫 장: 제목 두 줄·다음·건너뛰기가 보이고 낙관 도장은 없다', (tester) async {
    await _pumpOnboarding(tester);

    expect(find.text('아기가 왜 우는지'), findsOneWidget);
    expect(find.text('바로 찾아봐요'), findsOneWidget);
    expect(find.text('다음'), findsOneWidget);
    expect(find.text('건너뛰기'), findsOneWidget);
    expect(find.byType(InkSeal), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('다음을 두 번 누르면 마지막 장에서 시작하기 → 완료 저장 후 홈', (tester) async {
    await _pumpOnboarding(tester);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('지금 필요한 용품만'), findsOneWidget);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    expect(find.text('미리 알아 두세요'), findsOneWidget);
    expect(find.text('시작하기'), findsOneWidget);

    // 마지막 장의 건너뛰기는 CTA와 같은 동작이라 숨기고 탭도 막는다.
    await tester.tap(find.text('건너뛰기'), warnIfMissed: false);
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsNothing);

    await tester.tap(find.text('시작하기'));
    await tester.pumpAndSettle();
    expect(find.text('HOME'), findsOneWidget);
    expect(await OnboardingPrefs.isDone(), isTrue);
  });

  testWidgets('건너뛰기는 곧장 홈으로 가고 완료를 저장한다', (tester) async {
    await _pumpOnboarding(tester);

    await tester.tap(find.text('건너뛰기'));
    await tester.pumpAndSettle();

    expect(find.text('HOME'), findsOneWidget);
    expect(await OnboardingPrefs.isDone(), isTrue);
  });

  testWidgets('스와이프로 다음 장으로 넘어간다', (tester) async {
    await _pumpOnboarding(tester);

    await tester.drag(find.byType(PageView), const Offset(-300, 0));
    await tester.pumpAndSettle();

    expect(find.text('맞춤 육아용품'), findsOneWidget);
    expect(find.text('아기가 왜 우는지'), findsNothing);
  });

  testWidgets('마지막 장은 기록이 아니라 병원 신호를 소개한다', (tester) async {
    await _pumpOnboarding(tester);

    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('다음'));
    await tester.pumpAndSettle();

    expect(find.text('병원 신호'), findsWidgets);
    expect(find.text('이럴 땐 병원에'), findsWidgets);
    expect(find.byType(OnboardingSignalCard), findsOneWidget);
    expect(find.textContaining('기록'), findsNothing);
  });

  testWidgets('모션 켠 상태: 타이핑·신호 연출이 돌고 해제 시 타이머가 남지 않는다', (tester) async {
    await _pumpOnboarding(tester, reduceMotion: false);

    // 첫 진입 대기 + 자모 8타가 끝나면 검색어가 완성된다.
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 1800));
    expect(find.text('배앓이'), findsWidgets);

    final controller = tester
        .widget<PageView>(find.byType(PageView))
        .controller!;
    controller.jumpToPage(2);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 1200));
    expect(find.text('가까운 병원 찾기'), findsOneWidget);
    expect(find.byType(OnboardingAlertChip), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 2));
    expect(tester.takeException(), isNull);
  });
}
