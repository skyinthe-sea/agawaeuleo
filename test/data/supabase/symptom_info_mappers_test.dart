import 'dart:convert';

import 'package:agawaeuleo/data/supabase/symptom_info_mappers.dart';
import 'package:agawaeuleo/domain/entities/symptom_info.dart';
import 'package:flutter_test/flutter_test.dart';

/// `symptom_infos.sections`/`sources` jsonb 와이어 계약 파싱 검증
/// (lib/data/supabase/symptom_info_mappers.dart).
///
/// 계약: `{"type": "text|steps|checklist|table|qa|tips", ...}` — type 누락 시
/// text, 미지 type·필드 결손은 크래시 없이 text 폴백 또는 원소 스킵.
void main() {
  group('infoSectionsFromJson — 타입 6종', () {
    test('text: {title, body}를 InfoSection.text로 읽는다', () {
      final sections = infoSectionsFromJson([
        {'type': 'text', 'title': '원인', 'body': '본문'},
      ]);
      expect(sections, const [InfoSection.text(title: '원인', body: '본문')]);
    });

    test('steps: intro 선택 + items 순서 보존', () {
      final sections = infoSectionsFromJson([
        {
          'type': 'steps',
          'title': '트림 시키는 방법',
          'intro': '수유 중간에 시도해요.',
          'items': ['어깨에 기대 안기', '등을 아래에서 위로 쓸기'],
        },
      ]);
      expect(sections, const [
        InfoSection.steps(
          title: '트림 시키는 방법',
          intro: '수유 중간에 시도해요.',
          items: ['어깨에 기대 안기', '등을 아래에서 위로 쓸기'],
        ),
      ]);
    });

    test('checklist: intro 없는 형태도 읽는다', () {
      final sections = infoSectionsFromJson([
        {
          'type': 'checklist',
          'title': '외출 전 체크리스트',
          'items': ['기저귀', '여벌 옷'],
        },
      ]);
      expect(sections, const [
        InfoSection.checklist(title: '외출 전 체크리스트', items: ['기저귀', '여벌 옷']),
      ]);
    });

    test('table: columns/rows/caption을 읽고, 행 안 비문자열은 빈칸으로', () {
      final sections = infoSectionsFromJson([
        {
          'type': 'table',
          'title': '보관 기간',
          'columns': ['보관 위치', '기간'],
          'rows': [
            ['냉장', '72시간'],
            ['냉동', null],
          ],
          'caption': '기준은 상이할 수 있어요.',
        },
      ]);
      expect(sections, const [
        InfoSection.table(
          title: '보관 기간',
          columns: ['보관 위치', '기간'],
          rows: [
            ['냉장', '72시간'],
            ['냉동', ''],
          ],
          caption: '기준은 상이할 수 있어요.',
        ),
      ]);
    });

    test('qa: {q, a} 쌍 목록 + 결손 쌍은 스킵', () {
      final sections = infoSectionsFromJson([
        {
          'type': 'qa',
          'title': '자주 묻는 질문',
          'items': [
            {'q': '괜찮나요?', 'a': '대개 괜찮아요.'},
            {'q': 'a가 없는 항목'},
          ],
        },
      ]);
      expect(sections, const [
        InfoSection.qa(
          title: '자주 묻는 질문',
          items: [QaItem(q: '괜찮나요?', a: '대개 괜찮아요.')],
        ),
      ]);
    });

    test('tips: items 목록을 읽는다', () {
      final sections = infoSectionsFromJson([
        {
          'type': 'tips',
          'title': '조리원 실전 팁',
          'items': ['1시간마다 한다고 생각하면 마음이 편해요.'],
        },
      ]);
      expect(sections, const [
        InfoSection.tips(title: '조리원 실전 팁', items: ['1시간마다 한다고 생각하면 마음이 편해요.']),
      ]);
    });
  });

  group('infoSectionsFromJson — 폴백·스킵 (파싱 단위 실패 격리)', () {
    test('type 누락 → text로 해석(기존 [{title, body}] 하위 호환)', () {
      final sections = infoSectionsFromJson([
        {'title': '원인', 'body': '기존 데이터'},
      ]);
      expect(sections, const [InfoSection.text(title: '원인', body: '기존 데이터')]);
    });

    test('미지 type + body 있음 → text 폴백', () {
      final sections = infoSectionsFromJson([
        {'type': 'video', 'title': '새 타입', 'body': '구버전 앱을 위한 본문'},
      ]);
      expect(sections, const [
        InfoSection.text(title: '새 타입', body: '구버전 앱을 위한 본문'),
      ]);
    });

    test('미지 type + body 없음 → 해당 원소만 스킵(전체 로드 생존)', () {
      final sections = infoSectionsFromJson([
        {'type': 'video', 'title': '새 타입', 'url': 'https://example.com'},
        {'type': 'text', 'title': '정상', 'body': '본문'},
      ]);
      expect(sections, const [InfoSection.text(title: '정상', body: '본문')]);
    });

    test('타입 섹션의 필수 필드 결손(items 없음) → body 있으면 text 폴백, 없으면 스킵', () {
      final sections = infoSectionsFromJson([
        {'type': 'steps', 'title': '단계', 'body': '폴백 본문'},
        {'type': 'checklist', 'title': '체크'},
        {
          'type': 'table',
          'title': '표',
          'columns': ['한 열뿐'],
        },
        {'type': 'qa', 'title': '문답', 'items': <Object>[]},
      ]);
      expect(sections, const [InfoSection.text(title: '단계', body: '폴백 본문')]);
    });

    test('jsonb가 문자열로 도착해도(경로 따라) 디코드해 읽는다', () {
      final sections = infoSectionsFromJson(
        jsonEncode([
          {
            'type': 'tips',
            'title': '팁',
            'items': ['하나'],
          },
        ]),
      );
      expect(sections, const [
        InfoSection.tips(title: '팁', items: ['하나']),
      ]);
    });

    test('배열이 아니면 빈 목록', () {
      expect(infoSectionsFromJson(null), isEmpty);
      expect(infoSectionsFromJson({'title': '맵'}), isEmpty);
    });
  });

  group('infoSourcesFromJson', () {
    test('label 필수 + org/url 선택으로 읽는다', () {
      final sources = infoSourcesFromJson([
        {
          'label': '미국소아과학회 영아 수면 안내',
          'org': 'AAP',
          'url': 'https://example.org',
        },
        {'label': '질병관리청 예방접종도우미'},
      ]);
      expect(sources, const [
        InfoSource(
          label: '미국소아과학회 영아 수면 안내',
          org: 'AAP',
          url: 'https://example.org',
        ),
        InfoSource(label: '질병관리청 예방접종도우미'),
      ]);
    });

    test('label 결손·공백 원소는 스킵, 비배열은 빈 목록', () {
      final sources = infoSourcesFromJson([
        {'org': 'WHO'},
        {'label': '  '},
        {'label': '유효한 출처'},
      ]);
      expect(sources, const [InfoSource(label: '유효한 출처')]);
      expect(infoSourcesFromJson(null), isEmpty);
    });
  });
}
