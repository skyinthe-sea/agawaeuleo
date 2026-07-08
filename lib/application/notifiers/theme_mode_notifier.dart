import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

part 'theme_mode_notifier.g.dart';

/// §5(설정) · §10.2 테마 전환. 라이트 / 다크 / 시스템 3모드를 관리하고
/// 사용자의 선택을 shared_preferences에 저장·복원한다. 기본값은 시스템(ThemeMode.system).
///
/// 복원은 비동기(디스크 읽기)이므로 [build]가 `Future<ThemeMode>`를 반환한다.
/// 로딩 중에는 값이 없으므로 소비 측에서 `.value ?? ThemeMode.system` 으로 폴백한다.
@Riverpod(keepAlive: true)
class ThemeModeNotifier extends _$ThemeModeNotifier {
  /// SharedPreferences 저장 키.
  static const String prefsKey = 'settings.theme_mode';

  @override
  Future<ThemeMode> build() async {
    final prefs = await SharedPreferences.getInstance();
    return _decode(prefs.getString(prefsKey));
  }

  /// 테마 모드를 [mode]로 변경한다. UI에 즉시 반영한 뒤 디스크에 저장한다.
  Future<void> setThemeMode(ThemeMode mode) async {
    state = AsyncData<ThemeMode>(mode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, _encode(mode));
  }

  static ThemeMode _decode(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case _:
        return ThemeMode.system;
    }
  }

  static String _encode(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
