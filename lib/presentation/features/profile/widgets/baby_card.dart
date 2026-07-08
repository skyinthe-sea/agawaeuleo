import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../config/theme/theme.dart';
import '../../../../domain/entities/baby.dart';
import '../../../widgets/cards/app_card.dart';
import '../baby_format.dart';

/// §11.14 아기 프로필 카드 한 장. 이름 · 생년월일 · 개월수 배지.
/// 목록 진입 시 stagger(카드 순번 × 40ms 지연) fadeIn+slideY, 개월수 배지는 페이드인.
class BabyCard extends StatelessWidget {
  const BabyCard({
    required this.baby,
    required this.onTap,
    this.index = 0,
    super.key,
  });

  final Baby baby;
  final VoidCallback onTap;

  /// 목록 내 순번(stagger 지연 계산용).
  final int index;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final reduce = context.reduceMotion;

    Widget card = AppCard(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: colors.accentWash,
              shape: BoxShape.circle,
            ),
            child: Icon(
              switch (baby.gender) {
                BabyGender.male => Icons.male_rounded,
                BabyGender.female => Icons.female_rounded,
                BabyGender.na => Icons.child_care_rounded,
              },
              size: 26,
              color: colors.accent,
            ),
          ),
          const SizedBox(width: AppSpacing.x16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  baby.name,
                  style: texts.heading.copyWith(color: colors.ink900),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.x2),
                Text(
                  baby.birthDate == null
                      ? '생년월일 미입력'
                      : formatBirthDate(baby.birthDate!),
                  style: texts.caption.copyWith(color: colors.ink500),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.x8),
          _AgeBadge(ageInMonths: baby.ageInMonths),
          const SizedBox(width: AppSpacing.x4),
          Icon(Icons.chevron_right_rounded, size: 20, color: colors.ink300),
        ],
      ),
    );

    if (!reduce) {
      card = card
          .animate(delay: Duration(milliseconds: 40 * index))
          .fadeIn(duration: AppMotion.base, curve: AppMotion.enter)
          .slideY(begin: 0.08, end: 0, curve: AppMotion.enter);
    }
    return card;
  }
}

class _AgeBadge extends StatelessWidget {
  const _AgeBadge({required this.ageInMonths});

  final int? ageInMonths;

  @override
  Widget build(BuildContext context) {
    if (ageInMonths == null) return const SizedBox.shrink();
    final colors = context.colors;
    final texts = context.texts;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x4,
      ),
      decoration: BoxDecoration(
        color: colors.sageWash,
        borderRadius: AppRadius.brFull,
      ),
      child: Text(
        formatAgeBadge(ageInMonths),
        style: texts.caption.copyWith(color: colors.sage),
      ),
    ).animate().fadeIn(duration: AppMotion.base, curve: AppMotion.enter);
  }
}
