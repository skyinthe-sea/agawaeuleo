import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/presentation/widgets/animated/ink_wash_splash.dart';
import 'package:agawaeuleo/presentation/widgets/headers/section_header.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../search_providers.dart';

/// §11.8 최근 검색어 — 입력이 비었을 때 노출. 좌스와이프로 개별 삭제, 탭 시 재검색.
///
/// DESIGN v3 "몽글 클레이" §6 — 헤어라인 행 대신 **알약 칩 행**(paperRaised 알약 + e1,
/// 앞에 딸기 워시 동그라미 시계)을 간격을 두고 쌓는다. 스와이프 삭제 배경도 같은
/// 알약 모양의 토마토 워시.
class RecentSearchesView extends ConsumerWidget {
  const RecentSearchesView({required this.onSelect, super.key});

  /// 항목 탭 → 해당 검색어로 재검색.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentSearchesProvider);
    return async.maybeWhen(
      // DESIGN v2 §7.2-4 — 공용 `EmptyState`. v3 §5.5 — 클레이 장면을 일러스트 슬롯에.
      data: (items) => items.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              illustration: ClayIllustration(
                asset: ClayScenes.emptySearch,
                size: 140,
              ),
              title: '아직 검색 기록이 없어요',
              message: '증상 이름이나 초성으로 검색해 보세요',
            )
          : _list(context, ref, items),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<String> items) {
    return ListView.builder(
      padding: const EdgeInsets.only(bottom: AppSpacing.x24),
      itemCount: items.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return _Header(
            onClearAll: () {
              AppHaptics.toggle();
              ref.read(recentSearchRepositoryProvider).clear();
            },
          );
        }
        final query = items[index - 1];
        return _RecentRow(
          key: ValueKey(query),
          query: query,
          onTap: () => onSelect(query),
          onDelete: () {
            AppHaptics.toggle();
            ref.read(recentSearchRepositoryProvider).delete(query);
          },
        );
      },
    );
  }
}

/// DESIGN v2 §7.2-3 — `SectionHeader`(trailing="전체 삭제"). v3 — 삭제는 작은 딸기 알약.
class _Header extends StatelessWidget {
  const _Header({required this.onClearAll});

  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.x16,
        AppSpacing.screenPadding,
        AppSpacing.x8,
      ),
      child: SectionHeader(
        title: '최근 검색어',
        trailing: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onClearAll,
          child: Padding(
            // 보이는 알약보다 넓은 히트 영역.
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.x8),
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.x12,
                vertical: AppSpacing.x4,
              ),
              decoration: BoxDecoration(
                color: colors.accentWash,
                borderRadius: AppRadius.brFull,
              ),
              child: Text(
                '전체 삭제',
                style: context.texts.caption.copyWith(
                  color: colors.accent,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 좌스와이프(→ endToStart) 개별 삭제 + 탭 재검색 — 알약 칩 행.
class _RecentRow extends StatelessWidget {
  const _RecentRow({
    required this.query,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final String query;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x16,
        vertical: AppSpacing.x4,
      ),
      child: Dismissible(
        key: ValueKey(query),
        direction: DismissDirection.endToStart,
        onDismissed: (_) => onDelete(),
        background: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.coralWash,
            borderRadius: AppRadius.brFull,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
            child: Align(
              alignment: Alignment.centerRight,
              child: Icon(
                Icons.delete_outline_rounded,
                size: 20,
                color: colors.coral,
              ),
            ),
          ),
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.paperRaised,
            borderRadius: AppRadius.brFull,
            boxShadow: context.shadows.e1,
          ),
          child: Material(
            type: MaterialType.transparency,
            borderRadius: AppRadius.brFull,
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              splashFactory: InkWashSplash.splashFactory,
              splashColor: colors.accentWash,
              highlightColor: Colors.transparent,
              borderRadius: AppRadius.brFull,
              onTap: () {
                AppHaptics.tap();
                onTap();
              },
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.x8,
                  AppSpacing.x8,
                  AppSpacing.x16,
                  AppSpacing.x8,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        gradient: ClaySheen.gradient(
                          context,
                          colors.accentWash,
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.history_rounded,
                        size: 18,
                        color: colors.accent,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x12),
                    Expanded(
                      child: Text(
                        query,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.texts.bodyL.copyWith(
                          color: colors.ink900,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.x8),
                    Icon(
                      Icons.north_west_rounded,
                      size: 18,
                      color: colors.ink300,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
