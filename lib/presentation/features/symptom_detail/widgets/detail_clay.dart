import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:flutter/material.dart';

/// DESIGN v3 "몽글 클레이" — 증상 상세(케어 노트·제품 보드)가 함께 쓰는 작은
/// 클레이 조각과 톤 규칙.
///
/// 공용 위젯(`lib/presentation/widgets/`)으로 올릴 만큼 범용적이지 않은, 상세
/// 화면 안에서만 반복되는 문법(파스텔 버블·주아체 숫자·하트 오버라인·채운 알약 면
/// 보정·대상별 톤)을 모은다.
abstract final class DetailTone {
  /// 글자를 얹는 **채운 알약**의 면 — 톤을 본문 코코아(`ink900`) 쪽으로 10%만
  /// 당긴다. 클레이 광택(윗면이 밝아짐) 아래 알약 한가운데(글자 자리)에서도
  /// `paperRaised` 글자가 4.5:1 여유를 두고 넘게 한다(accent 그대로면 4.5 경계).
  /// 다크는 `ink900`이 밝은 색이라 같은 식이 면을 밝혀 어두운 글자 대비를 올린다.
  static Color fill(BuildContext context, Color fg) =>
      Color.lerp(fg, context.colors.ink900, 0.1)!;

  /// 증상 대상별 강조 톤 — 아기 돌봄 = 딸기(accent), 엄마 돌봄 = 라일락(lilac).
  static ({Color wash, Color fg}) audience(
    BuildContext context,
    SymptomAudience audience,
  ) {
    final colors = context.colors;
    return audience == SymptomAudience.mom
        ? (wash: colors.lilacWash, fg: colors.lilac)
        : (wash: colors.accentWash, fg: colors.accent);
  }
}

/// 파스텔 클레이 버블 — wash 원 + 윗면 광택(§5.0) + (선택) 흰 스티커 테두리·e1.
///
/// 아이콘 버블·번호 동그라미·셰브론 버블의 공통 몸체. 장식이므로 의미는 소비처가
/// 시맨틱 라벨로 전달한다.
class ClayBubble extends StatelessWidget {
  const ClayBubble({
    required this.size,
    required this.wash,
    super.key,
    this.icon,
    this.iconColor,
    this.iconSize,
    this.child,
    this.outline = false,
    this.lifted = false,
  }) : assert(icon != null || child != null, 'icon 또는 child 중 하나는 필요합니다.');

  final double size;

  /// 버블 면 색(보통 톤 wash).
  final Color wash;
  final IconData? icon;
  final Color? iconColor;
  final double? iconSize;

  /// 아이콘 대신 그릴 위젯(주아체 숫자 등).
  final Widget? child;

  /// 흰 스티커 테두리(`paperRaised`) — 사진·색면 위에 얹힐 때.
  final bool outline;

  /// e1 그림자로 살짝 띄운다.
  final bool lifted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: ClaySheen.gradient(context, wash),
        border: outline
            ? Border.all(color: colors.paperRaised, width: size >= 28 ? 2 : 1.5)
            : null,
        boxShadow: lifted ? context.shadows.e1 : null,
      ),
      child:
          child ??
          Icon(
            icon,
            size: iconSize ?? size * 0.5,
            color: iconColor ?? colors.accent,
          ),
    );
  }
}

/// 주아체 숫자(순번·개수) — v2의 모노 숫자(`01`)를 대신한다(§3.3).
class ClayNumber extends StatelessWidget {
  const ClayNumber(
    this.value, {
    required this.color,
    super.key,
    this.size = 14,
  });

  final String value;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      // heading 토큰(주아체)에서 크기만 바꾼다 — 주아체는 한 굵기라 weight 불변.
      style: context.texts.heading.copyWith(
        fontSize: size,
        height: 1.1,
        letterSpacing: 0,
        color: color,
      ),
    );
  }
}

/// 작은 하트 + 오버라인 — v2의 먹선 틱 오버라인(▍)을 대신한다.
class HeartOverline extends StatelessWidget {
  const HeartOverline({required this.label, super.key, this.heartColor});

  final String label;

  /// 하트 색(장식 — 기본 `seal` 딸기 핑크).
  final Color? heartColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Row(
      children: [
        ExcludeSemantics(
          child: Icon(
            Icons.favorite_rounded,
            size: 12,
            color: heartColor ?? colors.seal,
          ),
        ),
        const SizedBox(width: AppSpacing.x4 + AppSpacing.x2),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.texts.overline.copyWith(color: colors.ink500),
          ),
        ),
      ],
    );
  }
}
