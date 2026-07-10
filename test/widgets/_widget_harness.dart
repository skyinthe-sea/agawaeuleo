import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// `test/widgets/` 스모크 테스트 공용 하네스. 실제 앱 프로바이더 없이 테마 확장
/// (`AppColors`/`AppShadows`)만 배선한 최소 `MaterialApp`으로 위젯을 띄운다.
///
/// (`test/features/_app_harness.dart`의 `withReduceMotion`과 동일 패턴 —
/// `MaterialApp`은 조상 `MediaQuery`가 있으면 그대로 재사용한다.)
Future<void> pumpWidgetWithTheme(
  WidgetTester tester,
  Widget child, {
  bool dark = false,
  bool reduceMotion = false,
  bool highContrast = false,
}) async {
  final data = MediaQueryData.fromView(
    tester.view,
  ).copyWith(disableAnimations: reduceMotion, highContrast: highContrast);
  await tester.pumpWidget(
    MediaQuery(
      data: data,
      child: MaterialApp(
        theme: dark ? AppTheme.dark() : AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    ),
  );
}
