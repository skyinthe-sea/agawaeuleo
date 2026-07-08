import 'dart:convert';

/// Supabase(postgrest) 원시 행 값을 Dart 타입으로 변환하는 헬퍼 모음.
///
/// 엔티티 생성 시 컬럼값 정규화에 공용으로 쓴다. postgrest는 jsonb를 이미 디코드해
/// 넘기지만, 경로에 따라 문자열로 올 수 있어 방어적으로 처리한다.

/// text 배열을 문자열 목록으로. null이거나 List가 아니면 빈 목록.
List<String> asStringList(Object? value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList(growable: false);
  }
  return const [];
}

/// jsonb 배열을 맵 목록으로. 문자열이면 우선 디코드. null이면 빈 목록.
List<Map<String, dynamic>> asMapList(Object? value) {
  final decoded = value is String ? jsonDecode(value) : value;
  if (decoded is List) {
    return decoded
        .whereType<Map>()
        .map((e) => e.map((k, v) => MapEntry(k.toString(), v)))
        .toList(growable: false);
  }
  return const [];
}

/// timestamptz/date 문자열을 DateTime으로.
DateTime parseDate(Object? value) => DateTime.parse(value! as String);

/// nullable timestamptz/date 문자열을 DateTime으로.
DateTime? parseDateOrNull(Object? value) =>
    value == null ? null : DateTime.parse(value as String);

/// numeric/int 값을 int로.
int? asIntOrNull(Object? value) => (value as num?)?.toInt();

/// numeric 값을 double로.
double? asDoubleOrNull(Object? value) => (value as num?)?.toDouble();

/// DateTime을 YYYY-MM-DD 문자열로(Postgres date 컬럼 저장용).
String toDateOnly(DateTime date) =>
    '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';
