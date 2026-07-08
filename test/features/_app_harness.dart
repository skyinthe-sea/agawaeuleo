import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/data/local/local.dart';
import 'package:agawaeuleo/presentation/router/app_router.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// M3+M4 통합 위젯 테스트 공용 하네스.
///
/// - `appDatabaseProvider`를 파일 DB 대신 인메모리 Drift로 오버라이드(테스트 환경엔
///   path_provider가 없어 실제 파일 DB를 열 수 없다). Supabase 미구성이라 마스터
///   데이터는 픽스처가 자동 공급된다.
/// - reduce-motion을 강제(`disableAnimations: true`)해 shimmer/stagger 등 무한/장시간
///   애니메이션으로 `pumpAndSettle`이 멈추지 않게 한다.
ProviderScope _scoped({required Widget child}) => ProviderScope(
  overrides: [
    appDatabaseProvider.overrideWith((ref) {
      final db = AppDatabase.inMemory();
      ref.onDispose(db.close);
      return db;
    }),
  ],
  child: child,
);

/// reduce-motion을 강제하는 MediaQuery로 [child]를 감싼다.
/// (WidgetsApp은 조상 MediaQuery가 있으면 그대로 재사용한다.)
Widget withReduceMotion(WidgetTester tester, Widget child) {
  final data = MediaQueryData.fromView(
    tester.view,
  ).copyWith(disableAnimations: true);
  return MediaQuery(data: data, child: child);
}

/// 테스트 종료 전 트리를 언마운트해 `ProviderScope`(→ `appDatabaseProvider.onDispose`)를
/// 정리한다. drift 인메모리 DB의 스트림 갱신 타이머가 `db.close()`로 취소되지 않으면
/// 테스트 **본문 마지막**에서 호출해 트리를 언마운트한다.
///
/// `ProviderScope`가 사라지며 `appDatabaseProvider.onDispose(db.close)`가 실행되어
/// drift 인메모리 DB의 스트림 갱신 타이머가 취소된다. 이를 하지 않으면 teardown 시
/// "A Timer is still pending" 로 실패한다. (`addTearDown`은 이 검사 이후에 실행되어
/// 늦으므로 본문에서 직접 언마운트해야 한다.)
Future<void> disposeApp(WidgetTester tester) async {
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump(const Duration(milliseconds: 100));
}

/// 실제 go_router로 앱을 부팅해 홈까지 도달시킨다(홈/검색/상세 내비 이음새 검증용).
Future<GoRouter> pumpBootedApp(WidgetTester tester) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  final router = createAppRouter();
  await tester.pumpWidget(
    withReduceMotion(
      tester,
      _scoped(child: MaterialApp.router(routerConfig: router)),
    ),
  );
  // §11.1 스플래시는 최소 노출 600ms(Future.delayed) 후 목적지로 분기한다. 대기 중인
  // 타이머는 프레임을 스케줄하지 않아 pumpAndSettle이 건너뛰므로, 명시적으로 시간을
  // 진행시켜 부팅 타이머를 소진(→ 테스트 종료 시 pending timer 방지)한다.
  await tester.pump(const Duration(milliseconds: 800));
  await tester.pumpAndSettle();
  // 스플래시 분기 결과와 무관하게 검증 대상인 홈 셸로 이동한다.
  router.go(RoutePaths.home);
  await tester.pumpAndSettle();
  return router;
}

/// 단일 화면([screen])을 최소 MaterialApp으로 띄운다(모달 시트/Scaffold 자체 보유 화면용).
Future<void> pumpScreen(WidgetTester tester, Widget screen) async {
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await tester.pumpWidget(
    withReduceMotion(tester, _scoped(child: MaterialApp(home: screen))),
  );
}
