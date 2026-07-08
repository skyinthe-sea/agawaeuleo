import 'package:flutter/material.dart';

/// `Symptom.emojiOrIcon` 키 → Material 라인(outlined) 아이콘 매핑 (§11.7 · §11.9 · §11.15).
///
/// 홈 그리드·증상 상세 헤더·즐겨찾기가 **동일한 매핑**을 공유해야 홈→상세
/// Hero morph가 아이콘 점프 없이 자연스럽다. (통합 단계에서 feature별 로컬
/// 사본 3개를 이 공용 유틸 하나로 합쳤다.)
///
/// 시드/픽스처(0004_seed.sql, fixture_symptoms.dart)의 16종 증상 아이콘 키를
/// 수묵 라인 느낌의 outlined 아이콘으로 매핑한다. 미지 키/`null`은
/// [_fallbackIcon]으로 폴백한다.
class SymptomIcons {
  const SymptomIcons._();

  /// 미지 키/`null` 폴백 아이콘.
  static const IconData _fallbackIcon = Icons.medical_services_outlined;

  /// `emojiOrIcon` 키 → 아이콘.
  static const Map<String, IconData> _byKey = <String, IconData>{
    'tummy_pain': Icons.sick_outlined, // 배앓이(colic)
    'teething': Icons.sentiment_very_dissatisfied_outlined, // 이앓이
    'newborn_rash': Icons.face_outlined, // 태열
    'stool_color': Icons.palette_outlined, // 변 색깔 이상
    'burp': Icons.cloud_outlined, // 트림 안 나옴
    'spit_up': Icons.local_drink_outlined, // 게워냄
    'runny_nose': Icons.masks_outlined, // 콧물·코막힘
    'fever': Icons.thermostat, // 열
    'rash': Icons.grain, // 발진
    'sleep_moon': Icons.bedtime_outlined, // 수면퇴행
    'constipation': Icons.hourglass_empty, // 변비
    'diarrhea': Icons.opacity_outlined, // 설사
    'hiccup': Icons.air, // 딸꾹질
    'prickly_heat': Icons.water_drop_outlined, // 땀띠
    'jaundice': Icons.wb_sunny_outlined, // 황달
    'eye_care': Icons.visibility_outlined, // 눈곱·눈물
  };

  /// [key]에 해당하는 아이콘. 키가 `null`이거나 매핑에 없으면 폴백.
  static IconData resolve(String? key) => _byKey[key] ?? _fallbackIcon;
}
