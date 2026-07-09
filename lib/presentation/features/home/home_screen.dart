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
import 'package:agawaeuleo/presentation/widgets/skeletons/skeleton_blocks.dart';
import 'package:agawaeuleo/presentation/widgets/states/error_state.dart';
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

    return Scaffold(
      backgroundColor: colors.paperBg,
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            CupertinoSliverRefreshControl(
              onRefresh: () => ref.refresh(homeSymptomsProvider.future),
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
    final recent = _recentSymptoms(ref, symptoms);

    void onTap(Symptom symptom) {
      ref.read(recentSymptomsProvider.notifier).record(symptom.slug);
      context.pushNamed(
        Routes.symptomDetail,
        pathParameters: {RouteParams.slug: symptom.slug},
      );
    }

    return [
      if (recent.isNotEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.x12,
              bottom: AppSpacing.x4,
            ),
            child: RecentSymptomChips(symptoms: recent, onTap: onTap),
          ),
        ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenPadding,
          AppSpacing.x12,
          AppSpacing.screenPadding,
          AppSpacing.x20,
        ),
        sliver: SliverGrid(
          gridDelegate: _gridDelegate,
          delegate: SliverChildBuilderDelegate((context, index) {
            final symptom = symptoms[index];
            final card = SymptomCard(
              symptom: symptom,
              onTap: () => onTap(symptom),
            );
            if (reduce) {
              return KeyedSubtree(key: ValueKey(symptom.id), child: card);
            }
            // §10.2 첫 로드 stagger: fadeIn 260ms + slideY .08, 40ms 간격.
            // 키로 Animate 상태를 고정해 새로고침 시 재생되지 않게 한다.
            return card
                .animate(key: ValueKey('anim-${symptom.id}'))
                .fadeIn(
                  duration: AppMotion.base,
                  curve: AppMotion.enter,
                  delay: Duration(milliseconds: 40 * index),
                )
                .slideY(
                  begin: 0.08,
                  curve: AppMotion.enter,
                  duration: AppMotion.base,
                  delay: Duration(milliseconds: 40 * index),
                );
          }, childCount: symptoms.length),
        ),
      ),
    ];
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
    return Container(
      color: background,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        _top,
        AppSpacing.screenPadding,
        _bottom,
      ),
      child: HomeSearchBar(onTap: onTap),
    );
  }

  @override
  bool shouldRebuild(_SearchBarHeaderDelegate oldDelegate) =>
      oldDelegate.background != background || oldDelegate.onTap != onTap;
}
