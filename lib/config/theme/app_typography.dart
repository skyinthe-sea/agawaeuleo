import 'package:flutter/material.dart';

/// §9.2 폰트 패밀리. NotoSerifKR은 wght=700 고정 정적 서브셋
/// (assets/fonts/NotoSerifKR-Bold.ttf, pubspec에서 weight:700 단일 선언)이다.
/// 가변폰트가 아니므로 굵기는 fontWeight(w700)로 결정된다.
class AppFontFamily {
  const AppFontFamily._();

  static const String serif = 'NotoSerifKR';
  static const String sans = 'Pretendard';
  static const String mono = 'JetBrainsMono';
}

/// §9.2 타입 스케일(색상 비의존). 색은 ThemeData/텍스트가 주입.
/// 명조 계열은 정적 Bold 서브셋을 쓰므로 fontWeight(w700)만으로 충분하다.
/// fontVariations(wght 700)는 정적 폰트에서 무해하게 무시되며 호환성을 위해 유지한다.
class AppTypography {
  const AppTypography._();

  // 정적 Bold 서브셋에는 가변 축이 없어 실효는 없으나(무해), 명시성을 위해 유지.
  static const List<FontVariation> _serifBold = [FontVariation('wght', 700)];

  static const TextStyle display = TextStyle(
    fontFamily: AppFontFamily.serif,
    fontVariations: _serifBold,
    fontWeight: FontWeight.w700,
    fontSize: 28,
    height: 1.30,
  );

  static const TextStyle title = TextStyle(
    fontFamily: AppFontFamily.serif,
    fontVariations: _serifBold,
    fontWeight: FontWeight.w700,
    fontSize: 22,
    height: 1.35,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: AppFontFamily.sans,
    fontWeight: FontWeight.w600,
    fontSize: 18,
    height: 1.40,
  );

  static const TextStyle bodyL = TextStyle(
    fontFamily: AppFontFamily.sans,
    fontWeight: FontWeight.w400,
    fontSize: 16,
    height: 1.60,
  );

  static const TextStyle body = TextStyle(
    fontFamily: AppFontFamily.sans,
    fontWeight: FontWeight.w400,
    fontSize: 14,
    height: 1.60,
  );

  static const TextStyle label = TextStyle(
    fontFamily: AppFontFamily.sans,
    fontWeight: FontWeight.w600,
    fontSize: 15,
    height: 1.20,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFontFamily.sans,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.50,
  );

  static const TextStyle data = TextStyle(
    fontFamily: AppFontFamily.mono,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.20,
  );
}

/// context.texts 로 접근하는 인스턴스 뷰. 단일 소스는 [AppTypography] 정적 토큰.
class AppTextStyles {
  const AppTextStyles();

  TextStyle get display => AppTypography.display;
  TextStyle get title => AppTypography.title;
  TextStyle get heading => AppTypography.heading;
  TextStyle get bodyL => AppTypography.bodyL;
  TextStyle get body => AppTypography.body;
  TextStyle get label => AppTypography.label;
  TextStyle get caption => AppTypography.caption;
  TextStyle get data => AppTypography.data;
}
