import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/baby.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/features/home/home_providers.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/home_greeting_bar.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/home_search_bar.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/ink_drop_refresh_indicator.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/recent_symptom_chips.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/symptom_card.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:agawaeuleo/presentation/widgets/headers/section_header.dart';
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:agawaeuleo/presentation/widgets/states/error_state.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// §11.7 홈(증상 그리드) — 앱의 얼굴.
///
/// 상단바(인사·벨) → 고정 검색 바(sticky) → (선택)최근 본 증상 칩 → 증상 카드 2열 그리드.
/// 인사는 스크롤아웃, 검색 바는 pinned. 아래로 당김 → 잉크 드롭 pull-to-refresh.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// 그리드 열 수·간격·카드 높이(§11.7).
  static const int _columns = 2;
  static const double _gridGap = AppSpacing.x12;
  static const double _cardExtent = 120;

  static const SliverGridDelegateWithFixedCrossAxisCount _gridDelegate =
      SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _columns,
        mainAxisSpacing: _gridGap,
        crossAxisSpacing: _gridGap,
        mainAxisExtent: _cardExtent,
      );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = context.colors;
    final symptomsAsync = ref.watch(homeSymptomsProvider);
    final baby = ref.watch(selectedBabyProvider);
    // 오늘의 응원(3일 주기 회전, 전원 동일). 목록은 1회 조회·세션 캐시(호출 최소화),
    // 오늘 1건은 캐시에서 날짜로 계산하므로 추가 서버 호출이 없다.
    final dailyMessage = currentEncouragementMessage(
      ref.watch(dailyEncouragementsProvider).value,
    );

    return Scaffold(
      backgroundColor: colors.paperBg,
      // DESIGN v2 §7.1-5 — 그레인 표면.
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: CustomScrollView(
            slivers: [
              CupertinoSliverRefreshControl(
                // 당겨서 새로고침 → 서버 매니페스트 강제 재검증(§5.3). 캐시가 갱신되면
                // Drift 스트림(homeSymptomsProvider)이 자동 재방출한다. 미구성(데모)
                // 모드에서는 즉시 완료되는 no-op.
                onRefresh: () =>
                    ref.read(masterDataCacheServiceProvider).refresh(),
                builder:
                    (
                      context,
                      refreshState,
                      pulledExtent,
                      triggerDistance,
                      indicatorExtent,
                    ) => InkDropRefreshIndicator(
                      mode: refreshState,
                      pulledExtent: pulledExtent,
                      triggerDistance: triggerDistance,
                    ),
              ),
              SliverToBoxAdapter(
                child: HomeGreetingBar(
                  greeting: _greetingFor(baby),
                  dailyMessage: dailyMessage,
                  onBellTap: () => _onBellTap(context),
                ),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SearchBarHeaderDelegate(
                  background: colors.paperBg,
                  onTap: () => context.pushNamed(Routes.search),
                ),
              ),
              ...symptomsAsync.when(
                loading: () => _buildLoadingSlivers(context),
                error: (error, _) => [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: ErrorState(
                      onRetry: () => ref.invalidate(homeSymptomsProvider),
                    ),
                  ),
                ],
                data: (symptoms) => _buildDataSlivers(context, ref, symptoms),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 인사 문구: 아기가 있으면 이름, 없으면 기본 인사(§11.7).
  String _greetingFor(Baby? baby) =>
      (baby != null && baby.name.trim().isNotEmpty) ? baby.name : '오늘도 힘내세요';

  void _onBellTap(BuildContext context) {
    // §11.7 "벨 아이콘 탭 → (알림 목록 or 설정)". 별도 알림 목록 화면은 범위 밖이라
    // 알림 토글이 모여 있는 설정 화면(§11.16 알림 그룹)으로 이동한다.
    context.go(RoutePaths.settingsLocation);
  }

  List<Widget> _buildLoadingSlivers(BuildContext context) => <Widget>[
    SliverPadding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.x12,
        AppSpacing.screenPadding,
        AppSpacing.x20,
      ),
      sliver: SliverGrid(
        gridDelegate: _gridDelegate,
        delegate: SliverChildBuilderDelegate(
          (context, index) => const SymptomCardSkeleton(),
          childCount: 6,
        ),
      ),
    ),
  ];

  List<Widget> _buildDataSlivers(
    BuildContext context,
    WidgetRef ref,
    List<Symptom> symptoms,
  ) {
    final reduce = context.reduceMotion;
    // §10.2 stagger는 "첫 로드" 1회만. 스크롤 재마운트/상세 복귀 때마다
    // 재생하면 라우트 전환과 겹친 fadeIn이 중간 불투명도로 얼어붙어 카드가
    // 눌린 것처럼 어둡게 고착될 수 있다(실기기 재현). 재생 완료 후에는
    // 정적으로 렌더한다.
    final introPlayed = ref.watch(homeIntroPlayedProvider);
    if (!reduce && !introPlayed) {
      // 마지막 카드(delay 40ms×n) 재생이 끝난 뒤 플래그 승격. 빌드 중 state
      // 변경 금지라 지연 스케줄로 처리한다. 노티파이어를 지금 캡처해 두면
      // 홈 위젯이 먼저 dispose 되어도(ref 사용 불가) 안전하다(markPlayed 멱등).
      final intro = ref.read(homeIntroPlayedProvider.notifier);
      Future<void>.delayed(
        AppMotion.base + Duration(milliseconds: 40 * symptoms.length + 200),
        intro.markPlayed,
      );
    }
    final recent = _recentSymptoms(ref, symptoms);

    void onTap(Symptom symptom) {
      ref.read(recentSymptomsProvider.notifier).record(symptom.slug);
      context.pushNamed(
        Routes.symptomDetail,
        pathParameters: {RouteParams.slug: symptom.slug},
      );
    }

    // §11.7 개정 — mom(산모) 카드가 하나라도 있으면 '아기 돌봄'/'엄마 돌봄'
    // 2그룹(SectionHeader + 각각 2열 그리드, order_index 순)으로 나눈다.
    // mom 카드가 없으면 기존과 픽셀 동일(헤더 없는 단일 그리드).
    final momSymptoms = <Symptom>[
      for (final s in symptoms)
        if (s.audience == SymptomAudience.mom) s,
    ];
    final babySymptoms = <Symptom>[
      for (final s in symptoms)
        if (s.audience != SymptomAudience.mom) s,
    ];

    final recentSliver = recent.isNotEmpty
        ? SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(
                top: AppSpacing.x12,
                bottom: AppSpacing.x4,
              ),
              child: RecentSymptomChips(symptoms: recent, onTap: onTap),
            ),
          )
        : null;

    if (momSymptoms.isEmpty) {
      return [
        ?recentSliver,
        _cardGridSliver(
          symptoms: symptoms,
          indexOffset: 0,
          reduce: reduce,
          introPlayed: introPlayed,
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x12,
            AppSpacing.screenPadding,
            AppSpacing.x20,
          ),
        ),
      ];
    }

    return [
      ?recentSliver,
      // baby 카드가 없는 구성(운영에서 mom만 활성)에서는 카드 0개짜리 고아
      // 헤더를 남기지 않는다 — 위 momSymptoms.isEmpty 조기 반환과 대칭.
      if (babySymptoms.isNotEmpty) ...[
        _groupHeaderSliver('아기 돌봄'),
        _cardGridSliver(
          symptoms: babySymptoms,
          indexOffset: 0,
          reduce: reduce,
          introPlayed: introPlayed,
          onTap: onTap,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x12,
            AppSpacing.screenPadding,
            AppSpacing.x12,
          ),
        ),
      ],
      _groupHeaderSliver('엄마 돌봄'),
      _cardGridSliver(
        symptoms: momSymptoms,
        // §10.2 첫 로드 stagger 1회 계약 — 두 그룹에 걸쳐 **연속 인덱스**
        // (40ms×전체 인덱스)를 유지해 markPlayed 타이밍(40ms×전체 개수)과
        // 어긋나지 않게 한다.
        indexOffset: babySymptoms.length,
        reduce: reduce,
        introPlayed: introPlayed,
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.x12,
          AppSpacing.screenPadding,
          AppSpacing.x20,
        ),
      ),
    ];
  }

  /// 그룹 제목 슬리버 — 기존 [SectionHeader] 문법(잉크 틱 + heading) 재사용.
  Widget _groupHeaderSliver(String title) => SliverPadding(
    padding: const EdgeInsets.fromLTRB(
      AppSpacing.screenPadding,
      AppSpacing.x12,
      AppSpacing.screenPadding,
      0,
    ),
    sliver: SliverToBoxAdapter(child: SectionHeader(title: title)),
  );

  /// 증상 카드 2열 그리드 슬리버 1개.
  ///
  /// [indexOffset] — §10.2 첫 로드 stagger의 카드 지연(40ms×전체 인덱스)이
  /// 그룹 분할 후에도 홈 전체에서 연속되도록 하는 시작 인덱스.
  Widget _cardGridSliver({
    required List<Symptom> symptoms,
    required int indexOffset,
    required bool reduce,
    required bool introPlayed,
    required void Function(Symptom) onTap,
    required EdgeInsets padding,
  }) {
    return SliverPadding(
      padding: padding,
      sliver: SliverGrid(
        gridDelegate: _gridDelegate,
        delegate: SliverChildBuilderDelegate((context, index) {
          final symptom = symptoms[index];
          final card = SymptomCard(
            symptom: symptom,
            onTap: () => onTap(symptom),
          );
          if (reduce || introPlayed) {
            return KeyedSubtree(key: ValueKey(symptom.id), child: card);
          }
          // §10.2 첫 로드 stagger: fadeIn 260ms + slideY .08, 40ms 간격.
          // 키로 Animate 상태를 고정해 새로고침 시 재생되지 않게 한다.
          final staggerIndex = indexOffset + index;
          return card
              .animate(key: ValueKey('anim-${symptom.id}'))
              .fadeIn(
                duration: AppMotion.base,
                curve: AppMotion.enter,
                delay: Duration(milliseconds: 40 * staggerIndex),
              )
              .slideY(
                begin: 0.08,
                curve: AppMotion.enter,
                duration: AppMotion.base,
                delay: Duration(milliseconds: 40 * staggerIndex),
              );
        }, childCount: symptoms.length),
      ),
    );
  }

  /// 최근 본 증상 slug → 현재 로드된 [symptoms] 매핑(최신순, 누락 slug 제외).
  List<Symptom> _recentSymptoms(WidgetRef ref, List<Symptom> symptoms) {
    final slugs = ref.watch(recentSymptomsProvider);
    if (slugs.isEmpty) return const [];
    final bySlug = {for (final s in symptoms) s.slug: s};
    return [for (final slug in slugs) ?bySlug[slug]];
  }
}

/// 고정(sticky) 검색 바용 퍼시스턴트 헤더. 상단 인사 스크롤아웃 후에도 검색 바를 남긴다.
/// 배경(`paper.bg`)을 채워 아래 콘텐츠가 헤더를 통과해 비치지 않게 한다.
///
/// DESIGN v2 §7.1-2 — `overlapsContent`(콘텐츠가 헤더 아래로 스크롤되어 겹치기
/// 시작함, 즉 인사 바가 스크롤아웃된 상태)로 스크롤 여부를 감지해 `AppAppBar`와
/// 같은 2단 표면 문법(e2 + 하단 헤어라인)을 표출한다.
class _SearchBarHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _SearchBarHeaderDelegate({
    required this.background,
    required this.onTap,
  });

  final Color background;
  final VoidCallback onTap;

  static const double _top = AppSpacing.x8;
  static const double _bottom = AppSpacing.x12;
  double get _extent => HomeSearchBar.height + _top + _bottom;

  @override
  double get minExtent => _extent;

  @override
  double get maxExtent => _extent;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    final colors = context.colors;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        border: overlapsContent
            ? Border(bottom: BorderSide(color: colors.line))
            : null,
        boxShadow: overlapsContent ? context.shadows.e2 : null,
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          _top,
          AppSpacing.screenPadding,
          _bottom,
        ),
        child: HomeSearchBar(onTap: onTap),
      ),
    );
  }

  @override
  bool shouldRebuild(_SearchBarHeaderDelegate oldDelegate) =>
      oldDelegate.background != background || oldDelegate.onTap != onTap;
}
