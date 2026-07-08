import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'application/notifiers/theme_mode_notifier.dart';
import 'config/theme/theme.dart';
import 'presentation/router/app_router.dart';

void main() {
  runApp(const ProviderScope(child: AgawaeuleoApp()));
}

/// 앱 루트. 테마 모드(라이트/다크/시스템)와 go_router를 배선한다.
class AgawaeuleoApp extends ConsumerStatefulWidget {
  const AgawaeuleoApp({super.key});

  @override
  ConsumerState<AgawaeuleoApp> createState() => _AgawaeuleoAppState();
}

class _AgawaeuleoAppState extends ConsumerState<AgawaeuleoApp> {
  // 라우터는 앱 수명 동안 한 번만 생성한다(리빌드 시 상태·스택 보존).
  late final GoRouter _router = createAppRouter();

  @override
  Widget build(BuildContext context) {
    // 복원 완료 전까지는 시스템 모드로 폴백(기본값).
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return MaterialApp.router(
      title: '아가왜울어',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      // §10.2 테마 전환: 전체 색상 크로스페이드 300ms.
      themeAnimationDuration: const Duration(milliseconds: 300),
      themeAnimationCurve: AppMotion.standard,
      routerConfig: _router,
    );
  }
}
