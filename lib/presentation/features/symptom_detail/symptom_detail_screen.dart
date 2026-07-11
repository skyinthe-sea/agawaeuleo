import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/symptom_detail_providers.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/emergency_card.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/info_accordion.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/product_section.dart';
import 'package:agawaeuleo/presentation/widgets/animated/sparkle.dart';
import 'package:agawaeuleo/presentation/widgets/brand/ink_halo_icon.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:agawaeuleo/presentation/widgets/dividers/brush_divider.dart';
import 'package:agawaeuleo/presentation/widgets/navigation/app_app_bar.dart';
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:agawaeuleo/presentation/widgets/states/error_state.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// §11.9 증상 상세 — 정보 + 제품(수익 화면).
///
/// 라우트 `slug`(§4.1)로 증상을 조회한 뒤 헤더(Hero) · 요약 · (해당 시) 응급 경고 ·
/// 정보 아코디언 · 의학 면책(§13.3) · 추천 제품(§13.2 대가성 표시)을 구성한다.
class SymptomDetailScreen extends ConsumerStatefulWidget {
  const SymptomDetailScreen({required this.slug, super.key});

  final String slug;

  @override
  ConsumerState<SymptomDetailScreen> createState() =>
      _SymptomDetailScreenState();
}

class _SymptomDetailScreenState extends ConsumerState<SymptomDetailScreen> {
  bool _scrolled = false;

  bool _onScroll(ScrollNotification notification) {
    final scrolled = notification.metrics.pixels > 0;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final symptomAsync = ref.watch(symptomBySlugProvider(widget.slug));

    return Scaffold(
      backgroundColor: context.colors.paperBg,
      appBar: AppAppBar(scrolled: _scrolled),
      // DESIGN v2 §7.3-7 — 화면 전체에 종이 그레인 표면을 얹는다.
      body: PaperBackground(
        child: symptomAsync.when(
          loading: () => const _DetailSkeleton(),
          error: (error, _) => ErrorState(
            onRetry: () => ref.invalidate(symptomBySlugProvider(widget.slug)),
          ),
          data: (symptom) {
            if (symptom == null) {
              return const EmptyState(
                title: '증상을 찾을 수 없어요',
                message: '홈에서 다른 증상을 골라 보세요.',
                icon: Icons.search_off_rounded,
              );
            }
            return NotificationListener<ScrollNotification>(
              onNotification: _onScroll,
              child: _DetailBody(symptom: symptom),
            );
          },
        ),
      ),
    );
  }
}

class _DetailBody extends ConsumerWidget {
  const _DetailBody({required this.symptom});

  final Symptom symptom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.texts;
    final infoAsync = ref.watch(symptomInfoProvider(symptom.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.screenPadding,
        vertical: AppSpacing.screenPadding,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Header(symptom: symptom),
          const SizedBox(height: AppSpacing.sectionGap),
          infoAsync.when(
            loading: _SummarySkeleton.new,
            error: (_, _) => const SizedBox.shrink(),
            data: (info) => _InfoBlock(info: info),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          // §11.9-5 / §13.3 의학 면책 — 정보 유무와 무관하게 항상 노출.
          // DESIGN v2 §7.3-5: 격은 낮게, 존재감만(line 1px 보더 박스 + 안내 아이콘).
          // baby 문구는 원문 그대로(바이트 단위 불변). mom(산모 카드)은 상담
          // 대상만 산부인과 의료진으로 분기(§13.3 개정).
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              border: Border.all(color: colors.line),
              borderRadius: AppRadius.brSm,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline, size: 16, color: colors.ink500),
                const SizedBox(width: AppSpacing.iconTextGap),
                Expanded(
                  child: Text(
                    symptom.audience == SymptomAudience.mom
                        ? '본 정보는 의학적 진단이 아니며 참고용입니다. '
                              '증상이 우려되면 산부인과 전문의 등 의료진과 상담하세요.'
                        : '본 정보는 의학적 진단이 아니며 참고용입니다. '
                              '증상이 우려되면 소아과 전문의와 상담하세요.',
                    style: texts.caption.copyWith(color: colors.ink500),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          // DESIGN v2 §6.4/§7.3-4 — "정보 → 제품" 격 전환점(붓결 디바이더 + 32dp).
          const BrushDivider.section(),
          const SizedBox(height: AppSpacing.x32),
          ProductSection(symptomId: symptom.id),
        ],
      ),
    );
  }
}

/// §11.9-1 헤더: Hero 아이콘 56 + 증상명 title 22 + 즐겨찾기 별 24.
///
/// DESIGN v2 §7.3-1 — 독립 표면(`paperRaised` + 하단 헤어라인 + 그레인)으로
/// 감싸고, 히어로 원을 [InkHaloIcon](56, elevated, [SymptomTone] 색)로 승격한다.
/// [SymptomIllustrations] 등록 증상은 원 대신 동일 일러스트(56)를 써서 홈
/// 일러스트 카드에서 히어로가 이어지게 한다.
/// Hero 태그 `symptom-icon-<id>`/`symptom-name-<id>`는 그대로 유지한다.
class _Header extends ConsumerWidget {
  const _Header({required this.symptom});

  final Symptom symptom;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.texts;
    final isFavorite =
        ref.watch(symptomFavoriteProvider(symptom.id)).value ?? false;
    final tone = SymptomTone.resolve(context, symptom.emojiOrIcon);

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Hero(
          tag: 'symptom-icon-${symptom.id}',
          child: SymptomIllustrations.has(symptom.emojiOrIcon)
              ? SymptomIllustration(
                  illustrationKey: symptom.emojiOrIcon!,
                  size: 56,
                )
              : InkHaloIcon(
                  size: 56,
                  icon: SymptomIcons.resolve(symptom.emojiOrIcon),
                  washColor: tone.wash,
                  fgColor: tone.fg,
                  elevated: true,
                ),
        ),
        const SizedBox(width: AppSpacing.x16),
        Expanded(
          child: Hero(
            tag: 'symptom-name-${symptom.id}',
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                symptom.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: texts.title.copyWith(color: colors.ink900),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x8),
        Sparkle(
          isActive: isFavorite,
          onChanged: (_) => ref
              .read(favoriteRepositoryProvider)
              .toggle(
                targetType: FavoriteTargetType.symptom,
                targetId: symptom.id,
              ),
        ),
      ],
    );

    // §7.3-1: paperRaised 배경 + 하단 헤어라인 + 그레인. `ClipRRect`로 바깥
    // 모서리만 둥글리고, 하단 헤어라인은 (Border+radius 조합 대신) 별도의
    // 1px 스트립으로 그려 app_card.dart:54-66과 동일한 Flutter 비균일-보더
    // assert를 원천적으로 피한다.
    return ClipRRect(
      borderRadius: AppRadius.brMd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ColoredBox(
            color: colors.paperRaised,
            child: PaperBackground(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.cardPadding),
                child: row,
              ),
            ),
          ),
          ColoredBox(
            color: colors.line,
            child: const SizedBox(height: 1, width: double.infinity),
          ),
        ],
      ),
    );
  }
}

/// 요약 카드 + (해당 시) 응급 경고 + 정보 아코디언.
class _InfoBlock extends StatelessWidget {
  const _InfoBlock({required this.info});

  final SymptomInfo? info;

  @override
  Widget build(BuildContext context) {
    final data = info;
    if (data == null) return const SizedBox.shrink();

    final colors = context.colors;
    final texts = context.texts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // §11.9-2 / DESIGN v2 §7.3-2 요약 카드 — hero 격("겹친 한지" 스택) +
        // 상단 overline "한눈에 보기" + 좌측 잉크 틱(SectionHeader와 동일 3×16 accent 바).
        AppCard(
          emphasis: AppCardEmphasis.hero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 3,
                    height: 16,
                    decoration: BoxDecoration(
                      color: colors.accent,
                      borderRadius: BorderRadius.circular(1.5),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.iconTextGap),
                  Text(
                    '한눈에 보기',
                    style: texts.overline.copyWith(color: colors.ink500),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.x8),
              Text(
                data.summary,
                style: texts.bodyL.copyWith(color: colors.ink700),
              ),
            ],
          ),
        ),
        if (data.hasEmergency) ...[
          const SizedBox(height: AppSpacing.x16),
          EmergencyCard(signs: data.emergency),
        ],
        if (data.sections.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          InfoAccordionList(sections: data.sections),
        ],
        // §11.9 개정 — 참고 자료(출처 label 불릿). 면책 박스 위, 탭 액션·URL
        // 노출 없음. sources가 비면 블록 전체 생략.
        if (data.sources.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.x16),
          _SourcesBlock(sources: data.sources),
        ],
      ],
    );
  }
}

/// 참고 자료 블록 — "참고 자료" caption(ink500) + label 불릿 리스트(caption).
///
/// 출처는 신뢰 신호로만 노출한다(§13.3 — 링크·탭 액션 없음, org/url은
/// 검수용 메타데이터라 표시하지 않는다).
class _SourcesBlock extends StatelessWidget {
  const _SourcesBlock({required this.sources});

  final List<InfoSource> sources;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final captionStyle = texts.caption.copyWith(color: colors.ink500);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('참고 자료', style: captionStyle),
        const SizedBox(height: AppSpacing.x4),
        for (final source in sources)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.x2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Icon(
                    Icons.fiber_manual_record,
                    size: 4,
                    color: colors.ink500,
                  ),
                ),
                const SizedBox(width: AppSpacing.iconTextGap),
                Expanded(child: Text(source.label, style: captionStyle)),
              ],
            ),
          ),
      ],
    );
  }
}

/// 요약 자리 로딩 스켈레톤(정보 도착 전).
///
/// DESIGN v2 §7.3-2로 요약 카드가 hero 격(paperRaised/e2/brLg)으로 올라간 데
/// 맞춰 라디우스·표면을 대응시켜(§5.5) 로딩→데이터 전환 시 튐이 없게 한다.
class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.paperRaised,
        borderRadius: AppRadius.brLg,
        boxShadow: context.shadows.e2,
        border: Border.all(color: colors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SkeletonLine(),
          SizedBox(height: AppSpacing.x8),
          SkeletonLine(),
          SizedBox(height: AppSpacing.x8),
          SkeletonLine(width: 180),
        ],
      ),
    );
  }
}

/// 증상 로딩 시 전체 화면 스켈레톤.
class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: const [
              SkeletonBox(size: 56, circle: true),
              SizedBox(width: AppSpacing.x16),
              Expanded(child: SkeletonLine(height: 20)),
            ],
          ),
          const SizedBox(height: AppSpacing.sectionGap),
          const _SummarySkeleton(),
          const SizedBox(height: AppSpacing.sectionGap),
          const ProductCardSkeleton(),
          const SizedBox(height: AppSpacing.listItemGap),
          const ProductCardSkeleton(),
        ],
      ),
    );
  }
}
