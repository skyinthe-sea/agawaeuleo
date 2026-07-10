import 'package:agawaeuleo/presentation/widgets/dialogs/app_dialog_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('showAppDialog는 제목·본문·액션 버튼을 렌더하고 primary가 값을 반환한다', (
    tester,
  ) async {
    Object? result;
    await pumpWidgetWithTheme(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await showAppDialog<bool>(
              context,
              title: '로그아웃 할까요?',
              message: '다시 로그인하면 이어서 볼 수 있어요.',
              primaryLabel: '로그아웃',
              onPrimary: () => Navigator.of(context).pop(true),
              secondaryLabel: '취소',
              onSecondary: () => Navigator.of(context).pop(false),
            );
          },
          child: const Text('열기'),
        ),
      ),
    );

    await tester.tap(find.text('열기'));
    await tester.pumpAndSettle();

    expect(find.text('로그아웃 할까요?'), findsOneWidget);
    expect(find.text('다시 로그인하면 이어서 볼 수 있어요.'), findsOneWidget);

    await tester.tap(find.text('로그아웃'));
    await tester.pumpAndSettle();

    expect(result, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('destructive: true는 크래시 없이 렌더된다', (tester) async {
    await pumpWidgetWithTheme(
      tester,
      const AppDialogShell(
        title: '계정을 삭제할까요?',
        message: '모든 기록이 삭제되고 되돌릴 수 없어요.',
        destructive: true,
        primaryLabel: '삭제',
        secondaryLabel: '취소',
      ),
    );

    expect(find.text('계정을 삭제할까요?'), findsOneWidget);
    expect(find.text('삭제'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
