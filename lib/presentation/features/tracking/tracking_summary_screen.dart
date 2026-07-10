import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../domain/entities/tracking_log.dart';
import '../../widgets/animated/number_ticker.dart';
import '../../widgets/cards/app_card.dart';
import '../../widgets/navigation/app_app_bar.dart';
import '../../widgets/segments/sliding_segment.dart';
import '../../widgets/skeletons/skeleton_blocks.dart';
import '../../widgets/states/empty_state.dart';
import '../../widgets/states/error_state.dart';
import 'tracking_format.dart';
import 'tracking_providers.dart';

/// §11.12 기록 요약 — 기간 탭(오늘/7일/30일) · 타입별 통계 카드 · 수묵 막대그래프 ·
/// 일자별 리스트. 기간 전환 시 데이터/그래프 크로스페이드, 통계 수치 티커, 바 grow stagger.
class TrackingSummaryScreen extends ConsumerStatefulWidget {
  const TrackingSummaryScreen({super.key});

  @override
  ConsumerState<TrackingSummaryScreen> createState() =>
      _TrackingSummaryScreenState();
}

class _TrackingSummaryScreenState extends ConsumerState<TrackingSummaryScreen> {
  SummaryRange _range = SummaryRange.today;
  bool _scrolled = false;

  bool _onScroll(ScrollNotification n) {
    final scrolled = n.metrics.pixels > 4;
    if (scrolled != _scrolled) setState(() => _scrolled = scrolled);
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final babyId = ref.watch(selectedBabyIdProvider).value;
    final scope = (range: _range, babyId: babyId);
    final summaryAsync = ref.watch(summaryProvider(scope));

    return Scaffold(
      backgroundColor: colors.paperBg,
      appBar: AppAppBar(title: '기록 요약', scrolled: _scrolled),
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x16,
            AppSpacing.screenPadding,
            AppSpacing.x40,
          ),
          children: [
            // DESIGN v2 §4.7/§7.5.4 — 수제 _RangeTabs를 공용 SlidingSegment로.
            // 선택 가드·햅틱은 SlidingSegment 내부가 처리하므로 여기선 반영만 한다.
            SlidingSegment<SummaryRange>(
              items: SummaryRange.values,
              selected: _range,
              onChanged: (r) => setState(() => _range = r),
              labelOf: (r) => r.label,
            ),
            const SizedBox(height: AppSpacing.sectionGap),
            AnimatedSwitcher(
              duration: context.reduceMotion ? Duration.zero : AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: KeyedSubtree(
                key: ValueKey(_range),
                child: summaryAsync.when(
                  loading: () => const _SummarySkeleton(),
                  error: (_, _) => ErrorState(
                    onRetry: () => ref.invalidate(summaryProvider(scope)),
                  ),
                  data: (data) => _SummaryBody(data: data),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── 요약 본문 ─────────────────────────────────────────────────────────────

class _SummaryBody extends StatelessWidget {
  const _SummaryBody({required this.data});

  final SummaryData data;

  @override
  Widget build(BuildContext context) {
    final total = data.days.fold<int>(0, (s, d) => s + d.total);
    final reduce = context.reduceMotion;
    final types = TrackingType.values;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < types.length; i++) ...[
          _staggerIn(
            _StatCard(
              type: types[i],
              stat: data.stats[types[i]] ?? TypeStat.empty,
            ),
            index: i,
            reduce: reduce,
          ),
          const SizedBox(height: AppSpacing.x12),
        ],
        const SizedBox(height: AppSpacing.x12),
        Text(
          '일별 기록',
          style: context.texts.heading.copyWith(color: context.colors.ink900),
        ),
        const SizedBox(height: AppSpacing.x16),
        if (total == 0)
          const EmptyState(
            title: '이 기간에 기록이 없어요',
            message: '기록 홈에서 첫 기록을 남겨보세요',
            icon: Icons.insights_rounded,
          )
        else ...[
          _DayBarChart(days: data.days),
          const SizedBox(height: AppSpacing.sectionGap),
          for (final bucket in data.days.reversed)
            if (bucket.total > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.x8),
                child: _DayRow(bucket: bucket),
              ),
        ],
      ],
    );
  }

  /// DESIGN v2 §7.5.3 통계 카드 진입 stagger — 홈 그리드(§10.2)와 동일 문법
  /// (fadeIn 260ms + slideY .08, 40ms 간격). reduce-motion 시 즉시 표시.
  Widget _staggerIn(Widget card, {required int index, required bool reduce}) {
    if (reduce) {
      return KeyedSubtree(key: ValueKey('stat-card-$index'), child: card);
    }
    return card
        .animate(key: ValueKey('stat-card-anim-$index'))
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
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.type, required this.stat});

  final TrackingType type;
  final TypeStat stat;

  String get _totalText {
    switch (type) {
      case TrackingType.feed:
        return stat.totalAmount > 0 ? '${stat.totalAmount.round()}ml' : '—';
      case TrackingType.sleep:
        return stat.totalAmount > 0 ? formatSleepBand(stat.totalAmount) : '—';
      case TrackingType.diaper:
        return '—';
    }
  }

  String get _avgText {
    final avg = stat.avgIntervalMinutes;
    if (avg == null) return '—';
    return formatDuration(Duration(minutes: avg.round()));
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final style = trackingTypeStyle(context, type);
    // DESIGN v2 §5.1/§7.5.1 — 수제 Container 데코를 공용 AppCard(raised)로.
    return AppCard(
      emphasis: AppCardEmphasis.raised,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: style.wash,
                  shape: BoxShape.circle,
                ),
                child: Icon(style.icon, size: 18, color: style.color),
              ),
              const SizedBox(width: AppSpacing.x8),
              Text(
                style.label,
                style: texts.label.copyWith(color: colors.ink900),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x16),
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: '횟수',
                  child: NumberTicker(
                    value: stat.count,
                    suffix: '회',
                    style: texts.data.copyWith(
                      color: colors.ink900,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: _Metric(
                  label: type == TrackingType.diaper ? '종류' : '총량',
                  value: _totalText,
                ),
              ),
              Expanded(
                child: _Metric(label: '평균 간격', value: _avgText),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, this.value, this.child});

  final String label;
  final String? value;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: texts.caption.copyWith(color: colors.ink500)),
        const SizedBox(height: AppSpacing.x4),
        child ??
            Text(
              value ?? '—',
              style: texts.data.copyWith(color: colors.ink900, fontSize: 16),
            ),
      ],
    );
  }
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.bucket});

  final DayBucket bucket;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    // DESIGN v2 §5.1/§7.5.1 — 수제 Container 데코를 공용 AppCard(flat)로.
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.x12,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              formatDayLabel(bucket.day),
              style: texts.body.copyWith(color: colors.ink900),
            ),
          ),
          for (final type in TrackingType.values)
            if ((bucket.countsByType[type] ?? 0) > 0)
              Padding(
                padding: const EdgeInsets.only(left: AppSpacing.x8),
                child: _CountChip(
                  type: type,
                  count: bucket.countsByType[type] ?? 0,
                ),
              ),
        ],
      ),
    );
  }
}

class _CountChip extends StatelessWidget {
  const _CountChip({required this.type, required this.count});

  final TrackingType type;
  final int count;

  @override
  Widget build(BuildContext context) {
    final style = trackingTypeStyle(context, type);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: style.wash,
        borderRadius: AppRadius.brFull,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(style.icon, size: 14, color: style.color),
          const SizedBox(width: AppSpacing.x4),
          Text(
            '$count',
            style: context.texts.caption.copyWith(color: style.color),
          ),
        ],
      ),
    );
  }
}

// ── 수묵 막대그래프(외부 패키지 없이 CustomPaint) ─────────────────────────

class _DayBarChart extends StatefulWidget {
  const _DayBarChart({required this.days});

  final List<DayBucket> days;

  @override
  State<_DayBarChart> createState() => _DayBarChartState();
}

class _DayBarChartState extends State<_DayBarChart>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  int? _selected;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _play());
  }

  @override
  void didUpdateWidget(_DayBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days.length != widget.days.length) _play();
  }

  void _play() {
    if (!mounted) return;
    if (AppMotion.reduceMotion(context)) {
      _controller.value = 1;
    } else {
      _controller.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _handleTap(TapUpDetails details, Size size) {
    final n = widget.days.length;
    if (n == 0) return;
    final i = (details.localPosition.dx / size.width * n).floor().clamp(
      0,
      n - 1,
    );
    final bucket = widget.days[i];
    if (bucket.total == 0) return;
    AppHaptics.tap();
    setState(() => _selected = i);
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _DayDetailSheet(bucket: bucket),
    ).whenComplete(() {
      if (mounted) setState(() => _selected = null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final maxValue = widget.days.fold<int>(
      1,
      (m, d) => d.total > m ? d.total : m,
    );
    return SizedBox(
      height: 160,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final size = Size(constraints.maxWidth, constraints.maxHeight);
          return GestureDetector(
            onTapUp: (d) => _handleTap(d, size),
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) => CustomPaint(
                size: size,
                painter: _BarPainter(
                  days: widget.days,
                  maxValue: maxValue,
                  progress: _controller.value,
                  selected: _selected,
                  barColor: colors.accent,
                  selectedColor: colors.accentDeep,
                  trackColor: colors.line,
                  labelColor: colors.ink500,
                  showLabels: widget.days.length <= 7,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.days,
    required this.maxValue,
    required this.progress,
    required this.selected,
    required this.barColor,
    required this.selectedColor,
    required this.trackColor,
    required this.labelColor,
    required this.showLabels,
  });

  final List<DayBucket> days;
  final int maxValue;
  final double progress;
  final int? selected;
  final Color barColor;
  final Color selectedColor;
  final Color trackColor;
  final Color labelColor;
  final bool showLabels;

  static const List<String> _weekdays = ['월', '화', '수', '목', '금', '토', '일'];

  @override
  void paint(Canvas canvas, Size size) {
    final n = days.length;
    if (n == 0) return;
    final labelH = showLabels ? 18.0 : 0.0;
    final chartH = size.height - labelH;
    final slot = size.width / n;
    final barW = (slot * 0.5).clamp(4.0, 28.0);

    // 바닥 기준선(수묵 헤어라인).
    final base = Paint()
      ..color = trackColor
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, chartH), Offset(size.width, chartH), base);

    for (var i = 0; i < n; i++) {
      final cx = slot * i + slot / 2;
      final value = days[i].total;
      final ratio = value / maxValue;
      // stagger: 각 바가 순차로 grow.
      final startT = (i / n) * 0.5;
      final localT = ((progress - startT) / (1 - startT)).clamp(0.0, 1.0);
      final eased = Curves.easeOutCubic.transform(localT);
      final h = chartH * ratio * eased;
      final rect = RRect.fromRectAndRadius(
        Rect.fromLTWH(cx - barW / 2, chartH - h, barW, h),
        const Radius.circular(AppRadius.xs),
      );
      final paint = Paint()
        ..color = value == 0
            ? trackColor
            : (i == selected ? selectedColor : barColor);
      canvas.drawRRect(rect, paint);

      if (showLabels) {
        // DESIGN v2 §7.5.8 — fontSize 11 리터럴 대신 AppTypography.caption 기반.
        final tp = TextPainter(
          text: TextSpan(
            text: _weekdays[(days[i].day.weekday - 1) % 7],
            style: AppTypography.caption.copyWith(color: labelColor),
          ),
          textDirection: TextDirection.ltr,
        )..layout();
        tp.paint(
          canvas,
          Offset(cx - tp.width / 2, chartH + (labelH - tp.height) / 2),
        );
      }
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.progress != progress ||
      old.selected != selected ||
      old.days != days ||
      old.maxValue != maxValue;
}

// ── 바 탭 일자 상세 시트 ──────────────────────────────────────────────────

class _DayDetailSheet extends StatelessWidget {
  const _DayDetailSheet({required this.bucket});

  final DayBucket bucket;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final logs = [...bucket.logs]
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    return Container(
      decoration: BoxDecoration(
        color: colors.paperRaised,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppRadius.lg),
        ),
        boxShadow: context.shadows.e3,
      ),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenPadding,
            AppSpacing.x12,
            AppSpacing.screenPadding,
            AppSpacing.x20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.line,
                    borderRadius: AppRadius.brFull,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.x16),
              Text(
                formatDayLabel(bucket.day),
                style: context.texts.heading.copyWith(color: colors.ink900),
              ),
              const SizedBox(height: AppSpacing.x16),
              for (final log in logs)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.x12),
                  child: _DetailLogRow(log: log),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailLogRow extends StatelessWidget {
  const _DetailLogRow({required this.log});

  final TrackingLog log;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final style = trackingTypeStyle(context, log.type);
    return Row(
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
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: style.wash, shape: BoxShape.circle),
          child: Icon(style.icon, size: 18, color: style.color),
        ),
        const SizedBox(width: AppSpacing.x12),
        Expanded(
          child: Text(
            trackingLogSummary(log),
            style: texts.body.copyWith(color: colors.ink900),
          ),
        ),
      ],
    );
  }
}

// ── 로딩 스켈레톤 ─────────────────────────────────────────────────────────

class _SummarySkeleton extends StatelessWidget {
  const _SummarySkeleton();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < 3; i++) ...[
          const SkeletonLine(height: 96, radius: AppRadius.brMd),
          const SizedBox(height: AppSpacing.x12),
        ],
        const SizedBox(height: AppSpacing.x12),
        const SkeletonLine(height: 160, radius: AppRadius.brMd),
      ],
    );
  }
}
