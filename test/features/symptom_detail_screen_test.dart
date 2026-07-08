import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:flutter_test/flutter_test.dart';

import '_app_harness.dart';

void main() {
  testWidgets('증상 상세: 대가성 표시(§13.2)와 의학 면책(§13.3) 문구가 존재한다', (tester) async {
    final router = await pumpBootedApp(tester);

    // 배앓이(colic)는 픽스처에 추천 제품이 있어 대가성 섹션이 노출된다.
    router.pushNamed(
      Routes.symptomDetail,
      pathParameters: {RouteParams.slug: 'colic'},
    );
    await tester.pumpAndSettle();

    // §13.3 의학 면책(정보 유무와 무관하게 항상 노출).
    expect(find.textContaining('의학적 진단이 아니며'), findsOneWidget);

    // §13.2 제휴 대가성 표시.
    expect(find.text('쿠팡 파트너스 활동으로 수수료를 받습니다'), findsOneWidget);

    await disposeApp(tester);
  });
}
