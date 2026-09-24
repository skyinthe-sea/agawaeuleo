import 'dart:async';
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
import 'widgets/orbit_charms_painter.dart';
import 'widgets/splash_mark.dart';

/// §11.1 스플래시. 세션·원격config(강제업데이트/점검)를 함께 확인한다: [appGateProvider]가
/// 점검/강제 업데이트로 판정하면 해당 상태 화면으로 앱을 잠그고(라우팅 없이 인라인 렌더),
/// 통과하면 [splashBootProvider]의 목적지(온보딩/홈-게스트)로 이동한다.
///
/// DESIGN v2.3 §7.6-1 비트 + DESIGN v3 §6 외형 — 네이티브 런치 화면의 딸기 배지에서
/// 이어지는 브랜드 스테이지(클레이 아가가 울다 방긋, 파스텔 블롭·점선 궤도 번짐,
/// 주아체 워드마크).
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  /// 브랜드 연출이 끝났는지. 연출은 얼굴 에셋이 준비된 뒤(최대 300ms 늦게) 시작하므로,
  /// 부팅 최소 노출(1150ms)만 기다리면 끝의 한 줄 소개가 잘릴 수 있다 → 부팅 목적지와
  /// 연출 종료를 **둘 다** 기다린다.
  bool _introDone = false;
  SplashDestination? _pending;

  /// 연출이 어떤 이유로든(앱이 백그라운드로 가 티커가 멈추는 등) 끝나지 않아도
  /// 부팅이 끝난 뒤 이만큼 지나면 이동한다.
  static const Duration _introWaitLimit = Duration(milliseconds: 800);
  Timer? _introWait;

  void _onIntroDone() {
    _introDone = true;
    final pending = _pending;
    if (pending != null) _goTo(pending);
  }

  @override
  void dispose() {
    _introWait?.cancel();
    super.dispose();
  }

  void _goTo(SplashDestination destination) {
    if (_navigated || !mounted) return;
    if (!_introDone) {
      _pending = destination;
      _introWait ??= Timer(_introWaitLimit, _onIntroDone);
      return;
    }
    _introWait?.cancel();
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

    return _SplashLogo(onIntroDone: _onIntroDone);
  }
}

/// 브랜드 스테이지(게이트 판정 중 / 통과 후 부팅 대기 중 노출) — 2026-09-11 개편,
/// 2026-09-24 DESIGN v3 "몽글 클레이" 외형.
///
/// 네이티브 런치 화면(크림 바탕 + 가운데 딸기 배지 160dp)과 **같은 첫 프레임**에서 시작해:
/// 1. 배지가 한 번 눌렸다가(스탬프 — 분홍 링이 말랑하게 번진다) 작아지며 위로 올라서고,
/// 2. 뒤에서 파스텔 블롭이 번지고 점선 궤도가 한 바퀴 그려지며 하트·별·구슬이 톡 튀어나오고,
/// 3. 배지 속 **클레이 아가가 울다 방긋 웃는다**(마지막 눈물 한 방울이 흘러내려 사라지고,
///    얼굴이 말랑하게 눌렸다 늘어나며 웃는 얼굴로 바뀐다),
/// 4. 주아체 워드마크가 한 글자씩, 이어서 한 줄 소개가 올라온다.
///
/// 핵심 비트는 ~1s 안에 끝나고(부팅 최소 노출 1150ms), 부팅이 더 걸리면 블롭이
/// 숨쉬고 장식이 천천히 돈다(멈춘 화면이 아니라 준비 중인 무대). reduce-motion이면
/// 완성 상태로 바로 그린다. 컨트롤러는 Ticker라 게이트가 먼저 끝나 조기 언마운트돼도
/// [State.dispose]에서 안전하게 정리된다(테스트 Timer 잔존 없음).
///
/// 얼굴은 이미지 에셋이라 디코드 전 첫 프레임에 빈 배지가 비칠 수 있다 → 앱의 첫
/// 프레임이면 얼굴을 미리 읽는 동안(최대 [_faceWaitLimit]) 첫 프레임 전송을 미루고
/// (네이티브 런치 화면이 그대로 유지된다), 연출도 그때부터 시작한다.
class _SplashLogo extends StatefulWidget {
  const _SplashLogo({required this.onIntroDone});

  /// 첫 진입 연출이 끝났을 때(reduce-motion이면 즉시) 한 번 알린다.
  final VoidCallback onIntroDone;

  @override
  State<_SplashLogo> createState() => _SplashLogoState();
}

class _SplashLogoState extends State<_SplashLogo>
    with TickerProviderStateMixin {
  /// 첫 진입 연출 전체(부팅 최소 노출과 같은 길이).
  static const Duration _introDuration = Duration(milliseconds: 1150);

  /// 얼굴 에셋을 기다려 주는 상한 — 넘으면 얼굴 없이라도 먼저 띄운다.
  static const Duration _faceWaitLimit = Duration(milliseconds: 300);

  /// 네이티브 런치 배지 지름(네이티브 배지 생성기와 동일) → 연출 끝 크기.
  static const double _nativeBadge = 160;
  static const double _finalBadge = 112;

  /// 배지가 올라서는 거리 — 아래 워드마크 자리를 비운다.
  static const double _rise = 72;

  static const double _stageCanvas = 300;
  static const Offset _stageCenter = Offset(150, 150);
  static const double _blobRadius = 96;
  static const double _orbitScale = 1.26;
  static const String _wordmark = '아가왜울어';

  /// 궤도 장식 — 옛 행성 자리(시작각)에 하트·별·구슬.
  static const List<OrbitCharm> _charms = <OrbitCharm>[
    OrbitCharm.heart,
    OrbitCharm.star,
    OrbitCharm.bead,
  ];
  static const List<double> _charmBases = <double>[-0.7, 2.2, 3.9];
  static const List<double> _charmSpeeds = <double>[0, 0, 0];
  static const List<double> _charmSizes = <double>[6.5, 5.5, 3.5];

  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: _introDuration,
  );
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 6000),
  );

  /// 첫 프레임 전송을 미루는 중인지(미룬 만큼 정확히 한 번 풀어야 한다).
  bool _holdingFirstFrame = false;

  /// 얼굴 준비가 끝나(또는 상한을 넘겨) 연출을 시작해도 되는지.
  bool _faceReady = false;
  bool _precacheStarted = false;
  Timer? _faceWait;

  /// [_SplashLogo.onIntroDone]을 이미 알렸는지(한 번만).
  bool _reportedIntroDone = false;

  @override
  void initState() {
    super.initState();
    _intro.addStatusListener((status) {
      if (status != AnimationStatus.completed || !mounted) return;
      _ambient.repeat();
      if (!_reportedIntroDone) {
        _reportedIntroDone = true;
        widget.onIntroDone();
      }
    });
    final binding = WidgetsBinding.instance;
    if (!binding.firstFrameRasterized) {
      binding.deferFirstFrame();
      _holdingFirstFrame = true;
    }
    _faceWait = Timer(_faceWaitLimit, _handleFaceReady);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precacheStarted) {
      _precacheStarted = true;
      unawaited(SplashMark.precache(context).whenComplete(_handleFaceReady));
    }
    _syncMotion();
  }

  void _handleFaceReady() {
    _faceWait?.cancel();
    _faceWait = null;
    _releaseFirstFrame();
    if (_faceReady || !mounted) return;
    _faceReady = true;
    _syncMotion();
  }

  void _releaseFirstFrame() {
    if (!_holdingFirstFrame) return;
    _holdingFirstFrame = false;
    WidgetsBinding.instance.allowFirstFrame();
  }

  void _syncMotion() {
    if (context.reduceMotion) {
      _intro.value = 1;
      _ambient.stop();
    } else if (_faceReady && _intro.value == 0 && !_intro.isAnimating) {
      _intro.forward();
    }
  }

  @override
  void dispose() {
    _faceWait?.cancel();
    if (_holdingFirstFrame) {
      // 프레임 도중(트리 정리 단계)에 풀면 워밍업 프레임이 예약되지 않는다 — 다음
      // 화면이 정적(점검 화면 등)이어도 첫 프레임이 나가도록 한 장을 직접 예약한다.
      _releaseFirstFrame();
      WidgetsBinding.instance.scheduleFrame();
    }
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
                    // 기본 윤곽이 마름모로 읽히지 않게 비껴 두고, 대기 중엔 천천히 돈다.
                    final spin = 0.38 + _ambient.value * 2 * math.pi * 0.08;

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
                                // 블롭(딸기우유 워시 + 버터 아랫장)만 공용 페인터로 —
                                // 궤도·행성은 끄고 점선 궤도 + 하트·별을 위에 얹는다.
                                painter: PaperBlobPainter(
                                  page: 0,
                                  breath: _ambient.value,
                                  spin: spin,
                                  washes: [colors.sealWash],
                                  under: colors.amberWash,
                                  orbit: colors.lineStrong,
                                  rim: colors.paperBg,
                                  planets: const <Color>[],
                                  center: _stageCenter,
                                  radius: _blobRadius,
                                  orbitScale: _orbitScale,
                                  underOffset: const Offset(5, 7),
                                  orbitProgress: 0,
                                  planetScale: 0,
                                ),
                                foregroundPainter: OrbitCharmsPainter(
                                  page: 0,
                                  lastPage: 0,
                                  dotColor: colors.lineStrong,
                                  rim: colors.paperBg,
                                  charms: _charms,
                                  colors: [
                                    colors.accent,
                                    colors.amber,
                                    colors.sage,
                                  ],
                                  center: _stageCenter,
                                  radius: _blobRadius,
                                  orbitScale: _orbitScale,
                                  bases: _charmBases,
                                  speeds: _charmSpeeds,
                                  sizes: _charmSizes,
                                  orbitProgress: orbit,
                                  charmScale: planets,
                                  spin: spin,
                                  sway: _ambient.value * 3,
                                ),
                              ),
                            ),
                          ),
                        ),
                        // 배지가 눌리는 순간 말랑하게 번지는 분홍 링 한 겹.
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

/// 배지가 눌리는 순간의 분홍 링 — 가장자리에서 한 번 부드럽게(블러) 퍼지며 옅어진다.
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
      radius + 40 * progress,
      Paint()
        ..color = color.withValues(alpha: 0.4 * (1 - progress))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9 * (1 - progress) + 1.5
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, 2 + 4 * progress),
    );
  }

  @override
  bool shouldRepaint(_StampRipplePainter old) =>
      old.progress != progress ||
      old.center != center ||
      old.radius != radius ||
      old.color != color;
}
