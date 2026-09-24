import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// 증상 카테고리 톤 매핑(DESIGN v2 §6.2 — v3 "몽글 클레이"에서 매핑은 그대로, 값만
/// 파스텔 셔벗 토큰으로 바뀌었다: 토마토·민트·버터·딸기).
/// [SymptomIcons](`symptom_icon.dart`)와 나란한 프레젠테이션 유틸(도메인 데이터
/// 아님 — 아이콘 키 매핑과 동일한 성격)이다. 엄마 돌봄(audience=mom) 강조의 라일락(`lilac`)은 증상
/// 키가 아니라 audience 기준이므로 소비처가 따로 고른다(DESIGN v3 §3.1).
///
/// 증상 32종(기존 16 + 신규 아기 9·산모 7)의 `emojiOrIcon` 키를 4분류로
/// 매핑한다. 미지 키/`null`은 기본(호흡·피부·기타 = accent)으로 폴백한다.
///
/// | 카테고리 | 예 | wash / fg |
/// |---|---|---|
/// | 열·응급성·통증/염증 | 발열·젖몸살·유두 통증 | `coralWash` / `coral` |
/// | 소화·배변·수유/영양 | 배앓이·분유·모유수유 등 | `sageWash` / `sage` |
/// | 수면·정서·컨디션 | 이앓이·산후 우울감·회복 등 | `amberWash` / `amber` |
/// | 호흡·피부·기타(기본) | 콧물·발진·배꼽·예방접종 등 | `accentWash` / `accent` |
class SymptomTone {
  const SymptomTone._();

  /// 열·응급성 + 통증·염증성(산모 유방 트러블).
  static const Set<String> _emergency = <String>{
    'fever',
    'engorgement',
    'nipple_care',
  };

  /// 소화·배변 + 수유·영양(설소대·분유·모유 보관/수유/모유량).
  static const Set<String> _digestive = <String>{
    'tummy_pain',
    'stool_color',
    'burp',
    'spit_up',
    'constipation',
    'diarrhea',
    'hiccup',
    'tongue_tie',
    'formula',
    'milk_storage',
    'breastfeeding',
    'milk_supply',
  };

  /// 수면·정서·컨디션 — 이앓이(보챔)·수면퇴행 + 호르몬·산후 정서/회복.
  static const Set<String> _mood = <String>{
    'teething',
    'sleep_moon',
    'hormonal',
    'baby_blues',
    'recovery',
  };

  // 나머지 신규 키(thrush·umbilical·birthmark·dimple·vaccine·lochia)는
  // 피부·신체 징후·돌봄 기타 — 기본 accent 폴백에 의도적으로 남긴다.

  /// [key]에 해당하는 (wash, fg) 색 쌍. 매핑에 없는 키/`null`은 accent 기본.
  static ({Color wash, Color fg}) resolve(BuildContext context, String? key) {
    final colors = context.colors;
    if (key != null && _emergency.contains(key)) {
      return (wash: colors.coralWash, fg: colors.coral);
    }
    if (key != null && _digestive.contains(key)) {
      return (wash: colors.sageWash, fg: colors.sage);
    }
    if (key != null && _mood.contains(key)) {
      return (wash: colors.amberWash, fg: colors.amber);
    }
    return (wash: colors.accentWash, fg: colors.accent);
  }
}
