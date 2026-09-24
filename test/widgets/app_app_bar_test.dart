import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/widgets/navigation/app_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

/// 상단바 표면(가장 바깥 DecoratedBox)의 데코레이션.
BoxDecoration _barDecoration(WidgetTester tester) =>
    tester
            .widget<DecoratedBox>(
              find
                  .descendant(
                    of: find.byType(AppAppBar),
                    matching: find.byType(DecoratedBox),
                  )
                  .first,
            )
            .decoration
        as BoxDecoration;

void main() {
  testWidgets('DESIGN v3: 평상시엔 크림 바탕(paperBg)에 헤어라인·그림자 없이 화면에 녹아든다', (
    tester,
  ) async {
    await pumpWidgetWithTheme(tester, const AppAppBar(title: '홈'));

    final decoration = _barDecoration(tester);
    expect(decoration.color, AppColors.light.paperBg);
    expect(decoration.border, isNull);
    expect(decoration.boxShadow, isNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('scrolled: true면 장밋빛 음영(e2)이 올라 떠 보인다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const AppAppBar(title: '홈', scrolled: true),
    );

    expect(_barDecoration(tester).boxShadow, AppShadows.light.e2);
  });

  testWidgets('subtitle 슬롯이 title 아래에 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const AppAppBar(title: '증상 상세', subtitle: '이앓이'),
    );

    expect(find.text('증상 상세'), findsOneWidget);
    expect(find.text('이앓이'), findsOneWidget);
  });

  testWidgets('뒤로가기 버블은 시맨틱 버튼으로 노출되고 탭 시 onBack을 부른다', (tester) async {
    var backs = 0;
    await pumpWidgetWithTheme(
      tester,
      AppAppBar(title: '설정', showBack: true, onBack: () => backs++),
    );

    final handle = tester.ensureSemantics();
    final label = MaterialLocalizations.of(
      tester.element(find.byType(AppAppBar)),
    ).backButtonTooltip;
    expect(find.bySemanticsLabel(label), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();

    expect(backs, 1);
    handle.dispose();
    expect(tester.takeException(), isNull);
  });
}
