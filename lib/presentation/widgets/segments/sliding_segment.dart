import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';

/// DESIGN v2 §4.7 슬라이딩 세그먼트 — 제네릭 통합 컴포넌트.
///
/// `baby_gender_segment`·`segmented_control`·트래킹 `_TypeSegment`/`_RangeTabs`
/// 등 3곳 이상의 중복 구현을 단일 컴포넌트로 대체한다.
///
/// 트랙: `paperCard` + `line` 1px 보더 + r.sm(10), 높이 44(기본). 인디케이터:
/// `paperRaised` + e2 + `lineStrong` 헤어라인, `AnimatedAlign`(fast, standard).
/// 라벨: 선택 `accent` / 비선택 `ink500`. 탭 시 `selectionClick` 햅틱.
class SlidingSegment<T> extends StatelessWidget {
  const SlidingSegment({
    required this.items,
    required this.selected,
    required this.onChanged,
    required this.labelOf,
    super.key,
    this.height = 44,
  });

  final List<T> items;
  final T selected;
  final ValueChanged<T> onChanged;
  final String Function(T item) labelOf;
  final double height;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final index = items.indexOf(selected).clamp(0, items.length - 1);

    return Container(
      height: height,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: colors.line),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final segmentWidth = constraints.maxWidth / items.length;
          final alignX = items.length > 1
              ? (index / (items.length - 1)) * 2 - 1
              : 0.0;

          return Stack(
            children: [
              AnimatedAlign(
                duration: AppMotion.resolve(context, AppMotion.fast),
                curve: AppMotion.standard,
                alignment: Alignment(alignX, 0),
                child: Container(
                  width: segmentWidth,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.paperRaised,
                    borderRadius: AppRadius.brSm,
                    border: Border.all(color: colors.lineStrong),
                    boxShadow: context.shadows.e2,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final item in items)
                    Expanded(
                      child: _SegmentLabel(
                        label: labelOf(item),
                        selected: item == selected,
                        onTap: () {
                          if (item == selected) return;
                          AppHaptics.toggle();
                          onChanged(item);
                        },
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SegmentLabel extends StatelessWidget {
  const _SegmentLabel({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Center(
        child: AnimatedDefaultTextStyle(
          duration: AppMotion.resolve(context, AppMotion.fast),
          curve: AppMotion.standard,
          style: context.texts.label.copyWith(
            color: selected ? colors.accent : colors.ink500,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        ),
      ),
    );
  }
}
