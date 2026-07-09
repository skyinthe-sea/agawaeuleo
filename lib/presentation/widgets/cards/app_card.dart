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

  /// §9.5 카드 보더. 다크는 상단 1px 하이라이트([AppShadows.topHighlight]) + 나머지
  /// [line] 으로 카드를 띄운다(인셋 그림자로는 fill에 가려 무효과이므로 보더로 렌더).
  Border? _cardBorder(BuildContext context) {
    if (!widget.showBorder) return null;
    final colors = context.colors;
    final highlight = context.shadows.topHighlight;
    if (highlight == null) return Border.all(color: colors.line);
    final side = BorderSide(color: colors.line);
    return Border(
      top: BorderSide(color: highlight),
      left: side,
      right: side,
      bottom: side,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final shadows = context.shadows;
    final Color surface = widget.color ?? colors.paperCard;
    final Border? border = _cardBorder(context);

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
          // 눌림 시 e1 부양감 제거 — 오목함은 아래 foregroundDecoration으로 표현.
          boxShadow: _pressed ? AppShadows.e0 : shadows.e1,
          border: border,
        ),
        // §9.5 press 오목: 인셋 그림자를 자식 위(foregroundDecoration)에 덧그려야
        // 실제로 보인다. boxShadow(fill 뒤)로는 불투명 배경에 가려 무효과.
        foregroundDecoration: _pressed
            ? BoxDecoration(
                borderRadius: widget.borderRadius,
                boxShadow: shadows.press,
              )
            : null,
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
