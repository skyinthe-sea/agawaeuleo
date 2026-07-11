/// 증상 카드 한 줄 설명(태그라인) — [SymptomIllustrations]와 짝을 이루는
/// 프레젠테이션 카피. 일러스트 레이아웃 카드에서 제목 아래 캡션으로 노출된다.
///
/// ⚠️ 의학 정보 규칙(§13.3): 증상을 '설명'만 하고 진단·치료를 단정하지 않는
/// 참고용 톤을 유지할 것. 문구는 픽스처/시드의 검수 대상 summary 표현을
/// 벗어나지 않는 범위로 제한한다.
///
/// 16종 확산 시 이 카피는 `symptoms` 테이블 컬럼(스펙 §7.1 개정)으로 옮기는
/// 것이 원칙(증상 데이터 앱 하드코딩 금지)이다 — 현재는 배앓이 1종 트라이얼.
library;

class SymptomTaglines {
  const SymptomTaglines._();

  /// `slug` → 한 줄 설명. 카드 폭(2열 그리드 기준 약 120dp 텍스트 폭)에서
  /// 한 줄에 들어가도록 12자 내외를 유지한다.
  static const Map<String, String> _bySlug = <String, String>{
    'colic': '이유 없이 심하게 울 때',
  };

  /// [slug]의 태그라인. 미등록 증상은 `null`(카드가 캡션 줄을 생략).
  static String? resolve(String slug) => _bySlug[slug];
}
