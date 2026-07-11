-- =============================================================================
-- 0007_symptom_tagline.sql — 증상 카드 한 줄 설명(tagline) 컬럼
-- 적용: supabase db push  (또는 대시보드 SQL 에디터에서 실행)
-- 선행: 0001_schema.sql (symptoms), 0004_seed.sql (colic 행)
-- 멱등성: `add column if not exists` + slug 조건 update 로 재실행 안전.
--
-- 목적: 홈 일러스트 카드(§11.7 개정)의 제목 아래 한 줄 설명을 DB에서 관리
--   (증상 데이터 앱 하드코딩 금지 원칙 — §5.2). 등록된 일러스트 증상부터
--   채워 나가며, null 인 증상은 카드가 설명 줄을 생략한다.
--
-- ⚠️ 콘텐츠 카피 — 의학 문구 검수 대상(§13.3, supabase/CONTENT_REVIEW.md).
--   증상을 '설명'만 하는 참고용 톤 유지, 진단 단정/치료 권유 표현 금지.
--   카드 폭 특성상 12자 내외 권장(초과 시 앱이 2줄 말줄임 처리).
-- =============================================================================

alter table symptoms add column if not exists tagline text;

comment on column symptoms.tagline is
  '홈 카드 한 줄 설명(참고용 톤, 12자 내외 권장 — §11.7 일러스트 카드)';

-- 배앓이(트라이얼 1종) — 시드 summary(0004) 표현 범위 내 축약.
update symptoms
set tagline = '이유 없이 심하게 울 때'
where slug = 'colic';
