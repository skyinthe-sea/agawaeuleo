import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../presentation/widgets/animated/ink_wash_splash.dart';
import 'app_colors.dart';
import 'app_radius.dart';
import 'app_shadows.dart';
import 'app_typography.dart';

/// §9 + §11.0 을 ThemeData로 배선. Material3 기반 커스텀(DESIGN v3 "몽글 클레이" —
/// 버튼·칩·툴팁은 알약, 입력·카드·시트·다이얼로그는 한 단계 더 둥글게, 상단바는
/// 화면과 같은 크림 바탕, 스낵바는 코코아 토스트).
/// light()/dark() 두 빌더만 노출 — main/통합에서 사용.
class AppTheme {
  const AppTheme._();

  static ThemeData light() => _build(
    colors: AppColors.light,
    shadows: AppShadows.light,
    brightness: Brightness.light,
  );

  static ThemeData dark() => _build(
    colors: AppColors.dark,
    shadows: AppShadows.dark,
    brightness: Brightness.dark,
  );

  static const SystemUiOverlayStyle _lightOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static const SystemUiOverlayStyle _darkOverlay = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  static ThemeData _build({
    required AppColors colors,
    required AppShadows shadows,
    required Brightness brightness,
  }) {
    final c = colors;
    final scheme = _colorScheme(c, brightness);
    final textTheme = _textTheme(c);

    return ThemeData(
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: c.paperBg,
      canvasColor: c.paperBg,
      splashColor: c.accentWash,
      highlightColor: c.accentWash,
      // §10.1 잉크 워시 리플을 전역 splashFactory로 배선(InkWell/버튼 공통 적용).
      splashFactory: InkWashSplash.splashFactory,
      textTheme: textTheme,
      fontFamily: AppFontFamily.sans,
      extensions: <ThemeExtension<dynamic>>[c, shadows],
      appBarTheme: AppBarTheme(
        toolbarHeight: 56,
        // DESIGN v3 — 상단바는 화면 바탕(크림)과 한 몸(`AppAppBar`와 동일).
        backgroundColor: c.paperBg,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        foregroundColor: c.ink900,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 16,
        iconTheme: IconThemeData(color: c.ink900, size: 24),
        actionsIconTheme: IconThemeData(color: c.ink900, size: 24),
        titleTextStyle: AppTypography.title.copyWith(color: c.ink900),
        systemOverlayStyle: brightness == Brightness.light
            ? _lightOverlay
            : _darkOverlay,
      ),
      navigationBarTheme: NavigationBarThemeData(
        height: 64,
        backgroundColor: c.paperRaised,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        indicatorColor: c.accentWash,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(size: 28, color: selected ? c.accent : c.ink300);
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return AppTypography.caption.copyWith(
            color: selected ? c.accent : c.ink300,
          );
        }),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: c.paperRaised,
        selectedItemColor: c.accent,
        unselectedItemColor: c.ink300,
        selectedLabelStyle: AppTypography.caption,
        unselectedLabelStyle: AppTypography.caption,
        selectedIconTheme: const IconThemeData(size: 28),
        unselectedIconTheme: const IconThemeData(size: 28),
        type: BottomNavigationBarType.fixed,
        showUnselectedLabels: true,
        elevation: 0,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) return c.ink300;
            if (states.contains(WidgetState.pressed)) return c.accentDeep;
            return c.accent;
          }),
          foregroundColor: WidgetStatePropertyAll(c.paperRaised),
          overlayColor: WidgetStatePropertyAll(
            c.paperRaised.withValues(alpha: 0.08),
          ),
          textStyle: const WidgetStatePropertyAll(AppTypography.label),
          elevation: const WidgetStatePropertyAll(0),
          shadowColor: const WidgetStatePropertyAll(Colors.transparent),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          minimumSize: const WidgetStatePropertyAll(Size.fromHeight(54)),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
          side: WidgetStatePropertyAll(
            BorderSide(color: c.lineStrong, width: 1.5),
          ),
          // DESIGN v3 §5.2 — 보조 알약은 paperRaised 면(`GhostButton`과 동일).
          backgroundColor: WidgetStatePropertyAll(c.paperRaised),
          foregroundColor: WidgetStatePropertyAll(c.ink700),
          overlayColor: WidgetStatePropertyAll(c.accentWash),
          textStyle: const WidgetStatePropertyAll(AppTypography.label),
          padding: const WidgetStatePropertyAll(
            EdgeInsets.symmetric(horizontal: 20),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStatePropertyAll(c.accent),
          overlayColor: WidgetStatePropertyAll(c.accentWash),
          textStyle: const WidgetStatePropertyAll(AppTypography.label),
          shape: const WidgetStatePropertyAll(StadiumBorder()),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.paperRaised,
        isDense: false,
        constraints: const BoxConstraints(minHeight: 52),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: AppTypography.bodyL.copyWith(color: c.ink300),
        labelStyle: AppTypography.body.copyWith(color: c.ink500),
        floatingLabelStyle: AppTypography.body.copyWith(color: c.accent),
        errorStyle: AppTypography.caption.copyWith(color: c.coral),
        helperStyle: AppTypography.caption.copyWith(color: c.ink500),
        border: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: c.line, width: 1.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: c.line, width: 1.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: c.accent, width: 2),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: c.line, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: c.coral, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadius.brMd,
          borderSide: BorderSide(color: c.coral, width: 2),
        ),
      ),
      cardTheme: CardThemeData(
        color: c.paperCard,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
        clipBehavior: Clip.antiAlias,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: c.paperRaised,
        surfaceTintColor: Colors.transparent,
        modalBackgroundColor: c.paperRaised,
        elevation: 0,
        modalElevation: 0,
        showDragHandle: true,
        dragHandleColor: c.lineStrong,
        // DESIGN v3 §5.1 — 핸들 40×5 알약(`AppSheetShell` 그래버와 동일).
        dragHandleSize: const Size(40, 5),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: c.paperRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brXl),
        titleTextStyle: AppTypography.title.copyWith(color: c.ink900),
        contentTextStyle: AppTypography.bodyL.copyWith(color: c.ink700),
      ),
      // DESIGN v3 — 크림 바탕 위에서 또렷한 코코아 토스트(다크는 `ink900`이 밝아
      // 자동으로 크림 토스트로 뒤집힌다). 액션은 두 모드 모두 대비 4.5:1 이상인
      // `accentWash`(딸기 워시) 글자.
      snackBarTheme: SnackBarThemeData(
        backgroundColor: c.ink900,
        contentTextStyle: AppTypography.body.copyWith(color: c.paperRaised),
        actionTextColor: c.accentWash,
        behavior: SnackBarBehavior.floating,
        elevation: 0,
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.brLg),
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      chipTheme: ChipThemeData(
        backgroundColor: c.paperRaised,
        selectedColor: c.accentWash,
        side: BorderSide(color: c.line, width: 1.5),
        labelStyle: AppTypography.caption.copyWith(color: c.ink700),
        shape: const StadiumBorder(),
        showCheckmark: false,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: c.ink900,
          borderRadius: AppRadius.brFull,
        ),
        textStyle: AppTypography.caption.copyWith(color: c.paperRaised),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: c.accent,
        linearTrackColor: c.paperStack,
        circularTrackColor: Colors.transparent,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: c.accent,
        selectionColor: c.accentWash,
        selectionHandleColor: c.accent,
      ),
      iconTheme: IconThemeData(color: c.ink700, size: 24),
      primaryColor: c.accent,
      hintColor: c.ink300,
      disabledColor: c.ink300,
    );
  }

  static ColorScheme _colorScheme(AppColors c, Brightness brightness) {
    return ColorScheme(
      brightness: brightness,
      primary: c.accent,
      onPrimary: c.paperRaised,
      primaryContainer: c.accentWash,
      onPrimaryContainer: c.accentDeep,
      secondary: c.sage,
      onSecondary: c.paperRaised,
      secondaryContainer: c.sageWash,
      onSecondaryContainer: c.sage,
      tertiary: c.amber,
      onTertiary: c.paperRaised,
      // DESIGN v2 §3.1 — amberWash가 "정보/배지 옅은 배경" 역할이므로 배선.
      tertiaryContainer: c.amberWash,
      onTertiaryContainer: c.amber,
      error: c.coral,
      onError: c.paperRaised,
      errorContainer: c.coralWash,
      onErrorContainer: c.coral,
      surface: c.paperCard,
      onSurface: c.ink900,
      onSurfaceVariant: c.ink500,
      surfaceContainerLowest: c.paperBg,
      surfaceContainerLow: c.paperBg,
      surfaceContainer: c.paperCard,
      surfaceContainerHigh: c.paperRaised,
      surfaceContainerHighest: c.paperRaised,
      surfaceDim: c.paperBg,
      surfaceBright: c.paperRaised,
      outline: c.lineStrong,
      outlineVariant: c.line,
      shadow: const Color(0xFF000000),
      scrim: const Color(0xFF000000),
      inverseSurface: c.ink900,
      onInverseSurface: c.paperCard,
      inversePrimary: c.accentDeep,
    );
  }

  static TextTheme _textTheme(AppColors c) {
    final ink900 = c.ink900;
    final ink700 = c.ink700;
    final ink500 = c.ink500;
    return TextTheme(
      displayLarge: AppTypography.display.copyWith(color: ink900),
      displayMedium: AppTypography.display.copyWith(color: ink900),
      displaySmall: AppTypography.display.copyWith(color: ink900),
      headlineLarge: AppTypography.title.copyWith(color: ink900),
      headlineMedium: AppTypography.title.copyWith(color: ink900),
      headlineSmall: AppTypography.heading.copyWith(color: ink900),
      titleLarge: AppTypography.title.copyWith(color: ink900),
      titleMedium: AppTypography.heading.copyWith(color: ink900),
      titleSmall: AppTypography.label.copyWith(color: ink900),
      bodyLarge: AppTypography.bodyL.copyWith(color: ink900),
      bodyMedium: AppTypography.body.copyWith(color: ink700),
      bodySmall: AppTypography.caption.copyWith(color: ink500),
      labelLarge: AppTypography.label.copyWith(color: ink900),
      labelMedium: AppTypography.caption.copyWith(color: ink500),
      labelSmall: AppTypography.caption.copyWith(color: ink500),
    );
  }
}
