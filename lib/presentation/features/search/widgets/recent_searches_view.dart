import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/presentation/widgets/animated/ink_wash_splash.dart';
import 'package:agawaeuleo/presentation/widgets/headers/section_header.dart';
import 'package:agawaeuleo/presentation/widgets/states/empty_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../search_providers.dart';
import 'search_result_tile.dart';

/// §11.8 최근 검색어 — 입력이 비었을 때 노출. 좌스와이프로 개별 삭제, 탭 시 재검색.
class RecentSearchesView extends ConsumerWidget {
  const RecentSearchesView({required this.onSelect, super.key});

  /// 항목 탭 → 해당 검색어로 재검색.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentSearchesProvider);
    return async.maybeWhen(
      // DESIGN v2 §7.2-4 — 수제 `_EmptyHint` → 공용 `EmptyState`로 교체.
      data: (items) => items.isEmpty
          ? const EmptyState(
              icon: Icons.history_rounded,
              title: '아직 검색 기록이 없어요',
              message: '증상 이름이나 초성으로 검색해 보세요',
            )
          : _list(context, ref, items),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<String> items) {
    final colors = context.colors;
    // DESIGN v2 §7.2-2 — 행 사이 inset 헤어라인(좌 72dp, 결과 행과 동일 리듬).
    // 헤더와 첫 행 사이에는 넣지 않는다("행 사이"에만 적용).
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: AppSpacing.x24),
      itemCount: items.length + 1,
      separatorBuilder: (context, index) => index == 0
          ? const SizedBox.shrink()
          : Divider(
              height: 1,
              thickness: 1,
              indent: SearchResultTile.dividerIndent,
              color: colors.line,
            ),
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

/// DESIGN v2 §7.2-3 — `SectionHeader`(trailing="전체 삭제" 텍스트 버튼)로 교체.
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
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x8,
              vertical: AppSpacing.x4,
            ),
            child: Text(
              '전체 삭제',
              style: context.texts.caption.copyWith(color: colors.accent),
            ),
          ),
        ),
      ),
    );
  }
}

/// 좌스와이프(→ endToStart) 개별 삭제 + 탭 재검색.
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
    return Dismissible(
      key: ValueKey(query),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: ColoredBox(
        color: colors.coralWash,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.screenPadding,
          ),
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
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          splashFactory: InkWashSplash.splashFactory,
          splashColor: colors.accentWash,
          highlightColor: Colors.transparent,
          onTap: () {
            AppHaptics.tap();
            onTap();
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.screenPadding,
              vertical: AppSpacing.x12,
            ),
            child: Row(
              children: [
                Icon(Icons.history_rounded, size: 20, color: colors.ink300),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Text(
                    query,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.texts.bodyL.copyWith(color: colors.ink900),
                  ),
                ),
                const SizedBox(width: AppSpacing.x8),
                Icon(Icons.north_west_rounded, size: 18, color: colors.ink300),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
