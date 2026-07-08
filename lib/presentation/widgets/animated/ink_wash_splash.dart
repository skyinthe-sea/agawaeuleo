import 'dart:math' as math;

import 'package:flutter/material.dart';

/// §10.1 잉크 워시 리플. 기본 Material 리플 대신 탭 지점에서 accent.wash가 부드럽게
/// 번지는 수묵 스플래시. InkWell/버튼의 `splashFactory`로 지정해 사용한다.
/// 색은 위젯/테마의 splashColor(= accent.wash)를 그대로 사용한다.
class InkWashSplash extends InteractiveInkFeature {
  InkWashSplash({
    required MaterialInkController controller,
    required super.referenceBox,
    required this.textDirection,
    required Offset position,
    required super.color,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    super.customBorder,
    double? radius,
    super.onRemoved,
  }) : _position = position,
       _borderRadius = borderRadius ?? BorderRadius.zero,
       _targetRadius =
           radius ??
           _targetRadiusFor(
             referenceBox,
             containedInkWell,
             rectCallback,
             position,
           ),
       _clipCallback = _clipCallbackFor(
         referenceBox,
         containedInkWell,
         rectCallback,
       ),
       _repositionToReferenceBox = !containedInkWell,
       super(controller: controller) {
    final int baseAlpha = (color.a * 255.0).round().clamp(0, 255);
    _radiusController =
        AnimationController(duration: _kExpandDuration, vsync: controller.vsync)
          ..addListener(controller.markNeedsPaint)
          ..forward();
    _radius = _radiusController.drive(
      Tween<double>(
        begin: _targetRadius * 0.12,
        end: _targetRadius,
      ).chain(CurveTween(curve: Curves.easeOutCubic)),
    );

    _fadeInController =
        AnimationController(duration: _kFadeInDuration, vsync: controller.vsync)
          ..addListener(controller.markNeedsPaint)
          ..forward();
    _fadeIn = _fadeInController.drive(IntTween(begin: 0, end: baseAlpha));

    _fadeOutController =
        AnimationController(
            duration: _kFadeOutDuration,
            vsync: controller.vsync,
          )
          ..addListener(controller.markNeedsPaint)
          ..addStatusListener(_handleStatusChanged);
    _fadeOut = _fadeOutController.drive(
      IntTween(
        begin: baseAlpha,
        end: 0,
      ).chain(CurveTween(curve: Curves.easeInCubic)),
    );

    controller.addInkFeature(this);
  }

  static const Duration _kExpandDuration = Duration(milliseconds: 320);
  static const Duration _kFadeInDuration = Duration(milliseconds: 120);
  static const Duration _kFadeOutDuration = Duration(milliseconds: 260);

  final Offset _position;
  final BorderRadius _borderRadius;
  final double _targetRadius;
  final RectCallback? _clipCallback;
  final bool _repositionToReferenceBox;
  final TextDirection textDirection;

  late final Animation<double> _radius;
  late final AnimationController _radiusController;
  late final Animation<int> _fadeIn;
  late final AnimationController _fadeInController;
  late final Animation<int> _fadeOut;
  late final AnimationController _fadeOutController;
  bool _confirmed = false;

  /// InkWell/버튼/테마의 `splashFactory`에 지정한다.
  static const InteractiveInkFeatureFactory splashFactory =
      _InkWashSplashFactory();

  @override
  void confirm() {
    _confirmed = true;
    _fadeOutController.forward();
  }

  @override
  void cancel() {
    _fadeOutController.forward();
  }

  void _handleStatusChanged(AnimationStatus status) {
    if (status.isCompleted) dispose();
  }

  @override
  void dispose() {
    _radiusController.dispose();
    _fadeInController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  @override
  void paintFeature(Canvas canvas, Matrix4 transform) {
    final int alpha = _confirmed ? _fadeOut.value : _fadeIn.value;
    if (alpha <= 0) return;
    final paint = Paint()..color = color.withAlpha(alpha);
    Offset center = _position;
    if (_repositionToReferenceBox) {
      center = Offset.lerp(
        center,
        referenceBox.size.center(Offset.zero),
        _radiusController.value,
      )!;
    }
    paintInkCircle(
      canvas: canvas,
      transform: transform,
      paint: paint,
      center: center,
      textDirection: textDirection,
      radius: _radius.value,
      customBorder: customBorder,
      borderRadius: _borderRadius,
      clipCallback: _clipCallback,
    );
  }

  static RectCallback? _clipCallbackFor(
    RenderBox referenceBox,
    bool containedInkWell,
    RectCallback? rectCallback,
  ) {
    if (rectCallback != null) return rectCallback;
    if (containedInkWell) return () => Offset.zero & referenceBox.size;
    return null;
  }

  static double _targetRadiusFor(
    RenderBox referenceBox,
    bool containedInkWell,
    RectCallback? rectCallback,
    Offset position,
  ) {
    if (!containedInkWell) return Material.defaultSplashRadius;
    final Size size = rectCallback != null
        ? rectCallback().size
        : referenceBox.size;
    final double d1 = (position - size.topLeft(Offset.zero)).distance;
    final double d2 = (position - size.topRight(Offset.zero)).distance;
    final double d3 = (position - size.bottomLeft(Offset.zero)).distance;
    final double d4 = (position - size.bottomRight(Offset.zero)).distance;
    return math.max(math.max(d1, d2), math.max(d3, d4)).ceilToDouble();
  }
}

class _InkWashSplashFactory extends InteractiveInkFeatureFactory {
  const _InkWashSplashFactory();

  @override
  InteractiveInkFeature create({
    required MaterialInkController controller,
    required RenderBox referenceBox,
    required Offset position,
    required Color color,
    required TextDirection textDirection,
    bool containedInkWell = false,
    RectCallback? rectCallback,
    BorderRadius? borderRadius,
    ShapeBorder? customBorder,
    double? radius,
    VoidCallback? onRemoved,
  }) {
    return InkWashSplash(
      controller: controller,
      referenceBox: referenceBox,
      position: position,
      color: color,
      textDirection: textDirection,
      containedInkWell: containedInkWell,
      rectCallback: rectCallback,
      borderRadius: borderRadius,
      customBorder: customBorder,
      radius: radius,
      onRemoved: onRemoved,
    );
  }
}
