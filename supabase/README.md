# agawaeuleo — Supabase 백엔드 (마이그레이션 · RLS · Cron)

발주자용 운영 가이드. 설계서 §7(스키마·RLS·Edge Function·pg_cron) 기준.

## 구성 파일

| 파일 | 내용 | 설계서 |
|---|---|---|
| `migrations/0001_schema.sql` | 테이블 8종 + 확장(pgcrypto·pg_net) + updated_at 트리거 + 조회 인덱스 | §7.1 |
| `migrations/0002_rls.sql` | RLS 정책(공개 읽기 / 본인 소유) + 계정삭제 cascade 검증 주석 | §7.2 |
| `migrations/0003_cron.sql` | pg_cron 스케줄(매일 KST 05:00·17:00) → Edge Function 호출 | §7.4 |
| `migrations/0004_seed.sql` | 증상 16종 + 증상별 참고정보 시드 (**의료 콘텐츠 초안 — 배포 전 검수 필수**) | §3.1·§13.3 |
| `migrations/0005_cleanup_cron.sql` | pg_cron 스케줄(주 1회 KST 일 04:00) → 유휴 익명 계정 정리 Edge Function 호출 | §3.3 |
| `migrations/0006_encouragements.sql` | 홈 "오늘의 응원" 문구 테이블 + 100개 시드 (**콘텐츠 카피 — 검수 권장**) | §11.7 |
| `migrations/0007_symptom_tagline.sql` | `symptoms.tagline` 컬럼(홈 카드 한 줄 설명) + 배앓이 값 (**의료 카피 검수 대상**) | §11.7·§13.3 |
| `migrations/0008_care_columns.sql` | `symptoms.audience`('baby'/'mom') + `symptom_infos.sources` 컬럼 (v1.3) | §7.1·§16.4 |
| `migrations/0009_care_seed.sql` | **카드 32종 + 참고정보 전면 증보 시드 — 0004 콘텐츠를 대체** (**의료 콘텐츠 초안 — 배포 전 검수 필수, 0008 선행**) | §3.1·§13.3·§16.4 |
| `functions/refresh-products/` | 제품 갱신 Edge Function (별도 작업) | §7.3 |
| `functions/delete-account/` | 계정 삭제 Edge Function (앱 내 회원 탈퇴, 스토어 필수) | §3.3·§11.16·§13.4 |
| `functions/cleanup-anonymous/` | 유휴 익명 계정 정리 Edge Function (90일 초과 미사용 게스트 파기) | §3.3 |

마이그레이션은 파일명 순서(0001 → … → 0009)대로 적용해야 한다. FK·RLS·cron·시드가 앞 단계 오브젝트에 의존한다(특히 **0009 는 0008 의 audience/sources 컬럼을 전제**로 하고, 앱의 원격 조회도 0008 컬럼을 select 하므로 **0008 적용과 앱 배포를 같은 릴리스로** 묶을 것).

> ⚠️ **0004/0009 시드는 검수 전 프로덕션 금지**: 시드의 의학 문구는 Claude 가 작성한 초안이며
> 배포 전 의료 전문가 검수가 필요하다(체크리스트: `supabase/CONTENT_REVIEW.md` — v1.3 부터 32종).
> `supabase db push` 는 `migrations/*.sql` 을 **전부** 적용하므로 검수 완료 전에는 프로덕션에
> push 하지 말 것. (개발/스테이징 프로젝트에만 push 하거나, 검수 완료 시까지 0004·0009 를 임시 제외.)

## 1. 사전 준비

```bash
# Supabase CLI 설치 (미설치 시)
brew install supabase/tap/supabase

# 프로젝트 로그인 & 링크 (한 번만)
supabase login
supabase link --project-ref <PROJECT_REF>
```

`<PROJECT_REF>` 는 대시보드 Project Settings → General 의 Reference ID.

## 2. 마이그레이션 적용 — `supabase db push`

```bash
# 저장소 루트에서 실행. supabase/migrations/*.sql 을 파일명 순서대로 원격 DB에 적용.
supabase db push
```

- 모든 SQL 은 멱등(`if not exists` / `drop policy…create` / cron `unschedule…schedule` / 시드 `upsert`)하게 작성되어 **재실행해도 안전**하다.
- 대시보드 SQL 에디터에서 직접 실행할 경우에도 **0001 → 0002 → 0003 → 0004 순서**를 지킬 것.
- `db push` 는 `0004_seed.sql`(의료 콘텐츠 초안)까지 적용한다. **프로덕션에는 CONTENT_REVIEW.md 검수 완료 후에만** 적용할 것(위 경고 참조).

적용 후 스키마만 다시 확인하려면:
```bash
supabase db diff        # 로컬 정의와 원격 스키마 차이 확인
```

## 3. Vault 시크릿 등록 (cron 이 쓰는 인증 토큰)

`0003_cron.sql` 은 인증 토큰을 SQL 에 평문으로 넣지 않고 **Supabase Vault** 에서 복호화해 읽는다(`vault.decrypted_secrets`). 시크릿 이름은 **`refresh_products_token`** 로 고정.

> ★ **토큰 값은 Edge Function 의 `CRON_SECRET` 시크릿과 반드시 동일한 문자열**이어야 한다.
> `refresh-products` 함수는 들어온 `Authorization` 헤더(`Bearer ` 제거 후)를 `CRON_SECRET`
> 과 그대로 비교해 일치할 때만 실행한다(`--no-verify-jwt` 로 배포). 여기에 `service_role`
> JWT 를 넣으면 그 값은 `CRON_SECRET` 과 다르므로 cron 이 **항상 401 로 실패**한다.

대시보드 SQL 에디터(또는 `supabase db` 세션)에서 **1회** 실행:

```sql
select vault.create_secret(
  '<CRON_SECRET 과 동일한 값>',   -- ← Edge Function 의 CRON_SECRET 과 같은 문자열
  'refresh_products_token',
  'Bearer token for refresh-products cron'
);
```

토큰 값 갱신(교체) 시:
```sql
-- 기존 시크릿 id 조회 후 갱신
select id from vault.secrets where name = 'refresh_products_token';
select vault.update_secret('<위에서 조회한 id>', '<새 토큰 값>');
```

> 주의: `CRON_SECRET`(= 이 Vault 토큰 값)은 함수 호출을 보호하는 공유 비밀이다. 앱(.env)·클라이언트에는 절대 넣지 말고 Vault/Edge Function Secrets 에만 둘 것(설계서 §8.1). `openssl rand -hex 32` 등으로 생성한 무작위 문자열을 권장한다.

## 4. cron URL 치환 (발주자 필수 작업)

`migrations/0003_cron.sql` 안의 `<PROJECT_REF>` 를 실제 프로젝트 ref 로 바꾼 뒤 push 해야 한다. 호출 URL 형식:

```
https://<PROJECT_REF>.functions.supabase.co/refresh-products
# 대체 형식
https://<PROJECT_REF>.supabase.co/functions/v1/refresh-products
```

대시보드 **Integrations → Cron** UI 로 등록해도 동일(pg_cron). SQL 로 이미 등록했다면 UI 중복 등록은 피할 것.

## 5. 스케줄 시각 (시간대 주의)

pg_cron 은 **UTC** 기준으로 동작한다. 요구 시각은 KST(한국시간) 05:00·17:00.

| KST | UTC | cron |
|---|---|---|
| 05:00 | 20:00 (전날) | `0 20 * * *` |
| 17:00 | 08:00 | `0 8 * * *` |

→ 합쳐서 `0 8,20 * * *` (UTC) == 매일 KST 05:00 & 17:00.

## 6. Cron 확인 방법

```sql
-- 등록된 잡 확인
select jobid, schedule, jobname, active from cron.job;

-- 최근 실행 이력(성공/실패/반환코드)
-- ※ cron.job_run_details 에는 jobname 컬럼이 없으므로 cron.job 과 jobid 로 조인
select d.status, d.return_message, d.start_time, d.end_time
  from cron.job_run_details d
  join cron.job j on j.jobid = d.jobid
  where j.jobname = 'refresh-products-daily'
  order by d.start_time desc
  limit 20;

-- pg_net HTTP 응답 확인
select * from net._http_response order by created desc limit 5;

-- 즉시 수동 실행(테스트) — Vault 시크릿 등록 후
select net.http_post(
  url := 'https://<PROJECT_REF>.functions.supabase.co/refresh-products',
  headers := jsonb_build_object(
    'Content-Type','application/json',
    'Authorization','Bearer ' ||
      (select decrypted_secret from vault.decrypted_secrets where name='refresh_products_token')
  )
);

-- 잡 해제(필요 시)
select cron.unschedule('refresh-products-daily');
```

## 7. Edge Function 배포 (참고 — §7.3)

제품 갱신 함수 자체는 별도로 배포한다. 쿠팡 키는 **Edge Function Secrets** 에만 존재한다(앱 금지).
함수가 자체적으로 `CRON_SECRET` 을 검증하므로 플랫폼 JWT 검증은 끄고(`--no-verify-jwt`) 배포한다.

```bash
supabase functions deploy refresh-products --no-verify-jwt
supabase secrets set \
  COUPANG_ACCESS_KEY=... COUPANG_SECRET_KEY=... \
  CRON_SECRET="$(openssl rand -hex 32)"
```

> 위 `CRON_SECRET` 값을 §3 의 Vault 시크릿 `refresh_products_token` 에도 **똑같이** 등록해야
> cron 호출이 통과한다(둘이 다르면 401). 쿠팡 키가 아직 없으면(파트너스 승인 전) 함수는
> no-op 성공을 반환하므로(§6.4), `CRON_SECRET` 만 설정해도 파이프라인 배선을 미리 검증할 수 있다.

### 계정 삭제 함수 배포 (`delete-account` — §3.3·§13.4, 스토어 필수)

앱의 "설정 › 계정 관리 › 계정 삭제"가 **현재 사용자 JWT** 로 호출하는 함수다. `refresh-products`
와 달리 `CRON_SECRET` 이 아니라 **호출자 본인의 access token 을 검증**하므로 플랫폼 JWT 검증을
**켠 채(기본값, `--no-verify-jwt` 금지)** 배포한다.

```bash
supabase functions deploy delete-account
```

- 별도 시크릿 설정이 필요 없다. 함수가 쓰는 `SUPABASE_URL` / `SUPABASE_ANON_KEY` /
  `SUPABASE_SERVICE_ROLE_KEY` 는 Edge 런타임에 자동 주입된다(`service_role` 키는 앱에 절대 노출 금지).
- 개인 데이터(babies·tracking_logs·favorites 등)는 `auth.users` 삭제 시 `on delete cascade`
  FK(0001_schema.sql·0002_rls.sql)로 함께 파기된다 — §8 요약 참조. 배포 전, 개인 소유 테이블
  전체가 `user_id` FK `on delete cascade` 인지 마이그레이션에서 확인할 것(파기 완결 전제).
- 대시보드 **Authentication → Providers** 에서 Apple/Google 프로바이더를 활성화해야 소셜 연결이
  동작한다(계정 삭제 자체는 프로바이더와 무관).

### 유휴 익명 계정 정리 함수 배포 (`cleanup-anonymous` — §3.3)

게스트 우선 정책상 앱은 부팅 시 익명 로그인을 만든다. 앱을 한 번만 열고 이탈한 게스트의
익명 계정이 누적되지 않도록, 주 1회 `cleanup-anonymous` 를 호출해 **마지막 활동이 90일을
초과한 `is_anonymous` 계정을 파기**한다. 개인 데이터(babies·tracking_logs·favorites 등)는
`auth.users` 삭제 시 `on delete cascade` FK 로 함께 삭제된다(§8 요약 참조).

`refresh-products` 와 동일하게 **`CRON_SECRET` 공유 비밀로 보호**하므로 플랫폼 JWT 검증은
끄고(`--no-verify-jwt`) 배포한다(호출자 본인 JWT 를 검증하는 `delete-account` 와 다름 — 이
함수는 Admin API 로 계정을 지우므로 반드시 서버 비밀 뒤에 둔다).

```bash
supabase functions deploy cleanup-anonymous --no-verify-jwt
# CRON_SECRET 은 refresh-products 배포 시 이미 설정했다면 그대로 공유된다(같은 프로젝트 시크릿).
# 아직 없다면:
supabase secrets set CRON_SECRET="$(openssl rand -hex 32)"
```

- 임계 일수·1회 삭제 상한은 환경변수로 조정 가능:
  `CLEANUP_INACTIVE_DAYS`(기본 `90`), `CLEANUP_MAX_DELETIONS`(기본 `500`).
- cron 스케줄(`0005_cleanup_cron.sql`)은 §3 의 Vault 시크릿 `refresh_products_token` 을
  **재사용**한다(두 cron 이 같은 `CRON_SECRET` 을 공유하는 전제). 별도 시크릿을 쓰려면
  `0005_cleanup_cron.sql` 의 `vault.decrypted_secrets` 조회 `name` 을 바꾸고, §3 절차로 그
  이름의 시크릿을 추가 등록할 것.
- `0005_cleanup_cron.sql` 안의 `<PROJECT_REF>` 도 `db push` 전에 실제 ref 로 치환해야 한다
  (§4 와 동일). 스케줄: UTC 토 19:00 == **KST 일요일 04:00**(주 1회).
- 확인/수동 실행/해제 쿼리는 §6 과 동일한 패턴(잡 이름만 `cleanup-anonymous-weekly`).

## 8. RLS · 계정 삭제 요약

- **공개 읽기**: `symptoms`, `symptom_infos`, `products`(active만), `app_config` — 클라이언트 쓰기 전면 차단. `products` 쓰기는 `service_role`(Edge Function)만.
- **본인 소유**: `babies`, `tracking_logs`, `favorites` — `auth.uid() = user_id`. 익명 로그인도 그대로 동작, `linkIdentity()` 후 데이터 이관 불필요.
- **계정 삭제**: `auth.users` 행 삭제 시 `on delete cascade` FK 로 개인 데이터 전부 자동 삭제(고아 없음). 별도 정리 로직 불필요. 단, `auth.users` 삭제는 Admin API(`auth.admin.deleteUser`) = 서버 권한 필요 → 앱의 "회원 탈퇴"는 서버에서 호출.
