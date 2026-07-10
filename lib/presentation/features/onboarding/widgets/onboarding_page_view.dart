import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../config/theme/theme.dart';
import 'onboarding_illustration.dart';
import 'onboarding_page_data.dart';

/// §11.2 온보딩 한 장. 일러스트는 스와이프보다 살짝 느리게 움직이는 parallax를 받고,
/// 텍스트는 fadeIn+slideY로 등장한다(§10.2, §11.2 애니메이션).
class OnboardingPageView extends StatelessWidget {
  const OnboardingPageView({
    required this.data,
    required this.index,
    required this.pageController,
    super.key,
  });

  final OnboardingPageData data;
  final int index;
  final PageController pageController;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    Widget illustration = OnboardingIllustration(icon: data.icon, index: index);
    if (!reduce) {
      illustration = AnimatedBuilder(
        animation: pageController,
        builder: (context, child) {
          final hasPage =
              pageController.hasClients && pageController.page != null;
          final page = hasPage ? pageController.page! : index.toDouble();
          final delta = page - index;
          final width = MediaQuery.sizeOf(context).width;
          // 일러스트가 텍스트/프레임보다 살짝 느리게 이동하는 parallax(§11.2).
          final dx = delta * width * 0.30;
          return Transform.translate(offset: Offset(dx, 0), child: child);
        },
        child: illustration,
      );
    }

    Widget textBlock = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          data.title,
          textAlign: TextAlign.center,
          // DESIGN v2 §6.3/§7.6.6 — 온보딩 제목 display → displayL 승격.
          style: texts.displayL.copyWith(color: colors.ink900),
        ),
        const SizedBox(height: AppSpacing.x12),
        Text(
          data.body,
          textAlign: TextAlign.center,
          style: texts.bodyL.copyWith(color: colors.ink500),
        ),
      ],
    );
    if (!reduce) {
      textBlock = textBlock
          .animate()
          .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
          .slideY(begin: 0.08, end: 0, curve: AppMotion.enter);
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          illustration,
          const SizedBox(height: AppSpacing.x32),
          textBlock,
        ],
      ),
    );
  }
}
