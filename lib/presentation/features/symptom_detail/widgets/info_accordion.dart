import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/features/symptom_detail/widgets/detail_clay.dart';
import 'package:agawaeuleo/presentation/widgets/animated/scroll_reveal.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';

/// §11.9-4 정보 섹션 아코디언 리스트.
///
/// DESIGN v3 "몽글 클레이" — 둥근 카드 + 파스텔 아이콘 버블 + 동그란 셰브론 버블,
/// 타입별 본문도 말랑하게(번호 동그라미·동그란 체크·버터 메모·둥근 표).
///
/// 각 섹션은 heading(주아체) + 타입별 본문([InfoSection] 유니온 — text/steps/
/// checklist/table/qa/tips). 펼침/접힘 높이 트윈 260ms(§11.9). 첫 섹션은 기본 펼침.
///
/// 진입 모션은 빌드 시점이 아니라 **화면에 들어오는 순간** 재생한다([ScrollReveal]
/// — 계단 60ms·상한 2단). 케어 노트는 옆 장을 미리 빌드하므로 빌드 시점 stagger는
/// 사용자가 그 장에 도착하기 전에 끝나 버린다(대기 장은 [RevealGate]가 붙잡는다).
class InfoAccordionList extends StatelessWidget {
  const InfoAccordionList({required this.sections, super.key});

  final List<InfoSection> sections;

  @override
  Widget build(BuildContext context) {
    final step = AppMotion.fast ~/ 3;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, section) in sections.indexed)
          Padding(
            padding: EdgeInsets.only(
              bottom: index == sections.length - 1 ? 0 : AppSpacing.x12,
            ),
            child: ScrollReveal(
              delay: step * index.clamp(0, 2),
              child: _InfoAccordion(
                section: section,
                initiallyExpanded: index == 0,
              ),
            ),
          ),
      ],
    );
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
    // §7.3-3: 펼침 시 아이콘·제목 색 ink700→accent 트윈(fast). v3: 아이콘 버블 면도
    // 크림(paperStack)→딸기 워시로 함께 물든다.
    final tweenColor = _expanded ? colors.accent : colors.ink700;
    final tweenWash = _expanded ? colors.accentWash : colors.paperStack;
    final duration = AppMotion.resolve(context, AppMotion.fast);
    final curve = AppMotion.resolveCurve(context, AppMotion.standard);

    // 머리 줄은 누르는 자리 48을 확보하고, 그만큼 카드 위아래 여백을 줄여
    // 접힌 높이는 그대로 둔다.
    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.cardPadding,
        vertical: AppSpacing.x8 + AppSpacing.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48),
              child: Row(
                children: [
                  TweenAnimationBuilder<Color?>(
                    tween: ColorTween(begin: colors.paperStack, end: tweenWash),
                    duration: duration,
                    curve: curve,
                    builder: (context, wash, _) =>
                        TweenAnimationBuilder<Color?>(
                          tween: ColorTween(
                            begin: colors.ink700,
                            end: tweenColor,
                          ),
                          duration: duration,
                          curve: curve,
                          builder: (context, color, _) => ClayBubble(
                            size: 36,
                            wash: wash ?? tweenWash,
                            icon: _sectionIcon,
                            iconColor: color,
                            iconSize: 19,
                          ),
                        ),
                  ),
                  const SizedBox(width: AppSpacing.x12),
                  Expanded(
                    child: AnimatedDefaultTextStyle(
                      duration: duration,
                      curve: curve,
                      style: texts.heading.copyWith(color: tweenColor),
                      child: Text(widget.section.title),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.x8),
                  // 동그란 셰브론 버블 — 펼치면 딸기 워시로 물들며 뒤집힌다.
                  AnimatedContainer(
                    duration: duration,
                    curve: curve,
                    width: 30,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: tweenWash,
                      shape: BoxShape.circle,
                    ),
                    child: AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: AppMotion.resolve(context, AppMotion.base),
                      curve: AppMotion.enter,
                      child: Icon(
                        Icons.expand_more_rounded,
                        size: 22,
                        color: _expanded ? colors.accent : colors.ink500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          ClipRect(
            child: AnimatedSize(
              duration: AppMotion.resolve(context, AppMotion.base),
              curve: AppMotion.enter,
              alignment: Alignment.topCenter,
              child: _expanded
                  ? Padding(
                      padding: const EdgeInsets.only(
                        top: AppSpacing.x8,
                        bottom: AppSpacing.x8,
                      ),
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

/// steps — 파스텔 번호 동그라미(26dp, 딸기 워시 + 광택 + 주아체 숫자) + 본문 행.
/// intro가 있으면 리스트 위에 문단으로 얹는다.
class _StepsBody extends StatelessWidget {
  const _StepsBody({required this.items, this.intro});

  final String? intro;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final digit = colors.accent;
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
                ClayBubble(
                  size: 26,
                  wash: colors.accentWash,
                  child: ClayNumber('${index + 1}', color: digit),
                ),
                const SizedBox(width: AppSpacing.x12),
                Expanded(
                  child: Padding(
                    // 숫자 동그라미 가운데에 첫 줄이 오도록.
                    padding: const EdgeInsets.only(top: AppSpacing.x2),
                    child: _BodyText(item),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// checklist — 동그란 민트 체크(22dp 워시 원 + 체크) + 본문 리스트.
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
                  child: ClayBubble(
                    size: 22,
                    wash: colors.sageWash,
                    icon: Icons.check_rounded,
                    iconColor: colors.sage,
                    iconSize: 15,
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

/// table — 둥근 표(바깥 lineStrong 1.5 + 안쪽 line 헤어라인, 크림 머리 행).
/// 머리 행 overline(ink700), 셀 body(ink700). 표가 카드 폭을 넘으면 표 자신이
/// **가로 스크롤**된다(화면 가로 오버플로 절대 금지). caption은 표 아래 caption(ink500).
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

    TableRow buildRow(
      List<String> cells,
      TextStyle style, {
      Decoration? decoration,
    }) => TableRow(
      decoration: decoration,
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
          // 테두리는 전경으로 덧그린다 — 배경 테두리면 크림 머리 행이 둥근
          // 모서리의 선을 덮는다.
          child: Container(
            decoration: const BoxDecoration(borderRadius: AppRadius.brMd),
            foregroundDecoration: BoxDecoration(
              borderRadius: AppRadius.brMd,
              border: Border.all(color: colors.lineStrong, width: 1.5),
            ),
            clipBehavior: Clip.antiAlias,
            child: Table(
              defaultColumnWidth: const IntrinsicColumnWidth(),
              defaultVerticalAlignment: TableCellVerticalAlignment.middle,
              border: TableBorder.symmetric(
                inside: BorderSide(color: colors.line),
              ),
              children: [
                buildRow(
                  columns,
                  texts.overline.copyWith(color: colors.ink700),
                  decoration: BoxDecoration(color: colors.paperStack),
                ),
                for (final row in rows)
                  buildRow(row, texts.body.copyWith(color: colors.ink700)),
              ],
            ),
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

/// qa — 주아체 Q/A 동그라미 + 질문(body 볼드, ink900) / 답(body, ink700) 쌍.
/// 항목 사이는 헤어라인 대신 여백으로 숨을 둔다.
class _QaBody extends StatelessWidget {
  const _QaBody({required this.items});

  final List<QaItem> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    Widget mark(String letter, Color wash, Color fg) => ExcludeSemantics(
      child: ClayBubble(
        size: 24,
        wash: wash,
        child: ClayNumber(letter, color: fg, size: 13),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (index, item) in items.indexed) ...[
          if (index > 0) const SizedBox(height: AppSpacing.x16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mark('Q', colors.accentWash, colors.accent),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x2),
                  child: Text(
                    item.q,
                    style: texts.body.copyWith(
                      color: colors.ink900,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.x8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              mark('A', colors.sageWash, colors.sage),
              const SizedBox(width: AppSpacing.x8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.x2),
                  child: _BodyText(item.a),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// tips — 버터(amberWash) 메모 안 동그란 점 불릿 리스트('조리원 실전 팁' 시그니처).
/// 흰 스티커 테두리 + e1로 카드 위에 살짝 붙인 쪽지처럼.
class _TipsBody extends StatelessWidget {
  const _TipsBody({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.x16,
        AppSpacing.x12,
        AppSpacing.x16,
        AppSpacing.x12,
      ),
      decoration: BoxDecoration(
        color: colors.amberWash,
        borderRadius: AppRadius.brMd,
        border: Border.all(color: colors.paperRaised, width: 2),
        boxShadow: context.shadows.e1,
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
                    padding: const EdgeInsets.only(top: 7),
                    child: Icon(
                      Icons.fiber_manual_record,
                      size: 8,
                      color: colors.amber,
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
