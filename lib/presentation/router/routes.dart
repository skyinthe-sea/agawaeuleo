/// §4.1 내비게이션 트리에 대응하는 라우트 이름·경로 상수.
/// 화면 코드는 이 상수만 참조한다(문자열 하드코딩 금지).
abstract final class Routes {
  Routes._();

  static const splash = 'splash';
  static const onboarding = 'onboarding';
  static const login = 'login';
  static const signup = 'signup';
  static const resetPassword = 'reset-password';
  static const permissionPriming = 'permission-priming';

  static const home = 'home';
  static const search = 'search';
  static const symptomDetail = 'symptom';

  static const tracking = 'tracking';
  static const trackingEntry = 'tracking-entry';
  static const trackingSummary = 'tracking-summary';

  static const profile = 'profile';
  static const babyProfile = 'baby-profile';
  static const favorites = 'favorites';
  static const settings = 'settings';
  static const account = 'account';
  static const terms = 'terms';
}

/// 경로 파라미터 키.
abstract final class RouteParams {
  RouteParams._();

  static const slug = 'slug';
  static const doc = 'doc';
}

/// 절대 경로(top-level·브랜치 루트·딥링크)와 중첩 라우트용 상대 세그먼트.
abstract final class RoutePaths {
  RoutePaths._();

  // top-level (root navigator)
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const resetPassword = '/reset-password';
  static const permissionPriming = '/permission-priming';

  // branch roots (하단 탭)
  static const home = '/';
  static const tracking = '/tracking';
  static const profile = '/profile';

  // nested 상대 세그먼트 (GoRoute.path)
  static const searchSegment = 'search';
  static const symptomSegment = 'symptom/:${RouteParams.slug}';
  static const trackingEntrySegment = 'entry';
  static const trackingSummarySegment = 'summary';
  static const babyProfileSegment = 'baby';
  static const favoritesSegment = 'favorites';
  static const settingsSegment = 'settings';
  static const accountSegment = 'account';
  static const termsSegment = 'terms/:${RouteParams.doc}';

  // 절대 위치(context.go/딥링크). 홈 브랜치 루트가 '/' 이므로 서브루트는 루트 직속.
  static const searchLocation = '/search';
  static String symptom(String slug) => '/symptom/$slug';
  static const trackingEntryLocation = '/tracking/entry';
  static const trackingSummaryLocation = '/tracking/summary';
  static const babyProfileLocation = '/profile/baby';
  static const favoritesLocation = '/profile/favorites';
  static const settingsLocation = '/profile/settings';
  static const accountLocation = '/profile/settings/account';
  static String terms(String doc) => '/profile/settings/terms/$doc';
}
