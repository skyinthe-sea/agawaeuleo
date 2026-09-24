import 'package:flutter/material.dart';

/// §9.2 폰트 패밀리 — DESIGN v3 §3.3.
///
/// - [display] **주아체(Jua, SIL OFL 1.1)** — 제목·히어로. 통통하고 둥근 한 가지 굵기라
///   `fontWeight`는 의미가 없다(항상 같은 획). 가운뎃점(·) 등 일부 문장부호가 없어
///   [displayFallback]으로 Pretendard를 받친다.
/// - [sans] Pretendard — 본문·라벨(가독성 담당).
/// - [mono] JetBrains Mono — 수치(기록 기능 숨김 중이라 사용처가 적다).
class AppFontFamily {
  const AppFontFamily._();

  static const String display = 'Jua';
  static const String sans = 'Pretendard';
  static const String mono = 'JetBrainsMono';

  /// 주아체에 없는 글리프(·, 일부 기호)를 이어받는 폴백 체인.
  static const List<String> displayFallback = [sans];
}

/// §9.2 타입 스케일(색상 비의존, DESIGN v3 §3.3 개정 — 명조 → 주아체, 제목 계열 자간 0 근처).
/// 색은 ThemeData/텍스트가 주입.
class AppTypography {
  const AppTypography._();

  /// 온보딩 제목, 히어로 모먼트(주아체).
  static const TextStyle displayL = TextStyle(
    fontFamily: AppFontFamily.display,
    fontFamilyFallback: AppFontFamily.displayFallback,
    fontWeight: FontWeight.w400,
    fontSize: 34,
    height: 1.22,
    letterSpacing: -0.4,
  );

  static const TextStyle display = TextStyle(
    fontFamily: AppFontFamily.display,
    fontFamilyFallback: AppFontFamily.displayFallback,
    fontWeight: FontWeight.w400,
    fontSize: 28,
    height: 1.26,
    letterSpacing: -0.3,
  );

  static const TextStyle title = TextStyle(
    fontFamily: AppFontFamily.display,
    fontFamilyFallback: AppFontFamily.displayFallback,
    fontWeight: FontWeight.w400,
    fontSize: 22,
    height: 1.32,
    letterSpacing: -0.2,
  );

  static const TextStyle heading = TextStyle(
    fontFamily: AppFontFamily.display,
    fontFamilyFallback: AppFontFamily.displayFallback,
    fontWeight: FontWeight.w400,
    fontSize: 19,
    height: 1.36,
    letterSpacing: -0.1,
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
    letterSpacing: 0.2,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: AppFontFamily.sans,
    fontWeight: FontWeight.w500,
    fontSize: 12,
    height: 1.50,
    letterSpacing: 0.4,
  );

  /// DESIGN v2 §3.3 신규 — 섹션 오버라인, 날짜 라벨(`ink500` 소비처 책임).
  static const TextStyle overline = TextStyle(
    fontFamily: AppFontFamily.sans,
    fontWeight: FontWeight.w600,
    fontSize: 11,
    height: 1.30,
    letterSpacing: 1.2,
  );

  static const TextStyle data = TextStyle(
    fontFamily: AppFontFamily.mono,
    fontWeight: FontWeight.w500,
    fontSize: 16,
    height: 1.20,
  );

  /// DESIGN v2 §3.3 신규 — 트래킹 히어로 수치(경과시간 등).
  static const TextStyle dataL = TextStyle(
    fontFamily: AppFontFamily.mono,
    fontWeight: FontWeight.w500,
    fontSize: 28,
    height: 1.15,
  );
}

/// context.texts 로 접근하는 인스턴스 뷰. 단일 소스는 [AppTypography] 정적 토큰.
class AppTextStyles {
  const AppTextStyles();

  TextStyle get displayL => AppTypography.displayL;
  TextStyle get display => AppTypography.display;
  TextStyle get title => AppTypography.title;
  TextStyle get heading => AppTypography.heading;
  TextStyle get bodyL => AppTypography.bodyL;
  TextStyle get body => AppTypography.body;
  TextStyle get label => AppTypography.label;
  TextStyle get caption => AppTypography.caption;
  TextStyle get overline => AppTypography.overline;
  TextStyle get data => AppTypography.data;
  TextStyle get dataL => AppTypography.dataL;
}
