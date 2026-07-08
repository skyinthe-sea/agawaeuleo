import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';

/// [SegmentedControl]의 한 항목.
class SegmentedControlItem<T> {
  const SegmentedControlItem({required this.value, required this.label});

  final T value;
  final String label;
}

/// §11.16 테마 세그먼트(라이트/다크/시스템)에 쓰는 범용 세그먼트 컨트롤.
/// 인디케이터(선택 항목 배경)가 좌우로 슬라이드하며, 탭 시 `selectionClick` 햅틱.
class SegmentedControl<T> extends StatelessWidget {
  const SegmentedControl({
    required this.segments,
    required this.value,
    required this.onChanged,
    super.key,
  });

  final List<SegmentedControlItem<T>> segments;
  final T value;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final duration = AppMotion.resolve(context, AppMotion.fast);
    final selectedIndex = segments.indexWhere((s) => s.value == value);
    final count = segments.length;

    return Container(
      height: 40,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.paperBg,
        borderRadius: AppRadius.brFull,
        border: Border.all(color: colors.line),
      ),
      child: Stack(
        children: [
          if (selectedIndex >= 0)
            AnimatedAlign(
              duration: duration,
              curve: AppMotion.standard,
              alignment: Alignment(
                count <= 1 ? 0 : -1 + 2 * selectedIndex / (count - 1),
                0,
              ),
              child: FractionallySizedBox(
                widthFactor: 1 / count,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.paperRaised,
                    borderRadius: AppRadius.brFull,
                    boxShadow: context.shadows.e1,
                  ),
                ),
              ),
            ),
          Row(
            children: [
              for (final segment in segments)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (segment.value == value) return;
                      AppHaptics.toggle();
                      onChanged(segment.value);
                    },
                    child: Center(
                      child: Text(
                        segment.label,
                        style: texts.label.copyWith(
                          color: segment.value == value
                              ? colors.ink900
                              : colors.ink500,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
