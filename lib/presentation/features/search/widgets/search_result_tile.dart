import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/widgets/animated/ink_wash_splash.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:flutter/material.dart';

import '../search_highlight.dart';

/// §11.8 검색 결과 항목. 좌측 아이콘 원(40, accent.wash) + 매칭 하이라이트된 증상명.
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
    final colors = context.colors;
    return Container(
      width: SearchResultTile._iconSize,
      height: SearchResultTile._iconSize,
      decoration: BoxDecoration(
        color: colors.accentWash,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Icon(
        SymptomIcons.resolve(symptom.emojiOrIcon),
        size: 20,
        color: colors.accent,
      ),
    );
  }
}
