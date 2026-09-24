import 'package:flutter/material.dart';

/// `Symptom.emojiOrIcon` 키 → Material 둥근(`_rounded`) 아이콘 매핑 (§11.7 · §11.9 · §11.15).
///
/// 홈 그리드·증상 상세 헤더·즐겨찾기가 **동일한 매핑**을 공유해야 홈→상세
/// Hero morph가 아이콘 점프 없이 자연스럽다. (통합 단계에서 feature별 로컬
/// 사본 3개를 이 공용 유틸 하나로 합쳤다.)
///
/// 증상 32종(기존 16 + 신규 아기 9·산모 7)의 아이콘 키를 DESIGN v3 "몽글 클레이"의
/// 말랑한 인상에 맞춰 모서리가 둥근 채움형(`_rounded`) 아이콘으로 매핑한다. 미지 키/`null`은 [_fallbackIcon]으로
/// 폴백한다. (일러스트가 등록된 키는 카드/헤더에서 일러스트가 우선이고,
/// 이 매핑은 검색 결과 행 등 소형 맥락의 폴백이다.)
class SymptomIcons {
  const SymptomIcons._();

  /// 미지 키/`null` 폴백 아이콘.
  static const IconData _fallbackIcon = Icons.medical_services_rounded;

  /// `emojiOrIcon` 키 → 아이콘.
  static const Map<String, IconData> _byKey = <String, IconData>{
    'tummy_pain': Icons.sick_rounded, // 배앓이(colic)
    'teething': Icons.sentiment_very_dissatisfied_rounded, // 이앓이
    'newborn_rash': Icons.face_rounded, // 태열
    'stool_color': Icons.palette_rounded, // 변 색깔 이상
    'burp': Icons.cloud_rounded, // 트림 안 나옴
    'spit_up': Icons.local_drink_rounded, // 게워냄
    'runny_nose': Icons.masks_rounded, // 콧물·코막힘
    'fever': Icons.thermostat_rounded, // 열
    'rash': Icons.grain_rounded, // 발진
    'sleep_moon': Icons.bedtime_rounded, // 수면퇴행
    'constipation': Icons.hourglass_empty_rounded, // 변비
    'diarrhea': Icons.opacity_rounded, // 설사
    'hiccup': Icons.air_rounded, // 딸꾹질
    'prickly_heat': Icons.water_drop_rounded, // 땀띠
    'jaundice': Icons.wb_sunny_rounded, // 황달
    'eye_care': Icons.visibility_rounded, // 눈곱·눈물
    // 신규 16종 (콘텐츠 계약 §1 — order_index 17~32)
    'thrush': Icons.bubble_chart_rounded, // 아구창(입안 반점)
    'umbilical': Icons.adjust_rounded, // 배꼽·제대(동심원)
    'birthmark': Icons.blur_circular_rounded, // 반점·각질
    'hormonal': Icons.waves_rounded, // 가성생리·멍울(호르몬 물결)
    'dimple': Icons.trip_origin_rounded, // 엉덩이 딤플(오목 점)
    'tongue_tie': Icons.record_voice_over_rounded, // 설소대
    'vaccine': Icons.vaccines_rounded, // 예방접종
    'formula': Icons.science_rounded, // 분유 타기(조유)
    'milk_storage': Icons.kitchen_rounded, // 모유 보관(냉장)
    'lochia': Icons.local_florist_rounded, // 오로(꽃잎)
    'baby_blues': Icons.self_improvement_rounded, // 산후 우울감(돌봄·숨 고르기)
    'engorgement': Icons.whatshot_rounded, // 젖몸살·유선염(열감)
    'nipple_care': Icons.healing_rounded, // 유두 통증(연고·밴드)
    'breastfeeding': Icons.volunteer_activism_rounded, // 모유수유 시작
    'milk_supply': Icons.help_outline_rounded, // 모유량 고민(물음표)
    'recovery': Icons.spa_rounded, // 산후 회복(새싹)
  };

  /// [key]에 해당하는 아이콘. 키가 `null`이거나 매핑에 없으면 폴백.
  static IconData resolve(String? key) => _byKey[key] ?? _fallbackIcon;
}
