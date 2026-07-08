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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: _toggle,
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    widget.section.title,
                    style: texts.heading.copyWith(color: colors.ink900),
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
