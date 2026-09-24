import 'package:flutter/material.dart';

import '../../../../config/theme/theme.dart';
import '../../../../domain/entities/symptom.dart';
import '../../../widgets/animated/sparkle.dart';
import '../../../widgets/cards/app_card.dart';
import '../../../widgets/symptom/symptom_icon.dart';
import '../../../widgets/symptom/symptom_illustration.dart';
import '../../../widgets/symptom/symptom_tone.dart';

/// §11.15 즐겨찾기 "증상" 그리드 카드 — 홈(§11.7)과 동일한 카드 형태
/// (2열, 카드 간격 12, radius `r.md`, e1, 둥근 쿠션 위 클레이 썸네일 + 증상명
/// heading 18, 카드 높이 ~120)에 우측 상단 별 오버레이를 더해 해제(unfavorite)를
/// 지원한다.
///
/// DESIGN v3 §6 — 썸네일은 [SymptomTone] 카테고리 워시 쿠션 위에 등록된
/// [SymptomIllustration](클레이)을 올리고, 미등록 키는 기존 라인 아이콘으로
/// 폴백한다.
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
                      _Thumbnail(emojiOrIcon: symptom.emojiOrIcon),
                      // 고정 높이 카드라 큰 글자에서는 이름을 줄여 받는다(넘침 방지).
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomLeft,
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.bottomLeft,
                            child: Text(
                              symptom.name,
                              maxLines: 1,
                              style: texts.heading.copyWith(
                                color: colors.ink900,
                              ),
                            ),
                          ),
                        ),
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

/// 카테고리 톤 워시 쿠션(48dp) 위의 썸네일 — 등록된 일러스트가 있으면 클레이
/// 그림(36dp)을, 없으면 기존 라인 아이콘(22dp)을 올린다.
class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.emojiOrIcon});

  final String? emojiOrIcon;

  @override
  Widget build(BuildContext context) {
    final tone = SymptomTone.resolve(context, emojiOrIcon);
    final key = emojiOrIcon;
    final hasIllustration = SymptomIllustrations.has(key);
    return Container(
      width: 48,
      height: 48,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: tone.wash, shape: BoxShape.circle),
      child: hasIllustration
          ? SymptomIllustration(illustrationKey: key!, size: 36)
          : Icon(SymptomIcons.resolve(emojiOrIcon), size: 22, color: tone.fg),
    );
  }
}
