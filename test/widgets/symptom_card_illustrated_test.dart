import 'package:agawaeuleo/data/fixtures/fixture_symptoms.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/symptom_card.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

/// 홈 증상 카드 일러스트 레이아웃(배앓이 트라이얼) 스모크.
///
/// - 등록 증상(colic): 제목 + 한 줄 설명([Symptom.tagline]) + 우측 절반
///   일러스트. 일러스트가 아이콘 히어로(`symptom-icon-<id>`)로 비행한다.
/// - 미등록 증상(teething): 기존 아이콘 레이아웃 그대로.
/// - 라이트/다크 모두 페인터가 예외 없이 렌더.
void main() {
  final colic = fixtureSymptoms.firstWhere((s) => s.slug == 'colic');
  final teething = fixtureSymptoms.firstWhere((s) => s.slug == 'teething');

  // §11.7 홈 그리드 셀 크기(2열 · mainAxisExtent 120) 근사.
  Widget sized(Widget child) => SizedBox(width: 170, height: 120, child: child);

  Finder heroWithTag(String tag) =>
      find.byWidgetPredicate((w) => w is Hero && w.tag == tag);

  testWidgets('배앓이 카드는 제목+한 줄 설명+일러스트 레이아웃으로 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      sized(SymptomCard(symptom: colic, onTap: () {})),
    );

    expect(find.text('배앓이'), findsOneWidget);
    // 한 줄 설명은 엔티티(tagline — DB 컬럼 미러) 값이다.
    expect(find.text(colic.tagline!), findsOneWidget);
    expect(find.byType(SymptomIllustration), findsOneWidget);
    // 히어로 계약: 일러스트가 아이콘 히어로로, 증상명은 그대로 비행한다.
    expect(heroWithTag('symptom-icon-${colic.id}'), findsOneWidget);
    expect(heroWithTag('symptom-name-${colic.id}'), findsOneWidget);
    // 일러스트는 카드 우측 절반을 차지한다(§11.7 개정).
    final illustSize = tester.getSize(find.byType(SymptomIllustration));
    expect(illustSize.width, moreOrLessEquals(170 / 2, epsilon: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('다크 모드에서도 일러스트 카드가 예외 없이 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      sized(SymptomCard(symptom: colic, onTap: () {})),
      dark: true,
    );

    expect(find.byType(SymptomIllustration), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('일러스트 미등록 증상(이앓이)은 기존 아이콘 레이아웃을 유지한다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      sized(SymptomCard(symptom: teething, onTap: () {})),
    );

    expect(find.byType(SymptomIllustration), findsNothing);
    expect(heroWithTag('symptom-icon-${teething.id}'), findsOneWidget);
    expect(find.text('이앓이'), findsOneWidget);
  });
}
