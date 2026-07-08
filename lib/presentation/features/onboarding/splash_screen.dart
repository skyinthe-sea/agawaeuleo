import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/theme.dart';
import '../../router/routes.dart';
import 'state/splash_boot_provider.dart';
import 'widgets/ink_drop_logo.dart';

/// §11.1 스플래시. 중앙에 로고(96×96, `paper.bg` 배경)만 두고, [splashBootProvider]가
/// 최소 600ms 노출을 보장하며 세션/첫실행 여부를 판정하는 동안 로고가 잉크가 번지듯
/// scale .8→1 + fadeIn 400ms로 등장한다. 분기 완료 시 온보딩 또는 홈(게스트)으로 이동한다.
class SplashScreen extends ConsumerWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 목적지가 정해지는 즉시 1회 이동(§4.1: 첫 실행→온보딩, 아니면 홈-게스트).
    ref.listen<AsyncValue<SplashDestination>>(splashBootProvider, (
      previous,
      next,
    ) {
      next.whenData((destination) {
        if (!context.mounted) return;
        switch (destination) {
          case SplashDestination.onboarding:
            context.goNamed(Routes.onboarding);
          case SplashDestination.home:
            context.goNamed(Routes.home);
        }
      });
    });

    final colors = context.colors;
    final reduce = context.reduceMotion;

    Widget logo = const InkDropLogo(size: 96);
    if (!reduce) {
      logo = logo
          .animate()
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: AppMotion.slow,
            curve: AppMotion.enter,
          )
          .fadeIn(duration: AppMotion.slow, curve: AppMotion.enter);
    }

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: SafeArea(child: Center(child: logo)),
    );
  }
}
