import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/core/haptics/app_haptics.dart';
import 'package:agawaeuleo/domain/entities/symptom.dart';
import 'package:agawaeuleo/presentation/widgets/animated/ink_wash_splash.dart';
import 'package:agawaeuleo/presentation/widgets/surfaces/clay_sheen.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_icon.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_illustration.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';

import '../search_highlight.dart';

/// §11.8 검색 결과 항목 — 매칭 하이라이트된 증상명을 담은 둥근 타일.
///
/// DESIGN v3 "몽글 클레이" §6 — 헤어라인 행 대신 말랑한 둥근 카드(paperCard · r.lg ·
/// e1)를 간격을 두고 쌓는다. 왼쪽에는 카테고리 톤 워시 쿠션([SymptomTone]) 위에
/// 작은 클레이 썸네일([SymptomIllustration] — 미등록 키는 라인 아이콘 폴백).
/// 엄마 돌봄 증상은 라일락 '엄마' 스티커로 구분한다.
/// 탭 → 증상 상세(라이트 햅틱 + 워시 리플).
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

  /// 쿠션(썸네일 원) 지름.
  static const double _thumbSize = 52;

  /// 타일 좌우 바깥 여백.
  static const double tileInset = AppSpacing.x16;

  /// 텍스트가 시작하는 좌측 들여쓰기(바깥 여백 16 + 안쪽 12 + 쿠션 52 + 간격 12).
  /// v2의 inset 헤어라인 디바이더용 값이었다 — 행 사이 구분선이 필요한 소비처를 위해
  /// 같은 이름으로 남긴다.
  static const double dividerIndent =
      tileInset + AppSpacing.x12 + _thumbSize + AppSpacing.x12;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: tileInset),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.paperCard,
          borderRadius: AppRadius.brLg,
          boxShadow: context.shadows.e1,
        ),
        child: Material(
          type: MaterialType.transparency,
          borderRadius: AppRadius.brLg,
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            splashFactory: InkWashSplash.splashFactory,
            splashColor: colors.accentWash,
            highlightColor: Colors.transparent,
            borderRadius: AppRadius.brLg,
            onTap: () {
              AppHaptics.tap();
              onTap();
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.x12,
                AppSpacing.x8,
                AppSpacing.x12,
                AppSpacing.x8,
              ),
              child: Row(
                children: [
                  _Thumb(symptom: symptom),
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
                  // §11.8 개정 — 검색은 audience 무관 전체 대상. mom(산모) 카드는
                  // 작은 '엄마' 스티커(라일락 — DESIGN v3 §3.1 엄마 돌봄 톤)로만 구분한다.
                  if (symptom.audience == SymptomAudience.mom) ...[
                    const SizedBox(width: AppSpacing.x8),
                    const _MomSticker(),
                  ],
                  const SizedBox(width: AppSpacing.x8),
                  Icon(
                    Icons.chevron_right_rounded,
                    size: 20,
                    color: colors.ink500,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 톤 워시 동그라미 쿠션 + 클레이 썸네일(미등록 키는 라인 아이콘).
class _Thumb extends StatelessWidget {
  const _Thumb({required this.symptom});

  final Symptom symptom;

  @override
  Widget build(BuildContext context) {
    final tone = SymptomTone.resolve(context, symptom.emojiOrIcon);
    final key = symptom.emojiOrIcon;
    return Container(
      width: SearchResultTile._thumbSize,
      height: SearchResultTile._thumbSize,
      decoration: BoxDecoration(
        gradient: ClaySheen.gradient(context, tone.wash),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: SymptomIllustrations.has(key)
          ? SymptomIllustration(illustrationKey: key!, size: 48)
          : Icon(SymptomIcons.resolve(key), size: 22, color: tone.fg),
    );
  }
}

/// '엄마' 스티커 — 라일락 워시 알약 + 흰 스티커 테두리.
class _MomSticker extends StatelessWidget {
  const _MomSticker();

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.x8,
        vertical: AppSpacing.x2,
      ),
      decoration: BoxDecoration(
        color: colors.lilacWash,
        borderRadius: AppRadius.brFull,
        border: Border.all(color: colors.paperRaised, width: 1.5),
        boxShadow: context.shadows.e1,
      ),
      child: Text(
        '엄마',
        style: context.texts.caption.copyWith(
          color: colors.lilac,
          fontWeight: FontWeight.w700,
          letterSpacing: 0,
        ),
      ),
    );
  }
}
