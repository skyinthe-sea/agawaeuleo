import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';
import '../../../../domain/entities/baby.dart';

/// §11.14 편집 화면의 성별 세그먼트(남아/여아/미입력). 인디케이터가 슬라이드하며
/// 탭 시 `selectionClick` 햅틱(§10.2 세그먼트 전환 패턴).
class BabyGenderSegment extends StatelessWidget {
  const BabyGenderSegment({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final BabyGender value;
  final ValueChanged<BabyGender> onChanged;

  static const List<(BabyGender, String)> _options = [
    (BabyGender.male, '남아'),
    (BabyGender.female, '여아'),
    (BabyGender.na, '미입력'),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final duration = AppMotion.resolve(context, AppMotion.fast);
    final index = _options.indexWhere((o) => o.$1 == value);
    final count = _options.length;

    return Container(
      height: 44,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: colors.paperBg,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: colors.line),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: duration,
            curve: AppMotion.standard,
            alignment: Alignment(
              index < 0 ? -1 : -1 + 2 * index / (count - 1),
              0,
            ),
            child: FractionallySizedBox(
              widthFactor: 1 / count,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.accent,
                  borderRadius: AppRadius.brXs,
                  boxShadow: context.shadows.e1,
                ),
              ),
            ),
          ),
          Row(
            children: [
              for (final option in _options)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (option.$1 == value) return;
                      AppHaptics.toggle();
                      onChanged(option.$1);
                    },
                    child: Center(
                      child: Text(
                        option.$2,
                        style: texts.label.copyWith(
                          color: option.$1 == value
                              ? colors.paperRaised
                              : colors.ink700,
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
