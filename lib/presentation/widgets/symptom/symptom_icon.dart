import 'package:flutter/material.dart';

/// `Symptom.emojiOrIcon` 키 → Material 라인(outlined) 아이콘 매핑 (§11.7 · §11.9 · §11.15).
///
/// 홈 그리드·증상 상세 헤더·즐겨찾기가 **동일한 매핑**을 공유해야 홈→상세
/// Hero morph가 아이콘 점프 없이 자연스럽다. (통합 단계에서 feature별 로컬
/// 사본 3개를 이 공용 유틸 하나로 합쳤다.)
///
/// 증상 32종(기존 16 + 신규 아기 9·산모 7)의 아이콘 키를 수묵 라인 느낌의
/// outlined 아이콘으로 매핑한다. 미지 키/`null`은 [_fallbackIcon]으로
/// 폴백한다. (일러스트가 등록된 키는 카드/헤더에서 일러스트가 우선이고,
/// 이 매핑은 검색 결과 행 등 소형 맥락의 폴백이다.)
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
    // 신규 16종 (콘텐츠 계약 §1 — order_index 17~32)
    'thrush': Icons.bubble_chart_outlined, // 아구창(입안 반점)
    'umbilical': Icons.adjust, // 배꼽·제대(동심원)
    'birthmark': Icons.blur_circular, // 반점·각질
    'hormonal': Icons.waves, // 가성생리·멍울(호르몬 물결)
    'dimple': Icons.trip_origin, // 엉덩이 딤플(오목 점)
    'tongue_tie': Icons.record_voice_over_outlined, // 설소대
    'vaccine': Icons.vaccines_outlined, // 예방접종
    'formula': Icons.science_outlined, // 분유 타기(조유)
    'milk_storage': Icons.kitchen_outlined, // 모유 보관(냉장)
    'lochia': Icons.local_florist_outlined, // 오로(꽃잎)
    'baby_blues': Icons.self_improvement, // 산후 우울감(돌봄·숨 고르기)
    'engorgement': Icons.whatshot_outlined, // 젖몸살·유선염(열감)
    'nipple_care': Icons.healing_outlined, // 유두 통증(연고·밴드)
    'breastfeeding': Icons.volunteer_activism_outlined, // 모유수유 시작
    'milk_supply': Icons.help_outline, // 모유량 고민(물음표)
    'recovery': Icons.spa_outlined, // 산후 회복(새싹)
  };

  /// [key]에 해당하는 아이콘. 키가 `null`이거나 매핑에 없으면 폴백.
  static IconData resolve(String? key) => _byKey[key] ?? _fallbackIcon;
}
