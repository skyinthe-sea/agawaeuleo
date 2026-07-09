import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// §10.2 공용 바텀시트 오프너.
///
/// 바텀시트 등장 = **slide 300ms `easeOutBack`(스프링) + 배경 스크림 페이드**,
/// 이탈은 200ms. Flutter의 기본 `showModalBottomSheet` 전환(감속 곡선·기본 길이)
/// 대신 스펙 값을 [AnimationStyle]([sheetAnimationStyle])로 물려 slide 곡선/길이와
/// 스크림 페이드를 스펙에 맞춘다. reduce-motion 시 즉시(0ms) 표시.
///
/// 배경은 투명(시트 내용이 자체 `paper.raised` 표면·radius·e3를 그린다), 스크림은
/// `ink.900` 32%로 통일한다.
Future<T?> showAppBottomSheet<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useRootNavigator = true,
  Color? barrierColor,
}) {
  final reduce = AppMotion.reduceMotion(context);
  // §10.2 slide 300ms easeOutBack / 스크림·이탈 200ms.
  const enter = Duration(milliseconds: 300);
  const exit = Duration(milliseconds: 200);
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useRootNavigator: useRootNavigator,
    backgroundColor: Colors.transparent,
    barrierColor: barrierColor ?? context.colors.ink900.withValues(alpha: 0.32),
    sheetAnimationStyle: AnimationStyle(
      curve: reduce ? Curves.linear : AppMotion.spring,
      duration: reduce ? Duration.zero : enter,
      reverseCurve: reduce ? Curves.linear : AppMotion.exit,
      reverseDuration: reduce ? Duration.zero : exit,
    ),
    builder: builder,
  );
}
