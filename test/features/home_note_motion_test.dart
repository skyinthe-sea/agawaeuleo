import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/deck_scene.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/home_search_bar.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/note_chapters.dart';
import 'package:agawaeuleo/presentation/router/app_router.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 모션을 켠 상태의 스모크 — 홈 덱 등장·넘기기 힌트·검색 타이핑, 케어 노트 장 넘김이
/// 예외 없이 돌고, 화면을 내리면 타이머·티커가 남지 않는다.
///
/// 공용 하네스는 reduce-motion을 강제하므로(무한 반복 모션 때문에) 여기서는 직접
/// 부팅하고 `pumpAndSettle` 대신 시간을 잘라 진행한다.
void main() {
  Future<void> advance(WidgetTester tester, Duration total) async {
    const step = Duration(milliseconds: 50);
    var elapsed = Duration.zero;
    while (elapsed < total) {
      await tester.pump(step);
      elapsed += step;
    }
  }

  Future<GoRouter> boot(WidgetTester tester) async {
    SharedPreferences.setMockInitialValues(<String, Object>{});
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    final router = createAppRouter();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appDatabaseProvider.overrideWith((ref) {
            final db = AppDatabase.inMemory();
            ref.onDispose(db.close);
            return db;
          }),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await advance(tester, const Duration(milliseconds: 1500));
    router.go(RoutePaths.home);
    return router;
  }

  testWidgets('홈 덱: 등장 → 넘기기 힌트 → 타이핑 힌트 → 손 스와이프가 예외 없이 이어진다', (tester) async {
    await boot(tester);
    // 등장(900ms) + 넘기기 힌트(1.1s) + 첫 타이핑 일부.
    await advance(tester, const Duration(milliseconds: 2600));

    expect(
      find.descendant(of: find.byType(DeckScene), matching: find.text('배앓이')),
      findsOneWidget,
    );
    // 타이핑 힌트가 도는 중에는 정적 안내 문구 대신 조합 중인 글자가 보인다.
    expect(find.text(HomeSearchBar.restingHint), findsNothing);

    await tester.fling(
      find.byType(DeckScene).first,
      const Offset(-300, 0),
      1200,
    );
    await advance(tester, const Duration(seconds: 1));
    expect(
      find.descendant(of: find.byType(DeckScene), matching: find.text('이앓이')),
      findsOneWidget,
    );

    // 타이핑 한 바퀴가 끝나면 정적 안내 문구로 쉰다.
    await advance(tester, const Duration(seconds: 14));
    expect(find.text(HomeSearchBar.restingHint), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await advance(tester, const Duration(seconds: 1));
  });

  testWidgets('케어 노트: 장을 넘기며 대기 장의 등장 모션이 화면에 들어올 때 재생된다', (tester) async {
    final router = await boot(tester);
    await advance(tester, const Duration(seconds: 3));
    router.pushNamed(
      Routes.symptomDetail,
      pathParameters: {RouteParams.slug: 'colic'},
    );
    await advance(tester, const Duration(seconds: 1));

    await tester.fling(find.text('한눈에 보기'), const Offset(-300, 0), 1200);
    await advance(tester, const Duration(seconds: 1));
    expect(find.text('가까운 병원 찾기'), findsOneWidget);

    await tester.fling(find.text('이럴 땐 병원에'), const Offset(0, -900), 1500);
    await advance(tester, const Duration(seconds: 2));
    await tester.tap(find.byType(NoteNextCard).hitTestable());
    await advance(tester, const Duration(seconds: 1));
    expect(find.text('집에서 돌보는 법'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await advance(tester, const Duration(seconds: 1));
  });
}
