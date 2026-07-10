import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '_widget_harness.dart';

void main() {
  testWidgets('§6.2 매핑 — 열은 coral, 소화는 sage, 컨디션은 amber, 기타는 accent', (
    tester,
  ) async {
    late BuildContext capturedContext;
    await pumpWidgetWithTheme(
      tester,
      Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        },
      ),
    );

    final colors = capturedContext.colors;

    final fever = SymptomTone.resolve(capturedContext, 'fever');
    expect(fever.fg, colors.coral);
    expect(fever.wash, colors.coralWash);

    final tummyPain = SymptomTone.resolve(capturedContext, 'tummy_pain');
    expect(tummyPain.fg, colors.sage);
    expect(tummyPain.wash, colors.sageWash);

    final teething = SymptomTone.resolve(capturedContext, 'teething');
    expect(teething.fg, colors.amber);
    expect(teething.wash, colors.amberWash);

    final runnyNose = SymptomTone.resolve(capturedContext, 'runny_nose');
    expect(runnyNose.fg, colors.accent);
    expect(runnyNose.wash, colors.accentWash);
  });

  testWidgets('미지 키/null은 accent 기본으로 폴백한다', (tester) async {
    late BuildContext capturedContext;
    await pumpWidgetWithTheme(
      tester,
      Builder(
        builder: (context) {
          capturedContext = context;
          return const SizedBox.shrink();
        },
      ),
    );

    final colors = capturedContext.colors;

    final unknown = SymptomTone.resolve(capturedContext, 'unknown_key');
    expect(unknown.fg, colors.accent);

    final nullKey = SymptomTone.resolve(capturedContext, null);
    expect(nullKey.fg, colors.accent);
  });
}
