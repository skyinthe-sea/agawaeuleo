import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// DESIGN v2 §4.3 섹션 리듬 통일 컴포넌트. 기존 "텍스트 한 줄 섹션 제목"을
/// 전부 대체한다.
///
/// ```
/// [overline?]                      ← overline, ink500, 밑 4dp
/// ▍ 섹션 제목            [trailing?]  ← 잉크 틱(3×16, accent) + heading(ink900)
/// ```
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.overline,
    this.trailing,
  });

  final String title;

  /// 제목 위 소형 라벨(날짜·구분 등). 명조가 아닌 sans overline 서체(§6.3).
  final String? overline;

  /// 개수·"더보기" 액션 등 자유 슬롯.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (overline != null) ...[
          Text(overline!, style: texts.overline.copyWith(color: colors.ink500)),
          const SizedBox(height: AppSpacing.x4),
        ],
        Row(
          children: [
            Container(
              width: 3,
              height: 16,
              decoration: BoxDecoration(
                color: colors.accent,
                borderRadius: BorderRadius.circular(1.5),
              ),
            ),
            const SizedBox(width: AppSpacing.iconTextGap),
            Expanded(
              child: Text(
                title,
                style: texts.heading.copyWith(color: colors.ink900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            ?trailing,
          ],
        ),
      ],
    );
  }
}
