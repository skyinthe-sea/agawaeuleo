import '../../domain/entities/symptom_info.dart';
import 'row_mappers.dart';

/// `symptom_infos.sections`/`sources` jsonb ↔ 도메인 매핑 (§7.1 와이어 계약).
///
/// 원소 계약: `{"type": "text|steps|checklist|table|qa|tips", ...}`.
/// - `type` 누락 → text로 해석(기존 `[{title, body}]` 데이터와 하위 호환).
/// - 알 수 없는 `type`·필수 필드 결손 → **크래시 없이** body가 있으면 text
///   폴백, 없으면 해당 원소만 스킵. 파싱 단위 실패가 전체 참고정보 로드를
///   죽이면 안 된다(콘텐츠는 DB에서 관리되므로 방어적 파싱이 계약).

/// `sections` jsonb 배열 → [InfoSection] 목록. 파싱 불가 원소는 스킵.
List<InfoSection> infoSectionsFromJson(Object? value) => asMapList(
  value,
).map(infoSectionFromJson).whereType<InfoSection>().toList(growable: false);

/// `sections` 원소 1건 → [InfoSection]. 해석 불가 시 null(스킵 신호).
InfoSection? infoSectionFromJson(Map<String, dynamic> map) {
  final type = map['type'];
  final title = _string(map['title']);
  switch (type) {
    // type 누락(기존 데이터) 또는 명시적 text.
    case null || 'text':
      return InfoSection.text(title: title, body: _string(map['body']));
    case 'steps':
      final items = _stringItems(map['items']);
      if (items.isEmpty) return _textFallback(map);
      return InfoSection.steps(
        title: title,
        intro: _stringOrNull(map['intro']),
        items: items,
      );
    case 'checklist':
      final items = _stringItems(map['items']);
      if (items.isEmpty) return _textFallback(map);
      return InfoSection.checklist(
        title: title,
        intro: _stringOrNull(map['intro']),
        items: items,
      );
    case 'table':
      final columns = _stringItems(map['columns']);
      final rows = _rowItems(map['rows']);
      if (columns.isEmpty || rows.isEmpty) return _textFallback(map);
      return InfoSection.table(
        title: title,
        columns: columns,
        rows: rows,
        caption: _stringOrNull(map['caption']),
      );
    case 'qa':
      final items = _qaItems(map['items']);
      if (items.isEmpty) return _textFallback(map);
      return InfoSection.qa(title: title, items: items);
    case 'tips':
      final items = _stringItems(map['items']);
      if (items.isEmpty) return _textFallback(map);
      return InfoSection.tips(title: title, items: items);
    // 알 수 없는 type(신규 타입이 구버전 앱에 도달한 경우 등).
    default:
      return _textFallback(map);
  }
}

/// `sources` jsonb 배열 → [InfoSource] 목록. label 없는 원소는 스킵.
List<InfoSource> infoSourcesFromJson(Object? value) => [
  for (final map in asMapList(value))
    if (_stringOrNull(map['label']) != null)
      InfoSource(
        label: _string(map['label']),
        org: _stringOrNull(map['org']),
        url: _stringOrNull(map['url']),
      ),
];

/// 필드 결손·미지 type의 마지막 방어선 — body가 있으면 text로 읽고, 그마저
/// 없으면 null(원소 스킵).
InfoSection? _textFallback(Map<String, dynamic> map) {
  final body = _stringOrNull(map['body']);
  if (body == null) return null;
  return InfoSection.text(title: _string(map['title']), body: body);
}

String _string(Object? value) => value is String ? value : '';

String? _stringOrNull(Object? value) =>
    value is String && value.trim().isNotEmpty ? value : null;

/// `items`/`columns` — 문자열 배열. 문자열이 아닌 원소·공백 원소는 버린다.
List<String> _stringItems(Object? value) {
  if (value is! List) return const [];
  return value
      .whereType<String>()
      .where((e) => e.trim().isNotEmpty)
      .toList(growable: false);
}

/// `rows` — 문자열 2차원 배열. 행 안 비문자열 원소는 ''로, 빈 행은 스킵.
List<List<String>> _rowItems(Object? value) {
  if (value is! List) return const [];
  return [
    for (final row in value)
      if (row is List && row.isNotEmpty)
        [for (final cell in row) cell is String ? cell : ''],
  ];
}

/// `qa.items` — `{q, a}` 쌍 목록. 어느 한쪽이라도 결손이면 해당 쌍 스킵.
List<QaItem> _qaItems(Object? value) {
  if (value is! List) return const [];
  return [
    for (final item in value)
      if (item is Map &&
          _stringOrNull(item['q']) != null &&
          _stringOrNull(item['a']) != null)
        QaItem(q: item['q'] as String, a: item['a'] as String),
  ];
}
