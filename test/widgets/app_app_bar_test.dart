import 'package:agawaeuleo/presentation/widgets/navigation/app_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('scrolled: false에도 하단 헤어라인이 상시 표시된다(§5.2)', (tester) async {
    await pumpWidgetWithTheme(tester, const AppAppBar(title: '홈'));

    final decoratedBox = tester.widget<DecoratedBox>(
      find.byType(DecoratedBox).first,
    );
    final decoration = decoratedBox.decoration as BoxDecoration;
    expect(decoration.border, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('subtitle 슬롯이 title 아래에 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const AppAppBar(title: '증상 상세', subtitle: '이앓이'),
    );

    expect(find.text('증상 상세'), findsOneWidget);
    expect(find.text('이앓이'), findsOneWidget);
  });
}
