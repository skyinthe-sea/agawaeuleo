-- =============================================================================
-- 0003_cron.sql — pg_cron 스케줄 (설계서 §7.4)
-- 목적: 매일 정해진 시각에 refresh-products Edge Function 을 HTTP 호출해
--       쿠팡 파트너스 제품 캐시(products 테이블)를 갱신.
-- 선행: 0001_schema.sql (pg_net 활성화), 0002_rls.sql
-- 멱등성: 익스텐션은 `if not exists`, 스케줄은 unschedule 후 재등록.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. Extensions
--   pg_cron : 스케줄러 (cron.schedule / cron.job / cron.job_run_details)
--   pg_net  : net.http_post() — 0001 에서 켰지만 이 파일만 단독 실행해도 되도록 재확인
--   supabase_vault : 비밀값 저장. Supabase 프로젝트엔 기본 활성화되어 있음(no-op).
-- -----------------------------------------------------------------------------
create extension if not exists pg_cron;
create extension if not exists pg_net;
create extension if not exists supabase_vault;

-- -----------------------------------------------------------------------------
-- 1. 발주자가 채울 자리 (TODO)
--   (A) 아래 <PROJECT_REF> 를 실제 Supabase 프로젝트 ref 로 치환.
--       예: https://abcd1234.functions.supabase.co/refresh-products
--       (대체 형식: https://<PROJECT_REF>.supabase.co/functions/v1/refresh-products)
--   (B) Vault 에 인증 토큰 시크릿을 등록해 둘 것. 이름은 'refresh_products_token'.
--       ★ 중요: 이 토큰 값은 Edge Function 의 CRON_SECRET 시크릿과 "완전히 동일한 값"이어야
--         한다. refresh-products 함수는 Authorization 헤더에서 'Bearer ' 를 뗀 값을
--         CRON_SECRET 과 문자열 비교해 일치할 때만 실행한다(--no-verify-jwt 로 배포).
--         service_role JWT 등 다른 값을 넣으면 이 검사를 통과하지 못해 cron 이 항상 401 로
--         실패한다. (즉 여기에는 service_role JWT 가 아니라 CRON_SECRET 과 같은 문자열을 넣는다.)
--       평문 키를 이 SQL 에 절대 넣지 말 것 — 아래는 vault 에서 복호화해 읽는다.
--       등록 명령(값만 바꿔 1회 실행, supabase/README.md 참고):
--         select vault.create_secret(
--           '<CRON_SECRET 과 동일한 값>',   -- Edge Function 의 CRON_SECRET 과 같은 문자열
--           'refresh_products_token',
--           'Bearer token for refresh-products cron'
--         );
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 2. 스케줄 시각 — 시간대 환산
--   요구: 매일 05:00, 17:00 KST(한국시간).
--   pg_cron 은 서버 시간대(Supabase = UTC) 기준으로 동작한다.
--   KST = UTC+9 이므로:
--       05:00 KST = 20:00 UTC (전날)   ->  cron 분/시: 0 20
--       17:00 KST = 08:00 UTC          ->  cron 분/시: 0 08
--   합치면 UTC 기준 '0 8,20 * * *'  (== KST 05:00 & 17:00)
-- -----------------------------------------------------------------------------

-- 기존 잡이 있으면 먼저 해제(멱등성)
do $$
begin
  if exists (select 1 from cron.job where jobname = 'refresh-products-daily') then
    perform cron.unschedule('refresh-products-daily');
  end if;
end $$;

select cron.schedule(
  'refresh-products-daily',
  '0 8,20 * * *',   -- UTC 08:00 & 20:00  ==  KST 17:00 & 05:00  (KST = UTC+9)
  $CRON$
  select net.http_post(
    url     := 'https://<PROJECT_REF>.functions.supabase.co/refresh-products',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      -- 평문 금지: Vault 에서 토큰을 복호화해 Bearer 헤더 구성
      'Authorization', 'Bearer ' || (
        select decrypted_secret
        from vault.decrypted_secrets
        where name = 'refresh_products_token'
      )
    ),
    body    := jsonb_build_object('source', 'pg_cron', 'job', 'refresh-products-daily')
  );
  $CRON$
);

-- -----------------------------------------------------------------------------
-- 3. 확인/운영 쿼리 (참고 — 실행은 선택)
--   등록된 잡 목록:
--     select jobid, schedule, jobname, active from cron.job;
--   최근 실행 이력(성공/실패)  ※ job_run_details 에는 jobname 이 없어 jobid 로 조인:
--     select d.status, d.return_message, d.start_time, d.end_time
--       from cron.job_run_details d
--       join cron.job j on j.jobid = d.jobid
--       where j.jobname = 'refresh-products-daily'
--       order by d.start_time desc limit 20;
--   즉시 수동 실행(테스트) — Vault 시크릿 등록 후:
--     select net.http_post(
--       url := 'https://<PROJECT_REF>.functions.supabase.co/refresh-products',
--       headers := jsonb_build_object(
--         'Content-Type','application/json',
--         'Authorization','Bearer ' ||
--           (select decrypted_secret from vault.decrypted_secrets where name='refresh_products_token')
--       )
--     );
--   pg_net 응답 확인:
--     select * from net._http_response order by created desc limit 5;
--   잡 해제:
--     select cron.unschedule('refresh-products-daily');
-- -----------------------------------------------------------------------------
