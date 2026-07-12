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
