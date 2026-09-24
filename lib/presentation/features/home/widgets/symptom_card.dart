import 'dart:math' as math;

import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/widgets/cards/app_card.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';

/// §11.7 홈 증상 그리드 카드. 높이 ~120 · r.lg · e1 · 내부 패딩 16.
///
/// 두 가지 레이아웃(DESIGN v3 "몽글 클레이"):
/// - **일러스트 카드**([SymptomIllustrations] 등록 증상 — 시드 32종 전부):
///   좌상단 주아체 제목(heading) + 그 아래 한 줄 설명([Symptom.tagline], caption
///   `ink500`, 개행 없음), 우측 절반에 톤 워시 쿠션 위 클레이 일러스트(세로 중앙).
/// - **기본 카드**(폴백): 미등록 키/신규 증상용 — 상단 클레이 버블 라인 아이콘
///   (40 원형, `SymptomTone` 워시 + 광택) + 하단 증상명.
///
/// 탭 시 [AppCard]의 스프링(scale .96) + 눌림 그림자 + 워시 리플 +
/// 라이트 햅틱. 카드 자체는 그리드 밀도상 `flat`(기본값) 유지.
///
/// Hero 태그 계약(상세 화면과 공유 — §11.9): 아이콘 `symptom-icon-<id>`,
/// 증상명 `symptom-name-<id>`. 일러스트 카드는 일러스트 자체가 아이콘
/// 히어로로 비행한다(상세 헤더의 동일 일러스트로 축소 착지).
class SymptomCard extends StatelessWidget {
  const SymptomCard({required this.symptom, required this.onTap, super.key});

  final Symptom symptom;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    if (SymptomIllustrations.has(symptom.emojiOrIcon)) {
      return _buildIllustrated(context);
    }
    return _buildClassic(context);
  }

  /// 좌상단 제목/설명 + 우측 절반 일러스트.
  Widget _buildIllustrated(BuildContext context) {
    final colors = context.colors;
    final tagline = symptom.tagline;
    final tone = SymptomTone.resolve(context, symptom.emojiOrIcon);

    return AppCard(
      onTap: onTap,
      padding: EdgeInsets.zero,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 일러스트는 카드 우측 절반을 차지하되, 넓은 셀에서도 카드 높이
          // (120 - 상하 숨쉴 여백)를 넘지 않는다.
          final illustrationSize = math.min(
            constraints.maxWidth / 2,
            constraints.maxHeight - AppSpacing.x8,
          );
          return Stack(
            fit: StackFit.expand,
            children: [
              // 일러스트가 앉는 폭신한 톤 워시 쿠션(그림보다 조금 작게, 살짝 아래).
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: EdgeInsets.only(
                    right: AppSpacing.x4 + illustrationSize * 0.1,
                    top: illustrationSize * 0.12,
                  ),
                  child: Container(
                    width: illustrationSize * 0.8,
                    height: illustrationSize * 0.8,
                    decoration: BoxDecoration(
                      color: tone.wash,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.x4),
                  child: Hero(
                    tag: 'symptom-icon-${symptom.id}',
                    child: SymptomIllustration(
                      illustrationKey: symptom.emojiOrIcon!,
                      size: illustrationSize,
                    ),
                  ),
                ),
              ),
              Padding(
                // 우측 인셋은 일러스트 폭에서 x16 양보 — 일러스트 뷰박스의
                // 빈 왼쪽 마진(그림 본체는 x≈25dp부터)이라 겹쳐 보이지 않고,
                // 설명이 개행 없이 **한 줄**로 들어갈 폭이 확보된다(카피는
                // 공백 포함 8자 이내 계약 — §7.1 tagline 컬럼 코멘트).
                padding: EdgeInsets.fromLTRB(
                  AppSpacing.cardPadding,
                  AppSpacing.cardPadding,
                  illustrationSize - AppSpacing.x16,
                  AppSpacing.cardPadding,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _heroName(context),
                    const SizedBox(height: AppSpacing.x2),
                    if (tagline != null)
                      Text(
                        tagline,
                        style: context.texts.caption.copyWith(
                          color: colors.ink500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
            ],
          );
        },
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
                gradient: ClaySheen.gradient(context, tone.wash),
                shape: BoxShape.circle,
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
