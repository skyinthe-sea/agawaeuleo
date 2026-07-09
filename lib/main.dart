import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'application/notification_providers.dart';
import 'application/notifiers/theme_mode_notifier.dart';
import 'application/providers.dart';
import 'config/env.dart';
import 'config/theme/theme.dart';
import 'data/supabase/supabase.dart';
import 'l10n/app_localizations.dart';
import 'presentation/router/app_router.dart';

Future<void> main() async {
  // 플랫폼 채널(shared_preferences·Supabase·drift)을 안전하게 호출하려면 runApp 이전에
  // 바인딩을 초기화해야 한다.
  WidgetsFlutterBinding.ensureInitialized();

  // 미구성(.env 비어있음)이면 내부적으로 건너뛰고 false를 반환한다 — 로컬 전용 모드.
  // supabaseClientProvider가 최초 build에서 정적 isInitialized를 읽으므로, 초기화는
  // 반드시 runApp 이전에 await 되어야 원격 프로바이더가 올바른 값을 캐시한다.
  await SupabaseBootstrap.ensureInitialized();

  // 크래시 리포팅(§3.3): SENTRY_DSN 이 비어 있으면(미구성) 완전히 건너뛰고 현 동작 그대로
  // runApp 한다 — Sentry 를 초기화하지 않으므로 미구성 환경·테스트에 회귀가 없다.
  final dsn = Env.sentryDsn;
  if (dsn == null || dsn.isEmpty) {
    runApp(const ProviderScope(child: AgawaeuleoApp()));
    return;
  }

  // DSN 이 설정된 경우에만 Sentry 로 앱 실행을 감싼다. appRunner 안에서 runApp 을 호출해
  // 초기화 이후의 프레임/에러를 계측한다.
  await SentryFlutter.init((options) {
    options
      ..dsn = dsn
      // 프라이버시 존중(§8·§13): 개인 식별정보(PII)를 기본 첨부하지 않는다.
      ..sendDefaultPii = false;
  }, appRunner: () => runApp(const ProviderScope(child: AgawaeuleoApp())));
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
  void initState() {
    super.initState();
    // 앱 시작 시 동기화 서비스를 1회 기동한다(밀린 pending_ops 플러시 — §5.3). keepAlive
    // 프로바이더라 이후에도 유지된다. 미구성 시에는 원격 대상이 없어 즉시 no-op이 된다.
    ref.read(syncServiceProvider);

    // 알림 인프라 기동: 로컬 알림 채널·타임존 초기화(§3.2 S4)와 FCM 토큰 확보(§12).
    // 권한 요청은 하지 않는다 — 프라이밍 화면(§11.6)에서 맥락과 함께 요청한다. 두 호출 모두
    // 미구성(파이어베이스 설정 파일 없음 등) 환경을 내부 가드로 흡수하므로 부팅을 막지 않는다.
    ref.read(notificationServiceProvider).ensureInitialized();
    ref.read(fcmClientProvider).ensureInitialized();
  }

  @override
  Widget build(BuildContext context) {
    // 복원 완료 전까지는 시스템 모드로 폴백(기본값).
    final themeMode = ref.watch(themeModeProvider).value ?? ThemeMode.system;

    return MaterialApp.router(
      title: '아가왜울어',
      debugShowCheckedModeBanner: false,
      // §3.3 i18n 구조 배선: 로컬라이제이션 델리게이트 + 지원 로케일(ko).
      // 기존 하드코딩 문자열은 그대로 두고, 우선 구조만 연결한다(전면 이관은 범위 밖).
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
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
