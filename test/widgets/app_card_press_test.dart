import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

/// 눌림 시각(scale .96)의 타깃 값을 카드별로 읽는다.
/// AppCard는 탭 가능 시 자식을 [AnimatedScale]로 감싸며, `scale`은 `_pressed`를
/// 즉시 반영하는 "목표 값"이라 애니메이션 보간과 무관하게 눌림 여부를 판별한다.
double _scaleOf(WidgetTester tester, String label) => tester
    .widget<AnimatedScale>(
      find.ancestor(of: find.text(label), matching: find.byType(AnimatedScale)),
    )
    .scale;

void main() {
  testWidgets('누른 채 스크롤하면 눌림이 고착되지 않고(scale 복귀) 탭도 발생하지 않는다', (tester) async {
    var taps = 0;
    await pumpWidgetWithTheme(
      tester,
      ListView(
        children: [
          for (var i = 0; i < 12; i++)
            SizedBox(
              height: 120,
              child: AppCard(onTap: () => taps++, child: Text('card-$i')),
            ),
        ],
      ),
    );

    // 카드를 눌러 눌림 활성(scale < 1.0)까지 유도한다. 스크롤 조상이 있으면
    // 탭 인식기는 kPressTimeout(100ms) 뒤에야 onTapDown → 눌림을 켜므로 그 이상
    // 대기한다.
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('card-0')),
    );
    await tester.pump(const Duration(milliseconds: 150));
    expect(_scaleOf(tester, 'card-0'), lessThan(1.0));

    // 누른 채 세로 스크롤 — 터치 슬롭을 넘겨 부모 ListView가 제스처를 가져간다.
    // (card-0은 화면에 남을 만큼만 이동해 조회 가능 상태 유지.)
    await gesture.moveBy(const Offset(0, -40));
    await tester.pump();
    // 손을 떼기 전, 드래그가 슬롭을 넘긴 시점에 이미 눌림이 풀려야 한다
    // (Listener.onPointerMove 경로 — 스크롤 시작 즉시 해제).
    expect(_scaleOf(tester, 'card-0'), 1.0);

    await gesture.up();
    await tester.pumpAndSettle();

    // 손을 뗀 뒤에도 눌림은 풀린 채이고(고착 없음), 스크롤이므로 탭 콜백은 없다.
    expect(_scaleOf(tester, 'card-0'), 1.0);
    expect(taps, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('정상 탭은 그대로 콜백되고 눌림도 해제된다(회귀 방지)', (tester) async {
    var taps = 0;
    await pumpWidgetWithTheme(
      tester,
      SizedBox(
        height: 120,
        child: AppCard(onTap: () => taps++, child: const Text('tap-card')),
      ),
    );

    await tester.tap(find.text('tap-card'));
    await tester.pumpAndSettle();

    expect(taps, 1);
    expect(_scaleOf(tester, 'tap-card'), 1.0);
    expect(tester.takeException(), isNull);
  });
}
