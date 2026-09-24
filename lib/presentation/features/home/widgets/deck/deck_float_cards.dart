import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/deck_palette.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/symptom_detail_providers.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/note/note_chapters.dart';
import 'package:agawaeuleo/presentation/widgets/animated/tap_spring.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 홈 케어 덱 무대 위에 떠 있는 **실데이터 조각** — 온보딩 스테이지의 "떠 있는 UI
/// 조각" 문법을 그대로 가져와, 그 증상의 추천 용품 수와 1위 제품을 보여 준다.
///
/// 데이터는 상세 화면과 같은 프로바이더(`symptomProductsProvider`·
/// `symptomInfoProvider`)를 공유해, 덱에서 본 증상은 상세 진입 시 이미 캐시돼 있다.
///
/// DESIGN v3 §5.1·§6 — 표면은 말랑한 둥근 카드(paperRaised + 넓게 퍼지는 장밋빛 e3,
/// 헤어라인 없음). 무대 위 칩·배지는 §5.4 **스티커 문법**(알약 + 파스텔 워시 +
/// 흰 스티커 테두리 + e1)을 따른다.
class DeckFloatSurface extends StatelessWidget {
  const DeckFloatSurface({
    required this.child,
    super.key,
    this.width,
    this.borderRadius = AppRadius.brLg,
    this.padding = const EdgeInsets.all(AppSpacing.x12),
  });

  final Widget child;
  final double? width;
  final BorderRadius borderRadius;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      padding: padding,
      decoration: BoxDecoration(
        color: context.colors.paperRaised,
        borderRadius: borderRadius,
        boxShadow: context.shadows.e3,
      ),
      child: child,
    );
  }
}

/// §5.4 스티커 면 — 알약 + 워시(+ 은은한 클레이 광택) + 흰 스티커 테두리 + e1.
class _StickerFace extends StatelessWidget {
  const _StickerFace({
    required this.wash,
    required this.child,
    required this.height,
    required this.padding,
  });

  final Color wash;
  final Widget child;
  final double height;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: ClaySheen.gradient(context, wash),
        borderRadius: AppRadius.brFull,
        border: Border.all(color: context.colors.paperRaised, width: 2),
        boxShadow: context.shadows.e1,
      ),
      child: child,
    );
  }
}

/// 뒤 레이어 칩 — "추천 용품 N"(용품이 없으면 "병원 신호 N", 둘 다 없으면 숨김).
///
/// 탭하면 그 칩이 가리키는 장(추천 용품 / 병원 신호)으로 상세를 바로 연다 — 무대 위
/// 조각은 전부 "누를 수 있는 것"이라는 규칙을 지키기 위해 끝에 쉐브론을 세운다.
/// DESIGN v3 — 스티커 칩(추천 용품 = 버터 워시, 병원 신호 = 토마토 워시) + 주아체 개수.
class DeckMetaChip extends ConsumerWidget {
  const DeckMetaChip({
    required this.symptom,
    required this.onOpenChapter,
    super.key,
  });

  final Symptom symptom;

  /// 상세를 그 장(`NoteChapter.slug`)으로 연다.
  final ValueChanged<String> onOpenChapter;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.texts;
    final products = ref.watch(symptomProductsProvider(symptom.id)).value;
    final info = ref.watch(symptomInfoProvider(symptom.id)).value;

    final ({
      IconData icon,
      Color fg,
      Color wash,
      String label,
      int count,
      NoteChapter chapter,
    })?
    meta;
    if (products != null && products.isNotEmpty) {
      meta = (
        icon: Icons.auto_awesome_rounded,
        fg: colors.amber,
        wash: colors.amberWash,
        label: '추천 용품',
        count: products.length,
        chapter: NoteChapter.products,
      );
    } else if (info != null && info.hasEmergency) {
      meta = (
        icon: Icons.local_hospital_rounded,
        fg: colors.coral,
        wash: colors.coralWash,
        label: '병원 신호',
        count: info.emergency.length,
        chapter: NoteChapter.emergency,
      );
    } else {
      meta = null;
    }

    return AnimatedSwitcher(
      duration: AppMotion.resolve(context, AppMotion.fast),
      child: meta == null
          ? const SizedBox.shrink()
          : Semantics(
              key: ValueKey(meta.label),
              button: true,
              label: '${symptom.name} ${meta.label} ${meta.count}개 보기',
              excludeSemantics: true,
              child: TapSpring(
                onTap: () => onOpenChapter(meta!.chapter.slug),
                child: _StickerFace(
                  wash: meta.wash,
                  height: 36,
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.x12,
                    0,
                    AppSpacing.x8,
                    0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(meta.icon, size: 15, color: meta.fg),
                      const SizedBox(width: AppSpacing.x4),
                      Text(
                        meta.label,
                        style: texts.caption.copyWith(
                          color: meta.fg,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.x8),
                      Text(
                        '${meta.count}',
                        style: DeckPalette.digits(
                          texts.label.copyWith(color: meta.fg, height: 1),
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: meta.fg.withValues(alpha: 0.7),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

/// 앞 레이어 카드 — 이 증상의 1위 추천 용품(BEST PICK). 탭하면 상세의 '추천 용품'
/// 장으로 바로 연다(외부 링크는 대가성 표시가 있는 상세에서만 연다 — §13.2).
///
/// 덱이 이 장면에 안착하면([active]) 1위 배지가 도장 찍히듯 앉는다. DESIGN v3 —
/// 둥근 카드 위에 버터 워시 "BEST PICK" 스티커(앞에 주아체 1위 배지)를 붙인다.
class DeckBestPickCard extends ConsumerStatefulWidget {
  const DeckBestPickCard({
    required this.symptom,
    required this.active,
    required this.onTap,
    super.key,
  });

  final Symptom symptom;
  final bool active;
  final VoidCallback onTap;

  static const double width = 172;

  @override
  ConsumerState<DeckBestPickCard> createState() => _DeckBestPickCardState();
}

class _DeckBestPickCardState extends ConsumerState<DeckBestPickCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _stamp = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 560),
  );

  @override
  void initState() {
    super.initState();
    _stamp.value = 1;
    if (widget.active) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _play());
    }
  }

  @override
  void didUpdateWidget(DeckBestPickCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !oldWidget.active) _play();
  }

  void _play() {
    if (!mounted || context.reduceMotion) return;
    _stamp.forward(from: 0);
  }

  @override
  void dispose() {
    _stamp.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final products = ref
        .watch(symptomProductsProvider(widget.symptom.id))
        .value;
    final top = (products == null || products.isEmpty) ? null : products.first;

    final Widget card;
    if (top == null) {
      card = const SizedBox.shrink();
    } else {
      final badge = AnimatedBuilder(
        animation: _stamp,
        builder: (context, child) {
          final v = _stamp.value;
          final settle = Curves.easeOutBack.transform(
            const Interval(0.15, 1).transform(v),
          );
          return Opacity(
            opacity: const Interval(0, 0.35).transform(v),
            child: Transform.scale(scale: 1.7 - 0.7 * settle, child: child),
          );
        },
        child: DeckRankBadge(rank: 1, fg: colors.amber, size: 20),
      );

      final sticker = _StickerFace(
        wash: colors.amberWash,
        height: 30,
        padding: const EdgeInsets.fromLTRB(AppSpacing.x2, 0, AppSpacing.x8, 0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            badge,
            const SizedBox(width: AppSpacing.x4),
            Flexible(
              child: Text(
                'BEST PICK',
                maxLines: 1,
                softWrap: false,
                overflow: TextOverflow.fade,
                style: texts.caption.copyWith(
                  color: colors.amber,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
      );

      card = Semantics(
        button: true,
        // 좌상 칩과 같은 곳으로 가지만 라벨은 겹치지 않게 — 1위 제품을 읽어 준다.
        label: '${widget.symptom.name} 추천 용품 1위 ${top.title}, 전체 보기',
        excludeSemantics: true,
        child: TapSpring(
          key: ValueKey(top.id),
          onTap: widget.onTap,
          child: DeckFloatSurface(
            width: DeckBestPickCard.width,
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.x8,
              AppSpacing.x8,
              AppSpacing.x8,
              AppSpacing.x12,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: sticker,
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18,
                      color: colors.ink500,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.x8),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.x4,
                  ),
                  child: Text(
                    top.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: texts.body.copyWith(
                      color: colors.ink900,
                      fontWeight: FontWeight.w600,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return AnimatedSwitcher(
      duration: AppMotion.resolve(context, AppMotion.fast),
      child: card,
    );
  }
}

/// 순위 배지 — 제품 섹션 톤 사다리(1 amber · 2 accent · 3 sage)와 같은 문법.
///
/// DESIGN v3 — 동그란 클레이 스티커: [fg] 면(+ 광택) · 흰 스티커 테두리 · 주아체 숫자.
class DeckRankBadge extends StatelessWidget {
  const DeckRankBadge({
    required this.rank,
    required this.fg,
    this.size = 22,
    super.key,
  });

  final int rank;
  final Color fg;

  /// 배지 지름(dp).
  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: ClaySheen.gradient(context, fg),
        shape: BoxShape.circle,
        border: Border.all(color: colors.paperRaised, width: 1.5),
      ),
      padding: const EdgeInsets.all(AppSpacing.x2),
      child: FittedBox(
        child: Text(
          '$rank',
          style: DeckPalette.digits(
            context.texts.label.copyWith(color: colors.paperRaised, height: 1),
          ),
        ),
      ),
    );
  }
}
