import 'dart:math' as math;

import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/deck_float_cards.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/note_chapters.dart';
import 'package:agawaeuleo/presentation/widgets/animated/tap_spring.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';

/// 케어 덱의 한 장 — 무대(일러스트 + 떠 있는 실데이터 조각) + 글(오버라인·이름·
/// 한 줄 설명·열기 버튼).
///
/// 온보딩 스테이지와 같은 원리로 모든 레이어가 페이지 값에 **1:1로** 묶인다.
/// 장면은 페이지뷰 안에 있지만, 무대 레이어는 페이지 이동을 상쇄한 뒤 레이어별
/// 이동 배율(shift)만큼만 움직여 온보딩 고정 무대와 똑같은 깊이감을 낸다.
/// 옆 장면은 미리 빌드되어 있고(allowImplicitScrolling) 중간 지점 전에는 투명해,
/// 스와이프 첫 프레임에 옆 그림이 불쑥 보이지 않는다.
class DeckScene extends StatelessWidget {
  const DeckScene({
    required this.symptom,
    required this.index,
    required this.number,
    required this.groupLabel,
    required this.controller,
    required this.ambient,
    required this.intro,
    required this.stageHeight,
    required this.active,
    required this.onOpen,
    required this.onOpenChapter,
    super.key,
  });

  final Symptom symptom;
  final int index;

  /// 그룹 안 순번(1부터) — 오버라인 mono 번호.
  final int number;
  final String groupLabel;
  final PageController controller;

  /// 0→1 반복 호흡(카드 떠 있음).
  final Animation<double> ambient;

  /// 첫 진입 등장 진행도(0→1).
  final Animation<double> intro;
  final double stageHeight;

  /// 덱이 이 장면에 안착했는지 — 1회성 마이크로 인터랙션 트리거.
  final bool active;
  final VoidCallback onOpen;

  /// 무대 조각(칩·BEST 카드) 탭 — 상세를 그 장(`NoteChapter.slug`)으로 바로 연다.
  final ValueChanged<String> onOpenChapter;

  /// 무대 설계 좌표계. 실제 영역에 contain으로 맞춘다.
  static const Size canvas = Size(360, 300);
  static const double illustrationSize = 212;

  /// 글 영역 높이(오버라인 + 이름 + 설명 + '자세히 보기' 알약).
  /// 글자 배율 상한(1.3)에서도 넘치지 않는 값.
  static const double copyHeight = 186;

  double _offset() {
    final c = controller;
    if (c.hasClients && c.positions.length == 1) {
      final page = c.position.haveDimensions ? c.page : null;
      return (page ?? index.toDouble()) - index;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final illustration = _SceneIllustration(symptom: symptom, active: active);
    final chip = DeckMetaChip(symptom: symptom, onOpenChapter: onOpenChapter);
    final best = DeckBestPickCard(
      symptom: symptom,
      active: active,
      onTap: () => onOpenChapter(NoteChapter.products.slug),
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final scale = math.min(
          width / canvas.width,
          stageHeight / canvas.height,
        );

        final stage = SizedBox(
          height: stageHeight,
          child: FittedBox(
            child: SizedBox.fromSize(
              size: canvas,
              child: AnimatedBuilder(
                animation: Listenable.merge([controller, ambient, intro]),
                builder: (context, _) {
                  final p = _offset();
                  return _stageLayers(
                    p: p,
                    // 페이지뷰가 장면을 -p×width만큼 옮기므로 캔버스 단위로 되돌린다.
                    counter: scale > 0 ? p * width / scale : 0,
                    breath: ambient.value,
                    reveal: intro.value,
                    illustration: illustration,
                    chip: chip,
                    best: best,
                  );
                },
              ),
            ),
          ),
        );

        final copy = _SceneCopy(
          symptom: symptom,
          number: number,
          groupLabel: groupLabel,
          controller: controller,
          index: index,
          intro: intro,
          onOpen: onOpen,
        );

        return Semantics(
          container: true,
          label: '${symptom.name}, ${symptom.tagline ?? ''}',
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onOpen,
            child: Column(
              children: [
                stage,
                SizedBox(height: copyHeight, child: copy),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _stageLayers({
    required double p,
    required double counter,
    required double breath,
    required double reveal,
    required Widget illustration,
    required Widget chip,
    required Widget best,
  }) {
    final a = p.abs().clamp(0.0, 1.0);
    final wave = math.sin(breath * 2 * math.pi);
    final waveB = math.sin(breath * 2 * math.pi + 2.2);

    double phase(double begin, double end) =>
        AppMotion.enter.transform(Interval(begin, end).transform(reveal));

    Widget depth(
      Widget child, {
      required double shift,
      required double fade,
      required double revealed,
      double lift = 0,
      double bob = 0,
      double shrink = 0,
      double tilt = 0,
    }) {
      final opacity = ((1 - a * fade) * revealed).clamp(0.0, 1.0);
      return IgnorePointer(
        // 투명한 옆 장면 조각이 현재 장면의 탭을 가로채지 않게 한다.
        ignoring: opacity < 0.5,
        child: Opacity(
          opacity: opacity,
          child: Transform.translate(
            offset: Offset(
              counter - p * shift,
              a * lift + bob + (1 - revealed) * 18,
            ),
            child: Transform.rotate(
              angle: -p * tilt,
              child: Transform.scale(
                scale: (1 - a * shrink) * (0.94 + 0.06 * revealed),
                // 스와이프 프레임마다 바뀌는 건 이동·투명도뿐 — 떠 있는 카드의 e4
                // 그림자와 글자는 한 번 그린 레이어를 재사용한다.
                child: RepaintBoundary(child: child),
              ),
            ),
          ),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          // 오른쪽 아래 BEST 카드에 가려지지 않게 블롭 중심에서 왼쪽 위로 비켜 선다.
          left: (canvas.width - illustrationSize) / 2 - 18,
          top: (canvas.height - illustrationSize) / 2 - 12,
          width: illustrationSize,
          height: illustrationSize,
          child: depth(
            illustration,
            shift: 120,
            fade: 2.1,
            revealed: phase(0.1, 0.65),
            shrink: 0.12,
            tilt: 0.07,
            bob: wave * 1.5,
          ),
        ),
        Positioned(
          left: 6,
          top: 18,
          child: depth(
            chip,
            shift: 160,
            fade: 2.6,
            revealed: phase(0.3, 0.85),
            lift: 14,
            bob: wave * 3,
          ),
        ),
        Positioned(
          right: 0,
          top: 206,
          child: depth(
            best,
            shift: 240,
            fade: 2.6,
            revealed: phase(0.42, 1),
            lift: -12,
            bob: waveB * 3.5,
          ),
        ),
      ],
    );
  }
}

/// 무대 일러스트 — 안착 순간 한 번 "톡" 튀어 오르며 살짝 흔들린다.
class _SceneIllustration extends StatefulWidget {
  const _SceneIllustration({required this.symptom, required this.active});

  final Symptom symptom;
  final bool active;

  @override
  State<_SceneIllustration> createState() => _SceneIllustrationState();
}

class _SceneIllustrationState extends State<_SceneIllustration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _boop = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 720),
  );

  @override
  void initState() {
    super.initState();
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(_SceneIllustration oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
  }

  void _play() {
    if (!mounted || context.reduceMotion) return;
    _boop.forward(from: 0);
  }

  @override
  void dispose() {
    _boop.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final symptom = widget.symptom;
    final Widget art;
    if (SymptomIllustrations.has(symptom.emojiOrIcon)) {
      art = SymptomIllustration(
        illustrationKey: symptom.emojiOrIcon!,
        size: DeckScene.illustrationSize,
        holdInkWeight: true,
      );
    } else {
      // 일러스트 미등록 증상(신규 콘텐츠) — 톤 워시 원 + 라인 아이콘으로 자리를 지킨다.
      final tone = SymptomTone.resolve(context, symptom.emojiOrIcon);
      art = Center(
        child: Container(
          width: DeckScene.illustrationSize * 0.62,
          height: DeckScene.illustrationSize * 0.62,
          decoration: BoxDecoration(
            color: context.colors.paperRaised,
            shape: BoxShape.circle,
            border: Border.all(
              color: tone.fg.withValues(alpha: 0.28),
              width: 2,
            ),
          ),
          child: Icon(
            SymptomIcons.resolve(symptom.emojiOrIcon),
            size: DeckScene.illustrationSize * 0.3,
            color: tone.fg,
          ),
        ),
      );
    }

    return AnimatedBuilder(
      animation: _boop,
      child: Hero(tag: 'symptom-icon-${symptom.id}', child: art),
      builder: (context, child) {
        final t = _boop.value;
        // 한 번 부풀었다 가라앉는 사인 곡선 + 감쇠하는 좌우 흔들림.
        final pop = math.sin(t * math.pi) * (1 - t * 0.4);
        final wobble = math.sin(t * math.pi * 3) * (1 - t) * 0.045;
        return Transform.rotate(
          angle: wobble,
          child: Transform.scale(scale: 1 + 0.055 * pop, child: child),
        );
      },
    );
  }
}

/// 장면 글 — 오버라인(accent 틱 + mono 번호 + 그룹) · 명조 이름 · 한 줄 설명 · 열기.
///
/// 페이지와 함께 움직이되 블록마다 조금씩 더 빨리 흘러 나가며 흐려진다(온보딩 글과
/// 같은 키네틱 타이포, 추가 이동은 항상 화면 바깥 방향).
class _SceneCopy extends StatelessWidget {
  const _SceneCopy({
    required this.symptom,
    required this.number,
    required this.groupLabel,
    required this.controller,
    required this.index,
    required this.intro,
    required this.onOpen,
  });

  final Symptom symptom;
  final int number;
  final String groupLabel;
  final PageController controller;
  final int index;
  final Animation<double> intro;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    final overline = Row(
      children: [
        Container(
          width: 3,
          height: 14,
          decoration: BoxDecoration(
            color: colors.accent,
            borderRadius: AppRadius.brFull,
          ),
        ),
        const SizedBox(width: AppSpacing.x8),
        Text(
          number.toString().padLeft(2, '0'),
          style: texts.overline.copyWith(
            color: colors.accent,
            fontFamily: AppFontFamily.mono,
          ),
        ),
        const SizedBox(width: AppSpacing.x8),
        Text(
          groupLabel,
          style: texts.caption.copyWith(
            color: colors.ink500,
            fontWeight: FontWeight.w600,
            letterSpacing: 0,
          ),
        ),
      ],
    );

    final name = Hero(
      tag: 'symptom-name-${symptom.id}',
      // 비행 중 텍스트가 기본 스타일/밑줄로 깨지지 않도록 Material로 감싼다.
      child: Material(
        type: MaterialType.transparency,
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            symptom.name,
            maxLines: 1,
            softWrap: false,
            style: texts.displayL.copyWith(color: colors.ink900),
          ),
        ),
      ),
    );

    final tagline = Text(
      symptom.tagline ?? '',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: texts.bodyL.copyWith(color: colors.ink500, height: 1.3),
    );

    // 초보 사용자가 "어디를 눌러야 하는지" 한눈에 알도록, 먹색 원형 화살표 대신
    // 글자가 있는 **전폭 먹 캡슐**을 둔다(하단 먹 캡슐 네비와 같은 문법).
    // 무대·글 어디를 눌러도 같은 곳으로 가지만, 어피던스는 이 캡슐이 진다.
    final openButton = Semantics(
      button: true,
      label: '${symptom.name} 케어 노트 열기',
      excludeSemantics: true,
      child: TapSpring(
        pressedScale: 0.98,
        onTap: onOpen,
        child: Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
          decoration: BoxDecoration(
            color: colors.ink900,
            borderRadius: AppRadius.brFull,
            boxShadow: context.shadows.e2,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '자세히 보기',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: texts.label.copyWith(color: colors.paperRaised),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Icon(
                Icons.arrow_forward_rounded,
                size: 20,
                color: colors.paperRaised,
              ),
            ],
          ),
        ),
      ),
    );

    Widget block(Widget child, double speed, {double introBegin = 0.35}) {
      if (reduce) return child;
      return AnimatedBuilder(
        animation: Listenable.merge([controller, intro]),
        child: child,
        builder: (context, child) {
          final hasPage =
              controller.hasClients &&
              controller.positions.length == 1 &&
              controller.position.haveDimensions;
          final p =
              (hasPage ? controller.page ?? index.toDouble() : index) - index;
          final revealed = AppMotion.enter.transform(
            Interval(introBegin, 1).transform(intro.value),
          );
          return Opacity(
            opacity: ((1 - p.abs() * 1.5) * revealed).clamp(0.0, 1.0),
            child: Transform.translate(
              offset: Offset(-p * speed, (1 - revealed) * 14),
              child: child,
            ),
          );
        },
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x24,
        AppSpacing.x8,
        AppSpacing.x24,
        0,
      ),
      child: Column(
        // 캡슐이 글 폭을 그대로 채운다.
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          block(overline, 24, introBegin: 0.3),
          const SizedBox(height: AppSpacing.x8),
          // 큰 글자 배율에서 먼저 양보하는 건 이름(FittedBox가 줄여 받는다).
          Flexible(child: block(name, 48, introBegin: 0.38)),
          const SizedBox(height: AppSpacing.x4),
          block(tagline, 72, introBegin: 0.46),
          const SizedBox(height: AppSpacing.x12),
          block(openButton, 96, introBegin: 0.5),
        ],
      ),
    );
  }
}
