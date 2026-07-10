import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../animated/ink_wash_splash.dart';
import '../surfaces/paper_background.dart';

/// DESIGN v2 §5.1 카드 위계 3단. 기본값은 [flat](기존 호출부와 시각적으로 동일).
enum AppCardEmphasis {
  /// 정지 카드(그리드·정보·리스트 카드) — `paperCard` + e1 + `brMd`(14).
  flat,

  /// 강조·상승 표면 — `paperRaised` + e2 + `brLg`(20).
  raised,

  /// [raised]와 동일 표면이되, 뒤에 `paperStack` 아랫장을 겹쳐 "겹친 한지"
  /// 인상을 낸다(요약 카드 등 히어로 모먼트 전용 — 그리드 밀도상 남용 금지).
  hero,
}

/// §11.0 카드. 배경 paper.card · r.md · e1(+헤어라인 line) · 내부 패딩 16.
/// [onTap] 지정 시 탭 스프링(scale .96) + 눌림 그림자(오목) + 잉크 워시 리플.
///
/// [emphasis]로 위계를 3단(flat/raised/hero, DESIGN v2 §5.1)으로 올릴 수 있다.
/// 기본값 `flat`은 기존 시각과 완전히 동일하므로 기존 호출부는 무변경.
class AppCard extends StatefulWidget {
  const AppCard({
    required this.child,
    super.key,
    this.onTap,
    this.onLongPress,
    this.emphasis = AppCardEmphasis.flat,
    this.padding = const EdgeInsets.all(AppSpacing.cardPadding),
    this.color,
    this.borderRadius,
    this.showBorder = true,
    this.clipContent = false,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  /// 카드 위계(DESIGN v2 §5.1). 기본 `flat`.
  final AppCardEmphasis emphasis;
  final EdgeInsetsGeometry padding;
  final Color? color;

  /// 미지정 시 [emphasis]에 대응하는 라디우스(flat=brMd, raised/hero=brLg).
  final BorderRadius? borderRadius;

  /// e1의 헤어라인 보더 표시 여부.
  final bool showBorder;

  /// 자식을 카드 모서리로 클리핑할지(썸네일 등).
  final bool clipContent;

  /// [emphasis]의 기본 배경색.
  Color _defaultColor(AppColors colors) => switch (emphasis) {
    AppCardEmphasis.flat => colors.paperCard,
    AppCardEmphasis.raised || AppCardEmphasis.hero => colors.paperRaised,
  };

  /// [emphasis]의 기본 라디우스.
  BorderRadius _defaultRadius() => switch (emphasis) {
    AppCardEmphasis.flat => AppRadius.brMd,
    AppCardEmphasis.raised || AppCardEmphasis.hero => AppRadius.brLg,
  };

  /// [emphasis]의 기본 음영.
  List<BoxShadow> _defaultShadow(AppShadows shadows) => switch (emphasis) {
    AppCardEmphasis.flat => shadows.e1,
    AppCardEmphasis.raised || AppCardEmphasis.hero => shadows.e2,
  };

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
    final Color surface = widget.color ?? widget._defaultColor(colors);
    final BorderRadius radius = widget.borderRadius ?? widget._defaultRadius();
    final List<BoxShadow> baseShadow = widget._defaultShadow(shadows);
    final Border? border = _cardBorder(context);

    final bool grain = widget.emphasis == AppCardEmphasis.hero;
    final core = _buildCore(
      context: context,
      colors: colors,
      shadows: shadows,
      surface: surface,
      radius: radius,
      baseShadow: baseShadow,
      border: border,
      grain: grain,
    );

    if (!grain) return core;

    // DESIGN v2 §5.1 hero — 카드 뒤 paperStack 아랫장(좌우 10dp 인셋, 아래로 4dp
    // 오프셋, 동일 라디우스, 보더 없음) + 그레인 오버레이("겹친 한지" 시그니처).
    // 다크 모드는 별도 분기 없이 [AppColors.paperStack]의 다크 값을 그대로 쓴다
    // (다크 hero는 이미 topHighlight로 강조되므로 스택 색만 교체하면 충분).
    //
    // 그레인은 core "내부"(데코레이션 클립 안)에서 그린다 — core를 ClipRRect로
    // 감싸면 데코레이션이 칠하는 e2 그림자까지 잘려 나가 부양감이 사라진다.
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Positioned(
          left: 10,
          right: 10,
          top: 4,
          bottom: -4,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.paperStack,
              borderRadius: radius,
            ),
          ),
        ),
        core,
      ],
    );
  }

  /// [grain]이면 [child] 아래에 그레인 오버레이를 깐다(§5.1 hero 전용).
  Widget _withGrain(bool grain, Widget child) =>
      grain ? PaperBackground(child: child) : child;

  Widget _buildCore({
    required BuildContext context,
    required AppColors colors,
    required AppShadows shadows,
    required Color surface,
    required BorderRadius radius,
    required List<BoxShadow> baseShadow,
    required Border? border,
    required bool grain,
  }) {
    if (!_tappable) {
      // grain 시 패딩을 자식 쪽으로 옮겨 그레인이 카드 면 전체를 덮게 하고,
      // 데코레이션 클립(자식에만 적용, 그림자는 무사)으로 모서리를 정리한다.
      return Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: radius,
          boxShadow: baseShadow,
          border: border,
        ),
        clipBehavior: (grain || widget.clipContent)
            ? Clip.antiAlias
            : Clip.none,
        padding: grain ? null : widget.padding,
        child: grain
            ? PaperBackground(
                child: Padding(padding: widget.padding, child: widget.child),
              )
            : widget.child,
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
          borderRadius: radius,
          // 눌림 시 부양감 제거 — 오목함은 아래 foregroundDecoration으로 표현.
          boxShadow: _pressed ? AppShadows.e0 : baseShadow,
          border: border,
        ),
        // §9.5 press 오목: 인셋 그림자를 자식 위(foregroundDecoration)에 덧그려야
        // 실제로 보인다. boxShadow(fill 뒤)로는 불투명 배경에 가려 무효과.
        foregroundDecoration: _pressed
            ? BoxDecoration(borderRadius: radius, boxShadow: shadows.press)
            : null,
        child: Material(
          type: MaterialType.transparency,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          // grain은 Material 클립 안(그림자 밖)에서 그린다. 그레인 레이어는
          // IgnorePointer라 InkWell 탭/리플에 영향 없음.
          child: _withGrain(
            grain,
            InkWell(
              splashFactory: InkWashSplash.splashFactory,
              splashColor: colors.accentWash,
              highlightColor: Colors.transparent,
              borderRadius: radius,
              onTap: _handleTap,
              onLongPress: widget.onLongPress,
              onHighlightChanged: _setPressed,
              child: Padding(padding: widget.padding, child: widget.child),
            ),
          ),
        ),
      ),
    );
  }
}
