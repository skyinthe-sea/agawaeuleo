import 'package:flutter/material.dart';

/// §9.1 컬러 토큰(DESIGN v2 §3.1 개정). 순수 흑/백 금지 — 한지 미색 배경 + 희석 먹빛 텍스트 + 청록 잉크 액센트.
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
    required this.coral,
    required this.coralWash,
    required this.sage,
    required this.sageWash,
    required this.amber,
    required this.amberWash,
    required this.seal,
    required this.sealWash,
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
  final Color coral;
  final Color coralWash;
  final Color sage;
  final Color sageWash;
  final Color amber;

  /// DESIGN v2 §3.1 신규 — 정보/배지 옅은 배경(기존 amber.withValues 하드코딩 대체).
  final Color amberWash;

  /// DESIGN v2 §3.1 신규 — 낙관 인주(브랜드). coral(응급)과 의미 분리.
  final Color seal;

  /// DESIGN v2 §3.1 신규 — 낙관 옅은 배경(워터마크). 사용 빈도 낮음.
  final Color sealWash;

  static const AppColors light = AppColors(
    paperBg: Color(0xFFF0EADB),
    paperCard: Color(0xFFFBF7EF),
    paperRaised: Color(0xFFFFFDF9),
    paperStack: Color(0xFFE8E0CD),
    ink900: Color(0xFF26292B),
    ink700: Color(0xFF474A45),
    ink500: Color(0xFF736E64),
    ink300: Color(0xFFA8A296),
    line: Color(0xFFE7DFD1),
    lineStrong: Color(0xFFD6CBB8),
    accent: Color(0xFF3E6B7A),
    accentWash: Color(0xFFE2EAEC),
    accentDeep: Color(0xFF2C5361),
    coral: Color(0xFFBC6448),
    coralWash: Color(0xFFF4E4DD),
    sage: Color(0xFF6F8A5F),
    sageWash: Color(0xFFE7EDDF),
    amber: Color(0xFFC08A3E),
    amberWash: Color(0xFFF4E9D5),
    seal: Color(0xFFA8432C),
    sealWash: Color(0xFFF1DFD7),
  );

  static const AppColors dark = AppColors(
    paperBg: Color(0xFF1A1815),
    paperCard: Color(0xFF232019),
    paperRaised: Color(0xFF2C281F),
    paperStack: Color(0xFF201D16),
    ink900: Color(0xFFECE7DC),
    ink700: Color(0xFFC7C1B4),
    ink500: Color(0xFF9C968A),
    ink300: Color(0xFF6F6A5F),
    line: Color(0xFF34302A),
    lineStrong: Color(0xFF454038),
    accent: Color(0xFF6FA0B0),
    accentWash: Color(0xFF22343A),
    accentDeep: Color(0xFF8FB9C7),
    coral: Color(0xFFD9846A),
    coralWash: Color(0xFF3A2620),
    sage: Color(0xFF93AC82),
    sageWash: Color(0xFF2A3324),
    amber: Color(0xFFD8AC66),
    amberWash: Color(0xFF3A311F),
    seal: Color(0xFFC96B4F),
    sealWash: Color(0xFF392620),
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
    Color? coral,
    Color? coralWash,
    Color? sage,
    Color? sageWash,
    Color? amber,
    Color? amberWash,
    Color? seal,
    Color? sealWash,
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
      coral: coral ?? this.coral,
      coralWash: coralWash ?? this.coralWash,
      sage: sage ?? this.sage,
      sageWash: sageWash ?? this.sageWash,
      amber: amber ?? this.amber,
      amberWash: amberWash ?? this.amberWash,
      seal: seal ?? this.seal,
      sealWash: sealWash ?? this.sealWash,
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
      coral: Color.lerp(coral, other.coral, t)!,
      coralWash: Color.lerp(coralWash, other.coralWash, t)!,
      sage: Color.lerp(sage, other.sage, t)!,
      sageWash: Color.lerp(sageWash, other.sageWash, t)!,
      amber: Color.lerp(amber, other.amber, t)!,
      amberWash: Color.lerp(amberWash, other.amberWash, t)!,
      seal: Color.lerp(seal, other.seal, t)!,
      sealWash: Color.lerp(sealWash, other.sealWash, t)!,
    );
  }
}
