import 'package:agawaeuleo/data/fixtures/fixture_symptoms.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/symptom_card.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

/// 홈 증상 카드 일러스트 레이아웃(§11.7 개정 — 시드 16종 전부) 스모크.
///
/// - 등록 증상: 제목 + 한 줄 설명([Symptom.tagline], 개행 없음) + 우측 절반
///   일러스트. 일러스트가 아이콘 히어로(`symptom-icon-<id>`)로 비행한다.
/// - 미등록 키(신규/미지 증상): 기존 아이콘 레이아웃 폴백.
/// - 16종 전원 라이트/다크에서 페인터가 예외 없이 렌더.
void main() {
  final colic = fixtureSymptoms.firstWhere((s) => s.slug == 'colic');

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
    // 설명은 개행 없이 한 줄이다.
    final taglineText = tester.widget<Text>(find.text(colic.tagline!));
    expect(taglineText.maxLines, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('시드 16종 전원이 일러스트·태그라인을 갖고 라이트/다크에서 렌더된다', (tester) async {
    expect(fixtureSymptoms, hasLength(16));
    for (final symptom in fixtureSymptoms) {
      // 16종 확산 가드 — 새 시드 증상이 일러스트/태그라인 없이 추가되면 실패.
      expect(
        SymptomIllustrations.has(symptom.emojiOrIcon),
        isTrue,
        reason: '${symptom.slug} 일러스트 미등록',
      );
      expect(symptom.tagline, isNotNull, reason: '${symptom.slug} 태그라인 없음');

      for (final dark in [false, true]) {
        await pumpWidgetWithTheme(
          tester,
          sized(SymptomCard(symptom: symptom, onTap: () {})),
          dark: dark,
        );
        expect(find.byType(SymptomIllustration), findsOneWidget);
        expect(find.text(symptom.tagline!), findsOneWidget);
        expect(
          tester.takeException(),
          isNull,
          reason: '${symptom.slug} (dark=$dark) 렌더 예외',
        );
      }
    }
  });

  testWidgets('미등록 키 증상은 기존 아이콘 레이아웃으로 폴백한다', (tester) async {
    final unknown = colic.copyWith(
      slug: 'future-symptom',
      emojiOrIcon: 'unknown_key',
      tagline: null,
    );
    await pumpWidgetWithTheme(
      tester,
      sized(SymptomCard(symptom: unknown, onTap: () {})),
    );

    expect(find.byType(SymptomIllustration), findsNothing);
    expect(heroWithTag('symptom-icon-${unknown.id}'), findsOneWidget);
    expect(find.text('배앓이'), findsOneWidget); // name은 copyWith 원본 유지
  });
}
