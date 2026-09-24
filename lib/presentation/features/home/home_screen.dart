import 'dart:math' as math;

import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/baby.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/features/home/home_providers.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/care_deck.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/deck_rail.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/deck/deck_scene.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/home_greeting_bar.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/home_search_bar.dart';
import 'package:agawaeuleo/presentation/features/home/widgets/ink_drop_refresh_indicator.dart';
import 'package:agawaeuleo/presentation/router/routes.dart';
import 'package:agawaeuleo/presentation/widgets/animated/shimmer_skeleton.dart';
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:agawaeuleo/presentation/widgets/states/error_state.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/paper_background.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// §11.7 홈 — 앱의 얼굴(2026-09-11 전면 개편: 증상 그리드 → 케어 덱).
///
/// 인사(날짜·명조 인사·오늘의 응원·메뉴) → 타이핑 힌트 검색 바 → [CareDeck].
/// 덱이 화면의 남은 높이를 모두 쓰는 한 화면 구성이고, 작은 화면에서는 덱의 최소
/// 높이를 지키며 세로로 스크롤된다. 아래로 당기면 잉크 드롭 새로고침(§5.3).
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  /// 덱이 무너지지 않는 최소 높이(그룹 탭 44 + 무대 최소 ~218 + 글 186 + 레일 92).
  static const double _deckMinHeight = 540;

  /// 인사 + 검색 바가 차지하는 대략 높이(최소 높이 계산용 — 실제 배치는 Column).
  static const double _headerEstimate = 176;

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
    final symptoms = symptomsAsync.value ?? const <Symptom>[];

    final Widget deck = symptomsAsync.when(
      loading: () => const _DeckSkeleton(),
      error: (error, _) =>
          ErrorState(onRetry: () => ref.invalidate(homeSymptomsProvider)),
      data: (list) => list.isEmpty
          ? const EmptyState(
              title: '아직 준비된 증상이 없어요',
              message: '잠시 후 다시 확인해 주세요.',
              icon: Icons.menu_book_outlined,
            )
          : CareDeck(
              symptoms: list,
              playIntro: !ref.watch(homeIntroPlayedProvider),
              onIntroPlayed: ref
                  .read(homeIntroPlayedProvider.notifier)
                  .markPlayed,
              onOpen: (symptom, {chapter}) =>
                  _open(context, ref, symptom, chapter: chapter),
            ),
    );

    return Scaffold(
      backgroundColor: colors.paperBg,
      // DESIGN v2 §7.1-5 — 그레인 표면.
      body: PaperBackground(
        child: SafeArea(
          bottom: false,
          child: MediaQuery.withClampedTextScaling(
            // 한 화면 구성이라 큰 글자에서 덱이 눌리지 않게 상한을 둔다.
            maxScaleFactor: 1.3,
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = math.max(
                  constraints.maxHeight,
                  _headerEstimate + _deckMinHeight,
                );
                return CustomScrollView(
                  // 한 화면에 들어와도 당겨서 새로고침이 되도록 항상 스크롤 가능.
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    CupertinoSliverRefreshControl(
                      // 당겨서 새로고침 → 서버 매니페스트 강제 재검증(§5.3). 캐시가
                      // 갱신되면 Drift 스트림(homeSymptomsProvider)이 자동 재방출한다.
                      // 미구성(데모) 모드에서는 즉시 완료되는 no-op.
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
                      child: SizedBox(
                        height: height,
                        child: Column(
                          children: [
                            HomeGreetingBar(
                              greeting: _greetingFor(baby),
                              dailyMessage: dailyMessage,
                              onMenuTap: () => _onMenuTap(context),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screenPadding,
                                AppSpacing.x8,
                                AppSpacing.screenPadding,
                                AppSpacing.x8,
                              ),
                              child: HomeSearchBar(
                                hints: [
                                  for (final s in symptoms.take(4)) s.name,
                                ],
                                onTap: () => context.pushNamed(Routes.search),
                              ),
                            ),
                            Expanded(child: deck),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  void _open(
    BuildContext context,
    WidgetRef ref,
    Symptom symptom, {
    String? chapter,
  }) {
    ref.read(recentSymptomsProvider.notifier).record(symptom.slug);
    context.pushNamed(
      Routes.symptomDetail,
      pathParameters: {RouteParams.slug: symptom.slug},
      queryParameters: {RouteParams.chapter: ?chapter},
    );
  }

  /// 인사 문구: 아기가 있으면 이름, 없으면 기본 인사(§11.7).
  String _greetingFor(Baby? baby) =>
      (baby != null && baby.name.trim().isNotEmpty) ? baby.name : '오늘도 힘내세요';

  void _onMenuTap(BuildContext context) {
    // §11.7 우상단 메뉴(햄버거) 탭 → 설정 화면(§11.16)으로 이동.
    context.go(RoutePaths.settingsLocation);
  }
}

/// 덱 로딩 자리 — 실제 덱과 같은 뼈대(그룹 탭 · 무대 원 · 글 · 레일)로 맞춰
/// 데이터 도착 시 튐이 없게 한다(DESIGN v2 §5.5).
class _DeckSkeleton extends StatelessWidget {
  const _DeckSkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(
          height: 44,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppSpacing.x24),
            child: Row(
              children: [
                SkeletonLine(width: 72, height: 14),
                SizedBox(width: AppSpacing.x16),
                SkeletonLine(width: 72, height: 14),
                Spacer(),
                SkeletonLine(width: 44, height: 14),
              ],
            ),
          ),
        ),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final stage = math.max(
                0.0,
                constraints.maxHeight - DeckScene.copyHeight,
              );
              final circle = math.min(stage * 0.78, constraints.maxWidth * 0.7);
              return Column(
                children: [
                  SizedBox(
                    height: stage,
                    child: Center(
                      child: ShimmerSkeleton(
                        width: circle,
                        height: circle,
                        borderRadius: AppRadius.brFull,
                      ),
                    ),
                  ),
                  const SizedBox(
                    height: DeckScene.copyHeight,
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.x24,
                        AppSpacing.x12,
                        AppSpacing.x24,
                        0,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SkeletonLine(width: 96, height: 12),
                          SizedBox(height: AppSpacing.x12),
                          SkeletonLine(width: 160, height: 30),
                          SizedBox(height: AppSpacing.x8),
                          SkeletonLine(width: 120, height: 14),
                          SizedBox(height: AppSpacing.x20),
                          ShimmerSkeleton(
                            height: 52,
                            borderRadius: AppRadius.brFull,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        SizedBox(
          height: DeckRail.height,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              for (var i = 0; i < 4; i++)
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.x8),
                  child: SkeletonBox(size: 48, circle: true),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
