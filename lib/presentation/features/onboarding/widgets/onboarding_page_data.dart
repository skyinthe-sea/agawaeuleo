import '../../../../config/app_config.dart';

/// 온보딩 장면 종류 — 스테이지가 장면별 일러스트·떠 있는 UI 조각을 고른다.
enum OnboardingScene { search, products, tracking }

/// §11.2 온보딩 한 장의 콘텐츠.
///
/// 제목은 [titleLines]로 줄을 직접 나눈다(에디토리얼 조판 — 자동 줄바꿈에 맡기면
/// 한 글자가 다음 줄로 떨어진다). 좁은 화면에서는 줄마다 축소될 뿐 다시 줄바꿈되지
/// 않는다.
class OnboardingPageData {
  const OnboardingPageData({
    required this.scene,
    required this.overline,
    required this.titleLines,
    required this.body,
  });

  final OnboardingScene scene;

  /// 제목 위 짧은 섹션 라벨.
  final String overline;
  final List<String> titleLines;
  final String body;

  /// 스크린리더용 한 줄 제목.
  String get title => titleLines.join(' ');
}

/// §11.2 온보딩 3장 — ① 증상으로 빠르게 찾기 ② 필요한 육아용품 바로 보기
/// ③ 수유·수면 기록까지. 장면 서사는 우는 아기 → 케어 → 편안한 잠.
const List<OnboardingPageData> onboardingPages = <OnboardingPageData>[
  OnboardingPageData(
    scene: OnboardingScene.search,
    overline: '증상 검색',
    titleLines: <String>['아기가 왜 우는지', '바로 찾아봐요'],
    body: '배앓이, 열, 이앓이처럼 궁금한 증상을 검색하면 참고 정보와 대처법을 한눈에 정리해 드려요.',
  ),
  OnboardingPageData(
    scene: OnboardingScene.products,
    overline: '맞춤 육아용품',
    titleLines: <String>['지금 필요한 용품만', '골라서 보여드려요'],
    body: '증상마다 도움이 되는 육아용품을 순위로 정리했어요. 이것저것 비교하는 시간을 줄여 보세요.',
  ),
  OnboardingPageData(
    scene: OnboardingScene.tracking,
    overline: '육아 기록',
    titleLines: <String>['수유·수면·기저귀', '탭 한 번에 기록해요'],
    // "기기에만 저장" 약속은 개인기록 동기화가 꺼져 있을 때만 사실이다
    // (AppConfig.personalDataSyncEnabled 주석 참조) — 스위치와 문구를 묶어 둔다.
    body: AppConfig.personalDataSyncEnabled
        ? '하루 흐름과 패턴을 한눈에 확인해요. 필요한 순간에 바로 꺼내 보세요.'
        // "이 기기에만" 사이는 줄이 갈리지 않게 NBSP(U+00A0).
        : '하루 흐름과 패턴을 한눈에 확인해요. 기록은 이\u00A0기기에만 안전하게 저장돼요.',
  ),
];
