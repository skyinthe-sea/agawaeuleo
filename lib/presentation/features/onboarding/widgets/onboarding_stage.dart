import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../widgets/stage/paper_blob_painter.dart';
import '../../../widgets/symptom/symptom_illustration.dart';
import 'onboarding_float_cards.dart';
import 'onboarding_page_data.dart';
import 'orbit_charms_painter.dart';

/// 온보딩 히어로 스테이지 — 페이지뷰 **바깥**의 고정 무대.
///
/// 이전 구현은 일러스트를 각 페이지 안에 두고 느린 패럴랙스를 줬는데, 느린
/// 패럴랙스는 옆 페이지 그림을 화면 안쪽으로 끌어당긴다. 페이지뷰는 옆 페이지를
/// 스와이프가 시작돼야 빌드하므로, 첫 프레임에 옆 그림이 불쑥 나타났다.
///
/// 여기서는 세 장면을 한 무대에 항상 올려 두고(빌드 지연 없음), 페이지 컨트롤러의
/// 연속 값으로 레이어마다 이동·페이드·기울기를 **손가락에 1:1로** 연동한다.
/// 깊이감은 레이어별 이동 배율로 만든다(일러스트 < 앞 카드 < 맨 앞 카드).
/// 공유 배경([PaperBlobPainter] — 파스텔 블롭)은 장면 사이에서 모양과 색이
/// 모핑되고(딸기 → 버터 → 토마토 워시), 그 위 [OrbitCharmsPainter]가 둥근 점선
/// 궤도와 하트·별·구슬을 스와이프에 따라 돌린다(DESIGN v3 §6 "몽글 클레이").
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

  /// 궤도 장식 — 하트(딸기 핑크) · 별(버터) · 구슬(로즈).
  static const List<OrbitCharm> _charms = <OrbitCharm>[
    OrbitCharm.heart,
    OrbitCharm.star,
    OrbitCharm.bead,
  ];

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
                // 장면별 파스텔 — ① 딸기(검색) ② 버터(용품) ③ 토마토(병원 신호).
                final washes = [
                  colors.accentWash,
                  colors.amberWash,
                  colors.coralWash,
                ];
                return Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned.fill(
                      child: Opacity(
                        opacity: backdropIn,
                        child: Transform.scale(
                          scale: 0.92 + 0.08 * backdropIn,
                          child: CustomPaint(
                            // 블롭만 공용 페인터로 — 궤도·행성은 끄고(0) 점선 궤도 +
                            // 하트·별·구슬을 위에 얹는다.
                            painter: PaperBlobPainter(
                              page: page,
                              breath: breath,
                              washes: washes,
                              under: colors.paperStack,
                              orbit: colors.lineStrong,
                              rim: colors.paperBg,
                              planets: const <Color>[],
                              orbitProgress: 0,
                              planetScale: 0,
                            ),
                            // 장식 시작각·속도는 옛 행성과 같은 자리(세 장면 모두에서
                            // 떠 있는 카드와 겹치지 않는 공용 기본값) — 카드를 옮기면 재확인.
                            foregroundPainter: OrbitCharmsPainter(
                              page: page,
                              lastPage: washes.length - 1,
                              dotColor: colors.lineStrong,
                              rim: colors.paperBg,
                              charms: _charms,
                              colors: [
                                colors.seal,
                                colors.amber,
                                colors.accent,
                              ],
                              sway: breath,
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
        // 클레이 일러스트 둘이 반투명으로 겹치면 탁해진다 — 중간 지점 전에 서로 비켜
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
    Widget illo(String asset) =>
        ClayIllustration(asset: asset, size: illustrationSize);
    return switch (scene) {
      OnboardingScene.search => _SceneParts(
        illustration: illo(ClayScenes.onboardingCry),
        back: OnboardingSearchPill(active: active),
        backAnchor: const _Anchor.left(4, 18),
        front: const OnboardingResultCard(),
        frontAnchor: const _Anchor.right(0, 272),
      ),
      OnboardingScene.products => _SceneParts(
        illustration: illo(ClayScenes.onboardingCare),
        back: const OnboardingRecommendChip(),
        backAnchor: const _Anchor.right(6, 30),
        front: OnboardingBestPickCard(active: active),
        frontAnchor: const _Anchor.left(0, 206),
        // 왼쪽 아래를 덮는 랭킹 카드만큼 가방을 오른쪽으로 비켜 라벨을 살린다.
        illustrationDx: 16,
      ),
      // 병원 신호 — 구름 위 잠(차분히 확인하고 안심하는 밤)과 짝지은 장면.
      OnboardingScene.safety => _SceneParts(
        illustration: illo(ClayScenes.onboardingSleep),
        back: OnboardingAlertChip(active: active),
        backAnchor: const _Anchor.left(4, 24),
        front: OnboardingSignalCard(active: active),
        frontAnchor: const _Anchor.right(0, 222),
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
