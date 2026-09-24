import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// 섹션 리듬 통일 컴포넌트(DESIGN v2 §4.3 → v3 §5.4). 기존 "텍스트 한 줄 섹션
/// 제목"을 전부 대체한다.
///
/// ```
/// [overline?]                      ← overline, ink500, 밑 4dp
/// ● 섹션 제목            [trailing?]  ← 딸기 동그라미 점(8, accent) + 주아체 heading(ink900)
/// ```
///
/// v2의 먹선 틱(3×16)은 v3에서 **accent 동그라미 점(8dp)**으로 바뀌었다 — 수묵
/// 은유를 걷어내고 동글동글한 리듬만 남긴다.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    required this.title,
    super.key,
    this.overline,
    this.trailing,
  });

  final String title;

  /// 제목 위 소형 라벨(날짜·구분 등). 주아체가 아닌 sans overline 서체(§6.3).
  final String? overline;

  /// 개수·"더보기" 액션 등 자유 슬롯.
  final Widget? trailing;

  /// 제목 앞 동그라미 점 지름(DESIGN v3 §5.4).
  static const double _dot = 8;

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
              width: _dot,
              height: _dot,
              decoration: BoxDecoration(
                color: colors.accent,
                shape: BoxShape.circle,
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
