import 'package:agawaeuleo/presentation/features/tracking/tracking_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_app_harness.dart';

void main() {
  testWidgets('빠른 기록(수유) → 저장 → 오늘 타임라인에 항목이 남는다', (tester) async {
    await pumpScreen(tester, const TrackingScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 처음엔 오늘 기록이 없다.
    expect(find.text('아직 오늘 기록이 없어요'), findsOneWidget);

    // 빠른 기록 '수유' 알약 탭(요약 밴드 라벨과 겹치므로 마지막 = 알약).
    await tester.tap(find.text('수유').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 시트가 열리고 저장(직접 입력 분유 기본).
    expect(find.text('저장'), findsOneWidget);
    await tester.tap(find.text('저장'));
    await tester.pump();
    // 저장 완료 뷰는 720ms 후 시트를 닫는다(§11.11) — pumpAndSettle이 건너뛰는
    // Future.delayed 타이머를 명시적으로 소진해야 pending timer 없이 시트가 닫힌다.
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pumpAndSettle();

    // 타임라인에 기록 타일(Dismissible)이 생기고 빈 상태 문구는 사라진다.
    expect(find.byType(Dismissible), findsAtLeastNWidgets(1));
    expect(find.text('아직 오늘 기록이 없어요'), findsNothing);

    await disposeApp(tester);
  });

  testWidgets('수면 타이머 시작 → 진행 중 배지 → 종료', (tester) async {
    await pumpScreen(tester, const TrackingScreen());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // 빠른 기록 '수면' 알약 탭 → 시트(수면 타이머 기본).
    await tester.tap(find.text('수면').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    // 타이머 시작.
    expect(find.text('잠들었어요'), findsOneWidget);
    await tester.tap(find.text('잠들었어요'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.pump(const Duration(seconds: 1));

    // 진행 중 배지가 노출된다(§11.11).
    expect(find.textContaining('진행 중'), findsWidgets);

    // 배지 탭 → 종료 시트 → '깼어요'.
    await tester.tap(find.textContaining('진행 중').first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('깼어요'), findsOneWidget);

    await tester.tap(find.text('깼어요'));
    await tester.pump();
    await tester.pump(
      const Duration(milliseconds: 900),
    ); // stop + 완료뷰 720ms + pop
    await tester.pump(const Duration(seconds: 1));

    // 종료 후 진행 중 상태가 사라진다.
    expect(find.textContaining('진행 중'), findsNothing);

    await disposeApp(tester);
  });
}
