import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// DESIGN v2 §4.4 "아이콘-in-원" 공용 컴포넌트. 워시 원 + 바깥 링 + 중앙 아이콘의
/// flat 패턴 복붙 4곳(로그인 `AuthLogo`, 권한 프라이밍 원, 재설정 성공 원,
/// `EmptyState`/`ErrorState` 등)을 이 단일 위젯으로 대체한다.
///
/// 구조: 워시 원(배경 [washColor]) + 바깥 링(지름 +10dp, stroke 1.2,
/// `[fgColor].withValues(alpha: .28)`) + 중앙 아이콘([icon], 색 [fgColor]) —
/// 또는 [child]로 임의 위젯(예: `InkDropLogo`)을 대신 삽입.
///
/// [elevated]가 true면 원에 e2 그림자를 준다. [animate]가 true면 마운트 시
/// scale .88→1 + fade(base, enter)로 "잉크 번짐"처럼 등장한다(reduce-motion 시
/// 즉시 표시). [ring]을 false로 주면 바깥 링을 생략한다(밀집 그리드용).
class InkHaloIcon extends StatelessWidget {
  const InkHaloIcon({
    required this.size,
    super.key,
    this.icon,
    this.child,
    this.washColor,
    this.fgColor,
    this.elevated = false,
    this.animate = false,
    this.ring = true,
    this.iconSize,
    this.semanticLabel,
  }) : assert(icon != null || child != null, 'icon 또는 child 중 하나는 지정해야 합니다.');

  /// 워시 원의 지름(dp). 바깥 링을 포함하면 실제 차지 폭은 `size + 10`.
  final double size;

  /// 중앙에 그릴 아이콘. [child]가 지정되면 무시된다.
  final IconData? icon;

  /// 아이콘 대신 임의 위젯을 중앙에 배치(예: `InkDropLogo`).
  final Widget? child;

  /// 원 배경색(미지정 시 `colors.accentWash`).
  final Color? washColor;

  /// 아이콘/링 전경색(미지정 시 `colors.accent`).
  final Color? fgColor;

  /// true면 원에 e2 그림자를 준다.
  final bool elevated;

  /// true면 등장 시 scale .88→1 + fade 모션을 재생한다.
  final bool animate;

  /// false면 바깥 링을 생략한다.
  final bool ring;

  /// 아이콘 크기(미지정 시 [size]의 절반).
  final double? iconSize;

  /// 지정 시 [Semantics] 이미지 라벨로 감싼다. 기존 소비처가 자체 시맨틱을
  /// 이미 감싸고 있다면 지정하지 않아도 된다(중복 방지).
  final String? semanticLabel;

  static const double _ringInset = 10;
  static const double _ringStroke = 1.2;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final wash = washColor ?? colors.accentWash;
    final fg = fgColor ?? colors.accent;

    Widget circle = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: wash,
        shape: BoxShape.circle,
        boxShadow: elevated ? context.shadows.e2 : null,
      ),
      child: child ?? Icon(icon, size: iconSize ?? size * 0.5, color: fg),
    );

    if (ring) {
      circle = Container(
        width: size + _ringInset,
        height: size + _ringInset,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: fg.withValues(alpha: 0.28),
            width: _ringStroke,
          ),
        ),
        child: circle,
      );
    }

    if (semanticLabel != null) {
      circle = Semantics(
        label: semanticLabel,
        image: true,
        child: ExcludeSemantics(child: circle),
      );
    }

    if (!animate) return circle;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.88, end: 1),
      duration: AppMotion.resolve(context, AppMotion.base),
      curve: AppMotion.resolveCurve(context, AppMotion.enter),
      builder: (context, scale, child) {
        final opacity = ((scale - 0.88) / 0.12).clamp(0.0, 1.0);
        return Opacity(
          opacity: opacity,
          child: Transform.scale(scale: scale, child: child),
        );
      },
      child: circle,
    );
  }
}
