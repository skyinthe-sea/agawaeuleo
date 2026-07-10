import 'package:agawaeuleo/application/gate/gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/theme.dart';
import '../../router/routes.dart';
import '../../widgets/brand/ink_seal.dart';
import '../../widgets/surfaces/paper_background.dart';
import 'state/splash_boot_provider.dart';
import 'widgets/ink_drop_logo.dart';

/// §11.1 스플래시. 중앙에 로고(96×96, `paper.bg` 배경). 세션·원격config(강제업데이트/점검)를
/// 함께 확인한다: [appGateProvider]가 점검/강제 업데이트로 판정하면 해당 상태 화면으로 앱을
/// 잠그고(라우팅 없이 인라인 렌더), 통과하면 [splashBootProvider]의 목적지(온보딩/홈-게스트)로
/// 이동한다. 로고는 잉크가 번지듯 scale .8→1 + fadeIn 400ms로 등장한다.
///
/// DESIGN v2 §7.6.1 — 로고 아래 명조 워드마크 "아가왜울어" + 그 아래 `InkSeal.md`
/// stamp-in(로고 페이드 완료 후 200ms 지연)을 더하고, 표면에 `PaperBackground` 그레인을
/// 얹는다.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  void _goTo(SplashDestination destination) {
    if (_navigated || !mounted) return;
    _navigated = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      switch (destination) {
        case SplashDestination.onboarding:
          context.goNamed(Routes.onboarding);
        case SplashDestination.home:
          context.goNamed(Routes.home);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final gate = ref.watch(appGateProvider);
    final gateResult = gate.asData?.value;
    final blocked = gateResult?.isBlocked ?? false;

    // 게이트가 통과일 때만 부팅 목적지로 이동. 게이트와 부팅을 병렬로 돌리되(둘 다 watch),
    // 점검/강제 업데이트면 이동을 막고 상태 화면을 노출한다.
    if (!blocked) {
      final destination = ref.watch(splashBootProvider).asData?.value;
      final passed = gateResult?.status == AppGateStatus.passed;
      if (passed && destination != null) {
        _goTo(destination);
      }
    }

    if (gateResult != null) {
      switch (gateResult.status) {
        case AppGateStatus.maintenance:
          return MaintenanceScreen(
            message: gateResult.maintenanceMessage,
            onRetry: () => ref.invalidate(appGateProvider),
          );
        case AppGateStatus.forceUpdate:
          return const ForceUpdateScreen();
        case AppGateStatus.passed:
          break;
      }
    }

    return const _SplashLogo();
  }
}

/// 로고 + 워드마크 + 낙관(印) 표면(게이트 판정 중 / 통과 후 부팅 대기 중 노출).
///
/// DESIGN v2 §7.6.1 — 로고 아래 명조 워드마크, 그 아래 [InkSeal.md] stamp-in을 로고
/// 페이드(slow=400ms) 완료 후 200ms 지연해 등장시킨다. 지연은 원시 `Future.delayed`
/// (Timer)가 아니라 `AnimationController`(Ticker)로 구현해, 게이트 판정이 먼저 끝나
/// 이 위젯이 조기 언마운트되어도 [dispose]에서 안전하게 정리된다(위젯 테스트에서 Timer
/// 잔존 오류를 유발하지 않음).
class _SplashLogo extends StatefulWidget {
  const _SplashLogo();

  @override
  State<_SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<_SplashLogo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sealDelay = AnimationController(
    vsync: this,
    duration: AppMotion.slow + const Duration(milliseconds: 200),
  );
  bool _showSeal = false;

  @override
  void initState() {
    super.initState();
    _sealDelay.addStatusListener(_handleSealDelayStatus);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _sealDelay
        ..duration =
            AppMotion.resolve(context, AppMotion.slow) +
            const Duration(milliseconds: 200)
        ..forward();
    });
  }

  void _handleSealDelayStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed && mounted) {
      setState(() => _showSeal = true);
    }
  }

  @override
  void dispose() {
    _sealDelay.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    Widget logo = const InkDropLogo(size: 96);
    Widget wordmark = Text(
      '아가왜울어',
      style: texts.title.copyWith(color: colors.ink900),
    );
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
      wordmark = wordmark
          .animate(delay: AppMotion.fast)
          .fadeIn(duration: AppMotion.base, curve: AppMotion.enter);
    }

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: PaperBackground(
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                logo,
                const SizedBox(height: AppSpacing.x16),
                wordmark,
                const SizedBox(height: AppSpacing.x20),
                // 세로 공간을 미리 확보해 낙관 등장 시 레이아웃이 튀지 않게 한다.
                SizedBox(
                  height: InkSeal.sizeMd,
                  child: _showSeal ? const InkSeal.md(animate: true) : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
