import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// §11.9-4 정보 섹션 아코디언 리스트.
///
/// 각 섹션은 heading 18 + 타입별 본문([InfoSection] 유니온 — text/steps/
/// checklist/table/qa/tips). 펼침/접힘 높이 트윈 260ms(§11.9), 진입 stagger
/// fadeIn(§10.2). 첫 섹션은 기본 펼침.
class InfoAccordionList extends StatelessWidget {
  const InfoAccordionList({required this.sections, super.key});

  final List<InfoSection> sections;

  @override
  Widget build(BuildContext context) {
    final reduce = context.reduceMotion;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, section) in sections.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == sections.length - 1 ? 0 : AppSpacing.x12,
            ),
            child: _staggered(
              context,
              reduce: reduce,
              index: index,
              child: _InfoAccordion(
                section: section,
                initiallyExpanded: index == 0,
              ),
            ),
          ),
      ],
    );
  }

  Widget _staggered(
    BuildContext context, {
    required bool reduce,
    required int index,
    required Widget child,
  }) {
    if (reduce) return child;
    return child
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 60 * index),
          duration: AppMotion.base,
          curve: AppMotion.enter,
        )
        .slideY(begin: 0.06, end: 0, curve: AppMotion.enter);
  }
}

class _InfoAccordion extends StatefulWidget {
  const _InfoAccordion({
    required this.section,
    required this.initiallyExpanded,
  });

  final InfoSection section;
  final bool initiallyExpanded;

  @override
  State<_InfoAccordion> createState() => _InfoAccordionState();
}

class _InfoAccordionState extends State<_InfoAccordion> {
  late bool _expanded = widget.initiallyExpanded;

  void _toggle() {
    AppHaptics.toggle();
    setState(() => _expanded = !_expanded);
  }

  /// DESIGN v2 §7.3-3 — 섹션 성격별 라인 아이콘(20dp). **타입 우선** 매핑,
  /// text는 기존 제목 키워드 규칙("원인"·"주의점"·"집에서 돌보기")을 유지하고
  /// 그 외 제목은 일반 라인 아이콘으로 폴백한다.
  IconData get _sectionIcon => switch (widget.section) {
    InfoSectionSteps() => Icons.format_list_numbered_rounded,
    InfoSectionChecklist() => Icons.checklist_rounded,
    InfoSectionTable() => Icons.table_chart_outlined,
    InfoSectionQa() => Icons.forum_outlined,
    InfoSectionTips() => Icons.lightbulb_outline,
    InfoSectionText(:final title) => _textIcon(title),
  };

  static IconData _textIcon(String title) {
    if (title.contains('원인')) return Icons.help_outline;
    if (title.contains('주의') || title.contains('병원')) {
      return Icons.error_outline;
    }
    if (title.contains('돌보기') || title.contains('관리')) {
      return Icons.spa_outlined;
    }
    return Icons.article_outlined;
  }

  /// 타입별 본문 렌더러 (§11.9 개정 — InfoSection 유니온).
  Widget _sectionBody(BuildContext context) => switch (widget.section) {
    InfoSectionText(:final body) => _BodyText(body),
    InfoSectionSteps(:final intro, :final items) => _StepsBody(
      intro: intro,
      items: items,
    ),
    InfoSectionChecklist(:final intro, :final items) => _ChecklistBody(
      intro: intro,
      items: items,
    ),
    InfoSectionTable(:final columns, :final rows, :final caption) => _TableBody(
      columns: columns,
      rows: rows,
      caption: caption,
    ),
    InfoSectionQa(:final items) => _QaBody(items: items),
    InfoSectionTips(:final items) => _TipsBody(items: items),
  };

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    // §7.3-3: 펼침 시 아이콘·제목 색 ink700→accent 트윈(fast).
    final tweenColor = _expanded ? colors.accent : colors.ink700;
    final duration = AppMotion.resolve(context, AppMotion.fast);
    final curve = AppMotion.resolveCurve(context, AppMotion.standard);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Row(
              children: [
                TweenAnimationBuilder<Color?>(
                  tween: ColorTween(begin: colors.ink700, end: tweenColor),
                  duration: duration,
                  curve: curve,
                  builder: (context, color, _) =>
                      Icon(_sectionIcon, size: 20, color: color),
                ),
                const SizedBox(width: AppSpacing.iconTextGap),
                Expanded(
                  child: AnimatedDefaultTextStyle(
                    duration: duration,
                    curve: curve,
                    style: texts.heading.copyWith(color: tweenColor),
                    child: Text(widget.section.title),
                  ),
                ),
                AnimatedRotation(
                  turns: _expanded ? 0.5 : 0,
                  duration: AppMotion.resolve(context, AppMotion.base),
                  curve: AppMotion.enter,
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 24,
                    color: colors.ink500,
                  ),
                ),
              ],
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: AppMotion.resolve(context, AppMotion.base),
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.x8),
                      child: _sectionBody(context),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}

/// 본문 기본 문단(text 본문·intro 공용) — body(ink700).
class _BodyText extends StatelessWidget {
  const _BodyText(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: context.texts.body.copyWith(color: context.colors.ink700),
    );
  }
}

/// steps — 번호 원형 칩(24dp, accentWash 배경 + accent 숫자) + 본문 행.
/// intro가 있으면 리스트 위에 문단으로 얹는다.
class _StepsBody extends StatelessWidget {
  const _StepsBody({required this.items, this.intro});

  final String? intro;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (intro != null) ...[
          _BodyText(intro!),
          const SizedBox(height: AppSpacing.x12),
        ],
        for (final (index, item) in items.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : AppSpacing.listItemGap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.accentWash,
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${index + 1}',
                    style: texts.caption.copyWith(
                      color: colors.accent,
                      height: 1,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(child: _BodyText(item)),
              ],
            ),
          ),
      ],
    );
  }
}

/// checklist — 체크 라인 아이콘(accent) + 본문 리스트.
class _ChecklistBody extends StatelessWidget {
  const _ChecklistBody({required this.items, this.intro});

  final String? intro;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (intro != null) ...[
          _BodyText(intro!),
          const SizedBox(height: AppSpacing.x12),
        ],
        for (final (index, item) in items.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == items.length - 1 ? 0 : AppSpacing.listItemGap,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x2),
                  child: Icon(
                    Icons.check_rounded,
                    size: 18,
                    color: colors.accent,
                  ),
                ),
                const SizedBox(width: AppSpacing.iconTextGap),
                Expanded(child: _BodyText(item)),
              ],
            ),
          ),
      ],
    );
  }
}

/// table — 헤어라인(line) 보더 표. 헤더 행 overline(ink500), 셀 body(ink700).
/// 표가 카드 폭을 넘으면 표 자신이 **가로 스크롤**된다(화면 가로 오버플로
/// 절대 금지). caption은 표 아래 caption(ink500).
class _TableBody extends StatelessWidget {
  const _TableBody({required this.columns, required this.rows, this.caption});

  final List<String> columns;
  final List<List<String>> rows;
  final String? caption;

  /// 셀 한 칸의 최대 폭 — 문장형 셀은 이 폭에서 줄바꿈되어 표 전체가 화면
  /// 폭의 몇 배로 늘어나는 것을 막는다(IntrinsicColumnWidth의 상한 역할).
  /// 짧은 셀은 여전히 내용 폭만 차지하고, 열이 많아 카드 폭을 넘으면 표
  /// 자신이 가로 스크롤된다.
  static const double _cellMaxWidth = 220;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    TableRow buildRow(List<String> cells, TextStyle style) => TableRow(
      children: [
        for (var i = 0; i < columns.length; i++)
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.x12,
              vertical: AppSpacing.x8,
            ),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _cellMaxWidth),
              child: Text(i < cells.length ? cells[i] : '', style: style),
            ),
          ),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Table(
            defaultColumnWidth: const IntrinsicColumnWidth(),
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            border: TableBorder.all(
              color: colors.line,
              borderRadius: AppRadius.brXs,
            ),
            children: [
              buildRow(columns, texts.overline.copyWith(color: colors.ink500)),
              for (final row in rows)
                buildRow(row, texts.body.copyWith(color: colors.ink700)),
            ],
          ),
        ),
        if (caption != null) ...[
          const SizedBox(height: AppSpacing.x8),
          Text(caption!, style: texts.caption.copyWith(color: colors.ink500)),
        ],
      ],
    );
  }
}

/// qa — Q(body 볼드, ink900) / A(body, ink700) 쌍. 항목 사이 헤어라인.
class _QaBody extends StatelessWidget {
  const _QaBody({required this.items});

  final List<QaItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.x12),
              child: ColoredBox(
                color: colors.line,
                child: const SizedBox(height: 1, width: double.infinity),
              ),
            ),
          Text(
            item.q,
            style: texts.body.copyWith(
              color: colors.ink900,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.x4),
          _BodyText(item.a),
        ],
      ],
    );
  }
}

/// tips — accentWash 라운드 박스 안 잉크 도트 불릿 리스트
/// ('조리원 실전 팁' 시그니처).
class _TipsBody extends StatelessWidget {
  const _TipsBody({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.x12),
      decoration: BoxDecoration(
        color: colors.accentWash,
        borderRadius: AppRadius.brSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (index, item) in items.indexed)
            Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : AppSpacing.listItemGap,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.fiber_manual_record,
                      size: 6,
                      color: colors.accent,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.iconTextGap),
                  Expanded(child: _BodyText(item)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
