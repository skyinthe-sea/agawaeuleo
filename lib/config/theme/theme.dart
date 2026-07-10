import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_motion.dart';
import 'app_shadows.dart';
import 'app_typography.dart';

export 'app_colors.dart';
export 'app_motion.dart';
export 'app_radius.dart';
export 'app_shadows.dart';
export 'app_spacing.dart';
export 'app_texture.dart';
export 'app_theme.dart';
export 'app_typography.dart';

/// 페이퍼잉크 토큰 접근자. 위젯에서 `context.colors.accent`, `context.texts.title`,
/// `context.shadows.e1` 형태로 사용.
extension AppThemeX on BuildContext {
  /// §9.1 컬러 토큰(현재 테마 밝기 기준).
  AppColors get colors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  /// §9.5 음영 토큰(현재 테마 밝기 기준).
  AppShadows get shadows =>
      Theme.of(this).extension<AppShadows>() ?? AppShadows.light;

  /// §9.2 타입 스케일(색상 비의존).
  AppTextStyles get texts => const AppTextStyles();

  /// reduce-motion(동작 줄이기) 활성 여부.
  bool get reduceMotion => AppMotion.reduceMotion(this);

  /// 다크 모드 여부.
  bool get isDark => Theme.of(this).brightness == Brightness.dark;
}
