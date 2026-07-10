import 'package:agawaeuleo/presentation/widgets/headers/section_header.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('title만 지정 시 overline 없이 렌더된다', (tester) async {
    await pumpWidgetWithTheme(tester, const SectionHeader(title: '섹션 제목'));

    expect(find.text('섹션 제목'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('overline·trailing이 함께 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const SectionHeader(
        title: '즐겨찾기',
        overline: '모아보기',
        trailing: Text('3개'),
      ),
    );

    expect(find.text('모아보기'), findsOneWidget);
    expect(find.text('즐겨찾기'), findsOneWidget);
    expect(find.text('3개'), findsOneWidget);
  });
}
