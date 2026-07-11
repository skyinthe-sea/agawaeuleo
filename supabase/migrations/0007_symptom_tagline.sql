-- =============================================================================
-- 0007_symptom_tagline.sql — 증상 카드 한 줄 설명(tagline) 컬럼 + 16종 값
-- 적용: supabase db push  (또는 대시보드 SQL 에디터에서 실행)
-- 선행: 0001_schema.sql (symptoms), 0004_seed.sql (16종 행)
-- 멱등성: `add column if not exists` + slug 조건 update 로 재실행 안전.
--
-- 목적: 홈 일러스트 카드(§11.7 개정)의 제목 아래 한 줄 설명을 DB에서 관리
--   (증상 데이터 앱 하드코딩 금지 원칙 — §5.2). null 인 증상은 카드가
--   설명 줄을 생략한다.
--
-- ⚠️ 콘텐츠 카피 — 의학 문구 검수 대상(§13.3, supabase/CONTENT_REVIEW.md).
--   증상을 '설명'만 하는 참고용 톤 유지, 진단 단정/치료 권유 표현 금지.
--   카드 레이아웃 특성상 공백 포함 8자 이내(한 줄 고정 — 초과 시 앱이
--   말줄임 처리). 픽스처(fixture_symptoms.dart)와 값을 동일하게 유지할 것.
-- =============================================================================

alter table symptoms add column if not exists tagline text;

comment on column symptoms.tagline is
  '홈 카드 한 줄 설명(참고용 톤, 공백 포함 8자 이내 — §11.7 일러스트 카드)';

update symptoms as s
set tagline = v.tagline
from (
  values
    ('colic',                 '영아산통·가스'),
    ('teething',              '간질간질 잇몸'),
    ('newborn_heat_rash',     '발그레한 얼굴'),
    ('stool_color_abnormal',  '달라진 변 색깔'),
    ('burping_trouble',       '트림이 힘들 때'),
    ('spit_up_reflux',        '주르륵 게워냄'),
    ('runny_stuffy_nose',     '훌쩍이는 코'),
    ('fever',                 '뜨끈한 이마'),
    ('rash',                  '오돌토돌 피부'),
    ('sleep_regression',      '자주 깨는 밤'),
    ('constipation',          '며칠째 끙끙'),
    ('diarrhea',              '자꾸 묽은 변'),
    ('hiccups',               '깜짝깜짝 딸꾹'),
    ('prickly_heat',          '송골송골 좁쌀'),
    ('jaundice',              '노르스름 피부'),
    ('eye_discharge_tearing', '눈곱 낀 아침')
) as v(slug, tagline)
where s.slug = v.slug;
