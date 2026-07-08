import 'package:flutter/material.dart';

/// §9.7 모션 토큰 + reduce-motion 리졸버.
/// 시스템 "동작 줄이기"가 켜지면 duration을 Duration.zero로 대체.
class AppMotion {
  const AppMotion._();

  static const Duration instant = Duration(milliseconds: 100);
  static const Duration fast = Duration(milliseconds: 180);
  static const Duration base = Duration(milliseconds: 260);
  static const Duration slow = Duration(milliseconds: 400);
  static const Duration shimmer = Duration(milliseconds: 1200);

  static const Curve spring = Curves.easeOutBack;
  static const Curve enter = Curves.easeOutCubic;
  static const Curve exit = Curves.easeInCubic;
  static const Curve standard = Curves.easeInOut;

  /// MediaQuery.disableAnimations 값(없으면 false).
  static bool reduceMotion(BuildContext context) =>
      MediaQuery.maybeDisableAnimationsOf(context) ?? false;

  /// reduce-motion 시 Duration.zero, 아니면 [duration] 그대로.
  static Duration resolve(BuildContext context, Duration duration) =>
      reduceMotion(context) ? Duration.zero : duration;

  /// reduce-motion 시 단순화 커브(linear), 아니면 [curve] 그대로.
  static Curve resolveCurve(BuildContext context, Curve curve) =>
      reduceMotion(context) ? Curves.linear : curve;
}
