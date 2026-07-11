-- =============================================================================
-- 0008_care_columns.sql — 케어 콘텐츠 확장 컬럼 (audience, sources)
-- 적용: supabase db push  (또는 대시보드 SQL 에디터에서 실행)
-- 선행: 0001_schema.sql (symptoms, symptom_infos)
-- 멱등성: `add column if not exists` + 제약은 pg_constraint 존재 검사 후 추가로
--   재실행 안전.
--
-- 목적:
--   1) symptoms.audience — 카드 대상 구분('baby'|'mom'). 홈 그리드가
--      '아기 돌봄'/'엄마 돌봄' 2그룹으로 나뉘는 기준이자(§11.7 개정),
--      상세 의학 면책 문구 분기 기준(§13.3 — mom은 산부인과 안내).
--      기존 16종 행은 default 'baby'가 그대로 적용된다(update 불필요).
--   2) symptom_infos.sources — 참고 자료 출처 jsonb 배열
--      `[{"label": "...", "org": "...", "url": "..."}]` (org/url 선택).
--      상세 화면은 label만 불릿 리스트로 노출(탭 액션·URL 노출 없음 — §11.9
--      개정). 실존 문서만 기재(허위 인용 금지 — CONTENT_REVIEW.md).
--
-- 참고: sections jsonb 원소는 타입 섹션 계약으로 확장됨 —
--   `{"type": "text|steps|checklist|table|qa|tips", ...}` (type 누락 시 text).
--   스키마 변경은 없고(기존 jsonb 그대로) 앱 파서가 해석한다
--   (lib/data/supabase/symptom_info_mappers.dart).
-- =============================================================================

-- 1) symptoms.audience -------------------------------------------------------

alter table symptoms add column if not exists audience text not null default 'baby';

-- check 제약은 `add constraint if not exists`가 없어 존재 검사로 멱등 처리.
do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'symptoms_audience_check'
      and conrelid = 'symptoms'::regclass
  ) then
    alter table symptoms
      add constraint symptoms_audience_check
      check (audience in ('baby', 'mom'));
  end if;
end;
$$;

comment on column symptoms.audience is
  '카드 대상: baby(아기, 기본)|mom(산모). 홈 2그룹 렌더·상세 면책 문구 분기 기준(§11.7/§13.3)';

-- 2) symptom_infos.sources ---------------------------------------------------

alter table symptom_infos add column if not exists sources jsonb not null default '[]';

comment on column symptom_infos.sources is
  '참고 자료 출처 [{label, org?, url?}] — 앱은 label만 노출, url은 검수용(§11.9, CONTENT_REVIEW.md)';
