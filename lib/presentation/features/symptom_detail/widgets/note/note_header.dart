import 'dart:math' as math;

import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/symptom_detail_providers.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/detail_clay.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/note_chapters.dart';
import 'package:agawaeuleo/presentation/widgets/animated/sparkle.dart';
import 'package:agawaeuleo/presentation/widgets/animated/tap_spring.dart';
import 'package:agawaeuleo/presentation/widgets/brand/ink_halo_icon.dart';
import 'package:agawaeuleo/presentation/widgets/stage/paper_blob_painter.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 케어 노트 머리 — 위 막대(뒤로·즐겨찾기) + 히어로 줄(주아체 이름 · 무대) + 장 탭.
///
/// DESIGN v3 "몽글 클레이" — 크림 바탕 위에 장마다 색이 바뀌는 파스텔 무대(블롭)와
/// 클레이 일러스트, 장 탭은 알약 세그먼트(흐르는 젤리 알약 + 두 겹 라벨).
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
  static const double heroHeight = 156;
  static const double tabsHeight = 60;
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
          // 배경 — 불투명 크림 + 점토 결. 헤어라인 대신 접힐수록 장밋빛 그림자가
          // 아래로 번진다(펼친 상태에서는 아래 장과 한 면으로 이어진다).
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.paperBg,
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
              audience: symptom.audience,
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

/// 위 막대의 동그란 클레이 버튼(44 + 윗면 광택 + e1, 헤어라인 없음). 누르는 자리는
/// 48로 넉넉히 잡는다. [onTap]이 없으면 자식이 탭을 받는다.
class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.child,
    required this.semanticLabel,
    this.onTap,
  });

  final Widget child;
  final String semanticLabel;
  final VoidCallback? onTap;

  static const double _size = 44;
  static const double _hit = 48;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final circle = Container(
      width: _size,
      height: _size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ClaySheen.gradient(context, colors.paperRaised),
        boxShadow: context.shadows.e1,
      ),
      child: child,
    );
    if (onTap == null) return circle;
    return Semantics(
      button: true,
      label: semanticLabel,
      excludeSemantics: true,
      child: TapSpring(
        onTap: onTap,
        child: SizedBox.square(
          dimension: _hit,
          child: Center(child: circle),
        ),
      ),
    );
  }
}

/// 히어로 줄 — 왼쪽 스티커 라벨·주아체 이름(Hero)·한 줄 설명, 오른쪽 무대
/// (파스텔 블롭 + 클레이 일러스트 Hero).
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
    final tone = DetailTone.audience(context, symptom.audience);

    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        0,
        AppSpacing.x8,
        AppSpacing.x8,
      ),
      child: Row(
        children: [
          Expanded(
            // 고정 높이(heroHeight) 머리라 큰 글자에서 두 줄 이름 + 소개가 넘치지 않게
            // 배율 상한을 둔다(1.2에서 148dp 안에 들어옴 — 좁은 폰 두 줄 이름 기준).
            child: MediaQuery.withClampedTextScaling(
              maxScaleFactor: 1.2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // 스티커 라벨 — 대상별 톤(아기 딸기 / 엄마 라일락) + 작은 하트.
                  StickerChip(
                    label: '케어 노트 · $group',
                    icon: Icons.favorite_rounded,
                    wash: tone.wash,
                    fg: tone.fg,
                    dense: true,
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
          ),
          const SizedBox(width: AppSpacing.x4),
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

/// 머리 무대 — 장마다 색이 바뀌는 파스텔 블롭(톤 wash 쿠션) 위에 클레이 일러스트가
/// 앉는다. 장을 넘기는 동안 일러스트가 한 번 기울었다가(책장을 넘기듯) 제자리로 온다.
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

  /// 120 초과 — [ClayIllustration]의 원본 디코드 구간이라 홈 덱 무대(212)와 같은
  /// 디코드를 공유해 Hero 비행 중 다시 디코딩하며 깜박이지 않는다.
  static const double _illustration = 126;

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
                    center: const Offset(70, 74),
                    radius: 52,
                    orbitScale: 1.22,
                    rotationPerPage: 0.6,
                    underOffset: const Offset(4, 5),
                    planetBases: const [-0.9, 2.3, 0.9],
                    planetSpeeds: const [0.7, 0.5, 0.35],
                    // 하트·반짝이·동그라미 스티커(DESIGN v3) — 작은 캔버스라 조금 키운다.
                    planetRadii: const [5, 4.5, 3.5],
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

/// 장 탭 — 알약 세그먼트(DESIGN v3 §5.3·§6).
///
/// wash 트랙 위를 페이지 연속 값을 따라 **젤리 알약**(대상 톤 + 클레이 광택)이
/// 미끄러진다. 라벨은 두 겹 — 트랙 위 코코아 글자 위에, 알약 모양으로 오려 낸
/// 크림 글자를 겹쳐 알약 가장자리에서 글자색이 뒤집힌다(하단 탭바와 같은 문법).
/// 탭·시맨틱은 맨 위 투명한 칸 한 겹이 전담한다.
class _ChapterTabs extends StatelessWidget {
  const _ChapterTabs({
    required this.chapters,
    required this.page,
    required this.productCount,
    required this.audience,
    required this.onSelect,
  });

  final List<NoteChapter> chapters;
  final double page;
  final int productCount;
  final SymptomAudience audience;
  final ValueChanged<int> onSelect;

  /// 트랙 바깥 여백 · 위/아래 여백 · 알약과 트랙 사이 틈. 아래 여백은 알약의
  /// 톤 그림자가 머리 경계에서 잘리지 않을 만큼 둔다.
  static const double _side = AppSpacing.x16;
  static const double _top = AppSpacing.x4 + AppSpacing.x2;
  static const double _bottom = AppSpacing.x12;
  static const double _inset = AppSpacing.x4;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final tone = DetailTone.audience(context, audience);

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final n = chapters.length;
          final trackHeight = constraints.maxHeight - _top - _bottom;
          final inner = constraints.maxWidth - (_side + _inset) * 2;
          final cell = inner / n;
          final clamped = page.clamp(0.0, (n - 1).toDouble());
          final selected = clamped.round();
          final thumb = Rect.fromLTWH(
            _side + _inset + clamped * cell,
            _top + _inset,
            cell,
            trackHeight - _inset * 2,
          );

          // 라벨 한 겹(시맨틱은 맨 위 탭 칸이 전담하므로 제외).
          Widget labels(Color color) => Positioned(
            left: _side + _inset,
            top: _top + _inset,
            width: inner,
            height: thumb.height,
            child: ExcludeSemantics(
              child: Row(
                children: [
                  for (final chapter in chapters)
                    SizedBox(
                      width: cell,
                      child: _TabLabel(
                        chapter: chapter,
                        color: color,
                        count: chapter == NoteChapter.products
                            ? productCount
                            : null,
                      ),
                    ),
                ],
              ),
            ),
          );

          return Stack(
            children: [
              // 트랙 — 대상 톤 wash 알약.
              Positioned(
                left: _side,
                right: _side,
                top: _top,
                height: trackHeight,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: tone.wash,
                    borderRadius: AppRadius.brFull,
                  ),
                ),
              ),
              // 바깥 글자(코코아) — 알약이 지나가면 그 아래로 가려진다.
              labels(colors.ink700),
              // 흐르는 흰 젤리 알약(SlidingSegment와 같은 문법) — 작은 글자라
              // 채운 톤 면 대신 크림 면 + 톤 글자로 AA를 지킨다.
              Positioned.fromRect(
                rect: thumb,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: ClaySheen.gradient(context, colors.paperRaised),
                    borderRadius: AppRadius.brFull,
                    boxShadow: context.shadows.e1,
                  ),
                ),
              ),
              // 알약 안 글자(대상 톤) — 알약 모양으로 오려 낸 두 번째 겹.
              Positioned.fill(
                child: ClipPath(
                  clipper: _PillClipper(thumb),
                  child: Stack(children: [labels(tone.fg)]),
                ),
              ),
              // 탭·시맨틱 전담 — 칸마다 탭 높이 전체(≥48)를 누를 수 있다.
              Positioned(
                left: _side + _inset,
                top: 0,
                bottom: 0,
                width: inner,
                child: Row(
                  children: [
                    for (final (i, chapter) in chapters.indexed)
                      SizedBox(
                        width: cell,
                        child: Semantics(
                          button: true,
                          selected: selected == i,
                          label: chapter == NoteChapter.products
                              ? '${chapter.label} $productCount개'
                              : chapter.label,
                          excludeSemantics: true,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => onSelect(i),
                            child: const SizedBox.expand(),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// 탭 한 칸의 글자(장 이름 + 추천 용품 개수는 주아체 숫자). 색은 겹마다 다르다.
class _TabLabel extends StatelessWidget {
  const _TabLabel({required this.chapter, required this.color, this.count});

  final NoteChapter chapter;
  final Color color;
  final int? count;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts;
    return Center(
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                chapter.label,
                style: texts.body.copyWith(
                  color: color,
                  fontWeight: FontWeight.w700,
                  height: 1.2,
                ),
              ),
              if (count != null && count! > 0) ...[
                const SizedBox(width: AppSpacing.x4),
                ClayNumber('$count', color: color, size: 15),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// 흐르는 알약 모양 클립(두 번째 라벨 겹을 알약 안에만 보이게).
class _PillClipper extends CustomClipper<Path> {
  const _PillClipper(this.rect);

  final Rect rect;

  @override
  Path getClip(Size size) => Path()
    ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(rect.height / 2)));

  @override
  bool shouldReclip(_PillClipper oldClipper) => oldClipper.rect != rect;
}
