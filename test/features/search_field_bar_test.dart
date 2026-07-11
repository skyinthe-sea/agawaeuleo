import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/features/search/widgets/search_field_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// §11.8 검색 입력바 정렬 회귀 테스트.
///
/// 테마 `InputDecorationTheme.constraints(minHeight: 52)`는 데코레이터 박스만
/// 늘리고 InputDecorator는 잉여 공간을 아래에 붙이므로, 실제 앱 테마로 펌프해야
/// "텍스트가 알약 상단에 붙는" 버그가 재현/검증된다. (픽스처 테마 금지.)
void main() {
  const hint = '배앓이, ㅂㅇㅇ …';

  Future<FocusNode> pumpBar(WidgetTester tester) async {
    final controller = TextEditingController();
    final focusNode = FocusNode();
    addTearDown(controller.dispose);
    addTearDown(focusNode.dispose);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.all(AppSpacing.x16),
            child: SearchFieldBar(
              controller: controller,
              focusNode: focusNode,
              onChanged: (_) {},
              onSubmitted: (_) {},
              onClear: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    return focusNode;
  }

  testWidgets('알약 높이는 52이고 힌트·입력 라인이 세로 중앙에 온다', (tester) async {
    await pumpBar(tester);

    final pill = tester.getRect(find.byType(SearchFieldBar));
    expect(pill.height, 52);

    // 힌트(비어 있을 때)와 실제 입력 라인(EditableText) 모두 알약 세로 중앙.
    final hintRect = tester.getRect(find.text(hint));
    final editable = tester.getRect(find.byType(EditableText));
    expect(
      (hintRect.center.dy - pill.center.dy).abs(),
      lessThan(2),
      reason:
          '힌트가 알약 세로 중앙에서 벗어남 '
          '(hint=${hintRect.center.dy}, pill=${pill.center.dy})',
    );
    expect(
      (editable.center.dy - pill.center.dy).abs(),
      lessThan(2),
      reason:
          '입력 라인이 알약 세로 중앙에서 벗어남 '
          '(editable=${editable.center.dy}, pill=${pill.center.dy})',
    );
  });

  testWidgets('텍스트 라인 밖 알약 빈 영역 탭으로 포커스가 복원된다', (tester) async {
    final focusNode = await pumpBar(tester);
    expect(focusNode.hasFocus, isTrue, reason: 'autofocus');

    focusNode.unfocus();
    await tester.pump();
    expect(focusNode.hasFocus, isFalse);

    // 데코레이터가 텍스트 고유 높이로 줄었으므로, 알약 상단 가장자리(빈 영역)
    // 탭은 GestureDetector가 받아 포커스를 복원해야 한다.
    final pill = tester.getRect(find.byType(SearchFieldBar));
    await tester.tapAt(Offset(pill.center.dx, pill.top + 6));
    await tester.pump();
    expect(focusNode.hasFocus, isTrue);
  });
}
