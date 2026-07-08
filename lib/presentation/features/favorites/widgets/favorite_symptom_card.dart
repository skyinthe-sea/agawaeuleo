import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../domain/entities/symptom.dart';
import '../../../widgets/animated/sparkle.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/symptom/symptom_icon.dart';

/// §11.15 즐겨찾기 "증상" 그리드 카드 — 홈(§11.7)과 동일한 카드 형태
/// (2열, 카드 간격 12, radius `r.md`, e1, 아이콘 40×40 원 + 증상명 heading 18,
/// 카드 높이 ~120)에 우측 상단 별 오버레이를 더해 해제(unfavorite)를 지원한다.
///
/// [collapsing]이 true면 scale-down + fadeOut(§11.15 해제 애니메이션)으로
/// 축소되고, 실제 목록 제거는 호출부(지연 후 저장소 반영)가 담당한다.
class FavoriteSymptomCard extends StatelessWidget {
  const FavoriteSymptomCard({
    required this.symptom,
    required this.collapsing,
    required this.onTap,
    required this.onUnfavorite,
    super.key,
  });

  final Symptom symptom;
  final bool collapsing;
  final VoidCallback onTap;
  final VoidCallback onUnfavorite;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final texts = context.texts;
    final duration = AppMotion.resolve(context, AppMotion.base);

    return AnimatedOpacity(
      opacity: collapsing ? 0 : 1,
      duration: duration,
      curve: AppMotion.exit,
      child: AnimatedScale(
        scale: collapsing ? 0.82 : 1,
        duration: duration,
        curve: AppMotion.exit,
        child: IgnorePointer(
          ignoring: collapsing,
          child: Stack(
            children: [
              SizedBox(
                height: 120,
                child: AppCard(
                  onTap: onTap,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: colors.accentWash,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          SymptomIcons.resolve(symptom.emojiOrIcon),
                          size: 22,
                          color: colors.accent,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        symptom.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: texts.heading.copyWith(color: colors.ink900),
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                top: 6,
                right: 6,
                child: Sparkle(
                  isActive: true,
                  size: 18,
                  onChanged: (next) {
                    if (!next) onUnfavorite();
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
