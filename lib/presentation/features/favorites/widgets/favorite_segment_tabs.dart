import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../core/haptics/app_haptics.dart';

/// §11.15 즐겨찾기 세그먼트(증상/제품). 인디케이터 슬라이드 + `selectionClick`.
enum FavoriteTab {
  symptom('증상'),
  product('제품');

  const FavoriteTab(this.label);

  final String label;
}

class FavoriteSegmentTabs extends StatelessWidget {
  const FavoriteSegmentTabs({
    required this.value,
    required this.onChanged,
    super.key,
  });

  final FavoriteTab value;
  final ValueChanged<FavoriteTab> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final duration = AppMotion.resolve(context, AppMotion.fast);
    const options = FavoriteTab.values;
    final index = options.indexOf(value);

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
          AnimatedAlign(
            duration: duration,
            curve: AppMotion.standard,
            alignment: Alignment(-1 + 2 * index / (options.length - 1), 0),
            child: FractionallySizedBox(
              widthFactor: 1 / options.length,
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
              for (final option in options)
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      if (option == value) return;
                      AppHaptics.toggle();
                      onChanged(option);
                    },
                    child: Center(
                      child: Text(
                        option.label,
                        style: texts.label.copyWith(
                          color: option == value
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
