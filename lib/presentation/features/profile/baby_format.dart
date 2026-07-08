/// §11.14 아기 프로필 표기 유틸.
///
/// intl 로케일 초기화 의존을 피하기 위해 수동 포맷을 쓴다
/// (lib/presentation/features/tracking/tracking_format.dart와 동일한 관례).
library;

/// "2024.03.15" 생년월일 표기.
String formatBirthDate(DateTime date) {
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '${date.year}.$m.$d';
}

/// 개월수 배지 라벨. null이면 생년월일 미입력.
String formatAgeBadge(int? ageInMonths) {
  if (ageInMonths == null) return '생년월일 미입력';
  if (ageInMonths < 1) return '신생아';
  return '$ageInMonths개월';
}
