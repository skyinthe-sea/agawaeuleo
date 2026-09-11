import 'dart:math' as math;
import 'dart:ui' show lerpDouble;

import 'package:agawaeuleo/application/gate/gate.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../config/theme/theme.dart';
import '../../router/routes.dart';
import '../../widgets/stage/paper_blob_painter.dart';
import '../../widgets/surfaces/paper_background.dart';
import 'state/splash_boot_provider.dart';
import 'widgets/splash_mark.dart';

/// §11.1 스플래시. 세션·원격config(강제업데이트/점검)를 함께 확인한다: [appGateProvider]가
/// 점검/강제 업데이트로 판정하면 해당 상태 화면으로 앱을 잠그고(라우팅 없이 인라인 렌더),
/// 통과하면 [splashBootProvider]의 목적지(온보딩/홈-게스트)로 이동한다.
///
/// DESIGN v2.3 §7.6-1 — 네이티브 런치 화면의 인주 도장에서 이어지는 브랜드 스테이지
/// (우는 아기 → 방긋, 블롭·궤도 번짐, 명조 워드마크). 옛 물방울 로고·낙관 도장은 폐기.
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

/// 브랜드 스테이지(게이트 판정 중 / 통과 후 부팅 대기 중 노출) — 2026-09-11 개편.
///
/// 네이티브 런치 화면(종이색 + 가운데 인주 도장 160dp)과 **같은 첫 프레임**에서 시작해:
/// 1. 도장이 한 번 눌렸다가(스탬프) 작아지며 위로 올라서고,
/// 2. 뒤에서 종이 오림 블롭이 번지고 점선 궤도가 한 바퀴 그려지며 행성이 튀어나오고,
/// 3. 도장 속 **우는 아기가 방긋 웃는다**(눈물이 흘러내려 사라지고 입이 곡선으로),
/// 4. 명조 워드마크가 한 글자씩, 이어서 한 줄 소개가 올라온다.
///
/// 핵심 비트는 ~1s 안에 끝나고(부팅 최소 노출 1150ms), 부팅이 더 걸리면 블롭이
/// 숨쉬고 행성이 천천히 돈다(멈춘 화면이 아니라 준비 중인 무대). reduce-motion이면
/// 완성 상태로 바로 그린다. 컨트롤러는 Ticker라 게이트가 먼저 끝나 조기 언마운트돼도
/// [State.dispose]에서 안전하게 정리된다(테스트 Timer 잔존 없음).
class _SplashLogo extends StatefulWidget {
  const _SplashLogo();

  @override
  State<_SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<_SplashLogo>
    with TickerProviderStateMixin {
  /// 첫 진입 연출 전체(부팅 최소 노출과 같은 길이).
  static const Duration _introDuration = Duration(milliseconds: 1150);

  /// 네이티브 런치 배지 지름(generate_app_icon.py --splash와 동일) → 연출 끝 크기.
  static const double _nativeBadge = 160;
  static const double _finalBadge = 112;

  /// 도장이 올라서는 거리 — 아래 워드마크 자리를 비운다.
  static const double _rise = 72;

  static const double _stageCanvas = 300;
  static const String _wordmark = '아가왜울어';

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) _ambient.repeat();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.reduceMotion) {
      _intro.value = 1;
      _ambient.stop();
    } else if (_intro.value == 0 && !_intro.isAnimating) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _intro.dispose();
    _ambient.dispose();
    super.dispose();
  }

  double _phase(double begin, double end, [Curve curve = AppMotion.enter]) =>
      curve.transform(Interval(begin, end).transform(_intro.value));

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: PaperBackground(
        child: Semantics(
          label: '아가왜울어',
          container: true,
          child: ExcludeSemantics(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // 네이티브 런치 화면과 같은 기준 — 세이프에어리어를 빼지 않은 화면 정중앙.
                final center = constraints.biggest.center(Offset.zero);
                return AnimatedBuilder(
                  animation: Listenable.merge([_intro, _ambient]),
                  builder: (context, _) {
                    // 스탬프: 살짝 눌렸다가(0~10%) 스프링으로 작아지며 올라선다.
                    final press = math.sin(
                      math.pi * const Interval(0, 0.12).transform(_intro.value),
                    );
                    final move = _phase(0.08, 0.5, AppMotion.spring);
                    final badge =
                        lerpDouble(_nativeBadge, _finalBadge, move)! *
                        (1 - 0.06 * press);
                    final badgeCenter = center.translate(0, -_rise * move);

                    final bloom = _phase(0.1, 0.55);
                    final orbit = _phase(0.2, 0.7, Curves.easeInOutCubic);
                    final planets = _phase(0.55, 0.8, AppMotion.spring);
                    final smile = _phase(0.28, 0.62, Curves.easeInOutCubic);
                    final tear = _phase(0.22, 0.6, Curves.linear);
                    final tagline = _phase(0.68, 0.95);

                    return Stack(
                      children: [
                        Positioned(
                          left: badgeCenter.dx - _stageCanvas / 2,
                          top: badgeCenter.dy - _stageCanvas / 2,
                          width: _stageCanvas,
                          height: _stageCanvas,
                          child: Opacity(
                            opacity: bloom,
                            child: Transform.scale(
                              scale: 0.4 + 0.6 * bloom,
                              child: CustomPaint(
                                painter: PaperBlobPainter(
                                  page: 0,
                                  breath: _ambient.value,
                                  // 기본 윤곽이 마름모로 읽히지 않게 비껴 두고, 대기 중엔 천천히 돈다.
                                  spin:
                                      0.38 +
                                      _ambient.value * 2 * math.pi * 0.08,
                                  washes: [colors.sealWash],
                                  under: colors.paperStack,
                                  orbit: colors.lineStrong,
                                  rim: colors.paperBg,
                                  planets: [
                                    colors.accent,
                                    colors.amber,
                                    colors.sage,
                                  ],
                                  center: const Offset(150, 150),
                                  radius: 96,
                                  orbitScale: 1.26,
                                  underOffset: const Offset(5, 7),
                                  planetBases: const [-0.7, 2.2, 3.9],
                                  planetSpeeds: const [0, 0, 0],
                                  planetRadii: const [5, 3.5, 4],
                                  orbitProgress: orbit,
                                  planetScale: planets,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 도장이 찍히는 순간 번지는 먹 물결 한 겹.
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _StampRipplePainter(
                              center: badgeCenter,
                              radius: badge / 2,
                              progress: _phase(0.04, 0.42, Curves.easeOutCubic),
                              color: AppColors.light.seal,
                            ),
                          ),
                        ),
                        Positioned(
                          left: badgeCenter.dx - badge / 2,
                          top: badgeCenter.dy - badge / 2,
                          child: SplashMark(
                            size: badge,
                            smile: smile,
                            tear: tear,
                          ),
                        ),
                        Positioned(
                          left: 0,
                          right: 0,
                          top: center.dy + 64,
                          child: Column(
                            children: [
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  for (final (i, letter)
                                      in _wordmark.characters.indexed)
                                    Builder(
                                      builder: (context) {
                                        final t = _phase(
                                          0.36 + i * 0.05,
                                          0.66 + i * 0.05,
                                        );
                                        return Opacity(
                                          opacity: t,
                                          child: Transform.translate(
                                            offset: Offset(0, 16 * (1 - t)),
                                            child: Text(
                                              letter,
                                              style: texts.displayL.copyWith(
                                                color: colors.ink900,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.x8),
                              Opacity(
                                opacity: tagline,
                                child: Transform.translate(
                                  offset: Offset(0, 8 * (1 - tagline)),
                                  child: Text(
                                    '우는 이유부터 필요한 용품까지',
                                    style: texts.bodyL.copyWith(
                                      color: colors.ink500,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

/// 도장 스탬프 순간의 먹 물결 — 도장 가장자리에서 한 번 퍼지며 옅어진다.
class _StampRipplePainter extends CustomPainter {
  const _StampRipplePainter({
    required this.center,
    required this.radius,
    required this.progress,
    required this.color,
  });

  final Offset center;
  final double radius;
  final double progress;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1) return;
    canvas.drawCircle(
      center,
      radius + 44 * progress,
      Paint()
        ..color = color.withValues(alpha: 0.35 * (1 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5 * (1 - progress) + 0.5,
    );
  }

  @override
  bool shouldRepaint(_StampRipplePainter old) =>
      old.progress != progress ||
      old.center != center ||
      old.radius != radius ||
      old.color != color;
}
