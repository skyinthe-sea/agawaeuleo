import 'package:agawaeuleo/presentation/features/home/widgets/symptom_card.dart';
import 'package:flutter_test/flutter_test.dart';

import '_app_harness.dart';

void main() {
  testWidgets('홈 증상 그리드가 렌더되고 카드 탭 시 증상 상세로 이동한다', (tester) async {
    await pumpBootedApp(tester);

    // §11.7 증상 카드 2열 그리드(픽스처 16종)가 렌더된다.
    expect(find.byType(SymptomCard), findsWidgets);
    // 첫 카드는 픽스처 순서상 배앓이(colic).
    expect(find.text('배앓이'), findsWidgets);

    // 카드 탭 → §11.9 증상 상세로 push.
    await tester.tap(find.byType(SymptomCard).first);
    await tester.pumpAndSettle();

    // 상세 화면의 의학 면책(§13.3)은 항상 노출된다 → 이동 성공 확인.
    expect(find.textContaining('의학적 진단이 아니며'), findsOneWidget);

    await disposeApp(tester);
  });
}
