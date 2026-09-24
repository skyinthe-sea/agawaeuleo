import 'dart:async';
import 'dart:math' as math;

import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/deck_rail.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/deck_scene.dart';
import 'package:agawaeuleo/presentation/widgets/stage/paper_blob_painter.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';

/// §11.7 홈 **케어 덱**(2026-09-11 홈 전면 개편 — 그리드 폐기).
///
/// 증상을 격자로 늘어놓는 대신 한 장씩 넘겨 보는 무대다. 온보딩 히어로 스테이지의
/// 문법을 그대로 가져왔다:
/// - 뒤에는 종이 오림 블롭([PaperBlobPainter])이 증상 톤 색으로 모핑하고,
/// - 가운데 증상 일러스트와 떠 있는 **실데이터 조각**(추천 용품 수·1위 제품)이
///   레이어별 속도로 손가락에 1:1로 따라오며,
/// - 멈추면 일러스트가 톡 튀고 1위 배지가 도장 찍히듯 앉는다.
///
/// 위에는 '아기 돌봄 / 엄마 돌봄' 그룹 탭과 mono 카운터, 아래에는 한 번의 탭으로
/// 원하는 증상으로 건너뛰는 [DeckRail]이 붙는다.
class CareDeck extends StatefulWidget {
  const CareDeck({
    required this.symptoms,
    required this.onOpen,
    required this.playIntro,
    required this.onIntroPlayed,
    super.key,
  });

  /// 활성 증상 전체(`order_index` 순). 그룹은 [Symptom.audience]로 나눈다.
  final List<Symptom> symptoms;

  /// 증상 상세 열기 — [chapter]가 있으면 그 장으로 바로 연다.
  final void Function(Symptom symptom, {String? chapter}) onOpen;

  /// 세션 첫 진입 등장(배경 → 일러스트 → 조각)과 넘기기 힌트를 재생할지.
  final bool playIntro;
  final VoidCallback onIntroPlayed;

  @override
  State<CareDeck> createState() => _CareDeckState();
}

/// 덱 그룹 — 탭 라벨과 대상.
enum DeckGroup {
  baby('아기 돌봄', SymptomAudience.baby),
  mom('엄마 돌봄', SymptomAudience.mom);

  const DeckGroup(this.label, this.audience);

  final String label;
  final SymptomAudience audience;
}

class _CareDeckState extends State<CareDeck> with TickerProviderStateMixin {
  static const double _groupBarHeight = 44;

  late final AnimationController _ambient = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 4200),
  );
  late final AnimationController _intro = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );

  /// 넘기기 힌트 — 첫 장이 살짝 옆으로 밀렸다 돌아온다(세션 1회).
  late final AnimationController _nudge = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );

  final Map<DeckGroup, PageController> _controllers = {};
  final Map<DeckGroup, int> _settled = {};
  DeckGroup _group = DeckGroup.baby;
  bool _introStarted = false;
  bool _userTouched = false;

  @override
  void initState() {
    super.initState();
    _nudge.addListener(_applyNudge);
  }

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
      if (reduce || !widget.playIntro) {
        _intro.value = 1;
      } else {
        _intro.forward().whenCompleteOrCancel(() {
          if (!mounted) return;
          widget.onIntroPlayed();
          _startNudge();
        });
      }
    }
  }

  @override
  void dispose() {
    _nudge.removeListener(_applyNudge);
    _ambient.dispose();
    _intro.dispose();
    _nudge.dispose();
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  List<Symptom> _symptomsOf(DeckGroup group) => [
    for (final s in widget.symptoms)
      if ((s.audience == SymptomAudience.mom) == (group == DeckGroup.mom)) s,
  ];

  List<DeckGroup> get _groups => [
    for (final g in DeckGroup.values)
      if (_symptomsOf(g).isNotEmpty) g,
  ];

  PageController _controllerOf(DeckGroup group) =>
      _controllers.putIfAbsent(group, PageController.new);

  void _selectGroup(DeckGroup group) {
    if (group == _group) return;
    unawaited(AppHaptics.toggle());
    // 힌트는 첫 그룹의 첫 장에서만 — 그룹을 바꾸면 곧바로 멈춘다.
    _userTouched = true;
    if (_nudge.isAnimating) _nudge.stop();
    // 떠났던 그룹의 페이지뷰는 이미 해제돼 컨트롤러가 첫 장으로 되돌아간다 —
    // 보던 장에서 다시 열리도록 그 자리를 시작 페이지로 삼아 새로 만든다.
    final existing = _controllers[group];
    if (existing != null && !existing.hasClients) {
      existing.dispose();
      _controllers[group] = PageController(initialPage: _settled[group] ?? 0);
    }
    setState(() => _group = group);
  }

  void _startNudge() {
    if (!mounted || _userTouched || context.reduceMotion) return;
    final c = _controllerOf(_group);
    if (!c.hasClients || _symptomsOf(_group).length < 2) return;
    unawaited(_nudge.forward(from: 0));
  }

  double _nudgeBase = 0;

  void _applyNudge() {
    final c = _controllerOf(_group);
    if (!c.hasClients || _userTouched) {
      _nudge.stop();
      return;
    }
    if (_nudge.value == 0) _nudgeBase = c.position.pixels;
    // 한 번 밀었다가 스프링처럼 돌아오는 사인 곡선(최대 화면 폭의 9%).
    final t = _nudge.value;
    final swing = math.sin(t * math.pi) * math.pow(1 - t, 0.6);
    c.position.jumpTo(_nudgeBase + swing * c.position.viewportDimension * 0.09);
  }

  bool _onScroll(ScrollNotification n) {
    if (n.depth != 0) return false;
    if (n is ScrollStartNotification && n.dragDetails != null) {
      _userTouched = true;
      if (_nudge.isAnimating) _nudge.stop();
    }
    if (n is ScrollEndNotification) {
      final c = _controllerOf(_group);
      final page = c.hasClients ? c.page : null;
      if (page != null) {
        final settled = page.round();
        if ((page - settled).abs() < 0.01 &&
            settled != (_settled[_group] ?? 0)) {
          setState(() => _settled[_group] = settled);
        }
      }
    }
    return false;
  }

  void _jumpTo(int index) {
    final c = _controllerOf(_group);
    if (!c.hasClients) return;
    _userTouched = true;
    final current = c.page?.round() ?? 0;
    if (current == index) return;
    unawaited(AppHaptics.toggle());
    // 멀리 건너뛸 때 스무 장이 스쳐 지나가면 어지럽다 — 가까우면 넘기고, 멀면 바로 간다.
    if (context.reduceMotion || (index - current).abs() > 3) {
      c.jumpToPage(index);
      setState(() => _settled[_group] = index);
    } else {
      unawaited(
        c.animateToPage(
          index,
          duration: AppMotion.slow,
          curve: AppMotion.enter,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final groups = _groups;
    if (groups.isEmpty) return const SizedBox.shrink();
    if (!groups.contains(_group)) _group = groups.first;

    return Column(
      children: [
        SizedBox(
          height: _groupBarHeight,
          child: _GroupBar(
            groups: groups,
            selected: _group,
            countOf: (g) => _symptomsOf(g).length,
            controller: _controllerOf(_group),
            onSelect: _selectGroup,
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: AppMotion.resolve(context, AppMotion.base),
            switchInCurve: AppMotion.enter,
            switchOutCurve: AppMotion.exit,
            layoutBuilder: (current, previous) =>
                Stack(fit: StackFit.expand, children: [...previous, ?current]),
            child: _DeckBody(
              key: ValueKey(_group),
              group: _group,
              symptoms: _symptomsOf(_group),
              controller: _controllerOf(_group),
              settledIndex: _settled[_group] ?? 0,
              ambient: _ambient,
              intro: _intro,
              onScroll: _onScroll,
              onPageChanged: (_) => unawaited(AppHaptics.toggle()),
              onOpen: widget.onOpen,
              onSelect: _jumpTo,
            ),
          ),
        ),
      ],
    );
  }
}

/// 한 그룹의 덱 — 배경 블롭 + 장면 페이지뷰 + 레일.
class _DeckBody extends StatelessWidget {
  const _DeckBody({
    required this.group,
    required this.symptoms,
    required this.controller,
    required this.settledIndex,
    required this.ambient,
    required this.intro,
    required this.onScroll,
    required this.onPageChanged,
    required this.onOpen,
    required this.onSelect,
    super.key,
  });

  final DeckGroup group;
  final List<Symptom> symptoms;
  final PageController controller;
  final int settledIndex;
  final Animation<double> ambient;
  final Animation<double> intro;
  final NotificationListenerCallback<ScrollNotification> onScroll;
  final ValueChanged<int> onPageChanged;
  final void Function(Symptom symptom, {String? chapter}) onOpen;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final washes = [
      for (final s in symptoms)
        SymptomTone.resolve(context, s.emojiOrIcon).wash,
    ];

    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stageHeight = math.max(
                0.0,
                constraints.maxHeight - DeckScene.copyHeight,
              );
              return Stack(
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 0,
                    height: stageHeight,
                    child: IgnorePointer(
                      child: RepaintBoundary(
                        child: FittedBox(
                          child: SizedBox.fromSize(
                            size: DeckScene.canvas,
                            child: AnimatedBuilder(
                              animation: Listenable.merge([
                                controller,
                                ambient,
                                intro,
                              ]),
                              builder: (context, _) {
                                final hasPage =
                                    controller.hasClients &&
                                    controller.positions.length == 1 &&
                                    controller.position.haveDimensions;
                                final page = hasPage
                                    ? controller.page ?? 0.0
                                    : settledIndex.toDouble();
                                final shown = AppMotion.enter.transform(
                                  const Interval(
                                    0,
                                    0.55,
                                  ).transform(intro.value),
                                );
                                return Opacity(
                                  opacity: shown,
                                  child: Transform.scale(
                                    scale: 0.92 + 0.08 * shown,
                                    child: CustomPaint(
                                      painter: PaperBlobPainter(
                                        page: page,
                                        breath: ambient.value,
                                        washes: washes,
                                        under: colors.paperStack,
                                        orbit: colors.lineStrong,
                                        rim: colors.paperBg,
                                        planets: [
                                          colors.seal,
                                          colors.amber,
                                          colors.accent,
                                        ],
                                        center: const Offset(180, 150),
                                        radius: 112,
                                        orbitScale: 1.17,
                                        rotationPerPage: 0.35,
                                        // 칩(좌상)·BEST 카드(우하)를 피한 자리에서
                                        // 천천히 흐른다.
                                        planetBases: const [2.5, -0.55, 1.95],
                                        planetSpeeds: const [0.22, 0.16, 0.1],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: NotificationListener<ScrollNotification>(
                      onNotification: onScroll,
                      child: PageView.builder(
                        controller: controller,
                        // 옆 장면을 미리 빌드 — 스와이프 첫 프레임 빌드 지연 제거.
                        allowImplicitScrolling: true,
                        itemCount: symptoms.length,
                        onPageChanged: onPageChanged,
                        itemBuilder: (context, i) {
                          final symptom = symptoms[i];
                          return DeckScene(
                            key: ValueKey(symptom.id),
                            symptom: symptom,
                            index: i,
                            number: i + 1,
                            groupLabel: group.label,
                            controller: controller,
                            ambient: ambient,
                            intro: intro,
                            stageHeight: stageHeight,
                            active: i == settledIndex,
                            onOpen: () => onOpen(symptom),
                            onOpenChapter: (chapter) =>
                                onOpen(symptom, chapter: chapter),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        DeckRail(
          symptoms: symptoms,
          controller: controller,
          settledIndex: settledIndex,
          onSelect: onSelect,
        ),
      ],
    );
  }
}

/// 덱 머리 — 그룹 탭('아기 돌봄 25' / '엄마 돌봄 7') + 현재 위치 mono 카운터.
class _GroupBar extends StatelessWidget {
  const _GroupBar({
    required this.groups,
    required this.selected,
    required this.countOf,
    required this.controller,
    required this.onSelect,
  });

  final List<DeckGroup> groups;
  final DeckGroup selected;
  final int Function(DeckGroup) countOf;
  final PageController controller;
  final ValueChanged<DeckGroup> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final total = countOf(selected);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x12),
      child: Row(
        children: [
          for (final g in groups)
            _GroupTab(
              label: g.label,
              count: countOf(g),
              selected: g == selected,
              onTap: () => onSelect(g),
            ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.x12),
            child: AnimatedBuilder(
              animation: controller,
              builder: (context, _) {
                final hasPage =
                    controller.hasClients &&
                    controller.positions.length == 1 &&
                    controller.position.haveDimensions;
                final current = hasPage ? (controller.page ?? 0).round() : 0;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedSwitcher(
                      duration: AppMotion.resolve(context, AppMotion.fast),
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.35),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: Text(
                        (current + 1).toString().padLeft(2, '0'),
                        key: ValueKey(current),
                        style: texts.data.copyWith(color: colors.ink900),
                      ),
                    ),
                    Text(
                      ' / ${total.toString().padLeft(2, '0')}',
                      style: texts.caption.copyWith(
                        color: colors.ink300,
                        fontFamily: AppFontFamily.mono,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupTab extends StatelessWidget {
  const _GroupTab({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final duration = AppMotion.resolve(context, AppMotion.fast);

    return Semantics(
      button: true,
      selected: selected,
      label: '$label $count개',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: duration,
                      style: texts.body.copyWith(
                        color: selected ? colors.ink900 : colors.ink300,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      child: Text(label),
                    ),
                    const SizedBox(width: AppSpacing.x4),
                    Text(
                      '$count',
                      style: texts.caption.copyWith(
                        color: selected ? colors.accent : colors.ink300,
                        fontFamily: AppFontFamily.mono,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x4),
                AnimatedContainer(
                  duration: duration,
                  curve: AppMotion.enter,
                  width: selected ? 20 : 0,
                  height: 3,
                  decoration: BoxDecoration(
                    color: colors.ink900,
                    borderRadius: AppRadius.brFull,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
