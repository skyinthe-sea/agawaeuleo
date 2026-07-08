import 'package:agawaeuleo/application/providers.dart';
import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/presentation/widgets/animated/ink_wash_splash.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../search_providers.dart';

/// §11.8 최근 검색어 — 입력이 비었을 때 노출. 좌스와이프로 개별 삭제, 탭 시 재검색.
class RecentSearchesView extends ConsumerWidget {
  const RecentSearchesView({required this.onSelect, super.key});

  /// 항목 탭 → 해당 검색어로 재검색.
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(recentSearchesProvider);
    return async.maybeWhen(
      data: (items) =>
          items.isEmpty ? const _EmptyHint() : _list(context, ref, items),
      orElse: () => const SizedBox.shrink(),
    );
  }

  Widget _list(BuildContext context, WidgetRef ref, List<String> items) {
    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.x24),
      children: [
        _Header(
          onClearAll: () {
            AppHaptics.toggle();
            ref.read(recentSearchRepositoryProvider).clear();
          },
        ),
        for (final query in items)
          _RecentRow(
            key: ValueKey(query),
            query: query,
            onTap: () => onSelect(query),
            onDelete: () {
              AppHaptics.toggle();
              ref.read(recentSearchRepositoryProvider).delete(query);
            },
          ),
      ],
    );
  }
}

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
        AppSpacing.x12,
        AppSpacing.x8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              '최근 검색어',
              style: context.texts.label.copyWith(color: colors.ink500),
            ),
          ),
          GestureDetector(
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
        ],
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

class _EmptyHint extends StatelessWidget {
  const _EmptyHint();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.screenPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 40, color: colors.ink300),
            const SizedBox(height: AppSpacing.x12),
            Text(
              '증상 이름이나 초성으로 검색해 보세요',
              textAlign: TextAlign.center,
              style: context.texts.body.copyWith(color: colors.ink500),
            ),
          ],
        ),
      ),
    );
  }
}
