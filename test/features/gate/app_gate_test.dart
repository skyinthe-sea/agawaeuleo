import 'package:agawaeuleo/application/gate/app_gate_provider.dart';
import 'package:agawaeuleo/presentation/features/onboarding/splash_screen.dart';
import 'package:agawaeuleo/presentation/features/onboarding/state/splash_boot_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../_app_harness.dart';

void main() {
  group('§3.3 앱 게이트', () {
    testWidgets('점검 모드(maintenance=true)면 스플래시가 점검 화면으로 잠근다', (tester) async {
      SharedPreferences.setMockInitialValues(<String, Object>{});
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            // 원격 config가 점검 모드를 내려준 상황을 재현한다.
            appGateProvider.overrideWith(
              (ref) async => const AppGateResult(
                AppGateStatus.maintenance,
                maintenanceMessage: '서버 정비 중이에요',
              ),
            ),
            // 게이트 로딩 첫 프레임에 실 부팅(익명 세션·600ms 최소표시 타이머)이 돌지
            // 않도록 목적지를 즉시 반환한다(테스트 pending timer 방지).
            splashBootProvider.overrideWith(
              (ref) async => SplashDestination.home,
            ),
          ],
          child: withReduceMotion(
            tester,
            const MaterialApp(home: SplashScreen()),
          ),
        ),
      );
      // 게이트 Future가 해소되며 인라인 점검 화면으로 전환된다(라우팅 없음).
      await tester.pump();
      await tester.pumpAndSettle();

      expect(find.text('잠깐 점검 중이에요'), findsOneWidget);
      expect(find.text('서버 정비 중이에요'), findsOneWidget);
      expect(find.text('다시 시도'), findsOneWidget);

      // 트리를 언마운트해 ProviderScope를 정리한다.
      await tester.pumpWidget(const SizedBox.shrink());
    });
  });
}
