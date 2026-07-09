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

  /// §9.5 카드 보더 — 양 모드 모두 [line] 헤어라인 1px(균일색).
  ///
  /// 다크 상단 하이라이트([AppShadows.topHighlight])를 top 변만 다른 색으로 주면
  /// `Border` 가 비균일색이 되고, [AppCard.borderRadius] 와 함께 칠할 때
  /// Flutter `Border.paint()` 의 assert("A borderRadius can only be given on
  /// borders with uniform colors")가 페인트 도중 발생해 자식(카드 내용)이 렌더되지
  /// 않는다(release 는 assert 제거로 각진 모서리로 조용히 폴백). 따라서 균일
  /// [Border.all] 로만 렌더한다 — 라이트가 이미 쓰는 `paintUniformBorderWithRadius`
  /// 경로와 동일해 다크에서도 둥근 모서리 헤어라인이 정상 렌더된다.
  Border? _cardBorder(BuildContext context) {
    if (!widget.showBorder) return null;
    return Border.all(color: context.colors.line);
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
