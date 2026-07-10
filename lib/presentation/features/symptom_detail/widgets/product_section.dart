import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/symptom_detail_providers.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/product_card.dart';
import 'package:agawaeuleo/presentation/widgets/buttons/ghost_button.dart';
import 'package:agawaeuleo/presentation/widgets/headers/section_header.dart';
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// §11.9-6 추천 제품 섹션(수익).
///
/// 헤더 "이럴 때 도움되는 용품" + **대가성 표시 배지**(§13.2, 리스트 위 바로 보이는
/// 위치) + 제품 카드 리스트. 로딩 시 shimmer 스켈레톤 → 실제 카드 크로스페이드
/// 180ms(§10.2). 제품이 없으면 섹션 전체를 숨긴다.
class ProductSection extends ConsumerWidget {
  const ProductSection({required this.symptomId, super.key});

  final String symptomId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final texts = context.texts;
    final async = ref.watch(symptomProductsProvider(symptomId));

    // 데이터가 도착했는데 비어 있으면 섹션 자체를 숨긴다(§13.2: 리스트가 있을
    // 때만 대가성 배지를 노출).
    final products = async.value;
    if (async.hasValue && (products == null || products.isEmpty)) {
      return const SizedBox.shrink();
    }

    final Widget content;
    if (async.hasValue && products != null) {
      content = _ProductList(key: const ValueKey('list'), products: products);
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
        // DESIGN v2 §7.3-6 — 헤더를 SectionHeader로, trailing에 개수("N개").
        SectionHeader(
          title: '이럴 때 도움되는 용품',
          trailing: products != null
              ? Text(
                  '${products.length}개',
                  style: texts.data.copyWith(color: colors.ink500),
                )
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

/// §13.2 공정위 대가성 표시 배지. amber 옅은 톤 배경, 본문과 구분되는 색/크기.
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
        // DESIGN v2 §7.3-6 — 신규 amberWash 토큰(기존 amber.withValues 하드코딩 대체).
        color: colors.amberWash,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        children: [
          Icon(Icons.campaign_rounded, size: 16, color: colors.amber),
          const SizedBox(width: AppSpacing.iconTextGap),
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

class _ProductList extends StatelessWidget {
  const _ProductList({required this.products, super.key});

  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, product) in products.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == products.length - 1 ? 0 : AppSpacing.listItemGap,
            ),
            // DESIGN v2 §7.3-6 — 1위 카드에만 순위 배지 + lineStrong 보더.
            child: ProductCard(product: product, topRanked: index == 0),
          ),
      ],
    );
  }
}

class _ProductSkeletons extends StatelessWidget {
  const _ProductSkeletons({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ProductCardSkeleton(),
        SizedBox(height: AppSpacing.listItemGap),
        ProductCardSkeleton(),
        SizedBox(height: AppSpacing.listItemGap),
        ProductCardSkeleton(),
      ],
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
