import 'dart:math' as math;

import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/symptom_detail_providers.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/note_chapters.dart';
import 'package:agawaeuleo/presentation/widgets/animated/sparkle.dart';
import 'package:agawaeuleo/presentation/widgets/animated/tap_spring.dart';
import 'package:agawaeuleo/presentation/widgets/brand/ink_halo_icon.dart';
import 'package:agawaeuleo/presentation/widgets/stage/paper_blob_painter.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 케어 노트 머리 — 위 막대(뒤로·즐겨찾기) + 히어로 줄(명조 이름 · 무대) + 장 탭.
///
/// 페이지 위에 겹쳐 떠 있는 머리라, 현재 장을 위로 스크롤한 만큼([collapse])
/// 히어로 줄이 접혀 올라가고 위 막대에 작은 이름이 나타난다. 장 사이를 넘기는
/// 동안에는 두 장의 스크롤 위치를 페이지 값으로 보간한 값이 들어와 끊김이 없다.
///
/// 히어로 줄은 포인터를 통과시킨다(아래는 페이지의 빈 윗여백) — 그 자리에서
/// 시작한 드래그도 페이지를 넘기거나 스크롤한다. 위 막대와 탭은 아래 콘텐츠로
/// 탭이 새지 않게 막는다.
class NoteHeader extends StatelessWidget {
  const NoteHeader({
    required this.symptom,
    required this.chapters,
    required this.page,
    required this.collapse,
    required this.ambient,
    required this.productCount,
    required this.onSelect,
    super.key,
  });

  final Symptom symptom;
  final List<NoteChapter> chapters;

  /// 연속 페이지 값(장 인덱스).
  final double page;

  /// 접힌 거리(0 ~ [collapseRange]).
  final double collapse;
  final Animation<double> ambient;
  final int productCount;
  final ValueChanged<int> onSelect;

  static const double topBarHeight = 56;
  static const double heroHeight = 148;
  static const double tabsHeight = 52;
  static const double maxExtent = topBarHeight + heroHeight + tabsHeight;
  static const double collapseRange = heroHeight;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final c = (collapse / collapseRange).clamp(0.0, 1.0);
    final extent = maxExtent - collapse.clamp(0.0, collapseRange);
    final hero = heroHeight - collapse.clamp(0.0, collapseRange);

    return SizedBox(
      height: extent,
      child: Stack(
        children: [
          // 배경 — 불투명 종이 + 그레인, 접힐수록 아래로 그림자가 선다.
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.paperBg,
                  border: Border(bottom: BorderSide(color: colors.line)),
                  boxShadow: BoxShadow.lerpList(
                    const <BoxShadow>[],
                    context.shadows.e2,
                    c,
                  ),
                ),
                child: const PaperBackground(child: SizedBox.expand()),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: topBarHeight,
            height: hero,
            child: IgnorePointer(
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minHeight: heroHeight,
                  maxHeight: heroHeight,
                  child: Opacity(
                    opacity: (1 - c * 1.4).clamp(0.0, 1.0),
                    child: Transform.translate(
                      offset: Offset(0, -c * 28),
                      // 접힌 상태에서 되돌아갈 때 보이지 않는 자리에서 날아가지 않게.
                      child: HeroMode(
                        enabled: c < 0.5,
                        child: _HeroRow(
                          symptom: symptom,
                          chapters: chapters,
                          page: page,
                          ambient: ambient,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            top: 0,
            height: topBarHeight,
            child: _TopBar(symptom: symptom, titleShown: c),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: tabsHeight,
            child: _ChapterTabs(
              chapters: chapters,
              page: page,
              productCount: productCount,
              onSelect: onSelect,
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends ConsumerWidget {
  const _TopBar({required this.symptom, required this.titleShown});

  final Symptom symptom;

  /// 접힘 정도(0~1). 끝 무렵에만 작은 이름이 떠오른다.
  final double titleShown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.texts;
    final isFavorite =
        ref.watch(symptomFavoriteProvider(symptom.id)).value ?? false;
    final t = ((titleShown - 0.55) / 0.45).clamp(0.0, 1.0);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          const SizedBox(width: AppSpacing.x8),
          _RoundButton(
            semanticLabel: '뒤로 가기',
            onTap: () => Navigator.of(context).maybePop(),
            child: Icon(
              Icons.arrow_back_rounded,
              size: 22,
              color: colors.ink900,
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          Expanded(
            child: ExcludeSemantics(
              excluding: t < 0.5,
              child: Opacity(
                opacity: t,
                child: Transform.translate(
                  offset: Offset(0, (1 - t) * 8),
                  child: Text(
                    symptom.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texts.title.copyWith(color: colors.ink900),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          _RoundButton(
            semanticLabel: isFavorite ? '즐겨찾기 해제' : '즐겨찾기',
            child: Sparkle(
              isActive: isFavorite,
              onChanged: (_) => ref
                  .read(favoriteRepositoryProvider)
                  .toggle(
                    targetType: FavoriteTargetType.symptom,
                    targetId: symptom.id,
                  ),
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
        ],
      ),
    );
  }
}

/// 위 막대의 동그란 종이 버튼(44 + 헤어라인). [onTap]이 없으면 자식이 탭을 받는다.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.child,
    required this.semanticLabel,
    this.onTap,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final circle = Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.paperRaised,
        shape: BoxShape.circle,
        border: Border.all(color: colors.line),
      ),
      child: child,
    );
    if (onTap == null) return circle;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: TapSpring(onTap: onTap, child: circle),
    );
  }
}

/// 히어로 줄 — 왼쪽 명조 이름(Hero)·한 줄 설명, 오른쪽 무대(블롭 + 일러스트 Hero).
class _HeroRow extends StatelessWidget {
  const _HeroRow({
    required this.symptom,
    required this.chapters,
    required this.page,
    required this.ambient,
  });

  final Symptom symptom;
  final List<NoteChapter> chapters;
  final double page;
  final Animation<double> ambient;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final group = symptom.audience == SymptomAudience.mom ? '엄마 돌봄' : '아기 돌봄';

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.x12,
        AppSpacing.x8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Row(
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
                      '케어 노트',
                      style: texts.caption.copyWith(
                        color: colors.ink700,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0,
                      ),
                    ),
                    Text(
                      '  ·  $group',
                      style: texts.caption.copyWith(
                        color: colors.ink300,
                        letterSpacing: 0,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x8),
                Hero(
                  tag: 'symptom-name-${symptom.id}',
                  child: Material(
                    type: MaterialType.transparency,
                    child: Text(
                      symptom.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: texts.display.copyWith(color: colors.ink900),
                    ),
                  ),
                ),
                if ((symptom.tagline ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.x2),
                  Text(
                    symptom.tagline!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: texts.body.copyWith(color: colors.ink500),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          SizedBox.square(
            dimension: NoteHeader.heroHeight - AppSpacing.x8,
            child: _NoteStage(
              symptom: symptom,
              chapters: chapters,
              page: page,
              ambient: ambient,
            ),
          ),
        ],
      ),
    );
  }
}

/// 머리 무대 — 장마다 색이 바뀌는 종이 블롭 위에 증상 일러스트가 앉는다.
/// 장을 넘기는 동안 일러스트가 한 번 기울었다가(책장을 넘기듯) 제자리로 온다.
class _NoteStage extends StatelessWidget {
  const _NoteStage({
    required this.symptom,
    required this.chapters,
    required this.page,
    required this.ambient,
  });

  final Symptom symptom;
  final List<NoteChapter> chapters;
  final double page;
  final Animation<double> ambient;

  static const Size _canvas = Size(140, 140);
  static const double _illustration = 112;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = SymptomTone.resolve(context, symptom.emojiOrIcon);
    final washes = [
      for (final chapter in chapters)
        switch (chapter) {
          NoteChapter.overview => tone.wash,
          NoteChapter.emergency => colors.coralWash,
          NoteChapter.guide => colors.sageWash,
          NoteChapter.products => colors.amberWash,
        },
    ];

    final Widget art = SymptomIllustrations.has(symptom.emojiOrIcon)
        ? SymptomIllustration(
            illustrationKey: symptom.emojiOrIcon!,
            size: _illustration,
            holdInkWeight: true,
          )
        : InkHaloIcon(
            size: 64,
            icon: SymptomIcons.resolve(symptom.emojiOrIcon),
            washColor: tone.wash,
            fgColor: tone.fg,
            elevated: true,
          );
    final hero = Hero(tag: 'symptom-icon-${symptom.id}', child: art);

    // 넘김 중간(.5)에 가장 크게 기울고 정수 페이지에서 바로 선다.
    final fraction = page - page.floorToDouble();
    final turn = math.sin(fraction * math.pi) * 0.09;

    return FittedBox(
      child: SizedBox.fromSize(
        size: _canvas,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: ambient,
                builder: (context, _) => CustomPaint(
                  painter: PaperBlobPainter(
                    page: page,
                    breath: ambient.value,
                    washes: washes,
                    under: colors.paperStack,
                    orbit: colors.lineStrong,
                    rim: colors.paperBg,
                    planets: [colors.seal, colors.amber, colors.accent],
                    center: const Offset(70, 72),
                    radius: 50,
                    orbitScale: 1.26,
                    rotationPerPage: 0.6,
                    underOffset: const Offset(4, 5),
                    planetBases: const [-0.9, 2.3, 0.9],
                    planetSpeeds: const [0.7, 0.5, 0.35],
                    planetRadii: const [3.5, 2.5, 3],
                  ),
                ),
              ),
            ),
            Transform.rotate(
              angle: turn,
              child: Transform.scale(
                scale: 1 - math.sin(fraction * math.pi) * 0.06,
                child: SizedBox.square(dimension: _illustration, child: hero),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 장 탭 — 같은 폭 칸 + 페이지 연속 값을 따라 미끄러지는 먹 막대.
class _ChapterTabs extends StatelessWidget {
  const _ChapterTabs({
    required this.chapters,
    required this.page,
    required this.productCount,
    required this.onSelect,
  });

  final List<NoteChapter> chapters;
  final double page;
  final int productCount;
  final ValueChanged<int> onSelect;

  static const double _barWidth = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          const side = AppSpacing.x8;
          final cell = (constraints.maxWidth - side * 2) / chapters.length;
          final clamped = page.clamp(0.0, (chapters.length - 1).toDouble());
          return Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: side),
                  child: Row(
                    children: [
                      for (final (i, chapter) in chapters.indexed)
                        SizedBox(
                          width: cell,
                          child: _Tab(
                            chapter: chapter,
                            emphasis: (1 - (clamped - i).abs()).clamp(0.0, 1.0),
                            selected: clamped.round() == i,
                            count: chapter == NoteChapter.products
                                ? productCount
                                : null,
                            onTap: () => onSelect(i),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Positioned(
                left: side + clamped * cell + (cell - _barWidth) / 2,
                bottom: AppSpacing.x8,
                child: Container(
                  width: _barWidth,
                  height: 3,
                  decoration: BoxDecoration(
                    color: colors.ink900,
                    borderRadius: AppRadius.brFull,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Tab extends StatelessWidget {
  const _Tab({
    required this.chapter,
    required this.emphasis,
    required this.selected,
    required this.onTap,
    this.count,
  });

  final NoteChapter chapter;

  /// 0(멀리) ~ 1(현재) — 글자색 보간.
  final double emphasis;
  final bool selected;
  final int? count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Semantics(
      button: true,
      selected: selected,
      label: count == null ? chapter.label : '${chapter.label} $count개',
      excludeSemantics: true,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  chapter.label,
                  style: texts.body.copyWith(
                    color: Color.lerp(colors.ink300, colors.ink900, emphasis),
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
                if (count != null && count! > 0) ...[
                  const SizedBox(width: AppSpacing.x4),
                  Text(
                    '$count',
                    style: texts.caption.copyWith(
                      color: Color.lerp(colors.ink300, colors.amber, emphasis),
                      fontFamily: AppFontFamily.mono,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
