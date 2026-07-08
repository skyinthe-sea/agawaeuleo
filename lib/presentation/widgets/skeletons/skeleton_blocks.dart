import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../animated/shimmer_skeleton.dart';

/// §11.17 스켈레톤 프리셋. 실제 레이아웃과 동일 형태의 반짝임 블록.
/// 개별 블록은 placeholder 톤(line) 위로 반짝인다.

/// 카드/리스트 내부에 쓰는 한 줄 블록.
class SkeletonLine extends StatelessWidget {
  const SkeletonLine({
    super.key,
    this.width,
    this.height = 12,
    this.radius = AppRadius.brXs,
  });

  final double? width;
  final double height;
  final BorderRadius radius;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      width: width,
      height: height,
      borderRadius: radius,
      baseColor: context.colors.line,
    );
  }
}

/// 사각/원형 블록(썸네일·아이콘 자리).
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.size,
    super.key,
    this.radius = AppRadius.brSm,
    this.circle = false,
  });

  final double size;
  final BorderRadius radius;
  final bool circle;

  @override
  Widget build(BuildContext context) {
    return ShimmerSkeleton(
      width: size,
      height: size,
      borderRadius: circle ? BorderRadius.circular(size) : radius,
      baseColor: context.colors.line,
    );
  }
}

/// 공용 카드 셸(paper.card · r.md · e1) — 스켈레톤 내용을 감싼다.
class _SkeletonShell extends StatelessWidget {
  const _SkeletonShell({required this.child, this.height});

  final Widget child;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppRadius.brMd,
        boxShadow: context.shadows.e1,
        border: Border.all(color: colors.line),
      ),
      padding: const EdgeInsets.all(AppSpacing.cardPadding),
      child: child,
    );
  }
}

/// §11.7 홈 증상 그리드 카드(~120): 아이콘 원 + 제목 한 줄.
class SymptomCardSkeleton extends StatelessWidget {
  const SymptomCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonShell(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(size: 40, circle: true),
          Spacer(),
          SkeletonLine(width: 88, height: 14),
        ],
      ),
    );
  }
}

/// §11.9 추천 제품 카드(~96): 썸네일 72 + 제목 2줄 + 가격.
class ProductCardSkeleton extends StatelessWidget {
  const ProductCardSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    return const _SkeletonShell(
      height: 96,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(size: 64),
          SizedBox(width: AppSpacing.x12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(height: 12),
                SizedBox(height: AppSpacing.x8),
                SkeletonLine(width: 160, height: 12),
                Spacer(),
                SkeletonLine(width: 72, height: 14),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 범용 리스트 행: 선행 블록 + 2줄.
class ListItemSkeleton extends StatelessWidget {
  const ListItemSkeleton({super.key, this.leadingSize = 40});

  final double leadingSize;

  @override
  Widget build(BuildContext context) {
    return _SkeletonShell(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox(size: leadingSize, circle: true),
          const SizedBox(width: AppSpacing.x12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonLine(height: 12),
                SizedBox(height: AppSpacing.x8),
                SkeletonLine(width: 120, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// 세로 스켈레톤 리스트. [builder] 미지정 시 [ListItemSkeleton] 반복.
class SkeletonList extends StatelessWidget {
  const SkeletonList({
    super.key,
    this.count = 4,
    this.gap = AppSpacing.listItemGap,
    this.padding = const EdgeInsets.all(AppSpacing.screenPadding),
    this.builder,
  });

  final int count;
  final double gap;
  final EdgeInsetsGeometry padding;
  final IndexedWidgetBuilder? builder;

  @override
  Widget build(BuildContext context) {
    final itemBuilder = builder ?? (_, _) => const ListItemSkeleton();
    return ListView.separated(
      padding: padding,
      itemCount: count,
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      separatorBuilder: (_, _) => SizedBox(height: gap),
      itemBuilder: itemBuilder,
    );
  }
}
