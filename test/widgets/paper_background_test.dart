import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('기본 상태는 그레인 Stack과 child를 함께 렌더한다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const PaperBackground(child: Text('content')),
    );

    expect(find.text('content'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PaperBackground),
        matching: find.byType(Stack),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('highContrast 시 그레인 없이 child만 반환한다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const PaperBackground(child: Text('content')),
      highContrast: true,
    );

    expect(find.text('content'), findsOneWidget);
    expect(
      find.descendant(
        of: find.byType(PaperBackground),
        matching: find.byType(Stack),
      ),
      findsNothing,
    );
  });
}
