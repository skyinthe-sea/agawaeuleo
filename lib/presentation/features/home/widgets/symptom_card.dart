import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tagline.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';

/// §11.7 홈 증상 그리드 카드. 높이 ~120 · r.md · e1 · 내부 패딩 16.
///
/// 두 가지 레이아웃:
/// - **일러스트 카드**([SymptomIllustrations] 등록 증상 — 현재 배앓이 트라이얼):
///   좌상단 제목(heading) + 그 아래 한 줄 설명(caption `ink500`), 우하단
///   빈 공간에 먹선+하프톤 손그림 일러스트.
/// - **기본 카드**(나머지): 상단 수묵 라인 아이콘(40 원형, `SymptomTone` 톤) +
///   하단 증상명 — 기존 레이아웃 그대로.
///
/// 탭 시 [AppCard]의 스프링(scale .96) + 눌림 그림자 + 잉크 워시 리플 +
/// 라이트 햅틱. 카드 자체는 그리드 밀도상 `flat`(기본값) 유지.
///
/// Hero 태그 계약(상세 화면과 공유 — §11.9): 아이콘 `symptom-icon-<id>`,
/// 증상명 `symptom-name-<id>`. 일러스트 카드는 아이콘 히어로 소스가 없어
/// 증상명만 비행한다(상세 쪽 태그는 짝 없이 무해).
class SymptomCard extends StatelessWidget {
  const SymptomCard({required this.symptom, required this.onTap, super.key});

  final Symptom symptom;
  final VoidCallback onTap;

  /// 일러스트 렌더 크기·우하단 여백(dp). 카드 높이 120 기준 — 제목·설명
  /// 텍스트 블록(상단 ~60dp)과 일러스트 상단이 겹치지 않는 상한이다.
  static const double _illustrationSize = 56;

  @override
  Widget build(BuildContext context) {
    if (SymptomIllustrations.has(symptom.emojiOrIcon)) {
      return _buildIllustrated(context);
    }
    return _buildClassic(context);
  }

  /// 좌상단 제목/설명 + 우하단 일러스트.
  Widget _buildIllustrated(BuildContext context) {
    final colors = context.colors;
    final tagline = SymptomTaglines.resolve(symptom.slug);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            right: AppSpacing.x8,
            bottom: AppSpacing.x8,
            child: SymptomIllustration(
              illustrationKey: symptom.emojiOrIcon!,
              size: _illustrationSize,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _heroName(context),
                const SizedBox(height: AppSpacing.x2),
                if (tagline != null)
                  Text(
                    tagline,
                    style: context.texts.caption.copyWith(color: colors.ink500),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// 기존 레이아웃 — 상단 아이콘 + 하단 증상명.
  Widget _buildClassic(BuildContext context) {
    final tone = SymptomTone.resolve(context, symptom.emojiOrIcon);

    return AppCard(
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Hero(
            tag: 'symptom-icon-${symptom.id}',
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: tone.wash,
                shape: BoxShape.circle,
                border: Border.all(color: tone.fg.withValues(alpha: 0.22)),
              ),
              alignment: Alignment.center,
              child: Icon(
                SymptomIcons.resolve(symptom.emojiOrIcon),
                size: 22,
                color: tone.fg,
              ),
            ),
          ),
          const Spacer(),
          _heroName(context),
        ],
      ),
    );
  }

  Widget _heroName(BuildContext context) => Hero(
    tag: 'symptom-name-${symptom.id}',
    // 비행 중 텍스트가 기본 스타일/밑줄로 깨지지 않도록 Material로 감싼다.
    child: Material(
      type: MaterialType.transparency,
      child: Text(
        symptom.name,
        style: context.texts.heading.copyWith(color: context.colors.ink900),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  );
}
