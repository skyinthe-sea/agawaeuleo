import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../animated/ink_wash_splash.dart';

/// §11.0 카드. 배경 paper.card · r.md · e1(+헤어라인 line) · 내부 패딩 16.
/// [onTap] 지정 시 탭 스프링(scale .96) + 눌림 그림자(오목) + 잉크 워시 리플.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.color,
    this.borderRadius = AppRadius.brMd,
    this.showBorder = true,
    this.clipContent = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final BorderRadius borderRadius;

  /// e1의 헤어라인 보더 표시 여부.
  final bool showBorder;

  /// 자식을 카드 모서리로 클리핑할지(썸네일 등).
  final bool clipContent;

  @override
  State<AppCard> createState() => _AppCardState();
}

class _AppCardState extends State<AppCard> {
  bool _pressed = false;

  bool get _tappable => widget.onTap != null || widget.onLongPress != null;

  void _setPressed(bool value) {
    if (_pressed == value) return;
    setState(() => _pressed = value);
  }

  void _handleTap() {
    AppHaptics.tap();
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadows = context.shadows;
    final Color surface = widget.color ?? colors.paperCard;
    final Border? border = widget.showBorder
        ? Border.all(color: colors.line)
        : null;

    if (!_tappable) {
      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: widget.borderRadius,
          boxShadow: shadows.e1,
          border: border,
        ),
        clipBehavior: widget.clipContent ? Clip.antiAlias : Clip.none,
        padding: widget.padding,
        child: widget.child,
      );
    }

    final reduce = context.reduceMotion;
    final scale = (!reduce && _pressed) ? 0.96 : 1.0;

    return AnimatedScale(
      scale: scale,
      duration: _pressed ? AppMotion.instant : AppMotion.base,
      curve: _pressed ? AppMotion.standard : AppMotion.spring,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        curve: AppMotion.standard,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: widget.borderRadius,
          boxShadow: _pressed ? shadows.press : shadows.e1,
          border: border,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: widget.borderRadius,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            splashFactory: InkWashSplash.splashFactory,
            splashColor: colors.accentWash,
            highlightColor: Colors.transparent,
            borderRadius: widget.borderRadius,
            onTap: _handleTap,
            onLongPress: widget.onLongPress,
            onHighlightChanged: _setPressed,
            child: Padding(padding: widget.padding, child: widget.child),
          ),
        ),
      ),
    );
  }
}
