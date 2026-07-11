import 'package:freezed_annotation/freezed_annotation.dart';

part 'symptom.freezed.dart';

/// 카드 대상 구분 (§7.1 `symptoms.audience` — 'baby' | 'mom').
///
/// 홈 그리드 그룹핑('아기 돌봄'/'엄마 돌봄')과 상세 의학 면책 문구 분기의
/// 기준. 알 수 없는 와이어 값은 [baby]로 폴백한다.
enum SymptomAudience {
  /// 아기 증상·돌봄 카드(기본값).
  baby('baby'),

  /// 산모(엄마) 돌봄 카드.
  mom('mom');

  const SymptomAudience(this.wire);

  /// DB `audience` 컬럼 문자열 값.
  final String wire;

  /// 와이어 값 → enum. null·미지 값은 [baby] 폴백(크래시 금지).
  static SymptomAudience fromWire(String? value) =>
      value == mom.wire ? mom : baby;
}

/// 증상 마스터 엔티티 (§7.1 `symptoms`, §3 C1/C2).
///
/// 순수 도메인 모델 — Supabase/Drift 등 데이터 소스에 의존하지 않는다.
/// snake_case 컬럼 ↔ 이 엔티티 간 매핑은 data 레이어가 담당한다.
@freezed
abstract class Symptom with _$Symptom {
  const factory Symptom({
    /// `id` (uuid).
    required String id,

    /// `slug` — 'colic', 'teething' 등 안정적 식별자.
    required String slug,

    /// `name` — 표시명. 예: '배앓이'.
    required String name,

    /// `chosung` — 검색용 초성열. 예: 'ㅂㅇㅇ'. (§11.8)
    required String chosung,

    /// `aliases` — 동의어. 예: ['가스', '영아산통'].
    @Default(<String>[]) List<String> aliases,

    /// `tagline` — 홈 카드 한 줄 설명(§11.7 일러스트 카드). 예: '이유 없이
    /// 심하게 울 때'. 참고용 톤 유지 — 의학 카피 검수 대상(§13.3).
    String? tagline,

    /// `emoji_or_icon` — 아이콘 키(nullable).
    String? emojiOrIcon,

    /// `product_keywords` — 제품 검색 키워드(Edge Function 사용). §7.1
    @Default(<String>[]) List<String> productKeywords,

    /// `order_index` — 홈 그리드 정렬 순서.
    @Default(0) int orderIndex,

    /// `audience` — 카드 대상('baby'|'mom'). 기본 baby.
    @Default(SymptomAudience.baby) SymptomAudience audience,

    /// `is_active`.
    @Default(true) bool isActive,

    /// `created_at`.
    required DateTime createdAt,
  }) = _Symptom;
}
