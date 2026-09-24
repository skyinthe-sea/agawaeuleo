import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// DESIGN v3 §5.0 클레이 광택 — v3에서 허용된 **유일한** 그라데이션.
///
/// 떠 있는 면(주요 버튼·선택된 알약·스티커)에만 쓴다. 세로 2색으로 윗면이
/// 빛을 살짝 받은 점토처럼 보이게 할 뿐, 반짝이는 광택이 아니다. 둥근 버블
/// (아이콘 쿠션)에는 같은 빛을 좌상단 한 점으로 모은 [bubble]을 쓴다.
///
/// 빛 색은 모드별로 "더 밝은 쪽" 토큰이다 — 라이트는 `paperRaised`(크림),
/// 다크는 `ink900`(다크에서 밝은 텍스트 색). 둘 다 토큰이라 하드코딩이 없다.
abstract final class ClaySheen {
  /// 기본 광택 세기(윗면이 [base]에서 빛 쪽으로 옮겨 가는 비율).
  static const double strength = 0.22;

  /// 모드별 빛 색.
  static Color light(BuildContext context) =>
      context.isDark ? context.colors.ink900 : context.colors.paperRaised;

  /// [base] 면 위의 세로 광택 그라데이션.
  static LinearGradient gradient(
    BuildContext context,
    Color base, {
    double strength = ClaySheen.strength,
  }) {
    // 다크에서는 밝은 빛이 면을 탁하게 만들지 않게 절반만 섞는다.
    final s = context.isDark ? strength * 0.5 : strength;
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color.lerp(base, light(context), s)!, base],
    );
  }

  /// 채운 알약에 쓰는 자기 색 그림자(§3.2 톤 그림자). 다크는 공용 e2로 대신한다.
  ///
  /// [pressed]면 눌린 점토처럼 그림자가 바짝 줄어든다(§5.2 "눌림 = 그림자 축소") —
  /// 흐르는 탭 알약처럼 트랙 안에 앉은 작은 면에도 이 낮은 그림자를 쓴다.
  static List<BoxShadow> toneShadow(
    BuildContext context,
    Color tone, {
    bool pressed = false,
  }) {
    if (context.isDark) {
      return pressed ? context.shadows.e1 : context.shadows.e2;
    }
    return [
      BoxShadow(
        color: tone.withValues(alpha: pressed ? 0.22 : 0.28),
        offset: Offset(0, pressed ? 2 : 6),
        blurRadius: pressed ? 6 : 16,
      ),
    ];
  }

  /// 둥근 버블(아이콘 쿠션·도장) 위의 좌상단 하이라이트 — "점토 방울에 빛이 한 점
  /// 맺힌" 정도의 은은한 방사형 2색이다(§5.4 클레이 버블). 무지개·다색 금지 규칙은
  /// 그대로라 [base]와 그보다 밝은 [base] 두 색만 쓴다.
  static RadialGradient bubble(
    BuildContext context,
    Color base, {
    double strength = 0.5,
  }) {
    final s = context.isDark ? strength * 0.35 : strength;
    return RadialGradient(
      center: const Alignment(-0.42, -0.5),
      radius: 0.95,
      colors: [Color.lerp(base, light(context), s)!, base],
      stops: const [0, 0.72],
    );
  }
}

/// DESIGN v3 §5.4 스티커 칩 — 배지·BEST·순위·메타 칩의 공통 문법.
///
/// 알약 + wash 면(+ 은은한 클레이 광택) + fg 글자 + 흰 스티커 테두리
/// (`paperRaised`) + e1. 앞에 아이콘이나 임의 위젯([leading])을 붙일 수 있다.
/// 장식이 아니라 정보라면 소비처가 시맨틱 라벨을 책임진다(칩은 텍스트를 그대로
/// 노출한다).
class StickerChip extends StatelessWidget {
  const StickerChip({
    required this.label,
    this.icon,
    this.leading,
    this.wash,
    this.fg,
    this.dense = false,
    this.outline = true,
    super.key,
  });

  final String label;

  /// 앞 아이콘(선택). [leading]이 있으면 무시.
  final IconData? icon;

  /// 앞에 붙일 임의 위젯(작은 클레이 썸네일·점 등).
  final Widget? leading;

  /// 면 색(기본 `accentWash`).
  final Color? wash;

  /// 글자·아이콘 색(기본 `accent`).
  final Color? fg;

  /// 촘촘한 크기(높이 24) — 카드 안 배지용. 기본은 높이 30.
  final bool dense;

  /// 흰 스티커 테두리 여부.
  final bool outline;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final bg = wash ?? colors.accentWash;
    final color = fg ?? colors.accent;
    final lead =
        leading ??
        (icon != null ? Icon(icon, size: dense ? 13 : 15, color: color) : null);
    return Container(
      height: dense ? 24 : 30,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? AppSpacing.x8 : AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: bg,
        // 스티커도 떠 있는 면 — 윗면에 은은한 클레이 광택(§5.0).
        gradient: ClaySheen.gradient(context, bg),
        borderRadius: AppRadius.brFull,
        border: outline
            ? Border.all(color: colors.paperRaised, width: dense ? 1.5 : 2)
            : null,
        boxShadow: context.shadows.e1,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (lead != null) ...[lead, const SizedBox(width: AppSpacing.x4)],
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: texts.caption.copyWith(
                color: color,
                fontWeight: FontWeight.w700,
                letterSpacing: 0,
                height: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
