import 'package:flutter/material.dart';

import '../../../config/theme/theme.dart';

/// DESIGN v2 §6.2 증상 카테고리 톤 매핑. [SymptomIcons](`symptom_icon.dart`)와
/// 나란한 프레젠테이션 유틸(도메인 데이터 아님 — 아이콘 키 매핑과 동일한 성격)이다.
///
/// 픽스처(0004_seed.sql, fixture_symptoms.dart)의 16종 `emojiOrIcon` 키를
/// 4분류로 매핑한다. 미지 키/`null`은 기본(호흡·피부·기타 = accent)으로 폴백한다.
///
/// | 카테고리 | 예 | wash / fg |
/// |---|---|---|
/// | 열·응급성 | 발열 | `coralWash` / `coral` |
/// | 소화·배변 | 배앓이·변비·설사·구토 등 | `sageWash` / `sage` |
/// | 수면·컨디션 | 이앓이·수면퇴행 등 | `amberWash` / `amber` |
/// | 호흡·피부·기타(기본) | 콧물·발진·땀띠 등 | `accentWash` / `accent` |
class SymptomTone {
  const SymptomTone._();

  /// 열·응급성 — 발열.
  static const Set<String> _emergency = <String>{'fever'};

  /// 소화·배변 — 배앓이·변 색깔 이상·트림·게워냄·변비·설사·딸꾹질.
  static const Set<String> _digestive = <String>{
    'tummy_pain',
    'stool_color',
    'burp',
    'spit_up',
    'constipation',
    'diarrhea',
    'hiccup',
  };

  /// 수면·컨디션 — 이앓이(보챔)·수면퇴행.
  static const Set<String> _mood = <String>{'teething', 'sleep_moon'};

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
