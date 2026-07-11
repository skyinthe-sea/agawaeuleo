import 'package:freezed_annotation/freezed_annotation.dart';

part 'symptom_info.freezed.dart';

/// 참고정보 섹션 한 블록 (§7.1 `symptom_infos.sections` jsonb).
///
/// 와이어 계약: 원소는 `{"type": "text|steps|checklist|table|qa|tips", ...}`.
/// `type` 누락 시 text로 해석하며, 알 수 없는 type·필드 결손은 data 레이어가
/// text 폴백 또는 원소 스킵으로 흡수한다(파싱 단위 실패가 전체 정보 로드를
/// 죽이면 안 됨 — `lib/data/supabase/symptom_info_mappers.dart`).
///
/// 렌더링은 증상 상세 아코디언(`info_accordion.dart`)이 타입별로 분기한다.
@freezed
sealed class InfoSection with _$InfoSection {
  /// 기본 서술형 — `{title, body}` (기존 `[{title, body}]` 계약과 호환).
  const factory InfoSection.text({
    required String title,
    required String body,
  }) = InfoSectionText;

  /// 번호 매긴 단계 — `{title, intro?, items: [..]}`.
  const factory InfoSection.steps({
    required String title,
    required List<String> items,
    String? intro,
  }) = InfoSectionSteps;

  /// 체크리스트 — `{title, intro?, items: [..]}`.
  const factory InfoSection.checklist({
    required String title,
    required List<String> items,
    String? intro,
  }) = InfoSectionChecklist;

  /// 표 — `{title, columns: [..], rows: [[..]], caption?}`.
  const factory InfoSection.table({
    required String title,
    required List<String> columns,
    required List<List<String>> rows,
    String? caption,
  }) = InfoSectionTable;

  /// 질문/답변 목록 — `{title, items: [{q, a}]}`.
  const factory InfoSection.qa({
    required String title,
    required List<QaItem> items,
  }) = InfoSectionQa;

  /// 실전 팁 목록('조리원 실전 팁' 시그니처) — `{title, items: [..]}`.
  const factory InfoSection.tips({
    required String title,
    required List<String> items,
  }) = InfoSectionTips;
}

/// [InfoSection.qa]의 질문/답변 한 쌍 (`{q, a}`).
@freezed
abstract class QaItem with _$QaItem {
  const factory QaItem({required String q, required String a}) = _QaItem;
}

/// 참고 자료 출처 한 건 (§7.1 `symptom_infos.sources` jsonb
/// `[{label, org?, url?}]`).
///
/// 상세 화면은 [label]만 불릿 리스트로 노출한다(탭 액션·URL 노출 없음).
/// [org]/[url]은 검수·관리용 메타데이터.
@freezed
abstract class InfoSource with _$InfoSource {
  const factory InfoSource({
    /// 한국어 표시명(기관·문서명). 예: '질병관리청 예방접종도우미'.
    required String label,

    /// 발행 기관 축약(선택). 예: 'AAP', 'WHO'.
    String? org,

    /// 원문 URL(선택, 검증된 것만 — 앱은 노출하지 않는다).
    String? url,
  }) = _InfoSource;
}

/// 응급신호 한 항목 (§7.1 `symptom_infos.emergency` jsonb `[{sign, action}]`, §11.9).
@freezed
abstract class EmergencySign with _$EmergencySign {
  const factory EmergencySign({
    /// 신호(증상) 설명.
    required String sign,

    /// 권장 조치.
    required String action,
  }) = _EmergencySign;
}

/// 증상별 의학 참고정보 (§7.1 `symptom_infos`, §3 C3, §11.9).
@freezed
abstract class SymptomInfo with _$SymptomInfo {
  const SymptomInfo._();

  const factory SymptomInfo({
    required String id,
    required String symptomId,

    /// `summary` — 2~3문장 요약.
    required String summary,

    /// `sections` — 섹션형 본문(타입 유니온 [InfoSection]).
    @Default(<InfoSection>[]) List<InfoSection> sections,

    /// `emergency` — 응급신호 배열(없을 수 있음).
    @Default(<EmergencySign>[]) List<EmergencySign> emergency,

    /// `sources` — 참고 자료 출처(없을 수 있음 — 비면 상세 화면이 블록 생략).
    @Default(<InfoSource>[]) List<InfoSource> sources,

    required DateTime updatedAt,
  }) = _SymptomInfo;

  /// 응급신호 경고를 노출해야 하는지 (§11.9 "해당 시").
  bool get hasEmergency => emergency.isNotEmpty;
}
