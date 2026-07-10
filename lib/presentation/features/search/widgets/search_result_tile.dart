import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/widgets/animated/ink_wash_splash.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';

import '../search_highlight.dart';

/// §11.8 검색 결과 항목. 좌측 아이콘 원(40, DESIGN v2 §7.2-2 `SymptomTone` 카테고리
/// 색 매핑) + 매칭 하이라이트된 증상명. 카드화하지 않고 행 사이 inset 헤어라인
/// (좌 [dividerIndent] 72dp, 소비처가 그린다)으로만 리듬을 준다.
/// 탭 → 증상 상세(라이트 햅틱 + 잉크 워시 리플).
class SearchResultTile extends StatelessWidget {
  const SearchResultTile({
    required this.symptom,
    required this.query,
    required this.onTap,
    super.key,
  });

  final Symptom symptom;
  final String query;
  final VoidCallback onTap;

  static const double _iconSize = 40;

  /// DESIGN v2 §7.2-2 — 행 사이 inset 헤어라인 디바이더의 좌측 들여쓰기(아이콘
  /// 폭 40 + 좌 패딩 20 + 아이콘-텍스트 간격 12 = 72). 소비처(`search_screen.dart`)가
  /// `Divider(indent: dividerIndent)`로 소비한다.
  static const double dividerIndent = AppSpacing.screenPadding + _iconSize + 12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Material(
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
              _IconCircle(symptom: symptom),
              const SizedBox(width: AppSpacing.x12),
              Expanded(
                child: HighlightedName(
                  name: symptom.name,
                  query: query,
                  baseStyle: context.texts.heading.copyWith(
                    color: colors.ink900,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.x8),
              Icon(Icons.chevron_right_rounded, size: 20, color: colors.ink300),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconCircle extends StatelessWidget {
  const _IconCircle({required this.symptom});

  final Symptom symptom;

  @override
  Widget build(BuildContext context) {
    final tone = SymptomTone.resolve(context, symptom.emojiOrIcon);
    return Container(
      width: SearchResultTile._iconSize,
      height: SearchResultTile._iconSize,
      decoration: BoxDecoration(color: tone.wash, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Icon(
        SymptomIcons.resolve(symptom.emojiOrIcon),
        size: 20,
        color: tone.fg,
      ),
    );
  }
}
