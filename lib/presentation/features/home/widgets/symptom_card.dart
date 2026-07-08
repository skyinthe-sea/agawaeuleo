import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:flutter/material.dart';

/// §11.7 홈 증상 그리드 카드. 높이 ~120 · r.md · e1 · 내부 패딩 16.
///
/// 상단: 수묵 라인 아이콘(40 원형 배경 `accent.wash`), 하단: 증상명 heading 18 `ink.900`.
/// 탭 시 [AppCard]의 스프링(scale .96) + 눌림 그림자 + 잉크 워시 리플 + 라이트 햅틱.
///
/// Hero 태그 계약(상세 화면과 공유 — §11.9): 아이콘 `symptom-icon-<id>`,
/// 증상명 `symptom-name-<id>`.
class SymptomCard extends StatelessWidget {
  const SymptomCard({required this.symptom, required this.onTap, super.key});

  final Symptom symptom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

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
                color: colors.accentWash,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: Icon(
                SymptomIcons.resolve(symptom.emojiOrIcon),
                size: 22,
                color: colors.accent,
              ),
            ),
          ),
          const Spacer(),
          Hero(
            tag: 'symptom-name-${symptom.id}',
            // 비행 중 텍스트가 기본 스타일/밑줄로 깨지지 않도록 Material로 감싼다.
            child: Material(
              type: MaterialType.transparency,
              child: Text(
                symptom.name,
                style: context.texts.heading.copyWith(color: colors.ink900),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
