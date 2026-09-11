import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/care_note.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/note_chapters.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:agawaeuleo/presentation/widgets/brand/ink_halo_icon.dart';
import 'package:agawaeuleo/presentation/widgets/dividers/brush_divider.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_app_harness.dart';

/// §11.9 증상 상세 케어 노트(2026-09-11 개편) — 법적 문구·Hero 계약·장 넘김.
void main() {
  void usePhoneView(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Future<void> openColic(WidgetTester tester, {String? chapter}) async {
    usePhoneView(tester);
    final router = await pumpBootedApp(tester);
    router.pushNamed(
      Routes.symptomDetail,
      pathParameters: {RouteParams.slug: 'colic'},
      queryParameters: {RouteParams.chapter: ?chapter},
    );
    await tester.pumpAndSettle();
  }

  testWidgets('면책(§13.3)은 첫 장에, 대가성 표시(§13.2)는 추천 용품 장에 있다', (tester) async {
    await openColic(tester);

    expect(find.byType(CareNote), findsOneWidget);
    expect(find.textContaining('의학적 진단이 아니며'), findsOneWidget);
    expect(find.text('쿠팡 파트너스 활동으로 수수료를 받습니다'), findsNothing);

    await tester.tap(find.bySemanticsLabel('추천 용품 3개'));
    await tester.pumpAndSettle();

    expect(find.text('쿠팡 파트너스 활동으로 수수료를 받습니다'), findsOneWidget);
    // 제품 장 끝에도 면책이 붙는다(모든 장 공통).
    expect(find.textContaining('의학적 진단이 아니며'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('Hero 태그 유지 + 머리 일러스트(colic)·붓결 디바이더, 제품 장의 개수·1위 배지', (
    tester,
  ) async {
    await openColic(tester);

    // §7.3-1 / §9 가드레일 — Hero 태그 계약(symptom-icon-<id>/symptom-name-<id>) 유지.
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Hero &&
            widget.tag == 'symptom-icon-fixture-symptom-colic',
      ),
      findsOneWidget,
    );
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is Hero &&
            widget.tag == 'symptom-name-fixture-symptom-colic',
      ),
      findsOneWidget,
    );
    // 일러스트 등록 증상은 홈 덱과 같은 일러스트가 머리 무대에 착지한다.
    expect(find.byType(SymptomIllustration), findsOneWidget);
    expect(find.byType(InkHaloIcon), findsNothing);
    // 요약 → 목차 사이 격 전환점.
    expect(find.byType(BrushDivider), findsOneWidget);
    expect(find.text('이 노트에 담긴 것'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('추천 용품 3개'));
    await tester.pumpAndSettle();

    expect(find.text('3개'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('옆으로 넘기면 병원 신호, NEXT 카드로 돌보는 법, 목차로 원하는 장', (tester) async {
    await openColic(tester);

    await tester.fling(find.text('한눈에 보기'), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('이럴 땐 병원에'), findsOneWidget);
    expect(find.text('가까운 병원 찾기'), findsOneWidget);

    // 장 끝까지 내려 NEXT 카드로 다음 장.
    await tester.drag(find.text('이럴 땐 병원에'), const Offset(0, -700));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(NoteNextCard).hitTestable());
    await tester.pumpAndSettle();
    expect(find.text('집에서 돌보는 법'), findsOneWidget);

    // 탭으로 요약에 돌아가 목차에서 추천 용품으로.
    await tester.tap(find.bySemanticsLabel('요약'));
    await tester.pumpAndSettle();
    await tester.drag(find.text('한눈에 보기'), const Offset(0, -500));
    await tester.pumpAndSettle();
    await tester.tap(find.bySemanticsLabel(RegExp('^추천 용품, ')));
    await tester.pumpAndSettle();
    expect(find.text('이럴 때 도움되는 용품'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('?chapter=products 로 열면 추천 용품 장부터 보인다', (tester) async {
    await openColic(tester, chapter: 'products');

    expect(find.text('쿠팡 파트너스 활동으로 수수료를 받습니다'), findsOneWidget);
    expect(find.text('이 노트에 담긴 것'), findsNothing);

    await disposeApp(tester);
  });
}
