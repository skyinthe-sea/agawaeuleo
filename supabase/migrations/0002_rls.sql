-- =============================================================================
-- 0002_rls.sql — Row Level Security 정책 (설계서 §7.2 그대로)
-- 선행: 0001_schema.sql (테이블이 먼저 존재해야 함)
-- 멱등성: `drop policy if exists` → `create policy` 로 재실행 안전.
--   (create policy 는 or replace 를 지원하지 않으므로 drop 후 재생성)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 공개 읽기 (마스터 데이터)
--   쓰기 정책 없음 = 클라이언트(anon/authenticated) 쓰기 전면 차단.
--   products 쓰기는 RLS 를 우회하는 service_role(Edge Function)만 수행. (§7.2 주석)
-- -----------------------------------------------------------------------------
alter table symptoms       enable row level security;
alter table symptom_infos  enable row level security;
alter table products       enable row level security;
alter table app_config     enable row level security;

drop policy if exists "public read symptoms"      on symptoms;
drop policy if exists "public read symptom_infos" on symptom_infos;
drop policy if exists "public read products"      on products;
drop policy if exists "public read app_config"    on app_config;

create policy "public read symptoms"      on symptoms      for select using (true);
create policy "public read symptom_infos" on symptom_infos for select using (true);
create policy "public read products"      on products      for select using (is_active);
create policy "public read app_config"    on app_config    for select using (true);

-- -----------------------------------------------------------------------------
-- 개인 데이터: 본인 것만 (SELECT/INSERT/UPDATE/DELETE 전부 = for all)
--   using       → 읽기/수정/삭제 대상 행 필터
--   with check  → 삽입/수정 결과 행 검증 (남의 user_id 로 위조 삽입 차단)
-- -----------------------------------------------------------------------------
alter table babies        enable row level security;
alter table tracking_logs enable row level security;
alter table favorites     enable row level security;

drop policy if exists "own babies"    on babies;
drop policy if exists "own logs"      on tracking_logs;
drop policy if exists "own favorites" on favorites;

create policy "own babies"    on babies        for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own logs"      on tracking_logs for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
create policy "own favorites" on favorites     for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- -----------------------------------------------------------------------------
-- 익명(게스트) 사용자 노트 (§7.2)
--   Supabase 익명 로그인도 auth.uid() 가 발급되므로 위 "own *" 정책이 수정 없이
--   그대로 동작한다. 이후 linkIdentity() 로 계정 연결해도 user_id 가 유지되어
--   데이터 이관이 불필요. 익명만 배제하려면 JWT 의 is_anonymous 클레임
--   ((auth.jwt() ->> 'is_anonymous')::boolean = false) 조건을 개별 정책에 추가.
-- -----------------------------------------------------------------------------

-- =============================================================================
-- 계정 삭제 시 cascade 검증 (보조 주석 — 별도 트리거/코드 불필요)
-- -----------------------------------------------------------------------------
-- 요구: auth.users 의 사용자 행이 삭제될 때(계정 삭제) 그 사용자의 개인 데이터가
--       모두 자동 삭제(cascade)되는가?  → 0001_schema.sql 의 FK 로 이미 보장됨.
--
--   babies.user_id        -> auth.users(id)  ON DELETE CASCADE   [not null]
--   tracking_logs.user_id -> auth.users(id)  ON DELETE CASCADE   [not null]
--   tracking_logs.baby_id -> babies(id)      ON DELETE CASCADE   [nullable]
--   favorites.user_id     -> auth.users(id)  ON DELETE CASCADE   [not null]
--
--   ▶ auth.users 행 DELETE 시:
--       - babies         : user_id cascade 로 삭제
--       - tracking_logs  : user_id cascade 로 삭제 (baby_id 경로와 무관하게 직접 삭제되므로 고아 없음)
--       - favorites      : user_id cascade 로 삭제
--     => 사용자 소유 데이터에 고아(orphan) 행이 남지 않음. 별도 정리 로직 불필요.
--
--   ▶ 마스터 데이터(symptoms, symptom_infos, products, app_config)는 auth.users
--     로의 FK 가 없으므로 계정 삭제의 영향을 받지 않음(정상).
--
--   ▶ 계정 삭제 실행 주체: auth.users 삭제는 service_role/Admin API
--     (auth.admin.deleteUser) 로만 가능. 클라이언트는 자기 auth.users 행을
--     직접 지울 수 없으므로, 앱의 "회원 탈퇴"는 서버(Edge Function 등)에서
--     admin 권한으로 호출해야 위 cascade 가 발동한다.
--
--   ▶ 결론: 계정 삭제용 추가 FK/트리거 불필요. §7.1 FK 정의만으로 요구 충족.
-- =============================================================================
