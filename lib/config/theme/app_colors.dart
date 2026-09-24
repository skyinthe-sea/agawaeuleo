import 'package:flutter/material.dart';

/// §9.1 컬러 토큰(DESIGN v3 "몽글 클레이" §3.1 개정). 순수 흑/백 금지 — 딸기우유 크림 배경 +
/// 코코아 텍스트 + 로즈 액센트 + 파스텔 카테고리 워시.
///
/// 토큰 **이름**은 v2(페이퍼잉크)에서 그대로 물려받았다(`paper*`=표면, `ink*`=텍스트) —
/// 241개 파일의 소비처를 흔들지 않고 값만 바꾸기 위해서다. 의미 대응은 DESIGN v3 §3.1.
@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.paperBg,
    required this.paperCard,
    required this.paperRaised,
    required this.paperStack,
    required this.ink900,
    required this.ink700,
    required this.ink500,
    required this.ink300,
    required this.line,
    required this.lineStrong,
    required this.accent,
    required this.accentWash,
    required this.accentDeep,
    required this.accentFill,
    required this.coral,
    required this.coralWash,
    required this.sage,
    required this.sageWash,
    required this.amber,
    required this.amberWash,
    required this.seal,
    required this.sealWash,
    required this.lilac,
    required this.lilacWash,
  });

  final Color paperBg;
  final Color paperCard;
  final Color paperRaised;

  /// DESIGN v2 §3.1 신규 — 겹친 종이 아랫장(hero 카드 스택 전용).
  final Color paperStack;
  final Color ink900;
  final Color ink700;
  final Color ink500;
  final Color ink300;
  final Color line;
  final Color lineStrong;
  final Color accent;
  final Color accentWash;
  final Color accentDeep;

  /// DESIGN v3 §3.1 신규 — 채운 알약(주 버튼·탭바 알약·"자세히 보기")의 **면** 전용 딸기 핑크.
  /// 위 글자는 반드시 큰 글씨(주아체 19 이상 = WCAG 큰 텍스트)여야 한다 — 크림 글자 대비 3.7:1.
  /// 작은 글자·링크·강조 글자색은 [accent](4.5:1 이상)를 쓴다.
  final Color accentFill;
  final Color coral;
  final Color coralWash;
  final Color sage;
  final Color sageWash;
  final Color amber;

  /// DESIGN v2 §3.1 신규 — 정보/배지 옅은 배경(기존 amber.withValues 하드코딩 대체).
  final Color amberWash;

  /// 브랜드 딸기 핑크(v2 낙관 인주 → v3 스티커·앱 아이콘 바탕). coral(응급)과 의미 분리.
  /// 텍스트 색으로 쓰지 않는다(대비 부족) — 면·장식 전용.
  final Color seal;

  /// DESIGN v2 §3.1 신규 — 낙관 옅은 배경(워터마크). 사용 빈도 낮음.
  final Color sealWash;

  /// DESIGN v3 §3.1 신규 — 엄마 돌봄(audience=mom) 톤. 라일락.
  final Color lilac;

  /// DESIGN v3 §3.1 신규 — 엄마 돌봄 옅은 배경.
  final Color lilacWash;

  static const AppColors light = AppColors(
    paperBg: Color(0xFFFFF6EF),
    paperCard: Color(0xFFFFFBF8),
    paperRaised: Color(0xFFFFFDFB),
    paperStack: Color(0xFFF9E9E0),
    ink900: Color(0xFF4A3531),
    ink700: Color(0xFF6B524D),
    ink500: Color(0xFF7B6159),
    ink300: Color(0xFFC9B3AB),
    line: Color(0xFFF4E3DA),
    lineStrong: Color(0xFFEAD0C4),
    accent: Color(0xFFB53E5D),
    accentWash: Color(0xFFFDE4EA),
    accentDeep: Color(0xFF9E3452),
    accentFill: Color(0xFFD9557A),
    coral: Color(0xFFBA3C27),
    coralWash: Color(0xFFFDE6DE),
    sage: Color(0xFF28775E),
    sageWash: Color(0xFFDDF3EA),
    amber: Color(0xFF965E0A),
    amberWash: Color(0xFFFFF0CC),
    seal: Color(0xFFF28DA2),
    sealWash: Color(0xFFFDE8EC),
    lilac: Color(0xFF7152BE),
    lilacWash: Color(0xFFEEE7FB),
  );

  static const AppColors dark = AppColors(
    paperBg: Color(0xFF221A19),
    paperCard: Color(0xFF2B2221),
    paperRaised: Color(0xFF342A28),
    paperStack: Color(0xFF1D1615),
    ink900: Color(0xFFF7EAE4),
    ink700: Color(0xFFD8C6BF),
    ink500: Color(0xFFA8948C),
    ink300: Color(0xFF75625C),
    line: Color(0xFF3A2F2D),
    lineStrong: Color(0xFF4A3D3A),
    accent: Color(0xFFF291A8),
    accentWash: Color(0xFF45272F),
    accentDeep: Color(0xFFF7B3C3),
    accentFill: Color(0xFFF291A8),
    coral: Color(0xFFF28C73),
    coralWash: Color(0xFF43261F),
    sage: Color(0xFF86D0B4),
    sageWash: Color(0xFF1F3A31),
    amber: Color(0xFFEDC06A),
    amberWash: Color(0xFF3F3220),
    seal: Color(0xFFF28DA2),
    sealWash: Color(0xFF45272F),
    lilac: Color(0xFFBCA6F0),
    lilacWash: Color(0xFF2F2742),
  );

  @override
  AppColors copyWith({
    Color? paperBg,
    Color? paperCard,
    Color? paperRaised,
    Color? paperStack,
    Color? ink900,
    Color? ink700,
    Color? ink500,
    Color? ink300,
    Color? line,
    Color? lineStrong,
    Color? accent,
    Color? accentWash,
    Color? accentDeep,
    Color? accentFill,
    Color? coral,
    Color? coralWash,
    Color? sage,
    Color? sageWash,
    Color? amber,
    Color? amberWash,
    Color? seal,
    Color? sealWash,
    Color? lilac,
    Color? lilacWash,
  }) {
    return AppColors(
      paperBg: paperBg ?? this.paperBg,
      paperCard: paperCard ?? this.paperCard,
      paperRaised: paperRaised ?? this.paperRaised,
      paperStack: paperStack ?? this.paperStack,
      ink900: ink900 ?? this.ink900,
      ink700: ink700 ?? this.ink700,
      ink500: ink500 ?? this.ink500,
      ink300: ink300 ?? this.ink300,
      line: line ?? this.line,
      lineStrong: lineStrong ?? this.lineStrong,
      accent: accent ?? this.accent,
      accentWash: accentWash ?? this.accentWash,
      accentDeep: accentDeep ?? this.accentDeep,
      accentFill: accentFill ?? this.accentFill,
      coral: coral ?? this.coral,
      coralWash: coralWash ?? this.coralWash,
      sage: sage ?? this.sage,
      sageWash: sageWash ?? this.sageWash,
      amber: amber ?? this.amber,
      amberWash: amberWash ?? this.amberWash,
      seal: seal ?? this.seal,
      sealWash: sealWash ?? this.sealWash,
      lilac: lilac ?? this.lilac,
      lilacWash: lilacWash ?? this.lilacWash,
    );
  }

  @override
  AppColors lerp(covariant ThemeExtension<AppColors>? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      paperBg: Color.lerp(paperBg, other.paperBg, t)!,
      paperCard: Color.lerp(paperCard, other.paperCard, t)!,
      paperRaised: Color.lerp(paperRaised, other.paperRaised, t)!,
      paperStack: Color.lerp(paperStack, other.paperStack, t)!,
      ink900: Color.lerp(ink900, other.ink900, t)!,
      ink700: Color.lerp(ink700, other.ink700, t)!,
      ink500: Color.lerp(ink500, other.ink500, t)!,
      ink300: Color.lerp(ink300, other.ink300, t)!,
      line: Color.lerp(line, other.line, t)!,
      lineStrong: Color.lerp(lineStrong, other.lineStrong, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      accentWash: Color.lerp(accentWash, other.accentWash, t)!,
      accentDeep: Color.lerp(accentDeep, other.accentDeep, t)!,
      accentFill: Color.lerp(accentFill, other.accentFill, t)!,
      coral: Color.lerp(coral, other.coral, t)!,
      coralWash: Color.lerp(coralWash, other.coralWash, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      sageWash: Color.lerp(sageWash, other.sageWash, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberWash: Color.lerp(amberWash, other.amberWash, t)!,
      seal: Color.lerp(seal, other.seal, t)!,
      sealWash: Color.lerp(sealWash, other.sealWash, t)!,
      lilac: Color.lerp(lilac, other.lilac, t)!,
      lilacWash: Color.lerp(lilacWash, other.lilacWash, t)!,
    );
  }
}
