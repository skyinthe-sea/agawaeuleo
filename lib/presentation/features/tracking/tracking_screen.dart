import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/providers.dart';
import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../domain/entities/baby.dart';
import '../../../domain/entities/tracking_log.dart';
import '../../router/routes.dart';
import '../../widgets/animated/number_ticker.dart';
import '../../widgets/animated/tap_spring.dart';
import '../../widgets/skeletons/skeleton_blocks.dart';
import '../../widgets/states/error_state.dart';
import 'tracking_elapsed_ticker.dart';
import 'tracking_entry_sheet.dart';
import 'tracking_format.dart';
import 'tracking_providers.dart';

/// §11.10 기록 홈(트래킹) — 재방문 엔진.
///
/// 상단바(아기 전환 드롭다운 + 요약 아이콘) · 오늘 요약 밴드(3카드 티커) ·
/// 진행 중 배지 · 빠른 기록 알약 3종 · 오늘 타임라인(좌스와이프 삭제/실행취소·탭 편집) ·
/// 스크롤 시 라벨이 접히는 FAB.
class TrackingScreen extends ConsumerStatefulWidget {
  const TrackingScreen({super.key});

  @override
  ConsumerState<TrackingScreen> createState() => _TrackingScreenState();
}

class _TrackingScreenState extends ConsumerState<TrackingScreen> {
  final ScrollController _scroll = ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _scroll.addListener(_onScroll);
  }

  void _onScroll() {
    final scrolled = _scroll.hasClients && _scroll.offset > 4;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
  }

  @override
  void dispose() {
    _scroll
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  DateTime get _today {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day);
  }

  void _openEntry({TrackingType? presetType, String? babyId}) {
    unawaitedSheet(
      showTrackingEntrySheet(context, babyId: babyId, presetType: presetType),
    );
  }

  void _openStop(TrackingLog log) {
    unawaitedSheet(showTrackingEntrySheet(context, log: log));
  }

  void _editLog(TrackingLog log) {
    unawaitedSheet(showTrackingEntrySheet(context, log: log));
  }

  Future<void> _deleteWithUndo(TrackingLog log) async {
    final repo = ref.read(trackingRepositoryProvider);
    final messenger = ScaffoldMessenger.of(context);
    AppHaptics.tap();
    await repo.delete(log.id);
    if (!mounted) return;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: const Text('기록을 삭제했어요'),
          action: SnackBarAction(label: '실행취소', onPressed: () => repo.add(log)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final babyId = ref.watch(selectedBabyIdProvider).value;
    final babies = ref.watch(trackingBabiesProvider).value ?? const [];
    final scope = (day: _today, babyId: babyId);
    final dayAsync = ref.watch(trackingDayProvider(scope));
    final inProgress = ref.watch(inProgressProvider(babyId)).value ?? const [];

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppBar(
        toolbarHeight: 56,
        automaticallyImplyLeading: false,
        backgroundColor: colors.paperRaised,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        shape: _scrolled
            ? Border(bottom: BorderSide(color: colors.line))
            : null,
        titleSpacing: AppSpacing.screenPadding,
        title: _BabySwitcher(
          babies: babies,
          selectedId: babyId,
          onSelect: (id) {
            AppHaptics.toggle();
            ref.read(babyRepositoryProvider).selectBaby(id);
          },
        ),
        actions: [
          _AppBarIcon(
            icon: Icons.calendar_month_rounded,
            onTap: () {
              AppHaptics.tap();
              context.pushNamed(Routes.trackingSummary);
            },
          ),
          const SizedBox(width: AppSpacing.x8),
        ],
      ),
      floatingActionButton: _RecordFab(
        expanded: !_scrolled,
        onTap: () {
          AppHaptics.tap();
          _openEntry(babyId: babyId);
        },
      ),
      body: dayAsync.when(
        loading: () => const _HomeSkeleton(),
        error: (_, _) => ErrorState(
          onRetry: () => ref.invalidate(trackingDayProvider(scope)),
        ),
        data: (logs) => ListView(
          controller: _scroll,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x16,
            AppSpacing.screenPadding,
            AppSpacing.x64 + AppSpacing.x40,
          ),
          children: [
            _SummaryBand(totals: TodayTotals.of(logs)),
            if (inProgress.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.x12),
              for (final log in inProgress)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x8),
                  child: _InProgressBadge(
                    log: log,
                    onTap: () => _openStop(log),
                  ),
                ),
            ],
            const SizedBox(height: AppSpacing.x20),
            _QuickRow(
              onTap: (type) => _openEntry(presetType: type, babyId: babyId),
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            Text(
              '오늘',
              style: context.texts.heading.copyWith(color: colors.ink900),
            ),
            const SizedBox(height: AppSpacing.x12),
            if (logs.isEmpty)
              const _TimelineEmpty()
            else
              for (final log in logs)
                _TimelineTile(
                  key: ValueKey(log.id),
                  log: log,
                  onTap: () => _editLog(log),
                  onDelete: () => _deleteWithUndo(log),
                ),
          ],
        ),
      ),
    );
  }
}

/// showModalBottomSheet Future 를 명시적으로 버린다(lint 회피).
void unawaitedSheet(Future<void> future) {
  future.ignore();
}

// ── 상단바 아기 전환 ──────────────────────────────────────────────────────

class _BabySwitcher extends StatelessWidget {
  const _BabySwitcher({
    required this.babies,
    required this.selectedId,
    required this.onSelect,
  });

  final List<Baby> babies;
  final String? selectedId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    if (babies.isEmpty) {
      return Text('기록', style: texts.title.copyWith(color: colors.ink900));
    }
    Baby? selected;
    for (final b in babies) {
      if (b.id == selectedId) selected = b;
    }
    final label = selected?.name ?? babies.first.name;

    return Align(
      alignment: Alignment.centerLeft,
      child: PopupMenuButton<String?>(
        color: colors.paperRaised,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
        position: PopupMenuPosition.under,
        onSelected: onSelect,
        itemBuilder: (context) => [
          for (final b in babies)
            PopupMenuItem<String?>(
              value: b.id,
              child: Row(
                children: [
                  if (b.id == (selectedId ?? babies.first.id))
                    Icon(Icons.check_rounded, size: 18, color: colors.accent)
                  else
                    const SizedBox(width: 18),
                  const SizedBox(width: AppSpacing.x8),
                  Text(
                    b.name,
                    style: texts.body.copyWith(color: colors.ink900),
                  ),
                ],
              ),
            ),
        ],
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: texts.title.copyWith(color: colors.ink900),
              ),
            ),
            Icon(Icons.arrow_drop_down_rounded, color: colors.ink500),
          ],
        ),
      ),
    );
  }
}

class _AppBarIcon extends StatelessWidget {
  const _AppBarIcon({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 56,
        child: Center(
          child: Icon(icon, size: 24, color: context.colors.ink900),
        ),
      ),
    );
  }
}

// ── 오늘 요약 밴드 ────────────────────────────────────────────────────────

class _SummaryBand extends StatelessWidget {
  const _SummaryBand({required this.totals});

  final TodayTotals totals;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _SummaryCard(
            type: TrackingType.feed,
            label: '수유',
            child: NumberTicker(
              value: totals.feedCount,
              suffix: '회',
              style: _valueStyle(context),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          child: _SummaryCard(
            type: TrackingType.sleep,
            label: '수면',
            child: NumberTicker(
              value: totals.sleepMinutes,
              formatter: formatSleepBand,
              style: _valueStyle(context),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          child: _SummaryCard(
            type: TrackingType.diaper,
            label: '기저귀',
            child: NumberTicker(
              value: totals.diaperCount,
              suffix: '회',
              style: _valueStyle(context),
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _valueStyle(BuildContext context) =>
      context.texts.data.copyWith(color: context.colors.ink900, fontSize: 16);
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.type,
    required this.label,
    required this.child,
  });

  final TrackingType type;
  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = trackingTypeStyle(context, type);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppRadius.brMd,
        boxShadow: context.shadows.e1,
        border: Border.all(color: colors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(style.icon, size: 20, color: style.color),
          const SizedBox(height: AppSpacing.x8),
          Text(
            label,
            style: context.texts.caption.copyWith(color: colors.ink500),
          ),
          const SizedBox(height: AppSpacing.x2),
          child,
        ],
      ),
    );
  }
}

class _InProgressBadge extends StatelessWidget {
  const _InProgressBadge({required this.log, required this.onTap});

  final TrackingLog log;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final style = trackingTypeStyle(context, log.type);
    return TapSpring(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.x16,
          vertical: AppSpacing.x12,
        ),
        decoration: BoxDecoration(
          color: style.wash,
          borderRadius: AppRadius.brFull,
        ),
        child: Row(
          children: [
            Icon(style.icon, size: 20, color: style.color),
            const SizedBox(width: AppSpacing.x8),
            Expanded(
              child: ElapsedTicker(
                start: log.startedAt,
                prefix: '${style.label} 진행 중 · ',
                style: context.texts.label.copyWith(color: style.color),
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 20, color: style.color),
          ],
        ),
      ),
    );
  }
}

// ── 빠른 기록 알약 ────────────────────────────────────────────────────────

class _QuickRow extends StatelessWidget {
  const _QuickRow({required this.onTap});

  final ValueChanged<TrackingType> onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < TrackingType.values.length; i++) ...[
          if (i > 0) const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: _QuickPill(
              type: TrackingType.values[i],
              onTap: () => onTap(TrackingType.values[i]),
            ),
          ),
        ],
      ],
    );
  }
}

class _QuickPill extends StatelessWidget {
  const _QuickPill({required this.type, required this.onTap});

  final TrackingType type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = trackingTypeStyle(context, type);
    return TapSpring(
      onTap: onTap,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: colors.accentWash,
          borderRadius: AppRadius.brFull,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(style.icon, size: 20, color: colors.accent),
            const SizedBox(height: AppSpacing.x2),
            Text(
              style.label,
              style: context.texts.caption.copyWith(color: colors.accent),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 타임라인 ──────────────────────────────────────────────────────────────

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({
    required this.log,
    required this.onTap,
    required this.onDelete,
    super.key,
  });

  final TrackingLog log;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final style = trackingTypeStyle(context, log.type);
    final reduce = context.reduceMotion;

    Widget tile = Dismissible(
      key: ValueKey('dismiss-${log.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDelete(),
      background: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.x8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
        decoration: BoxDecoration(
          color: colors.coralWash,
          borderRadius: AppRadius.brMd,
        ),
        child: Icon(Icons.delete_outline_rounded, color: colors.coral),
      ),
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.x8),
        child: TapSpring(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.x12),
            decoration: BoxDecoration(
              color: colors.paperCard,
              borderRadius: AppRadius.brMd,
              boxShadow: context.shadows.e1,
              border: Border.all(color: colors.line),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 44,
                  child: Text(
                    formatClock(log.startedAt),
                    style: texts.data.copyWith(color: colors.ink500),
                  ),
                ),
                const SizedBox(width: AppSpacing.x8),
                Container(
                  width: 36,
                  height: 36,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: style.wash,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(style.icon, size: 20, color: style.color),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: log.isInProgress
                      ? ElapsedTicker(
                          start: log.startedAt,
                          prefix: '${style.label} · 진행 중 ',
                          style: texts.bodyL.copyWith(color: style.color),
                        )
                      : Text(
                          trackingLogSummary(log),
                          style: texts.bodyL.copyWith(color: colors.ink900),
                        ),
                ),
                Icon(Icons.more_horiz_rounded, size: 20, color: colors.ink300),
              ],
            ),
          ),
        ),
      ),
    );

    if (!reduce) {
      tile = tile
          .animate()
          .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
          .slideY(begin: -0.12, end: 0, curve: AppMotion.enter);
    }
    return tile;
  }
}

class _TimelineEmpty extends StatelessWidget {
  const _TimelineEmpty();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x32),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: colors.accentWash,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.edit_note_rounded,
              size: 36,
              color: colors.accent,
            ),
          ),
          const SizedBox(height: AppSpacing.x16),
          Text(
            '아직 오늘 기록이 없어요',
            style: context.texts.bodyL.copyWith(color: colors.ink900),
          ),
          const SizedBox(height: AppSpacing.x4),
          Text(
            '아래 + 로 첫 기록을 남겨보세요',
            style: context.texts.body.copyWith(color: colors.ink500),
          ),
        ],
      ),
    );
  }
}

// ── FAB ───────────────────────────────────────────────────────────────────

class _RecordFab extends StatelessWidget {
  const _RecordFab({required this.expanded, required this.onTap});

  final bool expanded;
  final VoidCallback onTap;

  /// §10.2 FAB 스케일인/라벨 확축: 300ms easeOutBack(스프링).
  static const Duration _springDuration = Duration(milliseconds: 300);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = context.reduceMotion;
    final Duration motion = reduce ? Duration.zero : _springDuration;

    final Widget fab = Material(
      color: colors.accent,
      borderRadius: AppRadius.brFull,
      elevation: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: AppRadius.brFull,
          boxShadow: context.shadows.e4,
        ),
        child: InkWell(
          borderRadius: AppRadius.brFull,
          onTap: onTap,
          child: AnimatedContainer(
            // §10.2 라벨 확장/축소도 진입과 동일 파라미터(300ms easeOutBack).
            duration: motion,
            curve: AppMotion.spring,
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x20),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: colors.paperRaised),
                AnimatedSize(
                  duration: motion,
                  curve: AppMotion.spring,
                  child: expanded
                      ? Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.x8),
                          child: Text(
                            '기록 추가',
                            style: context.texts.label.copyWith(
                              color: colors.paperRaised,
                            ),
                          ),
                        )
                      : const SizedBox.shrink(),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (reduce) return fab;
    // §10.2 진입 스케일인(스프링) — .8→1, 300ms easeOutBack(오버슈트).
    return fab.animate().scale(
      begin: const Offset(0.8, 0.8),
      end: const Offset(1, 1),
      duration: _springDuration,
      curve: AppMotion.spring,
    );
  }
}

// ── 로딩 스켈레톤 ─────────────────────────────────────────────────────────

class _HomeSkeleton extends StatelessWidget {
  const _HomeSkeleton();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(AppSpacing.screenPadding),
      children: [
        Row(
          children: [
            for (var i = 0; i < 3; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.x12),
              const Expanded(child: SkeletonBox(size: 76)),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.x20),
        const SkeletonLine(height: 56, radius: AppRadius.brFull),
        const SizedBox(height: AppSpacing.sectionGap),
        for (var i = 0; i < 4; i++) ...[
          const ListItemSkeleton(),
          const SizedBox(height: AppSpacing.x8),
        ],
      ],
    );
  }
}
