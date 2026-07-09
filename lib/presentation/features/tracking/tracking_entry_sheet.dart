import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../application/notification_providers.dart';
import '../../../application/providers.dart';
import '../../../config/theme/theme.dart';
import '../../../core/haptics/app_haptics.dart';
import '../../../core/notifications/notifications.dart';
import '../../../domain/entities/tracking_log.dart';
import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../../widgets/animated/check_draw.dart';
import '../../widgets/animated/number_ticker.dart';
import '../../widgets/buttons/ghost_button.dart';
import '../../widgets/buttons/primary_button.dart';
import 'tracking_elapsed_ticker.dart';
import 'tracking_format.dart';

/// §11.11 기록 추가/편집 시트를 모달로 연다(라우트 아님).
///
/// - [presetType] : 빠른 기록 알약/FAB에서 사전 선택할 타입.
/// - [log] : 편집(완료 로그) 또는 종료(진행 중 로그) 대상. null이면 신규.
Future<void> showTrackingEntrySheet(
  BuildContext context, {
  String? babyId,
  TrackingType? presetType,
  TrackingLog? log,
}) {
  return showModalBottomSheet<void>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: context.colors.ink900.withValues(alpha: 0.32),
    builder: (_) =>
        _TrackingEntrySheet(babyId: babyId, presetType: presetType, log: log),
  );
}

enum _EntryMode { create, edit, stop }

class _TrackingEntrySheet extends ConsumerStatefulWidget {
  const _TrackingEntrySheet({this.babyId, this.presetType, this.log});

  final String? babyId;
  final TrackingType? presetType;
  final TrackingLog? log;

  @override
  ConsumerState<_TrackingEntrySheet> createState() =>
      _TrackingEntrySheetState();
}

class _TrackingEntrySheetState extends ConsumerState<_TrackingEntrySheet> {
  late final _EntryMode _mode;
  late TrackingType _type;

  // feed
  TrackingSubtype _feedSub = TrackingSubtype.formula;
  bool _feedTimer = false; // 모유 타이머 모드
  String? _breastSide; // '왼쪽' | '오른쪽'

  // diaper
  TrackingSubtype _diaperSub = TrackingSubtype.pee;

  // sleep
  bool _sleepTimer = true; // §11.11 수면 타이머 모드 기본

  double _amount = 120;
  late DateTime _startedAt;
  DateTime? _endedAt;
  final TextEditingController _note = TextEditingController();

  bool _saving = false;
  bool _completed = false;

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    if (log == null) {
      _mode = _EntryMode.create;
      _type = widget.presetType ?? TrackingType.feed;
      _startedAt = DateTime.now();
      _endedAt = _startedAt.add(const Duration(hours: 1));
    } else {
      _mode = log.isInProgress ? _EntryMode.stop : _EntryMode.edit;
      _type = log.type;
      _startedAt = log.startedAt;
      _endedAt = log.endedAt ?? DateTime.now();
      _amount = log.amount ?? 120;
      _note.text = log.note ?? '';
      switch (log.type) {
        case TrackingType.feed:
          _feedSub = log.subtype ?? TrackingSubtype.formula;
        case TrackingType.diaper:
          _diaperSub = log.subtype ?? TrackingSubtype.pee;
        case TrackingType.sleep:
          break;
      }
    }
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  // ── 저장 동작 ────────────────────────────────────────────────────────

  Future<void> _guard(
    Future<TrackingLog> Function() op, {
    required bool complete,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    final nav = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    // 위젯이 pop 되기 전에 캡처(성공 후 트리 언마운트 시 ref 접근 방지).
    final scheduler = ref.read(feedingReminderSchedulerProvider);
    try {
      await op();
      if (!mounted) return;
      // 저장 성공 → "다음 수유 예상" 알림 재예약(§3.2 S4, 스케줄러 내부 가드로 실패 무시).
      unawaited(scheduler.rescheduleFromRecent(babyId: widget.babyId));
      if (complete) {
        AppHaptics.complete();
        setState(() => _completed = true);
        await Future<void>.delayed(const Duration(milliseconds: 720));
        if (mounted) nav.pop();
      } else {
        AppHaptics.toggle();
        nav.pop();
      }
      // §11.6 첫 기록 저장 직후 1회 알림 권한 프라이밍(맥락 있는 시점 → 수락률↑).
      await _maybeShowPriming();
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('저장하지 못했어요. 다시 시도해 주세요.')),
      );
    }
  }

  /// §11.6 첫 기록 저장 직후 알림 프라이밍을 1회 노출한다. 실제 루트 라우터가 붙어 있을
  /// 때만(=앱 부팅 경로) 이동하며, 위젯 테스트처럼 라우터가 없으면 조용히 건너뛴다.
  Future<void> _maybeShowPriming() async {
    final rootContext = rootNavigatorKey.currentContext;
    if (rootContext == null) return;
    final show = await NotificationPrimingPrefs.shouldShowAfterFirstRecord();
    if (!show || !rootContext.mounted) return;
    rootContext.pushNamed(Routes.permissionPriming);
  }

  String? _composedNote() {
    final base = _note.text.trim();
    if (_type == TrackingType.feed &&
        _feedSub == TrackingSubtype.breast &&
        _breastSide != null) {
      return [_breastSide!, if (base.isNotEmpty) base].join(' · ');
    }
    return base.isEmpty ? null : base;
  }

  TrackingLog _draft({required DateTime started, DateTime? ended}) {
    TrackingSubtype? sub;
    double? amount;
    switch (_type) {
      case TrackingType.feed:
        sub = _feedSub;
        amount = _feedSub == TrackingSubtype.breast && _feedTimer
            ? null
            : _amount;
      case TrackingType.diaper:
        sub = _diaperSub;
      case TrackingType.sleep:
        sub = null;
    }
    return TrackingLog(
      id: widget.log?.id ?? '',
      userId: widget.log?.userId ?? '',
      babyId: widget.babyId ?? widget.log?.babyId,
      type: _type,
      subtype: sub,
      amount: amount,
      note: _composedNote(),
      startedAt: started,
      endedAt: ended,
      createdAt: widget.log?.createdAt ?? DateTime.now(),
    );
  }

  void _startTimer() {
    // 진행 중 로그 생성(endedAt = null) — §11.11.
    unawaited(
      _guard(
        () => ref
            .read(trackingRepositoryProvider)
            .add(_draft(started: DateTime.now())),
        complete: false,
      ),
    );
  }

  void _stopTimer() {
    final log = widget.log!;
    unawaited(
      _guard(
        () => ref
            .read(trackingRepositoryProvider)
            .stop(
              id: log.id,
              endedAt: DateTime.now(),
              amount: _type == TrackingType.feed && _amount > 0
                  ? _amount
                  : null,
              note: _composedNote(),
            ),
        complete: true,
      ),
    );
  }

  void _saveCompleted() {
    final ended = _needsEnd ? _endedAt : _startedAt;
    final draft = _draft(started: _startedAt, ended: ended);
    final repo = ref.read(trackingRepositoryProvider);
    unawaited(
      _guard(
        () => _mode == _EntryMode.edit ? repo.update(draft) : repo.add(draft),
        complete: true,
      ),
    );
  }

  Future<void> _confirmDelete() async {
    final log = widget.log;
    if (log == null) return;
    final nav = Navigator.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _DeleteDialog(),
    );
    if (confirmed != true || !mounted) return;
    await ref.read(trackingRepositoryProvider).delete(log.id);
    if (mounted) nav.pop();
  }

  /// 이 조합에서 종료시각이 의미 있는지(수면·모유 직접입력).
  bool get _needsEnd {
    if (_type == TrackingType.sleep) return !_sleepTimer;
    if (_type == TrackingType.feed) {
      return _feedSub == TrackingSubtype.breast && !_feedTimer;
    }
    return false;
  }

  Future<void> _pickTime({required bool isEnd}) async {
    final current = isEnd ? (_endedAt ?? _startedAt) : _startedAt;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
    );
    if (picked == null) return;
    final next = DateTime(
      current.year,
      current.month,
      current.day,
      picked.hour,
      picked.minute,
    );
    AppHaptics.toggle();
    setState(() {
      if (isEnd) {
        _endedAt = next;
      } else {
        _startedAt = next;
      }
    });
  }

  // ── 빌드 ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = context.reduceMotion;

    return AnimatedPadding(
      duration: AppMotion.fast,
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
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
          child: AnimatedSwitcher(
            duration: reduce ? Duration.zero : AppMotion.base,
            switchInCurve: AppMotion.enter,
            child: _completed ? _completionView(context) : _formView(context),
          ),
        ),
      ),
    );
  }

  Widget _completionView(BuildContext context) {
    return Padding(
      key: const ValueKey('completed'),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.x48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CheckDraw(
            size: 48,
            color: context.colors.accent,
            trigger: _completed,
          ),
          const SizedBox(height: AppSpacing.x12),
          Text(
            '저장했어요',
            style: context.texts.heading.copyWith(color: context.colors.ink900),
          ),
        ],
      ),
    );
  }

  Widget _formView(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('form'),
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenPadding,
        AppSpacing.x8,
        AppSpacing.screenPadding,
        AppSpacing.x20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const _GrabBar(),
          const SizedBox(height: AppSpacing.x16),
          if (_mode == _EntryMode.stop)
            _stopBody(context)
          else ...[
            if (_mode == _EntryMode.create)
              _TypeSegment(
                value: _type,
                onChanged: (t) => setState(() => _type = t),
              ),
            SizedBox(height: _mode == _EntryMode.create ? AppSpacing.x20 : 0),
            AnimatedSwitcher(
              duration: context.reduceMotion ? Duration.zero : AppMotion.base,
              switchInCurve: AppMotion.enter,
              child: KeyedSubtree(
                key: ValueKey(_type),
                child: _typeForm(context),
              ),
            ),
            const SizedBox(height: AppSpacing.x24),
            _primaryAction(context),
            if (_mode == _EntryMode.edit) ...[
              const SizedBox(height: AppSpacing.x12),
              GhostButton(
                label: '삭제',
                icon: Icons.delete_outline_rounded,
                onPressed: _confirmDelete,
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _typeForm(BuildContext context) {
    switch (_type) {
      case TrackingType.feed:
        return _feedForm(context);
      case TrackingType.sleep:
        return _sleepForm(context);
      case TrackingType.diaper:
        return _diaperForm(context);
    }
  }

  // ── feed ─────────────────────────────────────────────────────────────
  Widget _feedForm(BuildContext context) {
    final isBreast = _feedSub == TrackingSubtype.breast;
    final showTimer = isBreast && _feedTimer && _mode == _EntryMode.create;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('방식'),
        _ChoiceChips<TrackingSubtype>(
          value: _feedSub,
          options: const [
            TrackingSubtype.breast,
            TrackingSubtype.formula,
            TrackingSubtype.solid,
          ],
          labelOf: subtypeLabel,
          onChanged: (v) => setState(() {
            _feedSub = v;
            if (v != TrackingSubtype.breast) _feedTimer = false;
          }),
        ),
        if (isBreast && _mode == _EntryMode.create) ...[
          const SizedBox(height: AppSpacing.x16),
          _FieldLabel('기록 방식'),
          _ChoiceChips<bool>(
            value: _feedTimer,
            options: const [true, false],
            labelOf: (v) => v ? '타이머' : '직접 입력',
            onChanged: (v) => setState(() => _feedTimer = v),
          ),
        ],
        if (isBreast && (showTimer || _feedTimer)) ...[
          const SizedBox(height: AppSpacing.x16),
          _FieldLabel('방향'),
          _ChoiceChips<String>(
            value: _breastSide ?? '왼쪽',
            options: const ['왼쪽', '오른쪽'],
            labelOf: (v) => v,
            onChanged: (v) => setState(() => _breastSide = v),
          ),
        ],
        if (!showTimer) ...[
          const SizedBox(height: AppSpacing.x16),
          _FieldLabel('양'),
          _AmountStepper(
            value: _amount,
            onChanged: (v) => setState(() => _amount = v),
          ),
        ],
        const SizedBox(height: AppSpacing.x16),
        _timeRow(context),
        const SizedBox(height: AppSpacing.x16),
        _noteField(context),
      ],
    );
  }

  // ── sleep ────────────────────────────────────────────────────────────
  Widget _sleepForm(BuildContext context) {
    final timer = _sleepTimer && _mode == _EntryMode.create;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_mode == _EntryMode.create) ...[
          _FieldLabel('기록 방식'),
          _ChoiceChips<bool>(
            value: _sleepTimer,
            options: const [true, false],
            labelOf: (v) => v ? '타이머' : '직접 입력',
            onChanged: (v) => setState(() => _sleepTimer = v),
          ),
          const SizedBox(height: AppSpacing.x16),
        ],
        if (!timer) ...[
          _timeRow(context, showEnd: true),
          const SizedBox(height: AppSpacing.x16),
        ],
        _noteField(context),
      ],
    );
  }

  // ── diaper ───────────────────────────────────────────────────────────
  Widget _diaperForm(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel('종류'),
        _ChoiceChips<TrackingSubtype>(
          value: _diaperSub,
          options: const [
            TrackingSubtype.pee,
            TrackingSubtype.poo,
            TrackingSubtype.mixed,
          ],
          labelOf: subtypeLabel,
          onChanged: (v) => setState(() => _diaperSub = v),
        ),
        const SizedBox(height: AppSpacing.x16),
        _timeRow(context),
        const SizedBox(height: AppSpacing.x16),
        _noteField(context),
      ],
    );
  }

  // ── stop(진행 중) ────────────────────────────────────────────────────
  Widget _stopBody(BuildContext context) {
    final log = widget.log!;
    final style = trackingTypeStyle(context, _type);
    final colors = context.colors;
    final isBreast = _type == TrackingType.feed;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(AppSpacing.cardPadding),
          decoration: BoxDecoration(
            color: style.wash,
            borderRadius: AppRadius.brMd,
          ),
          child: Row(
            children: [
              Icon(style.icon, size: 28, color: style.color),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${style.label} 진행 중',
                      style: context.texts.label.copyWith(color: colors.ink900),
                    ),
                    const SizedBox(height: AppSpacing.x2),
                    ElapsedTicker(
                      start: log.startedAt,
                      style: context.texts.data.copyWith(color: style.color),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        if (isBreast) ...[
          const SizedBox(height: AppSpacing.x16),
          _FieldLabel('양(선택)'),
          _AmountStepper(
            value: _amount,
            onChanged: (v) => setState(() => _amount = v),
          ),
        ],
        const SizedBox(height: AppSpacing.x16),
        _noteField(context),
        const SizedBox(height: AppSpacing.x24),
        PrimaryButton(
          label: _type == TrackingType.sleep ? '깼어요' : '수유 종료',
          icon: Icons.check_rounded,
          loading: _saving,
          onPressed: _stopTimer,
        ),
        const SizedBox(height: AppSpacing.x12),
        GhostButton(
          label: '기록 삭제',
          icon: Icons.delete_outline_rounded,
          onPressed: _confirmDelete,
        ),
      ],
    );
  }

  // ── 공통 액션 버튼 ─────────────────────────────────────────────────────
  Widget _primaryAction(BuildContext context) {
    if (_mode == _EntryMode.edit) {
      return PrimaryButton(
        label: '저장',
        loading: _saving,
        onPressed: _saveCompleted,
      );
    }
    // create
    if (_type == TrackingType.sleep && _sleepTimer) {
      return PrimaryButton(
        label: '잠들었어요',
        icon: Icons.nightlight_round,
        loading: _saving,
        onPressed: _startTimer,
      );
    }
    if (_type == TrackingType.feed &&
        _feedSub == TrackingSubtype.breast &&
        _feedTimer) {
      return PrimaryButton(
        label: '수유 시작',
        icon: Icons.play_arrow_rounded,
        loading: _saving,
        onPressed: _startTimer,
      );
    }
    return PrimaryButton(
      label: '저장',
      loading: _saving,
      onPressed: _saveCompleted,
    );
  }

  // ── 공통 필드 ─────────────────────────────────────────────────────────
  Widget _timeRow(BuildContext context, {bool showEnd = false}) {
    return Row(
      children: [
        Expanded(
          child: _TimeField(
            label: showEnd ? '시작' : '시간',
            value: formatClock(_startedAt),
            onTap: () => _pickTime(isEnd: false),
          ),
        ),
        if (showEnd) ...[
          const SizedBox(width: AppSpacing.x12),
          Expanded(
            child: _TimeField(
              label: '종료',
              value: formatClock(_endedAt ?? _startedAt),
              onTap: () => _pickTime(isEnd: true),
            ),
          ),
        ],
      ],
    );
  }

  Widget _noteField(BuildContext context) {
    final colors = context.colors;
    return TextField(
      controller: _note,
      style: context.texts.bodyL.copyWith(color: colors.ink900),
      cursorColor: colors.accent,
      minLines: 1,
      maxLines: 3,
      decoration: const InputDecoration(hintText: '메모 (선택)'),
    );
  }
}

// ── 하위 위젯 ────────────────────────────────────────────────────────────

class _GrabBar extends StatelessWidget {
  const _GrabBar();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 32,
        height: 4,
        decoration: BoxDecoration(
          color: context.colors.line,
          borderRadius: AppRadius.brFull,
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.x8),
      child: Text(
        text,
        style: context.texts.caption.copyWith(color: context.colors.ink500),
      ),
    );
  }
}

/// §11.11 타입 세그먼트(수유/수면/기저귀) — 슬라이딩 인디케이터 + selectionClick.
class _TypeSegment extends StatelessWidget {
  const _TypeSegment({required this.value, required this.onChanged});

  final TrackingType value;
  final ValueChanged<TrackingType> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    const options = TrackingType.values;
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth / options.length;
        final index = options.indexOf(value);
        return Container(
          height: 44,
          padding: const EdgeInsets.all(AppSpacing.x4),
          decoration: BoxDecoration(
            color: colors.accentWash,
            borderRadius: AppRadius.brSm,
          ),
          child: Stack(
            children: [
              AnimatedAlign(
                duration: context.reduceMotion ? Duration.zero : AppMotion.base,
                curve: AppMotion.spring,
                alignment: Alignment(
                  -1 + (index / (options.length - 1)) * 2,
                  0,
                ),
                child: Container(
                  width: w - AppSpacing.x8,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.accent,
                    borderRadius: AppRadius.brXs,
                    boxShadow: context.shadows.e1,
                  ),
                ),
              ),
              Row(
                children: [
                  for (final t in options)
                    Expanded(
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {
                          if (t == value) return;
                          AppHaptics.toggle();
                          onChanged(t);
                        },
                        child: Center(
                          child: Text(
                            trackingTypeLabel(t),
                            style: context.texts.label.copyWith(
                              color: t == value
                                  ? colors.paperRaised
                                  : colors.ink700,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

/// §11.11 칩 선택(방식/방향/종류/모드) — 배경 색 트윈 + 미세 스케일 + selectionClick.
class _ChoiceChips<T> extends StatelessWidget {
  const _ChoiceChips({
    required this.value,
    required this.options,
    required this.labelOf,
    required this.onChanged,
    super.key,
  });

  final T value;
  final List<T> options;
  final String Function(T) labelOf;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.x8,
      runSpacing: AppSpacing.x8,
      children: [
        for (final option in options)
          _Chip(
            label: labelOf(option),
            selected: option == value,
            onTap: () {
              if (option == value) return;
              AppHaptics.toggle();
              onChanged(option);
            },
          ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final reduce = context.reduceMotion;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: AnimatedScale(
        scale: (!reduce && selected) ? 1.04 : 1,
        duration: AppMotion.fast,
        curve: AppMotion.spring,
        child: AnimatedContainer(
          duration: reduce ? Duration.zero : AppMotion.fast,
          curve: AppMotion.standard,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.x16,
            vertical: AppSpacing.x8,
          ),
          decoration: BoxDecoration(
            color: selected ? colors.accentWash : colors.paperCard,
            borderRadius: AppRadius.brFull,
            border: Border.all(color: selected ? colors.accent : colors.line),
          ),
          child: Text(
            label,
            style: context.texts.label.copyWith(
              color: selected ? colors.accentDeep : colors.ink700,
            ),
          ),
        ),
      ),
    );
  }
}

/// §11.11 양(ml) 스텝퍼 — 값 트윈 + selectionClick.
class _AmountStepper extends StatelessWidget {
  const _AmountStepper({required this.value, required this.onChanged});

  final double value;
  final ValueChanged<double> onChanged;

  static const double step = 10;

  void _bump(double delta) {
    final next = (value + delta).clamp(0, 1000).toDouble();
    if (next == value) return;
    AppHaptics.toggle();
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      height: 52,
      decoration: BoxDecoration(
        color: colors.paperCard,
        borderRadius: AppRadius.brSm,
        border: Border.all(color: colors.line),
      ),
      child: Row(
        children: [
          _StepButton(icon: Icons.remove_rounded, onTap: () => _bump(-step)),
          Expanded(
            child: Center(
              child: NumberTicker(
                value: value,
                suffix: 'ml',
                style: context.texts.data.copyWith(
                  color: colors.ink900,
                  fontSize: 18,
                ),
              ),
            ),
          ),
          _StepButton(icon: Icons.add_rounded, onTap: () => _bump(step)),
        ],
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 52,
        height: 52,
        child: Icon(icon, size: 22, color: context.colors.accent),
      ),
    );
  }
}

class _TimeField extends StatelessWidget {
  const _TimeField({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
        decoration: BoxDecoration(
          color: colors.paperCard,
          borderRadius: AppRadius.brSm,
          border: Border.all(color: colors.line),
        ),
        child: Row(
          children: [
            Icon(Icons.schedule_rounded, size: 18, color: colors.ink500),
            const SizedBox(width: AppSpacing.x8),
            Text(
              label,
              style: context.texts.caption.copyWith(color: colors.ink500),
            ),
            const Spacer(),
            Text(
              value,
              style: context.texts.data.copyWith(color: colors.ink900),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeleteDialog extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AlertDialog(
      backgroundColor: colors.paperRaised,
      title: Text(
        '기록을 삭제할까요?',
        style: context.texts.heading.copyWith(color: colors.ink900),
      ),
      content: Text(
        '삭제한 기록은 되돌릴 수 없어요.',
        style: context.texts.body.copyWith(color: colors.ink500),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(
            '취소',
            style: context.texts.label.copyWith(color: colors.ink500),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            '삭제',
            style: context.texts.label.copyWith(color: colors.coral),
          ),
        ),
      ],
    );
  }
}
