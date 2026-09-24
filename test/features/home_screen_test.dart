import 'package:agawaeuleo/presentation/features/home/widgets/deck/care_deck.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/deck_rail.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/deck_scene.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/home_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_app_harness.dart';

/// §11.7 홈 케어 덱(2026-09-11 개편) — 넘기기·레일 점프·상세 진입 이음새.
void main() {
  void usePhoneView(WidgetTester tester) {
    tester.view
      ..physicalSize = const Size(1206, 2622)
      ..devicePixelRatio = 3;
    addTearDown(tester.view.reset);
  }

  Finder sceneText(String text) =>
      find.descendant(of: find.byType(DeckScene), matching: find.text(text));

  testWidgets('덱 첫 장(배앓이)이 뜨고, 열기 버튼으로 증상 상세에 들어간다', (tester) async {
    usePhoneView(tester);
    await pumpBootedApp(tester);

    expect(find.byType(CareDeck), findsOneWidget);
    expect(find.byType(HomeSearchBar), findsOneWidget);
    expect(sceneText('배앓이'), findsOneWidget);
    expect(find.text('01'), findsWidgets);
    // 떠 있는 실데이터 조각 — 픽스처 배앓이 제품 3개와 1위 카드.
    expect(find.text('추천 용품'), findsOneWidget);
    expect(find.text('BEST PICK'), findsOneWidget);

    await tester.tap(find.bySemanticsLabel('배앓이 케어 노트 열기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('의학적 진단이 아니며'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('옆으로 넘기면 다음 증상, 레일 썸네일을 누르면 그 증상으로 건너뛴다', (tester) async {
    usePhoneView(tester);
    await pumpBootedApp(tester);

    await tester.fling(
      find.byType(DeckScene).first,
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(sceneText('이앓이'), findsOneWidget);
    expect(sceneText('배앓이'), findsNothing);

    final rail = find.byType(DeckRail);
    await tester.tap(find.descendant(of: rail, matching: find.text('트림 안 나옴')));
    await tester.pumpAndSettle();
    expect(sceneText('트림 안 나옴'), findsOneWidget);
    expect(find.text('05'), findsWidgets);

    await disposeApp(tester);
  });

  testWidgets('BEST PICK 카드를 누르면 상세의 추천 용품 장이 바로 열린다', (tester) async {
    usePhoneView(tester);
    await pumpBootedApp(tester);

    await tester.tap(find.text('BEST PICK'));
    await tester.pumpAndSettle();

    // §13.2 대가성 표시는 추천 용품 장의 목록 바로 위에 있다.
    expect(find.text('쿠팡 파트너스 활동으로 수수료를 받습니다'), findsOneWidget);
    expect(find.text('이럴 때 도움되는 용품'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('무대 칩 "추천 용품 N"을 눌러도 추천 용품 장이 바로 열린다', (tester) async {
    usePhoneView(tester);
    await pumpBootedApp(tester);

    await tester.tap(find.bySemanticsLabel('배앓이 추천 용품 3개 보기'));
    await tester.pumpAndSettle();

    expect(find.text('쿠팡 파트너스 활동으로 수수료를 받습니다'), findsOneWidget);
    expect(find.text('이럴 때 도움되는 용품'), findsOneWidget);

    await disposeApp(tester);
  });

  testWidgets('글 영역의 "자세히 보기" 알약이 케어 노트를 연다', (tester) async {
    usePhoneView(tester);
    await pumpBootedApp(tester);

    // 초보 사용자용 어피던스 — 무대 아무 데나가 아니라 글자 있는 버튼으로도 열린다.
    expect(sceneText('자세히 보기'), findsOneWidget);

    await tester.tap(sceneText('자세히 보기'));
    await tester.pumpAndSettle();

    expect(find.textContaining('의학적 진단이 아니며'), findsOneWidget);

    await disposeApp(tester);
  });
}
