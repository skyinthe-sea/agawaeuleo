import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// §10.2 트래킹 수치 티커. count-up 500ms easeOutCubic. 값 변경 시 현재값→새값으로 트윈.
/// reduce-motion 시 즉시 갱신.
class NumberTicker extends StatelessWidget {
  const NumberTicker({
    required this.value,
    super.key,
    this.duration = const Duration(milliseconds: 500),
    this.style,
    this.formatter,
    this.prefix = '',
    this.suffix = '',
    this.textAlign,
  });

  final num value;
  final Duration duration;
  final TextStyle? style;

  /// 애니메이션 중간값 포맷터. 기본은 정수 반올림.
  final String Function(double value)? formatter;
  final String prefix;
  final String suffix;
  final TextAlign? textAlign;

  @override
  Widget build(BuildContext context) {
    final format = formatter ?? (v) => v.round().toString();
    final resolvedStyle =
        style ?? context.texts.data.copyWith(color: context.colors.ink900);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value.toDouble()),
      duration: context.reduceMotion ? Duration.zero : duration,
      curve: AppMotion.enter,
      builder: (context, v, _) {
        return Text(
          '$prefix${format(v)}$suffix',
          style: resolvedStyle,
          textAlign: textAlign,
        );
      },
    );
  }
}
