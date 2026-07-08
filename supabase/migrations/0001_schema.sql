-- =============================================================================
-- 0001_schema.sql — agawaeuleo 스키마 (설계서 §7.1 그대로)
-- 적용: supabase db push  (또는 대시보드 SQL 에디터에서 순서대로 실행)
-- 순서: 0001_schema.sql → 0002_rls.sql → 0003_cron.sql
-- 멱등성: 모든 오브젝트는 `if not exists` / `or replace` 로 재실행 안전.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. Extensions
--   pgcrypto : gen_random_uuid() (PG13+ 코어에도 있으나 명시적으로 보장)
--   pg_net   : net.http_post() — 0003_cron.sql 에서 Edge Function 호출에 사용.
--              (여기서 미리 켜 둔다. Supabase 에선 extensions 스키마에 설치됨)
-- -----------------------------------------------------------------------------
create extension if not exists pgcrypto;
create extension if not exists pg_net;

-- -----------------------------------------------------------------------------
-- 1. 마스터 데이터 (공개 읽기 대상)
-- -----------------------------------------------------------------------------

-- 증상 마스터
create table if not exists symptoms (
  id            uuid primary key default gen_random_uuid(),
  slug          text unique not null,           -- 'colic', 'teething' ...
  name          text not null,                  -- '배앓이'
  chosung       text not null,                  -- 'ㅂㅇㅇ' (검색용, 저장 시 생성)
  aliases       text[] default '{}',            -- 동의어 ['가스', '영아산통']
  emoji_or_icon text,                            -- 아이콘 키
  product_keywords text[] default '{}',          -- 제품 검색 키워드(Edge Function이 사용 — 코드 수정 없이 DB에서 관리)
  order_index   int default 0,
  is_active     boolean default true,
  created_at    timestamptz default now()
);

-- 증상별 의학 참고정보 (섹션형)
create table if not exists symptom_infos (
  id          uuid primary key default gen_random_uuid(),
  symptom_id  uuid references symptoms(id) on delete cascade,
  summary     text not null,                    -- 2~3문장 요약
  sections    jsonb not null default '[]',      -- [{title, body}] 형태
  emergency   jsonb default '[]',               -- 응급신호 배열 [{sign, action}]
  updated_at  timestamptz default now()
);

-- 제품 캐시 (파트너스 API 결과, Edge Function이 upsert)
create table if not exists products (
  id             uuid primary key default gen_random_uuid(),
  symptom_id     uuid references symptoms(id) on delete cascade,
  coupang_pid    text not null,                 -- 쿠팡 상품 식별자
  title          text not null,
  image_url      text,
  price          int,
  rating         numeric,
  deeplink       text not null,                 -- 내 코드 포함 파트너스 링크
  rank_index     int default 0,
  is_active      boolean default true,
  fetched_at     timestamptz default now(),
  unique(symptom_id, coupang_pid)
);

-- -----------------------------------------------------------------------------
-- 2. 개인 데이터 (auth.users 소유, RLS 로 본인만 접근 — 0002_rls.sql)
-- -----------------------------------------------------------------------------

-- 아기 프로필 (사용자 소유)
create table if not exists babies (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade not null,
  name        text not null,
  birth_date  date,
  gender      text,                              -- 'male'|'female'|'na'
  created_at  timestamptz default now()
);

-- 육아 기록
create table if not exists tracking_logs (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade not null,
  baby_id     uuid references babies(id) on delete cascade,
  type        text not null,                     -- 'feed'|'sleep'|'diaper'
  subtype     text,                              -- feed: 'breast'|'formula'|'solid' 등
  amount      numeric,                           -- ml, 분 등
  note        text,
  started_at  timestamptz not null,
  ended_at    timestamptz,
  created_at  timestamptz default now()
);

-- 즐겨찾기
create table if not exists favorites (
  id          uuid primary key default gen_random_uuid(),
  user_id     uuid references auth.users(id) on delete cascade not null,
  target_type text not null,                     -- 'symptom'|'product'
  target_id   uuid not null,
  created_at  timestamptz default now(),
  unique(user_id, target_type, target_id)
);

-- 원격 설정(강제 업데이트/점검 모드)
create table if not exists app_config (
  key   text primary key,                        -- 'min_version_ios' 등
  value jsonb not null
);

-- -----------------------------------------------------------------------------
-- 3. 트리거 — symptom_infos.updated_at 자동 갱신
--   UPDATE 시마다 updated_at 을 now() 로 덮어써서 캐시 무효화/동기화 판단에 사용.
-- -----------------------------------------------------------------------------
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at := now();
  return new;
end;
$$;

drop trigger if exists trg_symptom_infos_set_updated_at on symptom_infos;
create trigger trg_symptom_infos_set_updated_at
  before update on symptom_infos
  for each row
  execute function public.set_updated_at();

-- -----------------------------------------------------------------------------
-- 4. 조회 인덱스 (자주 쓰는 쿼리 경로)
-- -----------------------------------------------------------------------------

-- 증상 상세: 활성 제품을 rank 순으로 조회
--   WHERE symptom_id = ? AND is_active ORDER BY rank_index
create index if not exists idx_products_symptom_active_rank
  on products (symptom_id, is_active, rank_index);

-- 기록 목록: 특정 사용자/아기의 최신순 타임라인
--   WHERE user_id = ? [AND baby_id = ?] ORDER BY started_at DESC
create index if not exists idx_tracking_logs_user_baby_started
  on tracking_logs (user_id, baby_id, started_at desc);

-- 즐겨찾기 목록: 사용자별 조회
--   (참고: unique(user_id, target_type, target_id) 가 user_id 선두 인덱스를 이미
--    제공하지만, 설계서 요구대로 단일 컬럼 인덱스도 명시적으로 둔다.)
create index if not exists idx_favorites_user
  on favorites (user_id);
