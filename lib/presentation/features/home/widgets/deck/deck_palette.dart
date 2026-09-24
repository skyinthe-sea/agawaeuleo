import 'package:agawaeuleo/config/theme/theme.dart';
import 'package:agawaeuleo/domain/entities/entities.dart';
import 'package:agawaeuleo/presentation/widgets/symptom/symptom_tone.dart';
import 'package:flutter/material.dart';

/// DESIGN v3 "몽글 클레이" §3.1·§6 — 홈 케어 덱이 함께 쓰는 색·숫자 문법.
///
/// - **그룹 강조**: 아기 돌봄 = 딸기(`accent`), 엄마 돌봄 = 라일락(`lilac`). 선택된
///   그룹 탭 알약·레일 선택 링이 이 색을 쓴다.
/// - **장면 톤**: 증상 카테고리 워시([SymptomTone]). 엄마 돌봄 증상은 라일락 쪽으로
///   살짝 기울여 그룹의 결을 맞춘다(카테고리 색은 알아볼 만큼 남긴다). 무대 블롭·
///   레일 쿠션·번호 배지가 모두 같은 톤을 써서 한 장면이 한 색으로 묶인다.
/// - **숫자**: 모노(`01`) 대신 통통한 주아체 숫자(DESIGN v3 §3.3).
abstract final class DeckPalette {
  /// 엄마 돌봄 워시가 라일락 쪽으로 기우는 비율(카테고리 색은 70% 유지).
  static const double momLilacLean = 0.3;

  /// 그룹(대상) 강조색 — 선택 탭 알약·레일 링.
  static ({Color fg, Color wash}) emphasis(
    BuildContext context,
    SymptomAudience audience,
  ) {
    final colors = context.colors;
    return audience == SymptomAudience.mom
        ? (fg: colors.lilac, wash: colors.lilacWash)
        : (fg: colors.accent, wash: colors.accentWash);
  }

  /// 증상 한 장의 톤(무대 블롭·레일 쿠션·번호 배지 공용).
  ///
  /// 글자색(fg)은 카테고리 색 그대로라 워시 위 대비(4.5:1)가 유지된다 — 섞는 쪽은
  /// 옅은 워시끼리뿐이다.
  static ({Color fg, Color wash}) tone(BuildContext context, Symptom symptom) {
    final base = SymptomTone.resolve(context, symptom.emojiOrIcon);
    if (symptom.audience != SymptomAudience.mom) return base;
    return (
      fg: base.fg,
      wash: Color.lerp(base.wash, context.colors.lilacWash, momLilacLean)!,
    );
  }

  /// [base] 크기·색을 그대로 두고 주아체 숫자로 바꾼다. 주아체는 한 가지 굵기라
  /// 굵기를 400으로 되돌린다(가짜 볼드 방지).
  static TextStyle digits(TextStyle base) => base.copyWith(
    fontFamily: AppFontFamily.display,
    fontFamilyFallback: AppFontFamily.displayFallback,
    fontWeight: FontWeight.w400,
    letterSpacing: 0,
  );
}
