import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../config/theme/theme.dart';

/// §10.2 스켈레톤 반짝임. base(paper.card) 위로 highlight가 45°·1200ms 반복 스윕.
/// reduce-motion 시 정적 블록(반짝임 없음)으로 대체.
class ShimmerSkeleton extends StatelessWidget {
  const ShimmerSkeleton({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius = AppRadius.brSm,
    this.baseColor,
    this.highlightColor,
  });

  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final Color? baseColor;
  final Color? highlightColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final base = baseColor ?? colors.paperCard;
    final highlight = highlightColor ?? colors.paperRaised;

    final block = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(color: base, borderRadius: borderRadius),
    );

    if (context.reduceMotion) return block;

    return block
        .animate(onPlay: (c) => c.repeat())
        .shimmer(
          duration: AppMotion.shimmer,
          color: highlight,
          angle: math.pi / 4,
        );
  }
}
