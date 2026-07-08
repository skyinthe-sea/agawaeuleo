import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/widgets/animated/tap_spring.dart';
import 'package:flutter/material.dart';

/// §11.7 (선택) 최근 본 증상 가로 스크롤 칩.
///
/// 칩 높이 36 · r.full · 배경 `accent.wash` · 텍스트 `accent`. 탭 시 [onTap]으로
/// 해당 증상 상세로 이동한다.
class RecentSymptomChips extends StatelessWidget {
  const RecentSymptomChips({
    required this.symptoms,
    required this.onTap,
    super.key,
  });

  /// 최신순으로 정렬된 최근 본 증상 목록.
  final List<Symptom> symptoms;
  final ValueChanged<Symptom> onTap;

  @override
  Widget build(BuildContext context) {
    if (symptoms.isEmpty) return const SizedBox.shrink();
    final colors = context.colors;

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenPadding,
        ),
        itemCount: symptoms.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpacing.x8),
        itemBuilder: (context, index) {
          final symptom = symptoms[index];
          return TapSpring(
            onTap: () => onTap(symptom),
            child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.x16),
              decoration: BoxDecoration(
                color: colors.accentWash,
                borderRadius: AppRadius.brFull,
              ),
              child: Text(
                symptom.name,
                style: context.texts.caption.copyWith(color: colors.accent),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          );
        },
      ),
    );
  }
}
