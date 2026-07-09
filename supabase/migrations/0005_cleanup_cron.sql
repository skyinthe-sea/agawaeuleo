-- =============================================================================
-- 0005_cleanup_cron.sql — 유휴 익명 계정 정리 pg_cron 스케줄 (설계서 §3.3)
-- 목적: 주 1회 cleanup-anonymous Edge Function 을 HTTP 호출해, 마지막 활동이
--       90일을 초과한 익명(is_anonymous) 계정을 파기(개인 데이터는 FK cascade).
-- 선행: 0001_schema.sql(pg_net), 0002_rls.sql, 0003_cron.sql(vault·확장 활성화)
-- 멱등성: 익스텐션은 `if not exists`, 스케줄은 unschedule 후 재등록.
-- =============================================================================

-- -----------------------------------------------------------------------------
-- 0. Extensions (0003 에서 이미 켰지만 이 파일만 단독 실행해도 되도록 재확인)
-- -----------------------------------------------------------------------------
create extension if not exists pg_cron;
create extension if not exists pg_net;
create extension if not exists supabase_vault;

-- -----------------------------------------------------------------------------
-- 1. 발주자가 채울 자리 (TODO)
--   (A) 아래 <PROJECT_REF> 를 실제 Supabase 프로젝트 ref 로 치환.
--       예: https://abcd1234.functions.supabase.co/cleanup-anonymous
--       (대체 형식: https://<PROJECT_REF>.supabase.co/functions/v1/cleanup-anonymous)
--   (B) Vault 인증 토큰: 0003 에서 등록한 'refresh_products_token' 을 재사용한다.
--       (두 cron 이 같은 CRON_SECRET 을 공유하는 전제. 별도 시크릿을 쓰려면 아래
--        vault.decrypted_secrets 조회의 name 을 바꾸고 README 에 등록 절차를 추가할 것.)
--       ★ 중요: 이 토큰 값은 cleanup-anonymous 함수의 CRON_SECRET 시크릿과 "완전히
--         동일한 값"이어야 한다. 함수는 Authorization 헤더에서 'Bearer ' 를 뗀 값을
--         CRON_SECRET 과 문자열 비교해 일치할 때만 실행한다(--no-verify-jwt 로 배포).
-- -----------------------------------------------------------------------------

-- -----------------------------------------------------------------------------
-- 2. 스케줄 시각 — 시간대 환산
--   요구: 주 1회. 부하가 낮은 새벽에 실행.
--   pg_cron 은 서버 시간대(Supabase = UTC) 기준으로 동작한다. KST = UTC+9.
--       일요일 04:00 KST = 토요일 19:00 UTC  ->  cron: '0 19 * * 6'
--   (cron 필드: 분 시 일 월 요일. 요일 6 = 토요일(UTC 기준). == KST 일요일 04:00)
-- -----------------------------------------------------------------------------

-- 기존 잡이 있으면 먼저 해제(멱등성)
do $$
begin
  if exists (select 1 from cron.job where jobname = 'cleanup-anonymous-weekly') then
    perform cron.unschedule('cleanup-anonymous-weekly');
  end if;
end $$;

select cron.schedule(
  'cleanup-anonymous-weekly',
  '0 19 * * 6',   -- UTC 토 19:00  ==  KST 일 04:00  (주 1회, KST = UTC+9)
  $CRON$
  select net.http_post(
    url     := 'https://<PROJECT_REF>.functions.supabase.co/cleanup-anonymous',
    headers := jsonb_build_object(
      'Content-Type',  'application/json',
      -- 평문 금지: Vault 에서 토큰을 복호화해 Bearer 헤더 구성 (0003 과 동일 시크릿)
      'Authorization', 'Bearer ' || (
        select decrypted_secret
        from vault.decrypted_secrets
        where name = 'refresh_products_token'
      )
    ),
    body    := jsonb_build_object('source', 'pg_cron', 'job', 'cleanup-anonymous-weekly')
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
--       where j.jobname = 'cleanup-anonymous-weekly'
--       order by d.start_time desc limit 20;
--   즉시 수동 실행(테스트) — Vault 시크릿 등록 후:
--     select net.http_post(
--       url := 'https://<PROJECT_REF>.functions.supabase.co/cleanup-anonymous',
--       headers := jsonb_build_object(
--         'Content-Type','application/json',
--         'Authorization','Bearer ' ||
--           (select decrypted_secret from vault.decrypted_secrets where name='refresh_products_token')
--       )
--     );
--   잡 해제:
--     select cron.unschedule('cleanup-anonymous-weekly');
-- -----------------------------------------------------------------------------
