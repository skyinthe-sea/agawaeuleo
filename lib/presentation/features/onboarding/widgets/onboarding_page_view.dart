import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/utils/keep_all.dart';
import 'onboarding_page_data.dart';

/// §11.2 온보딩 한 장의 **글 영역**(일러스트는 페이지뷰 밖 `OnboardingStage`).
///
/// DESIGN v3 — 번호는 장면 톤 스티커(주아체), 제목은 주아체 displayL, 본문은 그대로.
///
/// 페이지 자체는 손가락과 1:1로 움직이고, 그 안에서 오버라인 → 제목 → 본문이
/// 조금씩 더 빨리 흘러 나가며 흐려진다(키네틱 타이포). 추가 이동은 항상 화면
/// **바깥 방향**이라, 대기 중인 옆 페이지 글이 먼저 화면에 들어오는 일이 없다.
class OnboardingPageView extends StatelessWidget {
  const OnboardingPageView({
    required this.data,
    required this.index,
    required this.pageController,
    required this.topInset,
    super.key,
  });

  final OnboardingPageData data;
  final int index;
  final PageController pageController;

  /// 위쪽 스테이지가 차지하는 높이 — 글은 그 아래부터 놓인다.
  final double topInset;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    // 장면 톤 — 스테이지 블롭과 같은 파스텔(① 딸기 ② 버터 ③ 토마토).
    final tone = switch (data.scene) {
      OnboardingScene.search => (wash: colors.accentWash, fg: colors.accent),
      OnboardingScene.products => (wash: colors.amberWash, fg: colors.amber),
      OnboardingScene.safety => (wash: colors.coralWash, fg: colors.coral),
    };

    // DESIGN v3 §1-3 — 먹선 틱·모노 `01` 대신 주아체 번호 동그라미 스티커.
    final overline = Row(
      children: [
        Container(
          width: 26,
          height: 26,
          alignment: Alignment.center,
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: BoxDecoration(
            color: tone.wash,
            shape: BoxShape.circle,
            border: Border.all(color: colors.paperRaised, width: 1.5),
            boxShadow: context.shadows.e1,
          ),
          child: FittedBox(
            child: Text(
              '${index + 1}',
              style: texts.label.copyWith(
                color: tone.fg,
                fontFamily: AppFontFamily.display,
                fontFamilyFallback: AppFontFamily.displayFallback,
                fontWeight: FontWeight.w400,
                letterSpacing: 0,
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x8),
        // 오버라인의 넓은 자간(+1.2)은 라틴 대문자용 — 한글은 글자가 흩어져 보여
        // 캡션 굵기만 빌리고 자간은 뺀다.
        Text(
          data.overline,
          style: texts.caption.copyWith(
            color: colors.ink500,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );

    final title = Semantics(
      header: true,
      label: data.title,
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (final line in data.titleLines)
              // 줄은 카피에서 직접 나눈다 — 좁은 화면에서는 줄바꿈 대신 축소.
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  line,
                  maxLines: 1,
                  softWrap: false,
                  style: texts.displayL.copyWith(color: colors.ink900),
                ),
              ),
          ],
        ),
      ),
    );

    final body = Text(
      keepAll(data.body),
      semanticsLabel: data.body,
      style: texts.bodyL.copyWith(color: colors.ink500),
    );

    Widget block(Widget child, double speed) {
      if (reduce) return child;
      return AnimatedBuilder(
        animation: pageController,
        builder: (context, child) {
          final hasPage =
              pageController.hasClients && pageController.positions.length == 1;
          final p =
              (hasPage ? pageController.page ?? index.toDouble() : index) -
              index;
          return Opacity(
            opacity: (1 - p.abs() * 1.5).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(-p * speed, 0),
              child: child,
            ),
          );
        },
        child: child,
      );
    }

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.x24,
        topInset + AppSpacing.x8,
        AppSpacing.x24,
        0,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          block(overline, 24),
          const SizedBox(height: AppSpacing.x12),
          block(title, 48),
          const SizedBox(height: AppSpacing.x12),
          block(body, 72),
        ],
      ),
    );
  }
}
