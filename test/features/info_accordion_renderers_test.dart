import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/symptom_info.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/info_accordion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../widgets/_widget_harness.dart';

/// §11.9 개정 — InfoSection 타입별 본문 렌더러(steps/checklist/table/qa/tips)
/// 위젯 검증. 각 타입을 첫 섹션(기본 펼침)으로 단독 렌더한다.
///
/// DESIGN v3 "몽글 클레이" — 번호는 주아체 파스텔 동그라미, 체크는 동그란 민트 버블,
/// 팁은 버터(amberWash) 메모, Q/A는 주아체 동그라미 표식.
void main() {
  Future<void> pumpSection(
    WidgetTester tester,
    InfoSection section, {
    double? width,
  }) async {
    final list = InfoAccordionList(sections: [section]);
    await pumpWidgetWithTheme(
      tester,
      width == null ? list : SizedBox(width: width, child: list),
      reduceMotion: true,
    );
    await tester.pumpAndSettle();
  }

  testWidgets('steps: 주아체 번호 동그라미(1부터) + intro + 본문 행을 렌더한다', (tester) async {
    await pumpSection(
      tester,
      const InfoSection.steps(
        title: '단계별 방법',
        intro: '순서대로 시도해 보세요.',
        items: ['첫 번째 단계', '두 번째 단계', '세 번째 단계'],
      ),
    );

    expect(find.text('단계별 방법'), findsOneWidget);
    expect(find.text('순서대로 시도해 보세요.'), findsOneWidget);
    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
    expect(find.text('3'), findsOneWidget);
    // v3 — 숫자 강조는 모노가 아니라 주아체(§3.3).
    expect(
      tester.widget<Text>(find.text('1')).style?.fontFamily,
      AppFontFamily.display,
    );
    expect(find.text('두 번째 단계'), findsOneWidget);
    expect(find.byIcon(Icons.format_list_numbered_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('checklist: 동그란 체크 + 항목 리스트를 렌더한다', (tester) async {
    await pumpSection(
      tester,
      const InfoSection.checklist(
        title: '체크리스트',
        items: ['확인 항목 하나', '확인 항목 둘'],
      ),
    );

    expect(find.byIcon(Icons.check_rounded), findsNWidgets(2));
    expect(find.text('확인 항목 하나'), findsOneWidget);
    expect(find.byIcon(Icons.checklist_rounded), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('table: 헤더·셀·caption 렌더 + 좁은 화면에서 가로 오버플로 없음', (tester) async {
    await pumpSection(
      tester,
      const InfoSection.table(
        title: '보관 기간 표',
        columns: ['보관 위치와 조건', '권장 기간(신생아 기준)', '비고와 추가 설명'],
        rows: [
          ['실온 보관(24°C 이하)', '4시간 이내 사용 권장', '여름철에는 더 짧게 보는 경우가 많아요'],
          ['냉장 보관(4°C)', '72시간(3일)', '냉장고 문 쪽이 아닌 안쪽에 두세요'],
        ],
        caption: '기관에 따라 기준이 다를 수 있어요.',
      ),
      // 카드 폭보다 넓은 표를 강제해 가로 스크롤 경로를 태운다.
      width: 320,
    );

    // 렌더 오버플로(RenderFlex overflowed 등) 예외가 없어야 한다.
    expect(tester.takeException(), isNull);
    expect(find.text('보관 위치와 조건'), findsOneWidget);
    expect(find.text('냉장 보관(4°C)'), findsOneWidget);
    expect(find.text('기관에 따라 기준이 다를 수 있어요.'), findsOneWidget);
    // 표는 자체 가로 스크롤 컨테이너 안에서 렌더된다(화면 가로 오버플로 금지).
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is SingleChildScrollView && w.scrollDirection == Axis.horizontal,
      ),
      findsOneWidget,
    );
    expect(find.byType(Table), findsOneWidget);
    expect(find.byIcon(Icons.table_chart_outlined), findsOneWidget);
  });

  testWidgets('qa: Q/A 쌍과 항목 사이 구분을 렌더한다', (tester) async {
    await pumpSection(
      tester,
      const InfoSection.qa(
        title: '자주 묻는 질문',
        items: [
          QaItem(q: '첫 질문인가요?', a: '네, 첫 답변이에요.'),
          QaItem(q: '두 번째 질문인가요?', a: '네, 두 번째 답변이에요.'),
        ],
      ),
    );

    expect(find.text('첫 질문인가요?'), findsOneWidget);
    expect(find.text('네, 첫 답변이에요.'), findsOneWidget);
    expect(find.text('두 번째 질문인가요?'), findsOneWidget);
    // 질문·답 앞 주아체 Q/A 표식(항목마다 한 쌍).
    expect(find.text('Q'), findsNWidgets(2));
    expect(find.text('A'), findsNWidgets(2));
    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('tips: 버터 메모 안 동그란 점 불릿 리스트를 렌더한다', (tester) async {
    await pumpSection(
      tester,
      const InfoSection.tips(title: '조리원 실전 팁', items: ['팁 하나예요.', '팁 둘이에요.']),
    );

    expect(find.text('팁 하나예요.'), findsOneWidget);
    expect(find.text('팁 둘이에요.'), findsOneWidget);
    expect(find.byIcon(Icons.fiber_manual_record), findsNWidgets(2));
    expect(find.byIcon(Icons.lightbulb_outline), findsOneWidget);
    // 버터(amberWash) 메모 면.
    expect(
      find.byWidgetPredicate(
        (w) =>
            w is Container &&
            w.decoration is BoxDecoration &&
            (w.decoration! as BoxDecoration).color == AppColors.light.amberWash,
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('text: 기존 서술형 본문과 제목 키워드 아이콘 규칙을 유지한다', (tester) async {
    await pumpSection(
      tester,
      const InfoSection.text(title: '원인', body: '서술형 본문이에요.'),
    );

    expect(find.text('서술형 본문이에요.'), findsOneWidget);
    expect(find.byIcon(Icons.help_outline), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
