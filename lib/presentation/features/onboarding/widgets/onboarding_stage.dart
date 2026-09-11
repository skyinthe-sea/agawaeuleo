import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../widgets/symptom/symptom_illustration.dart';
import 'onboarding_float_cards.dart';
import 'onboarding_illustration_data.dart';
import 'onboarding_page_data.dart';

/// 온보딩 히어로 스테이지 — 페이지뷰 **바깥**의 고정 무대.
///
/// 이전 구현은 일러스트를 각 페이지 안에 두고 느린 패럴랙스를 줬는데, 느린
/// 패럴랙스는 옆 페이지 그림을 화면 안쪽으로 끌어당긴다. 페이지뷰는 옆 페이지를
/// 스와이프가 시작돼야 빌드하므로, 첫 프레임에 옆 그림이 불쑥 나타났다.
///
/// 여기서는 세 장면을 한 무대에 항상 올려 두고(빌드 지연 없음), 페이지 컨트롤러의
/// 연속 값으로 레이어마다 이동·페이드·기울기를 **손가락에 1:1로** 연동한다.
/// 깊이감은 레이어별 이동 배율로 만든다(일러스트 < 앞 카드 < 맨 앞 카드).
/// 공유 배경(종이 오림 블롭 + 궤도)은 장면 사이에서 모양과 색이 모핑된다.
class OnboardingStage extends StatefulWidget {
  const OnboardingStage({
    required this.controller,
    required this.pages,
    required this.activeIndex,
    super.key,
  });

  final PageController controller;
  final List<OnboardingPageData> pages;

  /// 스크롤이 **멈춘** 페이지 — 1회성 마이크로 인터랙션(타이핑·스탬프·타이머)
  /// 트리거. `onPageChanged`는 스와이프 중간(0.5 지점)에 불려 장면이 아직 안 보일
  /// 때 연출이 시작되므로 쓰지 않는다.
  final int activeIndex;

  /// 장면 설계 좌표계. 실제 영역에 contain으로 맞춰 기기 크기와 무관하게 구도가 같다.
  static const Size canvas = Size(340, 364);

  @override
  State<OnboardingStage> createState() => _OnboardingStageState();
}

class _OnboardingStageState extends State<OnboardingStage>
    with TickerProviderStateMixin {
  // 떠 있는 카드의 은은한 호흡(상시 반복은 은은하게 — DESIGN v2 §7.3-6 원칙).
  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );

  /// 첫 진입 1회 등장 — 배경 → 일러스트 → 뒤 카드 → 앞 카드 순으로 내려앉는다.
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  bool _introStarted = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final reduce = context.reduceMotion;
    if (reduce) {
      _ambient
        ..stop()
        ..value = 0;
    } else if (!_ambient.isAnimating) {
      _ambient.repeat();
    }
    if (!_introStarted) {
      _introStarted = true;
      if (reduce) {
        _intro.value = 1;
      } else {
        _intro.forward();
      }
    }
  }

  @override
  void dispose() {
    _ambient.dispose();
    _intro.dispose();
    super.dispose();
  }

  /// 등장 진행도의 구간 [start]~[end] 부분(easeOutCubic).
  double _reveal(double start, double end) =>
      AppMotion.enter.transform(Interval(start, end).transform(_intro.value));

  double _page() {
    final c = widget.controller;
    if (c.hasClients && c.positions.length == 1) {
      return c.page ?? widget.activeIndex.toDouble();
    }
    return widget.activeIndex.toDouble();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // 장면 파츠는 여기서 한 번 만들어 빌더에 넘긴다 — 스와이프 프레임마다 트랜스폼만
    // 바뀌고 카드 서브트리는 재빌드되지 않는다(같은 위젯 인스턴스).
    final scenes = <_SceneParts>[
      for (var i = 0; i < widget.pages.length; i++)
        _SceneParts.of(widget.pages[i].scene, active: i == widget.activeIndex),
    ];

    return ExcludeSemantics(
      child: RepaintBoundary(
        child: FittedBox(
          child: SizedBox.fromSize(
            size: OnboardingStage.canvas,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                widget.controller,
                _ambient,
                _intro,
              ]),
              builder: (context, _) {
                final page = _page();
                final breath = _ambient.value;
                final backdropIn = _reveal(0, 0.55);
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: backdropIn,
                        child: Transform.scale(
                          scale: 0.92 + 0.08 * backdropIn,
                          child: CustomPaint(
                            painter: _BackdropPainter(
                              page: page,
                              breath: breath,
                              washes: [
                                colors.accentWash,
                                colors.amberWash,
                                colors.sageWash,
                              ],
                              under: colors.paperStack,
                              orbit: colors.lineStrong,
                              rim: colors.paperBg,
                              planets: [
                                colors.seal,
                                colors.amber,
                                colors.accent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    for (var i = 0; i < scenes.length; i++)
                      ..._layers(scenes[i], page - i, breath),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  /// 장면 하나의 레이어들. [p]는 이 장면 기준 페이지 오프셋(-1 오른쪽 대기 · 0 정위치
  /// · +1 왼쪽으로 나감). |p| ≥ 1이면 불투명도 0 → 페인트 자체를 건너뛴다.
  List<Widget> _layers(_SceneParts s, double p, double breath) {
    final a = p.abs().clamp(0.0, 1.0);
    final wave = math.sin(breath * 2 * math.pi);
    final waveB = math.sin(breath * 2 * math.pi + 2.2);

    Widget depth({
      required Widget child,
      required double shift,
      required double fade,
      required double reveal,
      double lift = 0,
      double bob = 0,
      double shrink = 0,
      double tilt = 0,
    }) {
      return Opacity(
        opacity: ((1 - a * fade) * reveal).clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(-p * shift, a * lift + bob + (1 - reveal) * 20),
          child: Transform.rotate(
            angle: -p * tilt,
            child: Transform.scale(
              scale: (1 - a * shrink) * (0.94 + 0.06 * reveal),
              child: child,
            ),
          ),
        ),
      );
    }

    const illo = _SceneParts.illustrationSize;
    final canvas = OnboardingStage.canvas;
    return [
      Positioned(
        left: (canvas.width - illo) / 2 + s.illustrationDx,
        top: _SceneParts.illustrationTop,
        width: illo,
        height: illo,
        // 선 일러스트 둘이 반투명으로 겹치면 탁해진다 — 중간 지점 전에 서로 비켜
        // 사라지고(빠른 페이드 + 큰 이동), 그 찰나는 모핑 블롭만 남는다.
        child: depth(
          child: s.illustration,
          shift: 110,
          fade: 2.1,
          reveal: _reveal(0.12, 0.7),
          shrink: 0.1,
          tilt: 0.06,
        ),
      ),
      Positioned(
        left: s.backAnchor.left,
        top: s.backAnchor.top,
        right: s.backAnchor.right,
        child: depth(
          child: s.back,
          shift: 150,
          fade: 2.6,
          reveal: _reveal(0.35, 0.88),
          lift: 16,
          bob: wave * 3,
        ),
      ),
      Positioned(
        left: s.frontAnchor.left,
        top: s.frontAnchor.top,
        right: s.frontAnchor.right,
        child: depth(
          child: s.front,
          shift: 230,
          fade: 2.6,
          reveal: _reveal(0.45, 1),
          lift: -12,
          bob: waveB * 3.5,
        ),
      ),
    ];
  }
}

/// 장면 설계 좌표계 안에서 카드를 붙이는 자리(좌 또는 우 기준).
class _Anchor {
  const _Anchor.left(this.left, this.top) : right = null;
  const _Anchor.right(this.right, this.top) : left = null;

  final double? left;
  final double? right;
  final double top;
}

/// 장면 한 장의 구성: 히어로 일러스트 + 뒤 카드(back) + 앞 카드(front).
class _SceneParts {
  const _SceneParts({
    required this.illustration,
    required this.back,
    required this.backAnchor,
    required this.front,
    required this.frontAnchor,
    this.illustrationDx = 0,
  });

  factory _SceneParts.of(OnboardingScene scene, {required bool active}) {
    Widget illo(List<IllustrationShape> shapes) => InkIllustration(
      shapes: shapes,
      size: illustrationSize,
      viewBox: onboardingIllustrationViewBox,
    );
    return switch (scene) {
      OnboardingScene.search => _SceneParts(
        illustration: illo(onboardingCryShapes),
        back: OnboardingSearchPill(active: active),
        backAnchor: const _Anchor.left(4, 18),
        front: const OnboardingResultCard(),
        frontAnchor: const _Anchor.right(0, 272),
      ),
      OnboardingScene.products => _SceneParts(
        illustration: illo(onboardingCareShapes),
        back: const OnboardingRecommendChip(),
        backAnchor: const _Anchor.right(6, 30),
        front: OnboardingBestPickCard(active: active),
        frontAnchor: const _Anchor.left(0, 206),
        // 왼쪽 아래를 덮는 랭킹 카드만큼 가방을 오른쪽으로 비켜 라벨을 살린다.
        illustrationDx: 16,
      ),
      OnboardingScene.tracking => _SceneParts(
        illustration: illo(onboardingSleepShapes),
        back: OnboardingTimerChip(active: active),
        backAnchor: const _Anchor.left(4, 24),
        front: OnboardingTimelineCard(active: active),
        frontAnchor: const _Anchor.right(0, 250),
      ),
    };
  }

  static const double illustrationSize = 250;
  static const double illustrationTop = 64;

  final Widget illustration;
  final Widget back;
  final _Anchor backAnchor;
  final Widget front;
  final _Anchor frontAnchor;

  /// 장면별 일러스트 가로 보정(카드와 겹치는 쪽을 피한다).
  final double illustrationDx;
}

/// 공유 배경 — 종이를 오려 붙인 블롭(아랫장 겹침) + 점선 궤도와 행성 3개.
///
/// 장면마다 블롭 윤곽(8점 반경 배율)과 워시 색이 정해져 있고, 페이지 값으로 그
/// 사이를 보간한다. 그라데이션 없이 단색 면만 쓴다(DESIGN v2 §0 불변 조항).
class _BackdropPainter extends CustomPainter {
  const _BackdropPainter({
    required this.page,
    required this.breath,
    required this.washes,
    required this.under,
    required this.orbit,
    required this.rim,
    required this.planets,
  });

  final double page;
  final double breath;
  final List<Color> washes;
  final Color under;
  final Color orbit;
  final Color rim;
  final List<Color> planets;

  static const List<List<double>> _outlines = <List<double>>[
    <double>[1.00, 0.93, 1.05, 0.95, 1.02, 0.92, 1.06, 0.96],
    <double>[0.94, 1.06, 0.92, 1.03, 0.97, 1.07, 0.93, 1.01],
    <double>[1.05, 0.96, 1.00, 1.07, 0.92, 1.01, 0.96, 1.05],
  ];

  static const double _radius = 136;
  static const Offset _center = Offset(170, 190);

  @override
  void paint(Canvas canvas, Size size) {
    final last = washes.length - 1;
    final clamped = page.clamp(0.0, last.toDouble());
    final i0 = clamped.floor().clamp(0, last);
    final i1 = math.min(i0 + 1, last);
    final f = clamped - i0;

    // ── 블롭 윤곽: 장면 윤곽 보간 + 아주 느린 호흡 + 페이지에 따른 회전.
    final rotation = clamped * 0.55;
    final points = <Offset>[];
    for (var k = 0; k < 8; k++) {
      final r0 = _outlines[i0 % _outlines.length][k];
      final r1 = _outlines[i1 % _outlines.length][k];
      final wobble = 1 + 0.014 * math.sin((breath + k / 8) * 2 * math.pi);
      final r = _radius * (r0 + (r1 - r0) * f) * wobble;
      final angle = rotation + k * math.pi / 4;
      points.add(_center + Offset(math.cos(angle), math.sin(angle)) * r);
    }
    final blob = _smoothClosed(points);

    canvas
      ..drawPath(blob.shift(const Offset(8, 10)), Paint()..color = under)
      ..drawPath(blob, Paint()..color = Color.lerp(washes[i0], washes[i1], f)!);

    // ── 점선 궤도.
    final orbitRadius = _radius * 1.1;
    final orbitRect = Rect.fromCircle(center: _center, radius: orbitRadius);
    final orbitPaint = Paint()
      ..color = orbit
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;
    const dashes = 56;
    const sweep = 2 * math.pi / dashes;
    final dashOffset = clamped * 0.3;
    for (var d = 0; d < dashes; d++) {
      canvas.drawArc(
        orbitRect,
        dashOffset + d * sweep,
        sweep * 0.45,
        false,
        orbitPaint,
      );
    }

    // ── 궤도 위 행성 — 스와이프에 따라 궤도를 돈다. 시작각·속도는 세 장면 모두에서
    // 떠 있는 카드와 겹치지 않는 자리로 골랐다(카드 위치를 옮기면 함께 재확인).
    const bases = <double>[0.15, 3.35, 5.6];
    const speeds = <double>[0.9, 0.9, 0.4];
    const radii = <double>[5.5, 4, 4.5];
    for (var k = 0; k < planets.length; k++) {
      final angle = bases[k] + clamped * speeds[k];
      final c =
          _center + Offset(math.cos(angle), math.sin(angle)) * orbitRadius;
      canvas
        ..drawCircle(c, radii[k] + 2.5, Paint()..color = rim)
        ..drawCircle(c, radii[k], Paint()..color = planets[k]);
    }
  }

  /// 닫힌 Catmull-Rom 스플라인 → 큐빅 베지어.
  static Path _smoothClosed(List<Offset> p) {
    final n = p.length;
    final path = Path()..moveTo(p[0].dx, p[0].dy);
    for (var i = 0; i < n; i++) {
      final p0 = p[(i - 1 + n) % n];
      final p1 = p[i];
      final p2 = p[(i + 1) % n];
      final p3 = p[(i + 2) % n];
      final c1 = p1 + (p2 - p0) / 6;
      final c2 = p2 - (p3 - p1) / 6;
      path.cubicTo(c1.dx, c1.dy, c2.dx, c2.dy, p2.dx, p2.dy);
    }
    return path..close();
  }

  @override
  bool shouldRepaint(_BackdropPainter old) =>
      old.page != page ||
      old.breath != breath ||
      old.under != under ||
      old.orbit != orbit ||
      old.rim != rim ||
      !_sameColors(old.washes, washes) ||
      !_sameColors(old.planets, planets);

  static bool _sameColors(List<Color> a, List<Color> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
