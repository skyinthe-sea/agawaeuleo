import 'package:agawaeuleo/presentation/features/home/widgets/home_search_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_app_harness.dart';

void main() {
  testWidgets('검색: 초성 ㅂㅇㅇ → 배앓이 결과 → 탭 시 상세로 이동', (tester) async {
    await pumpBootedApp(tester);

    // 홈 검색 바 탭 → §11.8 검색 화면(Hero morph).
    await tester.tap(find.byType(HomeSearchBar));
    await tester.pumpAndSettle();
    expect(find.byType(TextField), findsOneWidget);

    // 초성 검색어 입력 → 200ms 디바운스 확정.
    await tester.enterText(find.byType(TextField), 'ㅂㅇㅇ');
    await tester.pump(const Duration(milliseconds: 250));
    await tester.pumpAndSettle();

    // 배앓이(chosung 'ㅂㅇㅇ')가 결과에 노출된다.
    expect(find.text('배앓이'), findsOneWidget);

    // 결과 탭 → 증상 상세.
    await tester.tap(find.text('배앓이'));
    await tester.pumpAndSettle();
    expect(find.textContaining('의학적 진단이 아니며'), findsOneWidget);

    await disposeApp(tester);
  });
}
