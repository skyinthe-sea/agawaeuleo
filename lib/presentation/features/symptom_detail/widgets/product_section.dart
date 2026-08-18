import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/symptom_detail_providers.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/product_card.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_reveal.dart';
import 'package:agawaeuleo/presentation/widgets/buttons/ghost_button.dart';
import 'package:agawaeuleo/presentation/widgets/headers/section_header.dart';
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// §11.9-6 추천 제품 섹션(수익).
///
/// 헤더 "이럴 때 도움되는 용품"(+ 개수 알약) + **대가성 표시 배지**(§13.2, 리스트
/// 위 바로 보이는 위치) + 랭킹 보드. 로딩 시 실제 카드 형태와 같은 shimmer
/// 스켈레톤 → 실제 카드 크로스페이드 180ms(§10.2). 제품이 없으면 섹션 전체를 숨긴다.
///
/// DESIGN v2 §7.3-6 확장 — 리스트를 "1위 히어로 쇼케이스 + 2위 이하 랭킹 행"의
/// 에디토리얼 보드로 재구성하고, 각 카드는 **뷰포트에 들어오는 순간** 계단식으로
/// 등장한다([ScrollReveal], reduce-motion 시 정지).
class ProductSection extends ConsumerWidget {
  const ProductSection({required this.symptomId, super.key});

  final String symptomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(symptomProductsProvider(symptomId));

    // 데이터가 도착했는데 비어 있으면 섹션 자체를 숨긴다(§13.2: 리스트가 있을
    // 때만 대가성 배지를 노출).
    final products = async.value;
    if (async.hasValue && (products == null || products.isEmpty)) {
      return const SizedBox.shrink();
    }

    final Widget content;
    if (async.hasValue && products != null) {
      content = _ProductShowcase(
        key: const ValueKey('list'),
        products: products,
      );
    } else if (async.hasError) {
      content = _ProductError(
        key: const ValueKey('error'),
        onRetry: () => ref.invalidate(symptomProductsProvider(symptomId)),
      );
    } else {
      content = const _ProductSkeletons(key: ValueKey('skeleton'));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // DESIGN v2 §7.3-6 — 헤더를 SectionHeader로, trailing에 개수("N개") 알약.
        SectionHeader(
          title: '이럴 때 도움되는 용품',
          trailing: products != null
              ? _CountPill(count: products.length)
              : null,
        ),
        const SizedBox(height: AppSpacing.x12),
        const _CompensationBadge(),
        const SizedBox(height: AppSpacing.x16),
        AnimatedSwitcher(
          duration: AppMotion.resolve(context, AppMotion.fast),
          child: content,
        ),
      ],
    );
  }
}

/// 헤더 우측 개수 알약. 문자열("N개")은 그대로 두고 격만 올린다.
class _CountPill extends StatelessWidget {
  const _CountPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppRadius.brFull,
        border: Border.all(color: colors.line),
      ),
      child: Text('$count개', style: texts.data.copyWith(color: colors.ink500)),
    );
  }
}

/// §13.2 공정위 대가성 표시 배지. amber 옅은 톤 배경, 본문과 구분되는 색/크기.
/// **문구는 원문 그대로 유지**(§13.2 불변 조항) — 시각 격만 정리한다.
class _CompensationBadge extends StatelessWidget {
  const _CompensationBadge();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x12,
        vertical: AppSpacing.x8,
      ),
      decoration: BoxDecoration(
        // DESIGN v2 §7.3-6 — amberWash 토큰(기존 amber.withValues 하드코딩 대체).
        color: colors.amberWash,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: colors.paperRaised,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.campaign_rounded, size: 14, color: colors.amber),
          ),
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Text(
              '쿠팡 파트너스 활동으로 수수료를 받습니다',
              style: texts.caption.copyWith(color: colors.ink700),
            ),
          ),
        ],
      ),
    );
  }
}

/// 랭킹 보드 — 1위 히어로 + 2위 이하 행. 각 카드는 뷰포트 진입 시 계단식 등장.
class _ProductShowcase extends StatelessWidget {
  const _ProductShowcase({required this.products, super.key});

  final List<Product> products;

  /// 계단식 지연 — 모션 토큰 파생값(instant 100ms ÷ 2 = 50ms). 목록이 길어도
  /// 마지막 카드가 오래 기다리지 않도록 6단계에서 멈춘다.
  Duration _stagger(int step) => (AppMotion.instant ~/ 2) * step.clamp(0, 6);

  @override
  Widget build(BuildContext context) {
    final rest = products.skip(1).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ScrollReveal(child: ProductHeroCard(product: products.first)),
        for (final (index, product) in rest.indexed) ...[
          const SizedBox(height: AppSpacing.listItemGap),
          ScrollReveal(
            delay: _stagger(index + 1),
            child: ProductCard(product: product, rank: index + 2),
          ),
        ],
      ],
    );
  }
}

/// 로딩 자리 — 실제 보드와 같은 형태(히어로 1 + 행 2)로 맞춰 전환 시 튐을 없앤다
/// (DESIGN v2 §5.5).
class _ProductSkeletons extends StatelessWidget {
  const _ProductSkeletons({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _HeroSkeleton(),
        SizedBox(height: AppSpacing.listItemGap),
        _RowSkeleton(),
        SizedBox(height: AppSpacing.listItemGap),
        _RowSkeleton(),
      ],
    );
  }
}

/// 히어로 카드 스켈레톤(paperRaised · brLg · e2 — hero 격에 대응).
class _HeroSkeleton extends StatelessWidget {
  const _HeroSkeleton();

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
          Row(
            children: [
              SkeletonBox(size: 22, radius: AppRadius.brXs),
              SizedBox(width: AppSpacing.iconTextGap),
              SkeletonLine(width: 72, height: 10),
            ],
          ),
          SizedBox(height: AppSpacing.x16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SkeletonBox(size: 104, radius: AppRadius.brMd),
              SizedBox(width: AppSpacing.x16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SkeletonLine(),
                    SizedBox(height: AppSpacing.x8),
                    SkeletonLine(),
                    SizedBox(height: AppSpacing.x8),
                    SkeletonLine(width: 120),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: AppSpacing.x16),
          SkeletonLine(height: 44, radius: AppRadius.brSm),
        ],
      ),
    );
  }
}

/// 행 카드 스켈레톤(썸네일 76 + 2줄 + 원형 어피던스).
class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppRadius.brMd,
        boxShadow: context.shadows.e1,
        border: Border.all(color: colors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.x12),
      child: const Row(
        children: [
          SkeletonBox(size: 76),
          SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SkeletonLine(),
                SizedBox(height: AppSpacing.x8),
                SkeletonLine(),
                SizedBox(height: AppSpacing.x8),
                SkeletonLine(width: 140, height: 10),
              ],
            ),
          ),
          SizedBox(width: AppSpacing.x8),
          SkeletonBox(size: 32, circle: true),
        ],
      ),
    );
  }
}

class _ProductError extends StatelessWidget {
  const _ProductError({required this.onRetry, super.key});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('용품을 불러오지 못했어요', style: texts.body.copyWith(color: colors.ink500)),
        const SizedBox(height: AppSpacing.x12),
        GhostButton(
          label: '다시 시도',
          icon: Icons.refresh_rounded,
          expand: false,
          onPressed: onRetry,
        ),
      ],
    );
  }
}
