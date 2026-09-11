import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/gate/connectivity_provider.dart';
import '../../config/theme/theme.dart';
import '../features/auth/login_screen.dart';
import '../features/auth/permission_priming_screen.dart';
import '../features/auth/reset_password_screen.dart';
import '../features/auth/signup_screen.dart';
import '../features/favorites/favorites_screen.dart';
import '../features/home/home_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import '../features/onboarding/splash_screen.dart';
import '../features/profile/baby_profile_screen.dart';
import '../features/profile/profile_screen.dart';
import '../features/search/search_screen.dart';
import '../features/settings/account_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/settings/terms_viewer_screen.dart';
import '../features/symptom_detail/symptom_detail_screen.dart';
// 기록 기능 숨김 — 아래 기록 브랜치 주석과 함께 되살릴 것.
// import '../features/tracking/tracking_entry_screen.dart';
// import '../features/tracking/tracking_screen.dart';
// import '../features/tracking/tracking_summary_screen.dart';
import '../widgets/navigation/app_bottom_nav.dart';
import '../widgets/states/offline_banner.dart';
import 'routes.dart';

final GlobalKey<NavigatorState> rootNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'root',
);
final GlobalKey<NavigatorState> _homeNavigatorKey = GlobalKey<NavigatorState>(
  debugLabel: 'home',
);
// 기록 기능 숨김 — 기록 브랜치와 함께 되살릴 것.
// final GlobalKey<NavigatorState> _trackingNavigatorKey =
//     GlobalKey<NavigatorState>(debugLabel: 'tracking');
final GlobalKey<NavigatorState> _profileNavigatorKey =
    GlobalKey<NavigatorState>(debugLabel: 'profile');

/// §4.1 라우트 트리 + §10.2 전환(탭 fade-through 200ms / push shared-axis X 300ms).
GoRouter createAppRouter() {
  return GoRouter(
    navigatorKey: rootNavigatorKey,
    initialLocation: RoutePaths.splash,
    routes: [
      GoRoute(
        path: RoutePaths.splash,
        name: Routes.splash,
        // §11.1 스플래시 → 다음 화면 fade-through(페이드+미세 스케일). 스플래시가
        // 페이드아웃하며 아래 화면(홈/온보딩)을 드러낸다.
        pageBuilder: (context, state) =>
            _fadeThroughPage(context, state, const SplashScreen()),
      ),
      GoRoute(
        path: RoutePaths.onboarding,
        name: Routes.onboarding,
        pageBuilder: (context, state) =>
            _pushPage(context, state, const OnboardingScreen()),
      ),
      GoRoute(
        path: RoutePaths.login,
        name: Routes.login,
        pageBuilder: (context, state) =>
            _pushPage(context, state, const LoginScreen()),
      ),
      GoRoute(
        path: RoutePaths.signup,
        name: Routes.signup,
        pageBuilder: (context, state) =>
            _pushPage(context, state, const SignupScreen()),
      ),
      GoRoute(
        path: RoutePaths.resetPassword,
        name: Routes.resetPassword,
        pageBuilder: (context, state) =>
            _pushPage(context, state, const ResetPasswordScreen()),
      ),
      GoRoute(
        path: RoutePaths.permissionPriming,
        name: Routes.permissionPriming,
        pageBuilder: (context, state) =>
            _pushPage(context, state, const PermissionPrimingScreen()),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            _ShellScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            navigatorKey: _homeNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.home,
                name: Routes.home,
                builder: (context, state) => const HomeScreen(),
                routes: [
                  GoRoute(
                    path: RoutePaths.searchSegment,
                    name: Routes.search,
                    pageBuilder: (context, state) =>
                        _pushPage(context, state, const SearchScreen()),
                  ),
                  GoRoute(
                    path: RoutePaths.symptomSegment,
                    name: Routes.symptomDetail,
                    pageBuilder: (context, state) => _pushPage(
                      context,
                      state,
                      SymptomDetailScreen(
                        slug: state.pathParameters[RouteParams.slug]!,
                        // 홈 덱의 BEST PICK 카드처럼 특정 장으로 바로 여는 진입점.
                        initialChapter:
                            state.uri.queryParameters[RouteParams.chapter],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          // 기록 기능 숨김(2026-09-11 발주자 요청 — 제품 추천 집중). 탭 인덱스가
          // 브랜치 순서와 1:1이라 하단 탭 항목(app_bottom_nav.dart)과 함께 주석 처리했다.
          // 화면·데이터 코드는 그대로 두었으니 두 곳의 주석만 해제하면 복원된다.
          // StatefulShellBranch(
          //   navigatorKey: _trackingNavigatorKey,
          //   routes: [
          //     GoRoute(
          //       path: RoutePaths.tracking,
          //       name: Routes.tracking,
          //       builder: (context, state) => const TrackingScreen(),
          //       routes: [
          //         GoRoute(
          //           // §11.11 기록 입력은 라우트가 아니라 showModalBottomSheet로
          //           // 연다(홈 FAB/빠른 알약/타임라인에서 직접 호출). 딥링크가
          //           // 죽은 플레이스홀더에 착지하지 않도록 기록 홈으로 리다이렉트.
          //           path: RoutePaths.trackingEntrySegment,
          //           name: Routes.trackingEntry,
          //           redirect: (context, state) => RoutePaths.tracking,
          //           pageBuilder: (context, state) =>
          //               _pushPage(context, state, const TrackingEntryScreen()),
          //         ),
          //         GoRoute(
          //           path: RoutePaths.trackingSummarySegment,
          //           name: Routes.trackingSummary,
          //           pageBuilder: (context, state) => _pushPage(
          //             context,
          //             state,
          //             const TrackingSummaryScreen(),
          //           ),
          //         ),
          //       ],
          //     ),
          //   ],
          // ),
          StatefulShellBranch(
            navigatorKey: _profileNavigatorKey,
            routes: [
              GoRoute(
                path: RoutePaths.profile,
                name: Routes.profile,
                builder: (context, state) => const ProfileScreen(),
                routes: [
                  GoRoute(
                    path: RoutePaths.babyProfileSegment,
                    name: Routes.babyProfile,
                    pageBuilder: (context, state) =>
                        _pushPage(context, state, const BabyProfileScreen()),
                  ),
                  GoRoute(
                    path: RoutePaths.favoritesSegment,
                    name: Routes.favorites,
                    pageBuilder: (context, state) =>
                        _pushPage(context, state, const FavoritesScreen()),
                  ),
                  GoRoute(
                    path: RoutePaths.settingsSegment,
                    name: Routes.settings,
                    pageBuilder: (context, state) =>
                        _pushPage(context, state, const SettingsScreen()),
                    routes: [
                      GoRoute(
                        path: RoutePaths.accountSegment,
                        name: Routes.account,
                        pageBuilder: (context, state) =>
                            _pushPage(context, state, const AccountScreen()),
                      ),
                      GoRoute(
                        path: RoutePaths.termsSegment,
                        name: Routes.terms,
                        pageBuilder: (context, state) => _pushPage(
                          context,
                          state,
                          TermsViewerScreen(
                            doc: state.pathParameters[RouteParams.doc]!,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

const Duration _pushDuration = Duration(milliseconds: 300);
const double _sharedAxisShift = 30;

/// §11.1 스플래시 라우트 전환 = fade-through(페이드 + 0.96→1 미세 스케일) 300ms.
/// 진입(forward)은 페이드인, 이탈(reverse)은 페이드아웃 — 다음 화면과 크로스페이드.
/// reduce-motion 시 0ms.
CustomTransitionPage<void> _fadeThroughPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final duration = AppMotion.resolve(context, _pushDuration);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: _fadeThrough,
    child: child,
  );
}

Widget _fadeThrough(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  final curved = CurvedAnimation(parent: animation, curve: AppMotion.enter);
  return FadeTransition(
    opacity: curved,
    child: ScaleTransition(
      scale: Tween<double>(begin: 0.96, end: 1).animate(curved),
      child: child,
    ),
  );
}

/// §10.2 push = shared-axis X(슬라이드+페이드) 300ms. reduce-motion 시 0ms.
CustomTransitionPage<void> _pushPage(
  BuildContext context,
  GoRouterState state,
  Widget child,
) {
  final duration = AppMotion.resolve(context, _pushDuration);
  return CustomTransitionPage<void>(
    key: state.pageKey,
    transitionDuration: duration,
    reverseTransitionDuration: duration,
    transitionsBuilder: _sharedAxisX,
    child: child,
  );
}

Widget _sharedAxisX(
  BuildContext context,
  Animation<double> animation,
  Animation<double> secondaryAnimation,
  Widget child,
) {
  const fadeIn = Interval(0.30, 1, curve: Curves.easeOut);
  const fadeOut = Interval(0, 0.30, curve: Curves.easeIn);
  return AnimatedBuilder(
    animation: Listenable.merge([animation, secondaryAnimation]),
    builder: (context, child) {
      final a = animation.value;
      final s = secondaryAnimation.value;
      final covered = s > 0;
      final dx = covered
          ? -AppMotion.enter.transform(s) * _sharedAxisShift
          : (1 - AppMotion.enter.transform(a)) * _sharedAxisShift;
      final opacity = covered ? 1 - fadeOut.transform(s) : fadeIn.transform(a);
      return Opacity(
        opacity: opacity.clamp(0.0, 1.0),
        child: Transform.translate(offset: Offset(dx, 0), child: child),
      );
    },
    child: child,
  );
}

class _ShellScaffold extends ConsumerWidget {
  const _ShellScaffold({required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // §11.17 전역 오프라인 배너: 값이 없을 때(로딩)는 온라인으로 간주해 배너를 숨긴다.
    final online = ref.watch(connectivityStatusProvider).asData?.value ?? true;

    return Scaffold(
      // 상단 세이프에어리어를 셸에서 한 번 소비하고, 배너 아래 본문은 top 인셋을
      // 제거해(각 화면의 SafeArea 중복 방지) 배너가 시스템 바 바로 아래에 붙게 한다.
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            OfflineBanner(visible: !online),
            Expanded(
              child: MediaQuery.removePadding(
                context: context,
                removeTop: true,
                child: _FadeThroughSwitcher(
                  index: navigationShell.currentIndex,
                  child: navigationShell,
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

/// §10.2 탭 전환 fade-through 200ms. IndexedStack 셸의 상태를 보존하기 위해
/// 단일 라이브 자식(navigationShell)을 유지하고, 인덱스 변경 시에만 페이드+스케일을 재생한다.
class _FadeThroughSwitcher extends StatefulWidget {
  const _FadeThroughSwitcher({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_FadeThroughSwitcher> createState() => _FadeThroughSwitcherState();
}

class _FadeThroughSwitcherState extends State<_FadeThroughSwitcher>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 200),
    value: 1,
  );

  late final Animation<double> _fade = CurvedAnimation(
    parent: _controller,
    curve: AppMotion.enter,
  );

  late final Animation<double> _scale = Tween<double>(
    begin: 0.92,
    end: 1,
  ).animate(_fade);

  @override
  void didUpdateWidget(_FadeThroughSwitcher oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.index != widget.index) {
      if (AppMotion.reduceMotion(context)) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: ScaleTransition(scale: _scale, child: widget.child),
    );
  }
}
