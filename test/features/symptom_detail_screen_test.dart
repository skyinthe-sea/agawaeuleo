import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:agawaeuleo/presentation/widgets/brand/ink_halo_icon.dart';
import 'package:agawaeuleo/presentation/widgets/dividers/brush_divider.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:flutter/material.dart';
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

  testWidgets(
    'DESIGN v2 §7.3: Hero 태그 유지 + 히어로 일러스트(colic)/붓결 디바이더/제품 개수·순위 배지 렌더',
    (tester) async {
      final router = await pumpBootedApp(tester);

      // 배앓이(colic)는 픽스처에 제품 3개가 있어(§7.3-6 "3개" + 1위 배지) 검증에 적합하다.
      router.pushNamed(
        Routes.symptomDetail,
        pathParameters: {RouteParams.slug: 'colic'},
      );
      await tester.pumpAndSettle();

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

      // §7.3-1 히어로 — 일러스트 등록 증상(colic)은 InkHaloIcon 대신 홈 카드와
      // 동일한 일러스트가 착지한다(§11.7 일러스트 카드 히어로 연속성).
      // 미등록 증상의 InkHaloIcon 승격은 ink_halo_icon_test.dart 가 커버한다.
      expect(find.byType(SymptomIllustration), findsOneWidget);
      expect(find.byType(InkHaloIcon), findsNothing);

      // §7.3-5 의학 면책 박스의 안내 아이콘.
      expect(find.byIcon(Icons.info_outline), findsOneWidget);

      // §6.4/§7.3-4 "정보 → 제품" 격 전환점 붓결 디바이더.
      expect(find.byType(BrushDivider), findsOneWidget);

      // §7.3-6 제품 섹션 SectionHeader trailing("3개") + 1위 순위 배지("1").
      expect(find.text('3개'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);

      await disposeApp(tester);
    },
  );
}
