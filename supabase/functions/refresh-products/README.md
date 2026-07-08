# refresh-products — 쿠팡 파트너스 제품 캐시 갱신 Edge Function

증상(symptoms)별로 쿠팡 파트너스 Open API 를 호출해 상위 제품을 검색하고,
내 트래킹 코드가 포함된 딥링크를 생성해 `products` 테이블에 upsert 하는
Supabase Edge Function 입니다.

설계서 근거: §6(데이터 파이프라인), §7.3(Edge Function 의사코드),
§8.1/§8.3(비밀값 위치).

---

## 동작 요약

1. `Authorization` 헤더가 `CRON_SECRET` 과 일치하는지 검증(불일치 시 401).
2. `COUPANG_ACCESS_KEY` / `COUPANG_SECRET_KEY` 가 없으면 **no-op 성공**을
   반환(수동 큐레이션 모드, §6.4). — 파트너스 승인 전에도 앱/파이프라인이
   안전하게 동작.
3. 활성 증상(`symptoms.is_active = true`)을 `order_index` 순으로 로드.
4. 증상마다 `product_keywords`(없으면 `name`)로 **순차 검색** → productId 기준
   중복 제거 → 상위 **N=10** 수집.
5. 수집된 상품 URL로 딥링크 일괄 생성(실패 시 트래킹 포함 `productUrl` 폴백).
6. `products` 를 `onConflict: 'symptom_id,coupang_pid'` 로 upsert
   (`rank_index`, `is_active=true`, `fetched_at` 갱신).
7. 이번 배치에 **없는 기존 활성 제품**은 `is_active=false` 처리.
8. rate-limit 회피: 검색/딥링크에 지수 백오프, 증상·키워드 간 sleep.
   개별 증상 실패 시 그 증상의 **이전 캐시를 유지**하고 다음으로 진행(§6.3).

응답은 JSON 요약: `{ ok, mode, symptoms, processed, updatedProducts, failedSymptoms }`.
`mode` 는 `live`(정상 갱신) 또는 `manual-curation`(키 미설정 no-op).

---

## 필요한 시크릿 / 환경변수

| 키 | 위치 | 설명 |
|---|---|---|
| `COUPANG_ACCESS_KEY` | Supabase Secrets | 파트너스 Access Key. 없으면 no-op. |
| `COUPANG_SECRET_KEY` | Supabase Secrets | 파트너스 Secret Key(HMAC 서명용). |
| `CRON_SECRET` | Supabase Secrets | 호출 보호용 공유 비밀. cron/수동 호출이 `Authorization`에 실어 보냄. |
| `REFRESH_SLEEP_MS` | (선택) Secrets | 증상·키워드 간 sleep(ms), 기본 `1200`. |
| `SUPABASE_URL` | 플랫폼 자동 주입 | 별도 설정 불필요. |
| `SUPABASE_SERVICE_ROLE_KEY` | 플랫폼 자동 주입 | products 쓰기(RLS 우회)용. 별도 설정 불필요. |

> 쿠팡/CRON 비밀은 **서버(Supabase Secrets)에만** 둔다. 앱 `.env` 나 리포지토리에
> 절대 넣지 않는다(§8.1).

### 시크릿 설정

```bash
supabase secrets set \
  COUPANG_ACCESS_KEY="발급받은_액세스_키" \
  COUPANG_SECRET_KEY="발급받은_시크릿_키" \
  CRON_SECRET="$(openssl rand -hex 32)"

# 설정 확인(값은 표시되지 않음)
supabase secrets list
```

`CRON_SECRET` 값을 안전한 곳에 보관해 두고, 아래 cron/수동 호출에서 사용한다.

---

## 배포

```bash
# 프로젝트 링크(최초 1회)
supabase link --project-ref <PROJECT_REF>

# 배포. 이 함수는 자체적으로 CRON_SECRET 을 검증하므로
# 플랫폼 JWT 검증은 끈다(--no-verify-jwt).
supabase functions deploy refresh-products --no-verify-jwt
```

배포 후 함수 URL: `https://<PROJECT_REF>.functions.supabase.co/refresh-products`

---

## 수동 트리거 (curl)

```bash
curl -i -X POST \
  "https://<PROJECT_REF>.functions.supabase.co/refresh-products" \
  -H "Authorization: Bearer <CRON_SECRET>"
```

- `Authorization` 는 `Bearer <CRON_SECRET>` 또는 `<CRON_SECRET>` 원문 모두 허용.
- 키 미설정 시:
  `{"ok":true,"mode":"manual-curation","message":"Coupang keys not configured; refresh skipped (no-op)."}`
- 정상 시:
  `{"ok":true,"mode":"live","symptoms":N,"processed":N,"updatedProducts":M,"failedSymptoms":[]}`
- 잘못된 시크릿: `401 {"ok":false,"error":"unauthorized"}`

로컬 개발:

```bash
supabase functions serve refresh-products --no-verify-jwt --env-file ./supabase/.env.local
# 다른 터미널에서
curl -X POST http://localhost:54321/functions/v1/refresh-products \
  -H "Authorization: Bearer <CRON_SECRET>"
```

---

## pg_cron 스케줄 (설계서 §7.4)

Supabase 대시보드의 **Integrations → Cron** UI 로 등록하는 것을 권장한다
(내부적으로 pg_cron). SQL 로 직접 등록할 경우 `CRON_SECRET` 값을 SQL 평문에
넣지 말고 **Supabase Vault** 에 이름 `refresh_products_token` 으로 저장해
참조한다(값은 함수의 `CRON_SECRET` 시크릿과 동일해야 함).

> 아래는 개념 예시다. 실제 적용본은 `supabase/migrations/0003_cron.sql` 이며,
> 시각은 **UTC `0 8,20`**(= KST 05:00·17:00, KST=UTC+9)로 등록된다. pg_cron 은
> UTC 로 동작하므로 아래 스케줄 문자열도 그 값을 쓴다.

```sql
select cron.schedule(
  'refresh-products-daily',
  '0 8,20 * * *',                                  -- UTC 08:00·20:00 == KST 17:00·05:00
  $$
    select net.http_post(
      url     := 'https://<PROJECT_REF>.functions.supabase.co/refresh-products',
      headers := jsonb_build_object(
        'Content-Type', 'application/json',
        'Authorization', 'Bearer ' || (select decrypted_secret
                                        from vault.decrypted_secrets
                                        where name = 'refresh_products_token')
      )
    );
  $$
);
```

---

## 쿠팡 파트너스 API 참고 (구현 근거)

- **호스트**: `https://api-gateway.coupang.com`
- **상품검색**: `GET /v2/providers/affiliate_open_api/apis/openapi/products/search?keyword=<kw>&limit=<n>`
  - 응답: `{ rCode, rMessage, data: { landingUrl, productData: [ { productId, productName, productImage, productPrice, productUrl, rank, ... } ] } }`
- **딥링크 생성**: `POST /v2/providers/affiliate_open_api/apis/openapi/v1/deeplink`
  - 본문: `{ "coupangUrls": ["<productUrl>", ...] }`
  - 응답: `{ rCode, rMessage, data: [ { originalUrl, shortenUrl, landingUrl } ] }`
- **HMAC 서명 (CEA 알고리즘)**:
  - `signed-date` = GMT `yyMMddTHHmmssZ` (예: `260708T123456Z`)
  - `message` = `signed-date + METHOD + PATH + QUERY` (구분자 없이 연결,
    PATH 는 `/` 포함·쿼리 미포함, QUERY 는 `?` 없이 요청과 동일 문자열)
  - `signature` = `HmacSHA256(secretKey, message)` 의 hex
  - `Authorization: CEA algorithm=HmacSHA256, access-key=<AK>, signed-date=<date>, signature=<sig>`

> ⚠️ **rate-limit 주의**: 파트너스 상품검색 API 는 호출 한도가 있다(과거 기준
> 시간당 소수). 활성 증상 수 × 키워드 수만큼 검색이 발생하므로, 증상/키워드가
> 많으면 한도를 초과할 수 있다. 필요 시 `REFRESH_SLEEP_MS` 를 늘리거나 cron
> 빈도(하루 1~2회)를 조절하고, 증상당 키워드 수를 제한할 것. 현재 한도는
> 파트너스 대시보드/문서에서 확인.
