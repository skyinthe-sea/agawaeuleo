import 'package:agawaeuleo/presentation/widgets/brand/ink_halo_icon.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('icon 지정 시 아이콘과 링이 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const InkHaloIcon(size: 56, icon: Icons.favorite),
    );

    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('ring: false면 바깥 링 컨테이너를 추가하지 않는다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const InkHaloIcon(size: 40, icon: Icons.star, ring: false),
    );

    expect(find.byIcon(Icons.star), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('child 지정 시 icon 대신 child가 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const InkHaloIcon(size: 64, child: Text('LOGO')),
    );

    expect(find.text('LOGO'), findsOneWidget);
    expect(find.byType(Icon), findsNothing);
  });

  testWidgets('animate: true 등장 모션이 예외 없이 완료된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const InkHaloIcon(size: 96, icon: Icons.check, animate: true),
    );
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('elevated: true여도 크래시 없이 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const InkHaloIcon(size: 44, icon: Icons.info_outline, elevated: true),
    );

    expect(tester.takeException(), isNull);
  });
}
