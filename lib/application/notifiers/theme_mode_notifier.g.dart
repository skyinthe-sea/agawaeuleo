// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'theme_mode_notifier.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning
/// §5(설정) · §10.2 테마 전환. 라이트 / 다크 / 시스템 3모드를 관리하고
/// 사용자의 선택을 shared_preferences에 저장·복원한다. 기본값은 시스템(ThemeMode.system).
///
/// 복원은 비동기(디스크 읽기)이므로 [build]가 `Future<ThemeMode>`를 반환한다.
/// 로딩 중에는 값이 없으므로 소비 측에서 `.value ?? ThemeMode.system` 으로 폴백한다.

@ProviderFor(ThemeModeNotifier)
final themeModeProvider = ThemeModeNotifierProvider._();

/// §5(설정) · §10.2 테마 전환. 라이트 / 다크 / 시스템 3모드를 관리하고
/// 사용자의 선택을 shared_preferences에 저장·복원한다. 기본값은 시스템(ThemeMode.system).
///
/// 복원은 비동기(디스크 읽기)이므로 [build]가 `Future<ThemeMode>`를 반환한다.
/// 로딩 중에는 값이 없으므로 소비 측에서 `.value ?? ThemeMode.system` 으로 폴백한다.
final class ThemeModeNotifierProvider
    extends $AsyncNotifierProvider<ThemeModeNotifier, ThemeMode> {
  /// §5(설정) · §10.2 테마 전환. 라이트 / 다크 / 시스템 3모드를 관리하고
  /// 사용자의 선택을 shared_preferences에 저장·복원한다. 기본값은 시스템(ThemeMode.system).
  ///
  /// 복원은 비동기(디스크 읽기)이므로 [build]가 `Future<ThemeMode>`를 반환한다.
  /// 로딩 중에는 값이 없으므로 소비 측에서 `.value ?? ThemeMode.system` 으로 폴백한다.
  ThemeModeNotifierProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'themeModeProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$themeModeNotifierHash();

  @$internal
  @override
  ThemeModeNotifier create() => ThemeModeNotifier();
}

String _$themeModeNotifierHash() => r'9006aad5aff19908b5c9e498b023d458810a0037';

/// §5(설정) · §10.2 테마 전환. 라이트 / 다크 / 시스템 3모드를 관리하고
/// 사용자의 선택을 shared_preferences에 저장·복원한다. 기본값은 시스템(ThemeMode.system).
///
/// 복원은 비동기(디스크 읽기)이므로 [build]가 `Future<ThemeMode>`를 반환한다.
/// 로딩 중에는 값이 없으므로 소비 측에서 `.value ?? ThemeMode.system` 으로 폴백한다.

abstract class _$ThemeModeNotifier extends $AsyncNotifier<ThemeMode> {
  FutureOr<ThemeMode> build();
  @$mustCallSuper
  @override
  WhenComplete runBuild() {
    final ref = this.ref as $Ref<AsyncValue<ThemeMode>, ThemeMode>;
    final element =
        ref.element
            as $ClassProviderElement<
              AnyNotifier<AsyncValue<ThemeMode>, ThemeMode>,
              AsyncValue<ThemeMode>,
              Object?,
              Object?
            >;
    return element.handleCreate(ref, build);
  }
}
