-- ==============================================================================
-- apply_live_wiring.sql — 앱 라이브(실데이터) 모드 배선 (안전 번들)
-- 0007(tagline) + 0008(audience/sources 컬럼) + 0010(content_versions 매니페스트)
-- 모두 멱등(add column if not exists / on conflict / create or replace). 대시보드
-- SQL 에디터에 통째로 붙여넣어 실행하면 됨. 의학 콘텐츠 시드(0009)는 포함 안 함.
-- ==============================================================================

-- ───────── 0007_symptom_tagline.sql ─────────
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

-- ───────── 0008_care_columns.sql ─────────
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

-- ───────── 0010_content_versions.sql ─────────
-- =============================================================================
-- 0010_content_versions.sql — 콘텐츠 버전 매니페스트 (서버 주도 캐시 무효화)
-- 적용: supabase db push  (또는 대시보드 SQL 에디터에서 실행)
-- 선행: 0001_schema.sql (symptoms/symptom_infos/products), 0002_rls.sql.
--
-- 목적(§5.3 캐싱 기능):
--   마스터 데이터를 클라이언트가 로컬 Drift 캐시(cache_meta·cached_*)에 보관하고,
--   이 매니페스트로 신선도만 검증한다(stale-while-revalidate). `content_versions`는
--   데이터셋별 버전 정수 1행씩을 갖고, 마스터 테이블이 바뀌면 **트리거가 자동으로**
--   해당 버전을 올린다. 클라이언트(MasterDataCacheService)는 부팅·복귀·단일 realtime
--   구독으로 이 값을 읽어, 로컬과 다른 데이터셋만 재조회한다.
--
--   핵심: 어드민/운영자는 symptoms·symptom_infos·products를 평범하게 CRUD 하면 되고,
--   매니페스트는 손대지 않는다 — 트리거가 대신 올리므로 무효화를 빠뜨릴 수 없다.
--   어떤 write 경로(어드민 UI·SQL 콘솔·대량 임포트)에서도 동일하게 동작한다.
--
--   dataset 키는 클라이언트와 공유하는 문자열 계약: 'symptoms' | 'symptom_infos'
--   | 'products'. 신규 마스터 테이블을 추가하면 여기에도 (1) content_versions 행,
--   (2) bump 트리거를 함께 추가해야 한다.
--
-- 멱등성: create table if not exists / create or replace / drop trigger if exists /
--   on conflict do nothing / 정책·퍼블리케이션 존재 검사로 재실행 안전.
-- =============================================================================

begin;

-- 1) 매니페스트 테이블 -------------------------------------------------------

create table if not exists content_versions (
  dataset    text primary key,
  version    bigint      not null default 1,
  updated_at timestamptz not null default now()
);

comment on table content_versions is
  '데이터셋별 콘텐츠 버전(§5.3 캐시 무효화). 트리거가 마스터 변경 시 자동 증가. '
  'dataset ∈ {symptoms, symptom_infos, products} — 클라이언트 cache_meta와 공유 계약';

-- 초기 행(각 데이터셋 1건). 이미 있으면 유지.
insert into content_versions (dataset) values
  ('symptoms'),
  ('symptom_infos'),
  ('products')
on conflict (dataset) do nothing;

-- 2) 자동 증가 트리거 함수 ---------------------------------------------------
--   FOR EACH STATEMENT: 한 문장(트랜잭션)당 1회만 올린다 — 대량 편집에도 버전이
--   폭증하지 않는다(수렴에는 "바뀜/안 바뀜"만 필요). SECURITY DEFINER: 누가
--   마스터를 바꾸든(어드민/서비스롤) content_versions 갱신 권한을 함수 소유자
--   권한으로 보장한다(별도 write 정책 불필요). search_path 고정으로 하이재킹 방지.

create or replace function bump_content_version()
  returns trigger
  language plpgsql
  security definer
  set search_path = public
as $$
begin
  update content_versions
     set version = version + 1,
         updated_at = now()
   where dataset = tg_argv[0];
  return null;
end;
$$;

comment on function bump_content_version() is
  '트리거 인자(tg_argv[0])로 지정한 데이터셋의 content_versions.version 을 +1. '
  'AFTER ... FOR EACH STATEMENT 로 사용(§5.3)';

-- 3) 마스터 테이블 트리거 배선 -----------------------------------------------

drop trigger if exists trg_bump_symptoms_version on symptoms;
create trigger trg_bump_symptoms_version
  after insert or update or delete on symptoms
  for each statement execute function bump_content_version('symptoms');

drop trigger if exists trg_bump_symptom_infos_version on symptom_infos;
create trigger trg_bump_symptom_infos_version
  after insert or update or delete on symptom_infos
  for each statement execute function bump_content_version('symptom_infos');

drop trigger if exists trg_bump_products_version on products;
create trigger trg_bump_products_version
  after insert or update or delete on products
  for each statement execute function bump_content_version('products');

-- 4) RLS — 공개 읽기(마스터 테이블과 동일 정책 문법, 0002_rls.sql 참조) --------
--   쓰기 정책 없음 → anon 은 write 불가. 갱신은 트리거(SECURITY DEFINER)와
--   service_role/어드민(RLS 우회 또는 별도 write 정책)만 수행.

alter table content_versions enable row level security;

drop policy if exists "public read content_versions" on content_versions;
create policy "public read content_versions"
  on content_versions for select using (true);

-- 5) Realtime 퍼블리케이션 등록 ----------------------------------------------
--   클라이언트가 supabase `.stream()`(단일 채널)으로 매니페스트 변화를 즉시
--   받도록 supabase_realtime 퍼블리케이션에 추가한다. 퍼블리케이션이 있고,
--   아직 멤버가 아닐 때만(FOR ALL TABLES 이면 이미 포함되어 skip) 추가한다.

do $$
begin
  if exists (
    select 1 from pg_publication where pubname = 'supabase_realtime'
  ) and not exists (
    select 1
    from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'content_versions'
  ) then
    alter publication supabase_realtime add table content_versions;
  end if;
end;
$$;

commit;
