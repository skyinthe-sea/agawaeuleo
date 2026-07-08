import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';

/// §11.2 페이지 인디케이터(점 3개). 활성 점만 원→알약으로 width 트윈.
class PageIndicator extends StatelessWidget {
  const PageIndicator({required this.count, required this.index, super.key});

  final int count;
  final int index;

  static const double _dotSize = 8;
  static const double _activeWidth = 24;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final duration = AppMotion.resolve(context, AppMotion.base);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List<Widget>.generate(count, (i) {
        final active = i == index;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x4),
          child: AnimatedContainer(
            duration: duration,
            curve: AppMotion.standard,
            width: active ? _activeWidth : _dotSize,
            height: _dotSize,
            decoration: BoxDecoration(
              color: active ? colors.accent : colors.ink300,
              borderRadius: AppRadius.brFull,
            ),
          ),
        );
      }),
    );
  }
}
