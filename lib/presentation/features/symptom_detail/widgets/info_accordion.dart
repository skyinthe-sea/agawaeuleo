import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// §11.9-4 정보 섹션 아코디언 리스트.
///
/// 각 섹션은 heading 18 + body. 펼침/접힘 높이 트윈 260ms(§11.9), 진입 stagger
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

  /// DESIGN v2 §7.3-3 — 섹션 성격별 라인 아이콘(20dp). 픽스처 3종 제목
  /// ("원인"·"주의점"·"집에서 돌보기")에 매핑하고, 그 외 제목은 일반 라인
  /// 아이콘으로 폴백한다.
  IconData get _sectionIcon {
    final title = widget.section.title;
    if (title.contains('원인')) return Icons.help_outline;
    if (title.contains('주의') || title.contains('병원')) {
      return Icons.error_outline;
    }
    if (title.contains('돌보기') || title.contains('관리')) {
      return Icons.spa_outlined;
    }
    return Icons.article_outlined;
  }

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
                      child: Text(
                        widget.section.body,
                        style: texts.body.copyWith(color: colors.ink700),
                      ),
                    )
                  : const SizedBox(width: double.infinity),
            ),
          ),
        ],
      ),
    );
  }
}
