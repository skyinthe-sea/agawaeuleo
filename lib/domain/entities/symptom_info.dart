import 'package:freezed_annotation/freezed_annotation.dart';

part 'symptom_info.freezed.dart';

/// 참고정보 섹션 한 블록 (§7.1 `symptom_infos.sections` jsonb `[{title, body}]`).
@freezed
abstract class InfoSection with _$InfoSection {
  const factory InfoSection({required String title, required String body}) =
      _InfoSection;
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

    /// `sections` — 섹션형 본문.
    @Default(<InfoSection>[]) List<InfoSection> sections,

    /// `emergency` — 응급신호 배열(없을 수 있음).
    @Default(<EmergencySign>[]) List<EmergencySign> emergency,

    required DateTime updatedAt,
  }) = _SymptomInfo;

  /// 응급신호 경고를 노출해야 하는지 (§11.9 "해당 시").
  bool get hasEmergency => emergency.isNotEmpty;
}
