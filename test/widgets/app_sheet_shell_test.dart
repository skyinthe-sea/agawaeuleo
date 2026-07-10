import 'package:agawaeuleo/presentation/widgets/sheets/app_sheet_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('title·trailing·child·그래버가 모두 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const AppSheetShell(
        title: '기록 추가',
        trailing: Icon(Icons.close),
        child: Text('시트 본문'),
      ),
    );

    expect(find.text('기록 추가'), findsOneWidget);
    expect(find.byIcon(Icons.close), findsOneWidget);
    expect(find.text('시트 본문'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('title 미지정 시 헤더 행 없이 child만 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const AppSheetShell(showGrabber: false, child: Text('본문만')),
    );

    expect(find.text('본문만'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
