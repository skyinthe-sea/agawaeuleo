/// [RouteParams.doc] 값으로 쓰이는 약관 문서 식별자(§11.16 정보 그룹).
abstract final class TermsDoc {
  TermsDoc._();

  static const String privacy = 'privacy';
  static const String terms = 'terms';

  /// 설정 화면 행 라벨과 뷰어 상단바 제목이 항상 같은 문구를 쓰도록 하는 단일 소스.
  static String titleOf(String doc) => switch (doc) {
    privacy => '개인정보처리방침',
    terms => '이용약관',
    _ => '약관',
  };
}
