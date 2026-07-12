import 'package:agawaeuleo/presentation/features/home/widgets/home_greeting_bar.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/_widget_harness.dart';

/// §7.1-1(확장) 홈 인사 바 — "오늘의 응원" 세 번째 단 렌더 검증.
void main() {
  testWidgets('dailyMessage가 있으면 인사 아래에 응원 문구를 함께 렌더한다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      HomeGreetingBar(
        greeting: '오늘도 힘내세요',
        dailyMessage: '오늘도 애쓰는 당신, 참 대단해요',
        onMenuTap: () {},
      ),
    );

    expect(find.text('오늘도 힘내세요'), findsOneWidget);
    expect(find.text('오늘도 애쓰는 당신, 참 대단해요'), findsOneWidget);
  });

  testWidgets('dailyMessage가 없으면 응원 줄 없이 기존 2단으로 폴백한다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      HomeGreetingBar(greeting: '민준', onMenuTap: () {}),
    );

    expect(find.text('민준'), findsOneWidget);
    expect(find.text('오늘도 애쓰는 당신, 참 대단해요'), findsNothing);
  });

  testWidgets('공백만 있는 dailyMessage는 렌더하지 않는다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      HomeGreetingBar(
        greeting: '오늘도 힘내세요',
        dailyMessage: '   ',
        onMenuTap: () {},
      ),
    );

    expect(find.text('   '), findsNothing);
  });
}
